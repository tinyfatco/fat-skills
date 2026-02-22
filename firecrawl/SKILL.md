---
name: firecrawl
description: Web scraping and search via Firecrawl proxy API. Use when the user asks to scrape a webpage, search the web, or extract structured data from a URL.
---

# Firecrawl — Web Scraping & Search

Scrape web pages, search the web, and extract structured data. Proxied through the platform — no API key needed on the container.

All requests go to `POST https://tinyfat.com/api/tools/firecrawl`, authenticated via `FAT_TOOLS_TOKEN`.

## Scrape a URL

Get a page's content as clean markdown.

```bash
curl -s -X POST https://tinyfat.com/api/tools/firecrawl \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "scrape", "url": "https://example.com"}'
```

Optional: specify formats (default is `["markdown"]`):
```json
{"action": "scrape", "url": "https://example.com", "formats": ["markdown", "html"]}
```

## Search the Web

```bash
curl -s -X POST https://tinyfat.com/api/tools/firecrawl \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "search", "query": "your search query", "limit": 5}'
```

Returns up to `limit` results (default 5) with titles, URLs, and content snippets.

## Extract Structured Data

Pull structured data from a page using a JSON schema.

```bash
curl -s -X POST https://tinyfat.com/api/tools/firecrawl \
  -H "Authorization: Bearer $FAT_TOOLS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "extract",
    "url": "https://example.com/pricing",
    "schema": {
      "type": "object",
      "properties": {
        "plans": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "name": {"type": "string"},
              "price": {"type": "string"}
            }
          }
        }
      }
    }
  }'
```

## Tips

- **Scrape first, extract second.** If you just need the content, scrape is faster. Use extract when you need specific fields from a page.
- **Search + scrape combo.** Search to find URLs, then scrape the best results for full content. Good pattern for research tasks.
- **Rate limits.** The platform key is shared — don't hammer it. A few requests per minute is fine.
