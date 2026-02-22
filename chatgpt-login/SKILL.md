---
name: chatgpt-login
description: Log in with a ChatGPT Plus or Pro subscription to unlock OpenAI Codex models. Use when the user asks to connect ChatGPT, log in to OpenAI, set up Codex, or use their ChatGPT subscription.
---

# ChatGPT Login (OpenAI Codex OAuth)

Log in with a ChatGPT Plus/Pro subscription. This gives the agent access to OpenAI Codex models (GPT-5.x) via the user's existing subscription.

## How It Works

The login uses OAuth — the user visits a URL in their browser, authorizes, then pastes the redirect URL back. The local callback server won't work in this environment, so the manual paste flow is used.

## Step 1: Start the Login Flow

Run the pi-ai CLI in tmux (it's interactive):

```bash
mkdir -p ~/.pi/agent
tmux new-session -d -s chatgpt-login 'cd ~/.pi/agent && npx @mariozechner/pi-ai login openai-codex 2>&1 | tee /tmp/chatgpt-login.log'

sleep 5
cat /tmp/chatgpt-login.log
```

The output will contain an auth URL like `https://auth.openai.com/oauth/authorize?...`

**Tell the user:**
1. Open the URL in their browser
2. Log in to their ChatGPT account and authorize
3. The browser will redirect to `http://localhost:1455/...` which will fail — that's expected
4. Copy the **full URL** from their browser's address bar (it contains the authorization code)
5. Paste it back in chat

## Step 2: Complete the Login

Once the user pastes the redirect URL, type it into the tmux session:

```bash
tmux send-keys -t chatgpt-login "PASTE_URL_HERE" Enter
sleep 3
cat /tmp/chatgpt-login.log
```

Check for "Credentials saved to auth.json" in the output. If it appears, login succeeded.

Verify:
```bash
cat ~/.pi/agent/auth.json
```

You should see a JSON object with an `openai-codex` key containing `access`, `refresh`, `expires`, and `accountId`.

## Step 3: Persist Credentials

Without this step, the credentials are lost on container restart.

```bash
CREDS=$(cat ~/.pi/agent/auth.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get('openai-codex', {})))")

curl -s -X PATCH https://tinyfat.com/api/agent/secrets \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"codex_credentials\": $CREDS}"
```

If the curl returns `{"ok":true}`, credentials are durably stored. On next container wake, `~/.pi/agent/auth.json` will be restored automatically.

## Step 4: Switch Model (Optional)

After login, the user can switch to a Codex model:

```
/model openai-codex
```

Or tell the agent to use it for specific tasks.

## Troubleshooting

- **"npx: command not found"** — Node.js should be pre-installed. Try `node --version`.
- **Auth URL not appearing** — Wait longer, then `cat /tmp/chatgpt-login.log` again.
- **"Token exchange failed"** — The pasted URL may be wrong or expired. Kill the session (`tmux kill-session -t chatgpt-login`) and start over.
- **Credentials not persisting** — Check `echo $FAT_TOOLS_TOKEN` is set.
- **tmux session stuck** — `tmux kill-session -t chatgpt-login` and retry.
