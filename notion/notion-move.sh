#!/bin/bash
# Move a Notion block (page, database, etc.) to a new parent
# Usage: ./notion-move.sh <block-id> <new-parent-id>
#
# Works for pages and inline databases. For full-page databases,
# this will archive the old one and recreate it under the new parent.
#
# Example:
#   ./notion-move.sh abc123 def456

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
[ -f "$SCRIPT_DIR/.env" ] && eval $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | sed 's/^/export /')

BLOCK_ID="$1"
NEW_PARENT_ID="$2"

if [ -z "$BLOCK_ID" ] || [ -z "$NEW_PARENT_ID" ]; then
    echo "Usage: ./notion-move.sh <block-id> <new-parent-id>"
    exit 1
fi

# Clean IDs
BLOCK_ID=$(echo "$BLOCK_ID" | tr -d '-')
NEW_PARENT_ID=$(echo "$NEW_PARENT_ID" | tr -d '-')

# First, determine what type of block this is
BLOCK_INFO=$(curl -s "https://api.notion.com/v1/blocks/$BLOCK_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28")

BLOCK_TYPE=$(echo "$BLOCK_INFO" | jq -r '.type // "unknown"')

# Check if it's a page
PAGE_INFO=$(curl -s "https://api.notion.com/v1/pages/$BLOCK_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28")

IS_PAGE=$(echo "$PAGE_INFO" | jq -r 'if .object == "page" then "true" else "false" end')

# Check if it's a database
DB_INFO=$(curl -s "https://api.notion.com/v1/databases/$BLOCK_ID" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28")

IS_DATABASE=$(echo "$DB_INFO" | jq -r 'if .object == "database" then "true" else "false" end')

if [ "$IS_PAGE" = "true" ]; then
    echo "Moving page..."
    
    # Try to update the page's parent
    RESPONSE=$(curl -s -X PATCH "https://api.notion.com/v1/pages/$BLOCK_ID" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "{\"parent\": {\"page_id\": \"$NEW_PARENT_ID\"}}")
    
    if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
        ERROR=$(echo "$RESPONSE" | jq -r '.message')
        
        # If parent update fails, try database parent
        if [[ "$ERROR" == *"parent"* ]]; then
            echo "Trying as database child..."
            RESPONSE=$(curl -s -X PATCH "https://api.notion.com/v1/pages/$BLOCK_ID" \
                -H "Authorization: Bearer $NOTION_API_KEY" \
                -H "Notion-Version: 2022-06-28" \
                -H "Content-Type: application/json" \
                -d "{\"parent\": {\"database_id\": \"$NEW_PARENT_ID\"}}")
        fi
        
        if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
            echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
            exit 1
        fi
    fi
    
    echo "Moved page to new parent"
    echo "$RESPONSE" | jq -r '"URL: " + .url'

elif [ "$IS_DATABASE" = "true" ]; then
    echo "Moving database..."
    
    # Databases can't change parent via API - need to recreate
    DB_TITLE=$(echo "$DB_INFO" | jq -r '.title[0].plain_text // "Untitled"')
    DB_PROPS=$(echo "$DB_INFO" | jq '.properties')
    
    echo "Database: $DB_TITLE"
    echo "Note: Databases cannot be moved via API. Will recreate under new parent."
    read -p "Continue? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Create new database with same schema
    echo "Creating new database..."
    NEW_DB=$(curl -s -X POST "https://api.notion.com/v1/databases" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
            --arg parent_id "$NEW_PARENT_ID" \
            --arg title "$DB_TITLE" \
            --argjson props "$DB_PROPS" \
            '{
                parent: {type: "page_id", page_id: $parent_id},
                title: [{type: "text", text: {content: $title}}],
                properties: $props
            }')")
    
    if echo "$NEW_DB" | jq -e '.object == "error"' > /dev/null 2>&1; then
        echo "Error creating database: $(echo "$NEW_DB" | jq -r '.message')"
        exit 1
    fi
    
    NEW_DB_ID=$(echo "$NEW_DB" | jq -r '.id')
    echo "Created new database: $NEW_DB_ID"
    
    # Copy all rows
    echo "Copying rows..."
    ROWS=$(curl -s -X POST "https://api.notion.com/v1/databases/$BLOCK_ID/query" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d '{"page_size": 100}')
    
    ROW_COUNT=$(echo "$ROWS" | jq '.results | length')
    echo "Found $ROW_COUNT rows to copy"
    
    echo "$ROWS" | jq -c '.results[]' | while read -r row; do
        ROW_PROPS=$(echo "$row" | jq '.properties')
        
        curl -s -X POST "https://api.notion.com/v1/pages" \
            -H "Authorization: Bearer $NOTION_API_KEY" \
            -H "Notion-Version: 2022-06-28" \
            -H "Content-Type: application/json" \
            -d "$(jq -n \
                --arg db_id "$NEW_DB_ID" \
                --argjson props "$ROW_PROPS" \
                '{
                    parent: {type: "database_id", database_id: $db_id},
                    properties: $props
                }')" > /dev/null
        
        echo -n "."
    done
    echo ""
    
    # Archive old database
    echo "Archiving old database..."
    curl -s -X DELETE "https://api.notion.com/v1/blocks/$BLOCK_ID" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" > /dev/null
    
    echo "Done!"
    echo "New database: $NEW_DB_ID"
    echo "$NEW_DB" | jq -r '"URL: " + .url'

elif [ "$BLOCK_TYPE" = "child_page" ]; then
    echo "Moving child page..."
    
    # For child_page blocks, we need to move via the pages API
    RESPONSE=$(curl -s -X PATCH "https://api.notion.com/v1/pages/$BLOCK_ID" \
        -H "Authorization: Bearer $NOTION_API_KEY" \
        -H "Notion-Version: 2022-06-28" \
        -H "Content-Type: application/json" \
        -d "{\"parent\": {\"page_id\": \"$NEW_PARENT_ID\"}}")
    
    if echo "$RESPONSE" | jq -e '.object == "error"' > /dev/null 2>&1; then
        echo "Error: $(echo "$RESPONSE" | jq -r '.message')"
        exit 1
    fi
    
    echo "Moved child page to new parent"
    echo "$RESPONSE" | jq -r '"URL: " + .url'

elif [ "$BLOCK_TYPE" = "child_database" ]; then
    echo "Moving inline database..."
    
    # Inline databases also can't be moved - same recreation flow
    echo "Inline databases cannot be moved via API. Use the full database ID to recreate."
    echo "Block type: $BLOCK_TYPE"
    exit 1

else
    echo "Unknown block type: $BLOCK_TYPE"
    echo "Block info:"
    echo "$BLOCK_INFO" | jq '{type, id, parent}'
    exit 1
fi
