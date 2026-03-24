#!/bin/bash
# Query a Notion database with clean output
# Usage: ./notion-db.sh <database-id> [options]
#
# Options:
#   --format json|table|csv   Output format (default: table)
#   --filter "Prop=value"     Filter by property (can repeat)
#   --sort "Prop asc|desc"    Sort by property
#   --limit N                 Max rows (default: 100)
#   --cols "Col1,Col2,..."    Only show these columns
#
# Examples:
#   ./notion-db.sh 2cf4ba24-f6f5-80f2-bb54-ff59ea7bc30e
#   ./notion-db.sh <id> --filter "Available=true" --sort "Rating desc"
#   ./notion-db.sh <id> --format csv --cols "Name,Category,Notes"

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)

DB_ID="$1"
shift || true

FORMAT="table"
LIMIT=100
FILTERS=()
SORT=""
COLS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --format) FORMAT="$2"; shift 2 ;;
        --filter) FILTERS+=("$2"); shift 2 ;;
        --sort) SORT="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --cols) COLS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$DB_ID" ]; then
    echo "Usage: ./notion-db.sh <database-id> [options]"
    echo ""
    echo "Options:"
    echo "  --format json|table|csv   Output format (default: table)"
    echo "  --filter \"Prop=value\"     Filter by property"
    echo "  --sort \"Prop asc|desc\"    Sort by property"  
    echo "  --limit N                 Max rows (default: 100)"
    echo "  --cols \"Col1,Col2,...\"    Only show these columns"
    exit 1
fi

# Clean DB ID
DB_ID=$(echo "$DB_ID" | tr -d '-')

# Build query JSON
QUERY="{\"page_size\": $LIMIT"

# Add sorts if specified
if [ -n "$SORT" ]; then
    PROP=$(echo "$SORT" | awk '{print $1}')
    DIR=$(echo "$SORT" | awk '{print $2}')
    [ -z "$DIR" ] && DIR="ascending"
    [ "$DIR" = "desc" ] && DIR="descending"
    [ "$DIR" = "asc" ] && DIR="ascending"
    QUERY="$QUERY, \"sorts\": [{\"property\": \"$PROP\", \"direction\": \"$DIR\"}]"
fi

# TODO: Add filter support (complex - need property type detection)

QUERY="$QUERY}"

# Fetch database schema first to know property types
SCHEMA=$(curl -s "https://api.notion.com/v1/databases/$DB_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28")

DB_TITLE=$(echo "$SCHEMA" | jq -r '.title[0].plain_text // "Untitled"')

# Fetch rows
ROWS=$(curl -s "https://api.notion.com/v1/databases/$DB_ID/query" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "$QUERY")

# Extract property names in order (title first, then alphabetical)
PROPS=$(echo "$SCHEMA" | jq -r '
    .properties | to_entries | 
    sort_by(if .value.type == "title" then "0" else .key end) |
    map(.key) | @json')

# If --cols specified, filter to those
if [ -n "$COLS" ]; then
    PROPS=$(echo "$COLS" | jq -R 'split(",")')
fi

# JQ script to extract values from any property type
extract_value() {
    cat << 'JQ'
def extract_prop:
    if .type == "title" then
        (.title | map(.plain_text) | join(""))
    elif .type == "rich_text" then
        (.rich_text | map(.plain_text) | join(""))
    elif .type == "number" then
        (.number | tostring)
    elif .type == "select" then
        (.select.name // "")
    elif .type == "multi_select" then
        (.multi_select | map(.name) | join(", "))
    elif .type == "checkbox" then
        (if .checkbox then "✓" else "" end)
    elif .type == "url" then
        (.url // "")
    elif .type == "email" then
        (.email // "")
    elif .type == "phone_number" then
        (.phone_number // "")
    elif .type == "date" then
        (.date.start // "")
    elif .type == "formula" then
        (.formula.string // .formula.number // "")
    elif .type == "relation" then
        (.relation | length | tostring) + " links"
    elif .type == "rollup" then
        (.rollup.number // (.rollup.array | length | tostring) // "")
    elif .type == "created_time" then
        .created_time[0:10]
    elif .type == "last_edited_time" then
        .last_edited_time[0:10]
    elif .type == "created_by" then
        .created_by.name // ""
    elif .type == "last_edited_by" then
        .last_edited_by.name // ""
    elif .type == "status" then
        (.status.name // "")
    else
        ""
    end;
JQ
}

case $FORMAT in
    json)
        # Output as JSON array of objects
        echo "$ROWS" | jq --argjson props "$PROPS" '
            '"$(extract_value)"'
            .results | map(
                . as $row |
                reduce ($props[]) as $prop (
                    {};
                    . + {($prop): ($row.properties[$prop] | extract_prop)}
                )
            )'
        ;;
    
    csv)
        # Output as CSV
        echo "$ROWS" | jq -r --argjson props "$PROPS" '
            '"$(extract_value)"'
            ($props | @csv),
            (.results[] | 
                . as $row |
                [$props[] | $row.properties[.] | extract_prop] | @csv
            )'
        ;;
    
    table|*)
        # Output as formatted table
        echo "=== $DB_TITLE ==="
        echo ""
        echo "$ROWS" | jq -r --argjson props "$PROPS" '
            '"$(extract_value)"'
            # Header
            ($props | join("\t")),
            "---",
            # Rows
            (.results[] | 
                . as $row |
                [$props[] | $row.properties[.] | extract_prop] | join("\t")
            )' | column -t -s $'\t' 2>/dev/null || \
        echo "$ROWS" | jq -r --argjson props "$PROPS" '
            '"$(extract_value)"'
            ($props | join(" | ")),
            (.results[] | 
                . as $row |
                [$props[] | $row.properties[.] | extract_prop] | join(" | ")
            )'
        ;;
esac
