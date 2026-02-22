---
name: platform-apis
description: TinyFat platform API integrations — secrets persistence, contacts/whitelist management. Always loaded as a platform skill.
---

# TinyFat Platform APIs

These APIs let you manage your platform configuration from inside the container. All authenticated via `FAT_TOOLS_TOKEN`.

## Secrets Persistence

Persist secrets (API tokens, credentials) so they survive container restarts.

```bash
curl -s -X PATCH https://tinyfat.com/api/agent/secrets \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"key_name": "secret_value"}'
```

Known keys that get special handling on boot:
- `gh_token` — Sets `GH_TOKEN` env var + writes `~/.config/gh/hosts.yml`
- `openai_key` — Sets `OPENAI_API_KEY` env var
- `google_api_key` — Sets `GOOGLE_API_KEY` env var
- Any key prefixed with `env_` becomes an env var (e.g. `env_MY_KEY` → `MY_KEY`)

## Contacts Management

Manage your email contacts (who can email you, who you can email).

```bash
# List contacts
curl -s https://tinyfat.com/api/agent/contacts \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN"

# Add a contact (opens both inbound + outbound)
curl -s -X POST https://tinyfat.com/api/agent/contacts \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "person@example.com"}'

# Add entire domain
curl -s -X POST https://tinyfat.com/api/agent/contacts \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "@example.com", "match_type": "domain"}'

# Remove a contact
curl -s -X DELETE "https://tinyfat.com/api/agent/contacts?email=person@example.com" \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN"
```

Adding a contact opens both gates: they can email you (inbound) AND you can email them (outbound). Use domain match to whitelist an entire organization.
