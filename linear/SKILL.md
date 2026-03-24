---
name: linear
description: Linear issue tracking via GraphQL API. Activate when user mentions Linear, issues, tickets, tasks, or needs to create/update/query issues.
---

# Linear

Create, query, and update Linear issues via the GraphQL API.

Requires `LINEAR_API_TOKEN` env var (set via agent secrets).

## Quick Reference

```bash
# List open issues
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "{ issues(filter: { state: { type: { nin: [\"completed\", \"canceled\"] } } }, first: 20, orderBy: updatedAt) { nodes { identifier title state { name } priority updatedAt } } }"}' | jq '.data.issues.nodes[]'

# Create issue
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "mutation($input: IssueCreateInput!) { issueCreate(input: $input) { success issue { identifier url title } } }", "variables": {"input": {"teamId": "TEAM_UUID", "title": "Issue title", "description": "Description"}}}'

# Update issue
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "mutation { issueUpdate(id: \"ISSUE_ID\", input: { stateId: \"STATE_UUID\" }) { success } }"}'

# Add comment
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "mutation { commentCreate(input: { issueId: \"ISSUE_UUID\", body: \"Comment text\" }) { success } }"}'

# Search issues
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "{ searchIssues(term: \"search term\", first: 10) { nodes { identifier title state { name } } } }"}'

# List teams (to find team UUIDs)
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "{ teams { nodes { id name key } } }"}' | jq '.data.teams.nodes[]'

# List workflow states for a team
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  -d '{"query": "{ workflowStates(filter: { team: { key: { eq: \"TEAM_KEY\" } } }) { nodes { id name type } } }"}' | jq '.data.workflowStates.nodes[]'
```

## linearis CLI

`linearis` is also available on PATH for quick operations:

```bash
# Set token for the session
export LINEAR_API_TOKEN="$LINEAR_API_TOKEN"

# List issues
linearis issues list --limit 20

# Create issue (title is positional, team UUID required)
linearis issues create "Title" --team "TEAM_UUID" -d "Description" -p 1

# Read issue
linearis issues read FAT-123

# Update issue
linearis issues update FAT-123 --status "In Progress"

# Add comment
linearis comments create FAT-123 --body "Comment text"
```

## Notes

- All GraphQL mutations return `{ success: true/false }`
- Issue IDs can be the short form (FAT-123) or full UUID
- `jq` is available in the container for parsing responses
- Priority: 0=none, 1=urgent, 2=high, 3=medium, 4=low
