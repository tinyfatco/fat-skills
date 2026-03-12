---
name: scheduling
description: Schedule recurring jobs, one-shot reminders, and immediate triggers. Events are JSON files in /data/events/ that persist across container sleep/wake cycles.
---

# Scheduling

Schedule jobs by writing JSON files to `/data/events/`. The platform wakes your container automatically when events are due — even from a cold sleep.

## Event Types

### Periodic (recurring cron jobs)

```json
{"type": "periodic", "channelId": "CHANNEL_ID", "text": "Check inbox and summarize new messages", "schedule": "0 9 * * 1-5", "timezone": "America/Chicago"}
```

### One-shot (fire once at a specific time)

```json
{"type": "one-shot", "channelId": "CHANNEL_ID", "text": "Remind Nick about the proposal", "at": "2026-03-01T09:00:00+04:00"}
```

### Immediate (fire now)

```json
{"type": "immediate", "channelId": "CHANNEL_ID", "text": "New webhook received — check /data/inbox/"}
```

## Creating Events

```bash
cat > /data/events/daily-btc-report.json << 'EOF'
{"type": "periodic", "channelId": "CHANNEL_ID", "text": "Fetch Bitcoin price and email the daily report", "schedule": "0 4 * * *", "timezone": "UTC"}
EOF
```

**Rules:**
- File MUST have `.json` extension (not `.jsonl`, not `.txt`)
- File MUST be in `/data/events/` (not a subdirectory)
- Use descriptive filenames: `daily-btc-report.json`, `monday-standup.json`, `remind-dentist-1709312400.json`
- One event per file

## Required Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `type` | `"periodic"` / `"one-shot"` / `"immediate"` | Always | |
| `channelId` | string | Always | The channel to deliver the event to (see below) |
| `text` | string | Always | The message you'll receive when the event fires |
| `schedule` | cron string | Periodic only | `minute hour day-of-month month day-of-week` |
| `timezone` | IANA timezone | Periodic only | e.g. `America/New_York`, `Europe/Dubai`, `UTC` |
| `at` | ISO 8601 with offset | One-shot only | e.g. `2026-03-01T09:00:00-06:00` |

## Getting the channelId

The channelId tells the platform which channel to deliver the event on. **Use the channel you're currently in** unless the user asks for delivery elsewhere.

Your current channelId is visible in the system prompt under "Workspace Layout" — it's the directory name under `/data/`:

```
/data/
├── MEMORY.md
└── 8389147137/     ← this is the channelId for this Telegram chat
    ├── MEMORY.md
    └── log.jsonl
```

To find all your channels:

```bash
ls -d /data/*/  # directories with context.jsonl are active channels
```

Common channel ID formats:
- Telegram: numeric (e.g. `8389147137`, `-5270764036`)
- Slack: alphanumeric (e.g. `C09V58YMJGP`)
- Email: `email-user_domain_com`
- Web: `web`

## Heartbeat: Autonomous Thinking Sessions

Use the special channelId `_heartbeat` when you want to wake up and **think privately** before deciding whether to act. Heartbeat events don't post to any chat — they give you a silent session where you review context and decide what to do.

```json
{"type": "periodic", "channelId": "_heartbeat", "text": "Review task list and follow up on anything overdue", "schedule": "0 10 * * 1-5", "timezone": "America/Chicago"}
```

### When to use `_heartbeat` vs a regular channelId

| Use `_heartbeat` | Use a regular channelId |
|---|---|
| You need to think before deciding where (or whether) to send a message | You know exactly which channel should receive the output |
| The event should check multiple channels and act across them | The event is a reminder or report for one specific conversation |
| Most firings should be silent (nothing to do) | Every firing should produce visible output |

### What you get in a heartbeat

- **Cross-channel activity summary** — recent messages from all your channels (Telegram, Slack, email, web) are included automatically so you have situational awareness
- **`send_message` tool** — reach any channel from the heartbeat session. You can send to multiple channels in one heartbeat if warranted
- **Silent by default** — if nothing needs doing, respond with just `[SILENT]` and no message is posted anywhere

### Heartbeat guidelines

- **Be selective.** Most heartbeats should be silent. Only send messages when there's something worth saying.
- **Be concise.** When you do reach out, keep it short and purposeful.
- **Check your context.** Review your task list, memory, and the activity summary before deciding what to do.
- **Vary your timing.** If you want organic-feeling check-ins, use multiple one-shot events at slightly irregular times rather than a rigid cron.

### Example: Daily autonomous check-in

```bash
cat > /data/events/daily-checkin.json << 'EOF'
{"type": "periodic", "channelId": "_heartbeat", "text": "Morning check-in: review tasks, scan channels for anything that needs follow-up, send messages if warranted", "schedule": "0 9 * * 1-5", "timezone": "America/New_York"}
EOF
```

### Example: One-shot follow-up

```bash
TARGET=$(date -u -d '+3 hours' +%Y-%m-%dT%H:%M:%S+00:00)
cat > /data/events/followup-$(date +%s).json << EOF
{"type": "one-shot", "channelId": "_heartbeat", "text": "Check if Alex responded to the proposal question. If not, send a gentle nudge on Telegram.", "at": "$TARGET"}
EOF
```

## Cron Format

`minute hour day-of-month month day-of-week`

| Pattern | Meaning |
|---------|---------|
| `0 9 * * *` | Daily at 9:00 |
| `0 9 * * 1-5` | Weekdays at 9:00 |
| `30 14 * * 1` | Mondays at 14:30 |
| `0 0 1 * *` | First of each month at midnight |
| `0 */2 * * *` | Every 2 hours |
| `0 9,17 * * *` | 9:00 and 17:00 daily |

**Timezone matters.** A cron of `0 9 * * *` with timezone `America/New_York` fires at 9am Eastern. Always set timezone to the user's local timezone, not UTC, unless they specify otherwise.

## Managing Events

```bash
# List active events
ls /data/events/*.json

# View an event
cat /data/events/daily-btc-report.json

# Cancel/delete an event
rm /data/events/daily-btc-report.json

# Update an event (overwrite the file)
cat > /data/events/daily-btc-report.json << 'EOF'
{"type": "periodic", "channelId": "CHANNEL_ID", "text": "Updated task description", "schedule": "0 5 * * *", "timezone": "UTC"}
EOF
```

## When Events Fire

You receive a message like:

```
[EVENT:daily-btc-report.json:periodic:0 4 * * *] Fetch Bitcoin price and email the daily report
```

- **Immediate and one-shot events auto-delete** after firing
- **Periodic events persist** until you delete them
- If a periodic check finds nothing actionable, respond with just `[SILENT]` — this posts nothing to the channel

## After Creating an Event

Always verify it was written correctly:

```bash
cat /data/events/your-event.json | python3 -m json.tool
```

And confirm to the user what you scheduled, including the time and timezone.

## Common Patterns

### Daily morning report
```bash
cat > /data/events/morning-report.json << 'EOF'
{"type": "periodic", "channelId": "CHANNEL_ID", "text": "Morning report: check email, summarize calendar, list top priorities", "schedule": "0 8 * * *", "timezone": "America/Chicago"}
EOF
```

### Reminder in 2 hours
```bash
# Calculate the target time
TARGET=$(date -u -d '+2 hours' +%Y-%m-%dT%H:%M:%S+00:00)
cat > /data/events/remind-$(date +%s).json << EOF
{"type": "one-shot", "channelId": "CHANNEL_ID", "text": "Reminder: review the deployment", "at": "$TARGET"}
EOF
```

### Weekly Monday standup
```bash
cat > /data/events/monday-standup.json << 'EOF'
{"type": "periodic", "channelId": "CHANNEL_ID", "text": "Weekly standup: summarize last week, plan this week", "schedule": "0 9 * * 1", "timezone": "Europe/London"}
EOF
```

## Limits

- Maximum 5 event files at a time
- Don't create per-item immediate events for bulk activity — use one periodic event to poll instead

## Troubleshooting

**Event not firing:**
1. Check the file exists: `ls /data/events/*.json`
2. Check it's valid JSON: `cat /data/events/FILE.json | python3 -m json.tool`
3. Check the extension is `.json` (not `.jsonl`)
4. For periodic: verify cron syntax and timezone are correct
5. For one-shot: verify the `at` timestamp is in the future and includes timezone offset

**Event fired but nothing happened:**
- The `text` field is what you receive as a message. Make it descriptive enough that you know what to do when you wake up with no other context.

**Stale events in the directory:**
- `.jsonl` files in `/data/events/` are NOT events — they're orphaned session logs. Delete them: `rm /data/events/*.jsonl`
