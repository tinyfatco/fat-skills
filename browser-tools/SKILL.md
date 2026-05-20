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

## Screenshot

```bash
browser-screenshot.js
browser-screenshot.js https://example.com /tmp/example.png --full-page
browser-screenshot.js --width 390 --height 844
```

Returns the path to a PNG/JPEG/WebP image.

## Evaluate JavaScript

```bash
browser-eval.js 'document.title'
browser-eval.js --url https://example.com 'document.querySelectorAll("a").length'
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
```

## Cookies

```bash
browser-cookies.js https://example.com
```

Prints `document.cookie`; HttpOnly cookies are not exposed.

## Current Limits

Remote browser tools can load public `http` and `https` URLs. They cannot access an agent container's `localhost`, private network addresses, or keep a long-lived interactive tab. `browser-pick.js` is reserved for a future stateful/live-view slice.
