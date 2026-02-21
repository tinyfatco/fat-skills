---
name: gh-login
description: Authenticate the GitHub CLI (gh) and persist the token so it survives container restarts. Use when the user asks to set up GitHub, log into gh, or connect a GitHub account.
---

# GitHub CLI Authentication

Authenticate `gh` and persist the token to platform storage so it survives sleep/wake cycles.

## Option 1: Personal Access Token (Fastest)

If the user provides a GitHub PAT:

```bash
echo "TOKEN_HERE" | gh auth login --with-token
gh auth status
```

## Option 2: Device Flow (Interactive — requires tmux)

The device flow is interactive and needs a persistent session. Run it in tmux:

```bash
# Start the login flow in a tmux session
tmux new-session -d -s gh-login 'gh auth login --web -p https 2>&1 | tee /tmp/gh-login.log'

# Wait a moment for the prompts, then read the output
sleep 3
cat /tmp/gh-login.log
```

The output will contain:
1. A one-time code (e.g. `ABCD-1234`)
2. A URL (https://github.com/login/device)

**Tell the user both.** They visit the URL in their browser and enter the code.

After the user confirms they completed the browser flow:

```bash
# Check if the tmux session finished (login succeeded)
cat /tmp/gh-login.log
gh auth status
```

If `gh auth status` shows authenticated, proceed to persist the token below.

## After Authentication: Persist the Token

This step is critical — without it, the token is lost on container restart.

```bash
TOKEN=$(gh auth token)

curl -s -X PATCH https://tinyfat.com/api/agent/secrets \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"gh_token\": \"$TOKEN\"}"
```

If the curl returns `{"ok":true}`, the token is durably stored. On next container wake, `gh` will be pre-authenticated automatically via `GH_TOKEN` env var and `~/.config/gh/hosts.yml`.

## Troubleshooting

- **"gh: command not found"** — gh is pre-installed in the container image. This shouldn't happen.
- **Token not persisting** — Make sure `FAT_TOOLS_TOKEN` is set: `echo $FAT_TOOLS_TOKEN`
- **Auth fails after restart** — The persist step may have failed. Re-run the curl command above.
- **tmux session stuck** — `tmux kill-session -t gh-login` and retry.
