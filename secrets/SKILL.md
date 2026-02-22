---
name: secrets
description: Persist secrets (API tokens, credentials) so they survive container restarts. Use when the user asks to save a token, persist a key, or set up credentials that should last across sessions.
---

# Secrets Persistence

Persist secrets so they survive container sleep/wake cycles. Secrets are encrypted at rest.

Authenticated via `FAT_TOOLS_TOKEN`.

## Save Secrets

```bash
curl -s -X PATCH https://tinyfat.com/api/agent/secrets \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key_name": "secret_value"}'
```

Merges with existing secrets — only adds or overwrites keys you specify.

## Known Keys with Special Handling

These keys get automatically wired up on every container boot:

| Key | Effect on Boot |
|-----|---------------|
| `gh_token` | Sets `GH_TOKEN` env var + writes `~/.config/gh/hosts.yml` |
| `openai_key` | Sets `OPENAI_API_KEY` env var |
| `google_api_key` | Sets `GOOGLE_API_KEY` env var |
| `env_*` (prefix) | Any key starting with `env_` becomes an env var (e.g. `env_MY_KEY` → `MY_KEY`) |

## Example: Persist a GitHub Token

```bash
TOKEN=$(gh auth token)
curl -s -X PATCH https://tinyfat.com/api/agent/secrets \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"gh_token\": \"$TOKEN\"}"
```

After this, `gh` will be pre-authenticated on every boot.
