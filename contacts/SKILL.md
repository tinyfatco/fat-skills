---
name: contacts
description: Manage email contacts — control who can email you and who you can email. Use when the user asks to add, remove, or list email contacts, whitelist a sender, or unblock email to a new address.
---

# Email Contacts

Manage who can email you (inbound) and who you can email (outbound). Adding a contact opens both gates in one call.

All requests authenticated via `FAT_TOOLS_TOKEN`.

## List Contacts

```bash
curl -s https://tinyfat.com/api/agent/contacts \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN"
```

Returns each contact with `inbound` and `outbound` booleans showing which gates are open.

## Add a Contact

```bash
curl -s -X POST https://tinyfat.com/api/agent/contacts \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "person@example.com"}'
```

Idempotent — safe to call multiple times for the same email.

## Add an Entire Domain

```bash
curl -s -X POST https://tinyfat.com/api/agent/contacts \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email": "@example.com", "match_type": "domain"}'
```

Opens inbound + outbound for every address at that domain.

## Remove a Contact

```bash
curl -s -X DELETE "https://tinyfat.com/api/agent/contacts?email=person@example.com" \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN"
```

Removes from both inbound and outbound lists.

## Important

- **Before emailing someone new**, add them as a contact first or you'll get a 403.
- **Before someone new can email you**, they need to be added as a contact.
- Adding a contact handles both directions automatically.
