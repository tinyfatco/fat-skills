#!/bin/bash
# Create a new Notion page under a parent page/database
# Usage: ./notion-write.sh <parent-id> "Title" "Content in markdown-ish format"
# 
# Content format:
#   # Heading 1
#   ## Heading 2
#   ### Heading 3
#   - Bullet point
#   > Quote
#   Regular paragraph
#   --- (divider)

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
eval $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | sed 's/^/export /')

PARENT_ID="$1"
TITLE="$2"
CONTENT="$3"

if [ -z "$PARENT_ID" ] || [ -z "$TITLE" ]; then
    echo "Usage: ./notion-write.sh <parent-id> \"Title\" [\"Content\"]"
    echo "Example: ./notion-write.sh abc123 \"My Page\" \"# Hello\nThis is content\""
    exit 1
fi

# Clean parent ID (remove dashes if present)
PARENT_ID=$(echo "$PARENT_ID" | tr -d '-')

# Build the children blocks array from content
build_blocks() {
    local content="$1"
    
    if [ -z "$content" ]; then
        echo "[]"
        return
    fi
    
    local blocks=()
    
    # Process line by line using process substitution to avoid subshell
    while IFS= read -r line || [ -n "$line" ]; do
        local block=""
        
        if [[ "$line" =~ ^###[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            block=$(jq -n --arg t "$text" '{type:"heading_3",heading_3:{rich_text:[{type:"text",text:{content:$t}}]}}')
        elif [[ "$line" =~ ^##[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            block=$(jq -n --arg t "$text" '{type:"heading_2",heading_2:{rich_text:[{type:"text",text:{content:$t}}]}}')
        elif [[ "$line" =~ ^#[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            block=$(jq -n --arg t "$text" '{type:"heading_1",heading_1:{rich_text:[{type:"text",text:{content:$t}}]}}')
        elif [[ "$line" =~ ^-[[:space:]](.+) ]] || [[ "$line" =~ ^•[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            block=$(jq -n --arg t "$text" '{type:"bulleted_list_item",bulleted_list_item:{rich_text:[{type:"text",text:{content:$t}}]}}')
        elif [[ "$line" =~ ^\>[[:space:]](.+) ]]; then
            text="${BASH_REMATCH[1]}"
            block=$(jq -n --arg t "$text" '{type:"quote",quote:{rich_text:[{type:"text",text:{content:$t}}]}}')
        elif [[ "$line" == "---" ]]; then
            block='{"type":"divider","divider":{}}'
        elif [[ -n "$line" ]]; then
            block=$(jq -n --arg t "$line" '{type:"paragraph",paragraph:{rich_text:[{type:"text",text:{content:$t}}]}}')
        fi
        
        if [ -n "$block" ]; then
            blocks+=("$block")
        fi
    done <<< "$content"
    
    # Join blocks into JSON array
    if [ ${#blocks[@]} -eq 0 ]; then
        echo "[]"
    else
        printf '%s\n' "${blocks[@]}" | jq -s '.'
    fi
}

# Build blocks JSON array
BLOCKS_JSON=$(build_blocks "$CONTENT")

# Create the page
RESPONSE=$(curl -s -X POST "https://api.notion.com/v1/pages" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg parent_id "$PARENT_ID" \
        --arg title "$TITLE" \
        --argjson children "$BLOCKS_JSON" \
        '{
            parent: {page_id: $parent_id},
            properties: {
                title: {
                    title: [{type: "text", text: {content: $title}}]
                }
            },
            children: $children
        }')")

# Check for error
if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
    exit 1
fi

# Output result
echo "$RESPONSE" | jq -r '"Created: " + .id + " (" + .url + ")"'
