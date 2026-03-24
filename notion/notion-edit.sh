#!/bin/bash
# Edit/append content to an existing Notion page
# Usage: ./notion-edit.sh <page-id> "Content to append"
# 
# Use --replace to clear existing content first
# Use --title "New Title" to update the title

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
eval $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | sed 's/^/export /')

REPLACE=false
NEW_TITLE=""
PAGE_ID=""
CONTENT=""

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --replace)
            REPLACE=true
            shift
            ;;
        --title)
            NEW_TITLE="$2"
            shift 2
            ;;
        *)
            if [ -z "$PAGE_ID" ]; then
                PAGE_ID="$1"
            else
                CONTENT="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$PAGE_ID" ]; then
    echo "Usage: ./notion-edit.sh [--replace] [--title \"New Title\"] <page-id> [\"Content\"]"
    exit 1
fi

# Clean page ID
PAGE_ID=$(echo "$PAGE_ID" | tr -d '-')

# Update title if provided
if [ -n "$NEW_TITLE" ]; then
    curl -s -X PATCH "https://api.notion.com/v1/pages/$PAGE_ID" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg t "$NEW_TITLE" '{
            properties: {
                title: {title: [{type: "text", text: {content: $t}}]}
            }
        }')" | jq -r '"Title updated: " + .properties.title.title[0].plain_text'
fi

# If replace mode, delete existing blocks first
if [ "$REPLACE" = true ]; then
    echo "Clearing existing content..."
    BLOCKS=$(curl -s "https://api.notion.com/v1/blocks/$PAGE_ID/children?page_size=100" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" | jq -r '.results[].id')
    
    for block_id in $BLOCKS; do
        curl -s -X DELETE "https://api.notion.com/v1/blocks/$block_id" \
            -H "Authorization: Bearer $NOTION_API_KEY" \
            -H "Notion-Version: 2022-06-28" > /dev/null
    done
    echo "Cleared."
fi

# Append new content if provided
if [ -n "$CONTENT" ]; then
    # Build blocks (same logic as notion-write)
    BLOCKS_JSON=$(echo "$CONTENT" | while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^###[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            jq -n --arg t "$text" '{type:"heading_3",heading_3:{rich_text:[{type:"text",text:{content:$t}}]}}'
        elif [[ "$line" =~ ^##[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            jq -n --arg t "$text" '{type:"heading_2",heading_2:{rich_text:[{type:"text",text:{content:$t}}]}}'
        elif [[ "$line" =~ ^#[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            jq -n --arg t "$text" '{type:"heading_1",heading_1:{rich_text:[{type:"text",text:{content:$t}}]}}'
        elif [[ "$line" =~ ^-[[:space:]](.+) ]] || [[ "$line" =~ ^•[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            jq -n --arg t "$text" '{type:"bulleted_list_item",bulleted_list_item:{rich_text:[{type:"text",text:{content:$t}}]}}'
        elif [[ "$line" =~ ^\>[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            jq -n --arg t "$text" '{type:"quote",quote:{rich_text:[{type:"text",text:{content:$t}}]}}'
        elif [[ "$line" == "---" ]]; then
            echo '{"type":"divider","divider":{}}'
        elif [[ -n "$line" ]]; then
            jq -n --arg t "$line" '{type:"paragraph",paragraph:{rich_text:[{type:"text",text:{content:$t}}]}}'
        fi
    done | jq -s '.')

    RESPONSE=$(curl -s -X PATCH "https://api.notion.com/v1/blocks/$PAGE_ID/children" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --argjson children "$BLOCKS_JSON" '{children: $children}')")

    if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
        echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
        exit 1
    fi
    
    echo "Content appended: $(echo "$RESPONSE" | jq '.results | length') blocks"
fi
