#!/bin/bash
# snapshot-delta.sh — Diff current filesystem against base manifest, build delta tarball.
# Called by wrapper scripts after any package manager operation that succeeds.
# Persists to /data/.pkg-cache/delta.tar.gz (R2-backed).

set -euo pipefail

CACHE_DIR="/data/.pkg-cache"
BASE_MANIFEST="/opt/fat-pkg/base-manifest.txt"
DELTA_TARBALL="$CACHE_DIR/delta.tar.gz"
META_FILE="$CACHE_DIR/meta.json"

# Tracked directories — where package managers install files
TRACKED_DIRS=(
    /usr/bin
    /usr/sbin
    /usr/lib
    /usr/share
    /usr/local/bin
    /usr/local/lib/node_modules
    /usr/local/lib/python3*/dist-packages
    /etc
)

# Bail if /data isn't mounted (graceful degradation)
if ! mountpoint -q /data 2>/dev/null; then
    echo "[pkg-cache] /data not mounted, skipping snapshot" >&2
    exit 0
fi

# Bail if base manifest doesn't exist (image wasn't built with pkg-cache support)
if [[ ! -f "$BASE_MANIFEST" ]]; then
    echo "[pkg-cache] no base manifest at $BASE_MANIFEST, skipping snapshot" >&2
    exit 0
fi

mkdir -p "$CACHE_DIR"

# Build current file listing of tracked directories
CURRENT=$(mktemp)
# Expand globs and skip dirs that don't exist
for dir in "${TRACKED_DIRS[@]}"; do
    # shellcheck disable=SC2086
    for expanded in $dir; do
        [[ -d "$expanded" ]] && find "$expanded" -type f 2>/dev/null
    done
done | sort > "$CURRENT"

# Diff: files in current but not in base = agent-installed files
NEW_FILES=$(mktemp)
comm -23 "$CURRENT" "$BASE_MANIFEST" > "$NEW_FILES"

FILE_COUNT=$(wc -l < "$NEW_FILES")

if [[ "$FILE_COUNT" -eq 0 ]]; then
    echo "[pkg-cache] no new files to cache"
    rm -f "$CURRENT" "$NEW_FILES"
    exit 0
fi

# Build tarball from the delta files
tar czf "$DELTA_TARBALL" -T "$NEW_FILES" 2>/dev/null || true

TARBALL_SIZE=$(stat -c%s "$DELTA_TARBALL" 2>/dev/null || echo 0)

# Write metadata
IMAGE_VERSION="${CRAWDAD_VERSION:-unknown}"
cat > "$META_FILE" << EOF
{
    "image_version": "$IMAGE_VERSION",
    "file_count": $FILE_COUNT,
    "tarball_bytes": $TARBALL_SIZE,
    "snapshot_at": "$(date -Iseconds)",
    "trigger": "${PKG_CACHE_TRIGGER:-unknown}"
}
EOF

echo "[pkg-cache] cached $FILE_COUNT files ($(( TARBALL_SIZE / 1024 ))KB) to $DELTA_TARBALL"

rm -f "$CURRENT" "$NEW_FILES"
