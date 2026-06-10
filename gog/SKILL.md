---
name: gog
description: Google Workspace CLI for Gmail, Calendar, Drive, Contacts, Sheets, Docs, and Slides.
homepage: https://gogcli.sh
metadata: {"clawdbot":{"requires":{"bins":["gog"]}}}
---

# gog

Use `gog` for Google Workspace operations across Gmail, Calendar, Drive,
Contacts, Sheets, Docs, Slides, Tasks, People, Chat, Forms, Apps Script, Groups,
Admin, and Classroom. The CLI is JSON-friendly and supports multiple Google
accounts.

## Setup

Prefer the agent slash command:

```bash
/login google you@example.com
```

The command prints a Google authorization URL. Open it in a browser, approve
access, then paste the full `http://127.0.0.1:.../oauth2/callback?...` redirect
URL back into the chat.

If you are setting up credentials manually:

```bash
gog auth credentials set /path/to/client_secret.json
gog auth add you@example.com --services gmail,calendar,drive,contacts,docs,sheets --remote
gog auth list
```

Set the active account when needed:

```bash
export GOG_ACCOUNT=you@example.com
```

## Common Commands

Use `--json --no-input` for scripting.

```bash
gog --json --no-input auth status
gog --json --no-input people me
```

Gmail:

```bash
gog --json --no-input gmail search 'newer_than:7d' --max 10
gog --json --no-input gmail messages search 'in:inbox from:example.com' --max 20
gog --json --no-input gmail labels list
gog gmail drafts create --to person@example.com --subject "Subject" --body-file ./message.txt
gog gmail send --to person@example.com --subject "Subject" --body-file ./message.txt
gog gmail send --to person@example.com --subject "Re: Subject" --body-file ./reply.txt --reply-to-message-id <msgId>
```

Gmail body formatting:

For Gmail drafts and sends, prefer minimal HTML passed through `--body-html`
when formatting matters. Keep the output as close to native Gmail composition
as possible:

- Do not use a layout wrapper, max-width container, table shell, custom font
  stack, fixed font size, custom line-height, or artificial body spacing.
- Use `body { margin:0; padding:0; }` to avoid an extra gap above the first
  line.
- Use paragraphs with `margin:0 0 1em 0;` so the first paragraph has no top
  margin and each paragraph keeps natural spacing after it.
- Prefer `1em` spacing over fixed pixels so spacing scales with the email
  client's default text size.

Example:

```bash
cat > message.html <<'EOF'
<!doctype html>
<html>
<body style="margin:0; padding:0;">
<p style="margin:0 0 1em 0;">Hi Alex,</p>
<p style="margin:0 0 1em 0;">Thanks for sending this over. I drafted the reply in Gmail.</p>
<p style="margin:0 0 1em 0;">Best,<br>Alex's AI agent</p>
</body>
</html>
EOF
gog gmail drafts create --to person@example.com --subject "Subject" --body-html "$(cat ./message.html)"
```

Calendar:

```bash
gog --json --no-input calendar list
gog --json --no-input calendar events primary --from 2026-06-09T00:00:00-05:00 --to 2026-06-10T00:00:00-05:00
gog calendar create primary --summary "Call" --from 2026-06-09T14:00:00-05:00 --to 2026-06-09T14:30:00-05:00
gog calendar update primary <eventId> --summary "New title"
gog calendar colors
```

Drive and Docs:

```bash
gog --json --no-input drive search "name contains 'invoice'" --max 10
gog drive download <fileId> --out ./downloaded-file
gog docs export <docId> --format txt --out /tmp/doc.txt
gog docs cat <docId>
```

Sheets:

```bash
gog --json --no-input sheets get <sheetId> "Tab!A1:D10"
gog sheets update <sheetId> "Tab!A1:B2" --values-json '[["A","B"],["1","2"]]' --input USER_ENTERED
gog sheets append <sheetId> "Tab!A:C" --values-json '[["x","y","z"]]' --insert INSERT_ROWS
gog sheets clear <sheetId> "Tab!A2:Z"
gog --json --no-input sheets metadata <sheetId>
```

## Credential Storage

This v1 integration is not egress-proxied. The Google OAuth client credentials
are hydrated from the agent's encrypted secrets to
`/data/.config/gogcli/credentials.json`. After `/login google`, `gog` stores the
account refresh token in its file keyring under `/data/.config/gogcli/keyring`.
That path lives on the encrypted R2-backed `/data` mount, but the awake agent can
read and use it at runtime.

## Safety

Confirm before sending mail, creating calendar events, or modifying files or
sheets. Prefer drafts for outbound email unless the user explicitly asks you to
send.
