#!/bin/bash
# Fetch a Notion page by ID and extract content
# Usage: ./notion-page.sh <page-id>

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)

PAGE_ID="$1"
shift || true

if [ -z "$PAGE_ID" ]; then
    echo "Usage: ./notion-page.sh <page-id>"
    echo "Example: ./notion-page.sh 1a824612a17f80dc8d2bf80a3eaa908a"
    exit 1
fi

# Clean page ID (remove dashes if present)
PAGE_ID=$(echo "$PAGE_ID" | tr -d '-')

# Check if it's a database by trying to fetch as database first
DB_CHECK=$(curl -s "https://api.notion.com/v1/databases/$PAGE_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" | jq -r '.object // "error"')

if [ "$DB_CHECK" = "database" ]; then
    # It's a database - delegate to notion-db.sh
    exec "$SCRIPT_DIR/notion-db.sh" "$PAGE_ID" "$@"
fi

# Fetch page metadata - filter aggressively
echo "=== Page ==="
curl -s "https://api.notion.com/v1/pages/$PAGE_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" | jq -r '
    (
        .properties.title.title[0].plain_text //
        .properties.Name.title[0].plain_text //
        .properties["Task name"].title[0].plain_text //
        .properties.Page.title[0].plain_text //
        "Untitled"
    ) + " (updated: " + .last_edited_time[0:10] + ")"'

echo ""
# Fetch blocks - extract text only
curl -s "https://api.notion.com/v1/blocks/$PAGE_ID/children?page_size=100" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" | jq -r '
    .results[] | 
    if .type == "paragraph" then
        (.paragraph.rich_text | map(.plain_text) | join(""))
    elif .type == "heading_1" then
        "\n# " + (.heading_1.rich_text | map(.plain_text) | join(""))
    elif .type == "heading_2" then
        "\n## " + (.heading_2.rich_text | map(.plain_text) | join(""))
    elif .type == "heading_3" then
        "\n### " + (.heading_3.rich_text | map(.plain_text) | join(""))
    elif .type == "bulleted_list_item" then
        "• " + (.bulleted_list_item.rich_text | map(.plain_text) | join(""))
    elif .type == "numbered_list_item" then
        "- " + (.numbered_list_item.rich_text | map(.plain_text) | join(""))
    elif .type == "toggle" then
        "▸ " + (.toggle.rich_text | map(.plain_text) | join(""))
    elif .type == "quote" then
        "> " + (.quote.rich_text | map(.plain_text) | join(""))
    elif .type == "callout" then
        "📌 " + (.callout.rich_text | map(.plain_text) | join(""))
    elif .type == "to_do" then
        (if .to_do.checked then "☑ " else "☐ " end) + (.to_do.rich_text | map(.plain_text) | join(""))
    elif .type == "code" then
        "```\n" + (.code.rich_text | map(.plain_text) | join("")) + "\n```"
    elif .type == "divider" then
        "---"
    elif .type == "child_page" then
        "→ " + .child_page.title
    elif .type == "child_database" then
        "⊞ " + .child_database.title
    else
        empty
    end | select(. != "")'
