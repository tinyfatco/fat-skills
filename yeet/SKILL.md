---
name: yeet
description: Unified platform CLI for managing TinyFat site projects, deployments, secrets, contacts, tasks, and status. Use when you need to create or publish a website, save credentials, manage contacts, track tasks, or check agent status.
---

# Yeet — Agent Platform CLI

One CLI for platform operations. Networked commands authenticate with `FAT_TOOLS_TOKEN`.

## Core Concepts

- **Site projects** are TinyFat-managed websites. They publish through Workers for Platforms and get URLs like `https://my-business.preview.tinyfat.dev/`.
- **Local project config** lives in `yeet.json`. It stores the current project name and default deploy directory so you can run `yeet project deploy`.
- **Preview deploys** use `https://my-business-preview.preview.tinyfat.dev/`.
- **Legacy Pages projects** are the older Cloudflare Pages path. Use `--pages` only when explicitly asked for the old path.
- **Agent secrets** are credentials you need in your own container. They persist across container sleep.
- **Project env vars** are currently only for legacy Pages projects.

## Create and Publish a TinyFat Website

Use this for "make a new site" work.

```bash
# Create/select a project name and write yeet.json
yeet project init my-business

# Build or write the site. Static deploys must include index.html.
mkdir -p public
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html><body><h1>Hello</h1></body></html>
EOF

# Publish to https://my-business.preview.tinyfat.dev/
yeet project deploy public
```

If `yeet.json` already exists, use:

```bash
yeet project deploy
```

To change the current project without contacting the deploy API:

```bash
yeet project use new-project-name public
```

## Preview Deploys

```bash
yeet project deploy public --preview
```

This publishes to `https://<project>-preview.preview.tinyfat.dev/` and keeps the normal project URL untouched.

## Direct Site Deploy Alias

`yeet site deploy` is a direct alias when you do not want to use `yeet.json`.

```bash
yeet site deploy my-business public
yeet site deploy my-business public --preview
```

## Inspect Site Projects

```bash
yeet project ls
yeet project info
yeet project info my-business
```

`info` shows the production URL, preview URL, state, and recent deploys.

## Legacy Cloudflare Pages

Only use this when asked for the old Pages path.

```bash
yeet project init my-dashboard --pages
yeet project deploy my-dashboard ./build --pages
yeet project ls --pages
yeet project info my-dashboard --pages
yeet project rm my-dashboard --pages
```

Legacy Pages env vars:

```bash
yeet project env my-dashboard set STRIPE_KEY=sk_live_xxx
yeet project env my-dashboard rm OLD_KEY
```

## Save Your Secrets

```bash
yeet secret set gh_token=ghp_xxxxxxxxxxxx
yeet secret set openai_key=sk-xxxxxxxxxxxx
yeet secret set env_MY_CUSTOM_VAR=some_value
```

Secrets are encrypted at rest and write-only. You can overwrite a key, but delete is not supported yet.

### Known Secret Keys

| Key | What Happens |
|-----|-------------|
| `gh_token` | Sets `GH_TOKEN` env var + writes `~/.config/gh/hosts.yml` |
| `openai_key` | Sets `OPENAI_API_KEY` env var |
| `google_api_key` | Sets `GOOGLE_API_KEY` env var |
| `openrouter_key` | Sets `OPENROUTER_API_KEY` env var |
| `env_*` | Any key starting with `env_` becomes an env var on boot |

## Manage Contacts

Control who can email you and who you can email.

```bash
yeet contact ls
yeet contact add person@example.com
yeet contact add @example.com
yeet contact rm person@example.com
```

You must add someone as a contact before you can email them or they can email you.

## Track Tasks

Tasks persist across container sleep in `/data/.td`.

```bash
yeet task ls
yeet task add "Fix the contact form"
yeet task add -p my-business "Add mobile nav"
yeet task done <id>
```

`yeet task` is a wrapper around `td`, so normal `td` commands work:

```bash
yeet task show <id>
yeet task move <id> in-progress
yeet task comment <id> "Blocked on customer copy"
yeet task search "contact"
```

## Check Status

```bash
yeet who
```

Shows token status, key env vars, service URLs, and the current `yeet.json` project when present.
