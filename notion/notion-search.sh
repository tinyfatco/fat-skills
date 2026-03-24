#!/bin/bash
# Search Notion pages/databases
# Usage: ./notion-search.sh [query]

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export $(cat "$SCRIPT_DIR/.env" | grep -v '^#' | xargs)

QUERY="${1:-}"

if [ -n "$QUERY" ]; then
    DATA="{\"query\": \"$QUERY\", \"page_size\": 20}"
else
    DATA='{"page_size": 20}'
fi

curl -s "https://api.notion.com/v1/search" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -H "Content-Type: application/json" \
    -d "$DATA" | jq -r '
    .results[] | 
    [
        .id,
        (if .object == "database" then "db" else "pg" end),
        (
            # Extract title - different locations for pages vs databases
            if .object == "database" then
                (.title[0].plain_text // "untitled")
            else
                (
                    .properties.title.title[0].plain_text //
                    .properties.Name.title[0].plain_text //
                    .properties["Task name"].title[0].plain_text //
                    .properties.Page.title[0].plain_text //
                    "untitled"
                )
            end
        ),
        .last_edited_time[0:10]
    ] | @tsv'
