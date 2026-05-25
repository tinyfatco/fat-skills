---
name: scheduling
description: Create or edit TinyFat calendar events and attention queue prompts. Use when adding user-world calendar items, one-shot reminders, recurring checks, immediate triggers, or quiet periodic background work.
---

# Scheduling

Use this skill for two different time-related surfaces:

- Calendar events in `/data/calendar/events/`
- Attention prompts in `/data/attention/queue/`

Calendar events are visible context for the workspace calendar. They do not wake
the agent. Attention prompts wake the agent and inject work back into awareness.

## Calendar Events

Create one JSON file per user-world calendar item in:

`/data/calendar/events/`

Use unique, readable filenames, usually with a date prefix:

`/data/calendar/events/2026-05-21-demo-call.json`

Timed event:

```json
{
  "id": "2026-05-21-demo-call",
  "title": "Demo call",
  "start": "2026-05-21T14:00:00-05:00",
  "end": "2026-05-21T14:30:00-05:00",
  "allDay": false,
  "source": "agent",
  "status": "confirmed",
  "description": "Optional notes or context for the event."
}
```

All-day event:

```json
{
  "id": "2026-05-22-launch-day",
  "title": "Launch day",
  "start": "2026-05-22T00:00:00-05:00",
  "end": "2026-05-23T00:00:00-05:00",
  "allDay": true,
  "source": "agent"
}
```

Calendar notes:

- `start` is required. Use ISO 8601 with an explicit timezone offset.
- `end` is recommended. If omitted, the calendar assumes 30 minutes for timed
  events or 24 hours for all-day events.
- `title` is recommended. If omitted, the filename becomes the title.
- `description` or `notes` can hold optional context.
- `source` can be `agent`, `user`, or `google`; it affects default color.
- `status: "cancelled"` renders the event muted.
- `color` can override the default event color with a CSS color such as
  `#0f766e`.
- Accepted aliases: `start_at`, `at`, or `date` for `start`; `end_at` for
  `end`; `all_day` for `allDay`; `summary` or `text` for `title`; `notes` for
  `description`.

## Attention Queue

Create one JSON file per scheduled prompt in:

`/data/attention/queue/`

Attention prompts bring something back into awareness. Do not specify
`channelId`; attention prompts run in the heartbeat channel by default. If the
task needs to reach a specific real channel, use `send_message_to_channel` when
the prompt executes.

Immediate prompt:

```json
{
  "type": "immediate",
  "text": "New webhook received - check /data/inbox/"
}
```

One-shot prompt:

```json
{
  "type": "one-shot",
  "text": "Remind Nick about the proposal",
  "at": "2026-03-01T09:00:00-06:00"
}
```

Periodic prompt:

```json
{
  "type": "periodic",
  "text": "Check inbox and summarize new messages",
  "schedule": "0 9 * * 1-5",
  "timezone": "America/Chicago"
}
```

Attention notes:

- File must have a `.json` extension.
- Use unique filenames with a timestamp or short slug.
- Keep at most 5 queued prompts unless the user explicitly needs more.
- Immediate and one-shot prompts auto-delete after firing.
- Periodic prompts persist until deleted.
- Debounce immediate prompts; batch multiple signals into one file instead of
  creating many.
- Triggered prompts appear as `[ATTENTION:filename.json:type:time] text`.
- For periodic prompts with nothing to report, use `yield_no_action` so the
  quiet completion is recorded without posting a response.

## Timezones

When the user gives a fuzzy time like "tomorrow afternoon," convert it to a
concrete ISO timestamp in their timezone before writing the event or prompt.
When no timezone is specified, use the timezone from the current system prompt.
