#!/bin/bash
# Add a row to a Notion database
# Usage: ./notion-row.sh <database-id> '<row-json>'
#
# Row JSON format (property names must match database columns):
# {
#   "Name": "Row title",
#   "URL": "https://example.com",
#   "Status": "Done",
#   "Tags": ["tag1", "tag2"],
#   "Notes": "Some text",
#   "Count": 42,
#   "Date": "2024-01-15",
#   "Checkbox": true
# }
#
# Example:
# ./notion-row.sh abc123 '{"Name":"My Item","URL":"https://example.com","Status":"Todo"}'

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && eval $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | sed 's/^/export /')

DATABASE_ID="$1"
ROW_JSON="$2"

if [ -z "$DATABASE_ID" ] || [ -z "$ROW_JSON" ]; then
    echo "Usage: ./notion-row.sh <database-id> '<row-json>'"
    echo ""
    echo "Example:"
    echo '  ./notion-row.sh abc123 '\''{"Name":"Task 1","Status":"Todo","URL":"https://example.com"}'\'''
    exit 1
fi

# Clean database ID
DATABASE_ID=$(echo "$DATABASE_ID" | tr -d '-')

# First, get the database schema to understand property types
SCHEMA=$(curl -s "https://api.notion.com/v1/databases/$DATABASE_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" | jq '.properties')

# Build properties object based on schema and input
PROPERTIES=$(echo "$ROW_JSON" | jq --argjson schema "$SCHEMA" '
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
        elif $type == "date" then
            .[$entry.key] = {date: {start: $entry.value}}
        elif $type == "select" then
            .[$entry.key] = {select: {name: $entry.value}}
        elif $type == "multi_select" then
            .[$entry.key] = {multi_select: ($entry.value | map({name: .}))}
        else
            .
        end
    )
')

# Create the page (row)
RESPONSE=$(curl -s -X POST "https://api.notion.com/v1/pages" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg db_id "$DATABASE_ID" \
        --argjson props "$PROPERTIES" \
        '{
            parent: {type: "database_id", database_id: $db_id},
            properties: $props
        }')")

# Check for error
if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
    exit 1
fi

# Output result
echo "$RESPONSE" | jq -r '"Added row: " + .id'
