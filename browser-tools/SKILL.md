---
name: browser-tools
description: Remote browser automation via TinyFat and Cloudflare Browser Rendering. Use when you need to load public web pages, take screenshots, extract page content, render PDFs, or evaluate JavaScript without starting local Chrome.
---

# Browser Tools

Browser tools run Chrome through TinyFat's Cloudflare Browser Rendering API. They do not start or require local Chromium in the agent container.

## Check Configuration

```bash
browser-start.js
```

## Navigate

```bash
browser-nav.js https://example.com
```

This records an active URL in `/tmp` for subsequent commands. Remote browser sessions are stateless, so each command loads the page fresh.

## Stateful Session

Use a session when a workflow needs page continuity, such as logging in, clicking
through a multi-step flow, or inspecting state after a script changes the page.

```bash
browser-session.js start https://example.com
browser-nav.js --session https://example.com/dashboard
browser-eval.js --session 'document.title'
browser-screenshot.js --session /tmp/session.png
browser-session.js close
```

Sessions are per-agent and time out when idle. Use stateless commands for quick
one-shot fetches.

## Screenshot

```bash
browser-screenshot.js
browser-screenshot.js https://example.com /tmp/example.png --full-page
browser-screenshot.js --width 390 --height 844
browser-screenshot.js --session /tmp/current-tab.png
```

Returns the path to a PNG/JPEG/WebP image.

## Evaluate JavaScript

```bash
browser-eval.js 'document.title'
browser-eval.js --url https://example.com 'document.querySelectorAll("a").length'
browser-eval.js --session 'document.querySelectorAll("button").length'
```

Use expressions that can be wrapped in `return (...)`.

## Extract Page Content

```bash
browser-content.js https://example.com
```

Prints visible page text and a bounded list of links.

## Search

```bash
browser-search.js "query terms"
browser-search.js "query terms" -n 3 --content
```

## PDF

```bash
browser-pdf.js https://example.com /tmp/example.pdf
browser-pdf.js --html-file resume.html /tmp/resume.pdf
browser-pdf.js /data/display/projects/report/index.html /tmp/report.pdf
```

HTML file rendering reads the file from the agent workspace through TinyFat's
R2-backed workspace path. Use workspace-relative paths such as `resume.html` or
absolute `/data/...` paths. It does not expose the file as a public URL.

## Cookies

```bash
browser-cookies.js https://example.com
```

Prints `document.cookie`; HttpOnly cookies are not exposed.

## Current Limits

Remote browser tools can load public `http` and `https` URLs. PDF rendering can
also load HTML files from the agent workspace by path. They cannot access an
agent container's `localhost` or private network addresses. Stateful sessions
preserve a Browser Rendering tab for short workflows, but they are not a visible
live-view browser. `browser-pick.js` is reserved for a future interactive slice.
