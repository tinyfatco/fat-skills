---
name: browser-tools
description: Headless Chrome browser automation via CLI. Use when you need to browse the web, take screenshots, extract page content, fill forms, or interact with web pages.
---

# Browser Tools

Headless Chrome automation via Chrome DevTools Protocol.

## Start Chrome

```bash
browser-start.js
```

Launches headless Chrome with remote debugging on `:9222`. Auto-detects environment (headless in containers, headed with display). Idempotent — safe to call multiple times.

## Navigate

```bash
browser-nav.js https://example.com --new    # Open in new tab
browser-nav.js https://example.com          # Navigate current tab
```

## Screenshot

```bash
browser-screenshot.js
```

Captures current viewport, returns path to PNG file in `/tmp/`.

## Evaluate JavaScript

```bash
browser-eval.js 'document.title'
browser-eval.js 'document.querySelectorAll("a").length'
```

Execute JavaScript in the active tab. Returns the result.

## Extract Page Content

```bash
browser-content.js https://example.com
```

Navigate to URL and extract readable content as markdown (Mozilla Readability + Turndown).

## Search

```bash
browser-search.js "query terms"
```

Google search and extract results.

## Cookies

```bash
browser-cookies.js
```

Display cookies for the current page.

## Pick Elements

```bash
browser-pick.js "Click the submit button"
```

Interactive element picker — returns CSS selectors for selected elements.

## Common Patterns

### Browse and screenshot
```bash
browser-start.js
browser-nav.js https://example.com --new
browser-screenshot.js
```

### Fill a form
```bash
browser-eval.js 'document.querySelector("input[name=\"email\"]").value = "user@example.com"'
browser-eval.js 'document.querySelector("button[type=\"submit\"]").click()'
```

### Extract data from a page
```bash
browser-content.js https://example.com/article
```
