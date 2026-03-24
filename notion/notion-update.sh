#!/bin/bash
# Update a Notion page/row properties
# Usage: ./notion-update.sh <page-id> '<props-json>'

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
eval $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | sed 's/^/export /')

PAGE_ID="$1"
PROPS_JSON="$2"

if [ -z "$PAGE_ID" ] || [ -z "$PROPS_JSON" ]; then
    echo "Usage: ./notion-update.sh <page-id> '<props-json>'"
    exit 1
fi

PAGE_ID=$(echo "$PAGE_ID" | tr -d '-')

# Get page to find parent database
PAGE=$(curl -s "https://api.notion.com/v1/pages/$PAGE_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28")

DB_ID=$(echo "$PAGE" | jq -r '.parent.database_id // empty')

if [ -z "$DB_ID" ]; then
    echo "Error: Page is not in a database"
    exit 1
fi

# Get database schema
SCHEMA=$(curl -s "https://api.notion.com/v1/databases/$DB_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" | jq '.properties')

# Build properties object
PROPERTIES=$(echo "$PROPS_JSON" | jq --argjson schema "$SCHEMA" '
    reduce (to_entries[]) as $entry ({};
        ($schema[$entry.key].type) as $type |
        if $type == "title" then
            .[$entry.key] = {title: [{type: "text", text: {content: $entry.value}}]}
        elif $type == "rich_text" then
            .[$entry.key] = {rich_text: [{type: "text", text: {content: $entry.value}}]}
        elif $type == "url" then
            .[$entry.key] = {url: $entry.value}
        elif $type == "number" then
            .[$entry.key] = {number: $entry.value}
        elif $type == "checkbox" then
            .[$entry.key] = {checkbox: $entry.value}
        elif $type == "select" then
            .[$entry.key] = {select: {name: $entry.value}}
        else
            .
        end
    )
')

RESPONSE=$(curl -s -X PATCH "https://api.notion.com/v1/pages/$PAGE_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --argjson props "$PROPERTIES" '{properties: $props}')")

if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
    exit 1
fi

echo "Updated: $PAGE_ID"
