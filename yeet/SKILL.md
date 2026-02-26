---
name: yeet
description: Unified platform CLI for managing projects, secrets, contacts, tasks, and deployments. Use when you need to deploy a site, save credentials, manage email contacts, track tasks, or check agent status.
---

# Yeet — Agent Platform CLI

One CLI for all platform operations. Authenticated via `FAT_TOOLS_TOKEN`.

## Concepts

You manage two kinds of things:

- **Your secrets** — credentials YOU need (GitHub tokens, API keys). Persist across container sleep. Set with `yeet secret`.
- **Project env vars** — credentials your DEPLOYED SITES need (Stripe keys, API tokens for a dashboard). Scoped to a specific project. Set with `yeet project env`.

These are different. Your GitHub token is YOUR secret. Your dashboard's Stripe key is that PROJECT's env var.

## Create a Project

```bash
# Create a new project (CF Pages project, ready for deploys)
yeet project init my-dashboard

# List your projects
yeet project ls

# Get project details and deploy history
yeet project info my-dashboard

# Delete a project
yeet project rm my-dashboard
```

`init` creates the project on Cloudflare Pages. You can also skip `init` — `deploy` auto-creates the project on first deploy. Each project gets a URL like `my-dashboard.pages.dev` (prefixed with your agent name).

## Deploy a Site

```bash
# Build your site, then deploy it
yeet project deploy my-dashboard ./build

# Deploy current directory
yeet project deploy my-dashboard .
```

Subsequent deploys update the same project.

## Manage Project Env Vars

```bash
# Set an env var on a deployed project
yeet project env my-dashboard set STRIPE_KEY=sk_live_xxx
yeet project env my-dashboard set API_URL=https://api.example.com

# Remove an env var
yeet project env my-dashboard rm OLD_KEY
```

These are CF Pages environment variables — available to your project's `_worker.js` or build-time config.

## Save Your Secrets

```bash
# Save a credential that persists across sleep
yeet secret set gh_token=ghp_xxxxxxxxxxxx
yeet secret set openai_key=sk-xxxxxxxxxxxx

# Generic env var (env_ prefix → becomes env var on boot)
yeet secret set env_MY_CUSTOM_VAR=some_value
```

Secrets are merge-only — you can overwrite a key but not delete it.

### Known Secret Keys

These get special handling on container boot:

| Key | What Happens |
|-----|-------------|
| `gh_token` | Sets `GH_TOKEN` env var + writes `~/.config/gh/hosts.yml` |
| `openai_key` | Sets `OPENAI_API_KEY` env var |
| `google_api_key` | Sets `GOOGLE_API_KEY` env var |
| `openrouter_key` | Sets `OPENROUTER_API_KEY` env var |
| `env_*` (prefix) | Any key starting with `env_` becomes an env var (e.g., `env_MY_KEY` → `MY_KEY`) |

Secrets are encrypted at rest. They're write-only — you can't list them for security.

## Manage Contacts

Control who can email you and who you can email.

```bash
# List contacts
yeet contact ls

# Add a contact (opens both inbound and outbound)
yeet contact add person@example.com

# Add an entire domain
yeet contact add @example.com

# Remove a contact
yeet contact rm person@example.com
```

You must add someone as a contact before you can email them or they can email you.

## Track Tasks

Tasks persist across container sleep (stored on R2). You can scope tasks to a project or keep them general.

```bash
# List tasks
yeet task ls

# List tasks for a specific project
yeet task ls -p my-dashboard

# Create a task
yeet task add "Fix the login page"
yeet task add -p my-dashboard "Add dark mode"

# Complete a task
yeet task done <id>
```

`yeet task` is a wrapper around `td` (the task tracker CLI). All `td` commands work through `yeet task`:

```bash
# Show task details
yeet task show <id>

# Move task to a status
yeet task move <id> in-progress

# Add a comment
yeet task comment <id> "Blocked on API response"

# Create subtasks
yeet task sub <parent-id> "Subtask title"

# Search tasks
yeet task search "login"
```

You can also use `td` directly — just know that `yeet task` points the database at `/data/.td` (durable storage), while bare `td` uses `~/.td` (ephemeral).

## Check Status

```bash
yeet who
```

Shows whether your platform token and key env vars are set.

## Common Workflows

### Deploy a static site
```bash
mkdir -p /workspace/scratch/my-site
cat > /workspace/scratch/my-site/index.html << 'EOF'
<!DOCTYPE html>
<html><body><h1>Hello</h1></body></html>
EOF
yeet project deploy my-site /workspace/scratch/my-site
```

### Set up GitHub, then deploy from a repo
```bash
yeet secret set gh_token=ghp_xxxxxxxxxxxx
# (token available after next wake, or set GH_TOKEN manually for now)
export GH_TOKEN=ghp_xxxxxxxxxxxx
gh repo clone user/project
cd project && npm run build
yeet project deploy project ./dist
```

### Email someone new
```bash
yeet contact add newperson@company.com
# Now you can send them email via send_message
```

### Track project tasks
```bash
yeet task add -p my-dashboard "Build contact form"
yeet task add -p my-dashboard "Add form validation"
yeet task ls -p my-dashboard
# Work on it...
yeet task done td-a1b2
```

## Reference

- Platform API: `https://tinyfat.com`
- Deploy API: `https://deploy.tinyfat.com`
- All auth via `FAT_TOOLS_TOKEN` (set automatically in your environment)
