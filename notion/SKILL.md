---
name: notion
description: Read and write Notion pages and databases. Activate when user mentions Notion, notion page, notion database, reading/writing to Notion, or provides a notion.so URL.
---

# Notion

Read/write Notion pages and databases. Scripts are at `/opt/fat-skills/notion/`.

Requires `NOTION_API_KEY` env var (set via agent secrets).

## Commands

```bash
# Search
/opt/fat-skills/notion/notion-search.sh              # List all accessible
/opt/fat-skills/notion/notion-search.sh "query"      # Search by title

# Read page (auto-detects databases)
/opt/fat-skills/notion/notion-page.sh <page-id>

# Query database
/opt/fat-skills/notion/notion-db.sh <database-id>
/opt/fat-skills/notion/notion-db.sh <id> --format json
/opt/fat-skills/notion/notion-db.sh <id> --sort "Rating desc" --limit 10

# Create page
/opt/fat-skills/notion/notion-write.sh <parent-id> "Title" "Content"

# Edit/append
/opt/fat-skills/notion/notion-edit.sh <page-id> "Content to append"
/opt/fat-skills/notion/notion-edit.sh --replace <page-id> "New content"
/opt/fat-skills/notion/notion-edit.sh --title "New Title" <page-id>

# Add database row
/opt/fat-skills/notion/notion-row.sh <database-id> "Name=Value" "Status=Done"

# Update row
/opt/fat-skills/notion/notion-update.sh <row-page-id> "Status=In Progress"

# Move page
/opt/fat-skills/notion/notion-move.sh <page-id> <new-parent-id>
```

## Page IDs

From URLs like `https://www.notion.so/Page-Title-2ec4ba24f6f5801ab45aea407a21a996`:
- The ID is the 32-char hex at the end: `2ec4ba24f6f5801ab45aea407a21a996`

## Notes

- Integration must be shared with pages — Notion API only sees pages explicitly shared with the integration
- Child pages inherit sharing from parent
