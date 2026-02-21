---
name: gh-login
description: Authenticate the GitHub CLI (gh) and persist the token so it survives container restarts. Use when the user asks to set up GitHub, log into gh, or connect a GitHub account.
---

# GitHub CLI Authentication

Authenticate `gh` and persist the token to platform storage so it survives sleep/wake cycles.

## Option 1: Personal Access Token (Recommended)

If the user provides a GitHub PAT:

```bash
# Set the token directly
echo "TOKEN_HERE" | gh auth login --with-token

# Verify it works
gh auth status
```

## Option 2: Device Flow (Interactive)

If the user wants to do the browser-based OAuth flow:

```bash
gh auth login --web
```

This will print a device code and URL. The user visits the URL in their browser and enters the code.

## After Authentication: Persist the Token

After `gh auth status` confirms success, persist the token so it survives container restarts:

```bash
# Extract the current token
TOKEN=$(gh auth token)

# Persist to platform storage
curl -s -X PATCH https://tinyfat.com/api/agent/secrets \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"gh_token\": \"$TOKEN\"}"
```

If the curl returns `{"ok":true}`, the token is stored. On next container wake, `gh` will be pre-authenticated automatically.

## Verifying Persistence

After persisting, you can confirm the token is stored:

```bash
# This works now (current session)
gh auth status

# After a restart, gh will also work because the platform
# hydrates GH_TOKEN and ~/.config/gh/hosts.yml on boot
```

## Troubleshooting

- **"gh: command not found"** — gh is pre-installed in the container image. This shouldn't happen.
- **Token not persisting** — Make sure `FAT_TOOLS_TOKEN` is set. Run `echo $FAT_TOOLS_TOKEN` to check.
- **Auth fails after restart** — The persist step may have failed. Re-run the curl command above.
