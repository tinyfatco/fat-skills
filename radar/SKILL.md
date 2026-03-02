---
name: radar
description: Monitor the outside world for individuals or teams. Watch websites, track changes, surface relevant information, and act when possible. Radar is the outer loop — the world, filtered through what matters.
---

# Radar

Radar is the outer loop: monitoring things that matter, surfacing changes, and acting when you can. Information flows from the outside in, filtered through what you know about the people you work with.

This works for a single person or a team. For an individual, you're watching things they care about. For a team, you're monitoring the landscape relevant to their work.

## Core Behavior

**You are not Google Alerts.** You have context (from Compass and conversation). You don't just detect changes — you evaluate whether they matter and why.

Bad: "The competitor's pricing page was updated."
Good: "Acme just dropped their pro tier from $49 to $29/mo. That undercuts our $39 plan. Worth discussing at the next sync?"

**You act when you can.** The full computer backing means you're not limited to notifications. If you can sign up for the waitlist, register for the event, or pull down the data — do it (within the trust boundaries that have been set).

## How It Works

### 1. Capture Radar Items

When someone says to watch something, store it in MEMORY.md under a Radar section:

```markdown
## Radar — Watching

### Active Items
- **Competitor pricing (Acme, Bolt, Cirrus)** — Check pricing pages weekly. Alert on any changes. Compare to our tiers.
- **Industry job postings** — Check LinkedIn/Indeed daily for "AI agent" roles at target companies. Signals who's building what.
- **Conference CFPs** — Watch major tech conferences for call-for-proposals deadlines. Team wants to submit to 2-3 this year.
- **Apartment listings under $2K in Williamsburg** — Check StreetEasy daily. 1br+, pet-friendly, available April 1.
- **Favorite band tour dates** — Check website weekly. Alert if shows near home city.

### Completed/Expired
- ~~SXSW early bird registration~~ — Signed up March 1. Confirmed.
```

### 2. Schedule Monitoring Jobs

Use the scheduling skill to create recurring checks for each radar item. Match the cadence to urgency:

**Daily** — time-sensitive things (listings, ticket drops, job postings, stock movements):
```json
{
  "type": "periodic",
  "channelId": "CHANNEL_ID",
  "text": "Radar sweep: Check apartment listings on StreetEasy. Check job postings for AI agent roles.",
  "schedule": "0 8 * * *",
  "timezone": "America/New_York"
}
```

**Weekly** — slower-moving things (competitor landscape, industry news, tour dates):
```json
{
  "type": "periodic",
  "channelId": "CHANNEL_ID",
  "text": "Radar sweep: Check competitor pricing pages. Scan for new players in the space. Check conference CFP deadlines.",
  "schedule": "0 10 * * 1",
  "timezone": "America/New_York"
}
```

**One-shot** — check once at a specific time:
```json
{
  "type": "one-shot",
  "channelId": "CHANNEL_ID",
  "text": "Radar: Conference early bird registration was supposed to open today. Check and register if live.",
  "at": "2026-03-01T09:00:00-05:00"
}
```

### 3. Execute the Sweep

When a radar event fires:

1. **Check the source.** Use browser-tools for dynamic sites, Firecrawl for content extraction, or curl/wget for simple pages.

```bash
# Browser for dynamic/JS-heavy sites
browser-nav.js https://example.com/pricing --new
browser-screenshot.js
# Then read the screenshot or eval the page

# Firecrawl for clean content extraction
firecrawl scrape https://example.com/listings

# Simple fetch for static pages
curl -s https://example.com/page | head -200
```

2. **Compare to last known state.** Store previous results in `/data/radar/` so you can detect changes:

```
/data/radar/
├── competitor-pricing.json      # Last scraped pricing data
├── apartment-listings.json      # Last seen listings
├── job-postings.md              # Last scan results
└── band-tour-dates.md           # Last known dates
```

3. **Evaluate relevance.** Use your Compass context. Is this change something that matters? Does it match location, timing, budget, priorities?

4. **Report or act.**
   - If informational: send a concise summary via the preferred channel.
   - If actionable and within trust bounds: do the thing (sign up, register, download) and report what you did.
   - If actionable but outside trust bounds: say what you found and ask whether to act.

### 4. Report Format

Keep radar reports concise and actionable:

"**Radar: Competitor Pricing**
Acme dropped their pro tier from $49 to $29/mo. Bolt unchanged. Cirrus added a new enterprise tier at $199/mo.
→ Want me to pull together a full comparison?"

"**Radar: Apartment Listings**
2 new places today:
- 145 Bedford Ave — 1br, $1,850/mo, pet-friendly, avail April 1. Nice light.
- 88 Berry St — 1br, $1,950/mo, no pets. Rooftop access.
→ Want details or to schedule viewings?"

"**Radar: Industry Jobs**
Nothing new this week at the target companies. Quiet hiring cycle."

**Team-oriented examples:**

"**Radar: Conference CFPs**
Two deadlines coming up:
- Strange Loop — CFP closes March 15. Nobody's submitted yet.
- AI Engineer Summit — CFP opens next Monday.
→ Who's writing proposals?"

"**Radar: Competitive Landscape**
New entrant: Prism AI launched yesterday. YC W26. Positioning as 'AI ops for startups.' Direct overlap with our SMB tier.
→ Worth a deeper look? I can pull their marketing, pricing, and team background."

### 5. Trust Boundaries for Action

Start conservative. Default to informing, not acting. Escalate capability as trust builds:

**Level 1 (default):** Monitor and report. "I found X. Want me to do Y?"
**Level 2 (with permission):** Act on low-stakes things. Sign up for free waitlists, save listings, register for events, download resources.
**Level 3 (explicit authorization):** Spend money, submit applications, make commitments. Only with clear prior approval and spending limits.

If someone says "just register us if it's free" — that's Level 2 authorization for that category. Store it in memory and respect the boundary. Spending money always requires explicit approval with limits.

## What Radar Is Not

- Not a news aggregator. Don't send daily digests of random industry news unless asked. Watch specific things people have told you to watch.
- Not a search engine. Don't go looking for random interesting things. Monitor what's been put on the radar.
- Not always-on surveillance. Each radar item has a cadence. Respect it. Don't burn compute checking things every hour unless that's what was requested.

## Managing the Radar

- When an item is fulfilled (registered, purchased, found, expired), mark it complete and remove the scheduled job.
- Periodically review active radar items. "You asked me to watch X back in February — still relevant?" Monthly is a good cadence for this.
- If a source goes down or changes structure, report it. Don't silently fail.
- For teams: make radar findings visible to everyone, not just the person who requested it. Surface things in shared channels unless told otherwise.
