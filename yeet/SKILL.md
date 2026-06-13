---
name: yeet
description: Unified platform CLI for managing TinyFat site projects, deployments, secrets, contacts, tasks, and status. Use when you need to create or publish a website, save credentials, manage contacts, track tasks, or check agent status.
---

# Yeet — Agent Platform CLI

One CLI for platform operations. Networked commands authenticate with `FAT_TOOLS_TOKEN`.

## Core Concepts

- **Site projects** are TinyFat-managed websites. They publish through Workers for Platforms and get URLs like `https://my-business.preview.tinyfat.dev/`.
- **Project workspaces** live at `/data/projects/<slug>/` when you run `yeet project init <slug>` or `yeet project use <slug>` without an explicit deploy directory.
- **Local project config** lives in `yeet.json`. In a standard workspace, it is `/data/projects/<slug>/yeet.json` and deploys `site/`.
- **Preview deploys** use `https://my-business-preview.preview.tinyfat.dev/`.
- **Legacy Pages projects** are the older Cloudflare Pages path. Use `--pages` only when explicitly asked for the old path.
- **Agent secrets** are credentials you need in your own container. They persist across container sleep.
- **Project env vars** are currently only for legacy Pages projects.

## Create and Publish a TinyFat Website

Use this for "make a new site" work.

```bash
# Create/select a project workspace at /data/projects/my-business
yeet project init my-business
cd /data/projects/my-business

# Build or write the site. Static deploys must include index.html.
cat > site/index.html << 'EOF'
<!DOCTYPE html>
<html><body><h1>Hello</h1></body></html>
EOF

# Publish to https://my-business.preview.tinyfat.dev/
yeet project deploy
```

Run `yeet project deploy` from the directory containing `yeet.json`. If the site files live outside that directory, use the explicit form:

```bash
yeet project deploy my-business /absolute/path/to/public
```

To open/create the standard workspace for an existing project without contacting the deploy API:

```bash
yeet project use new-project-name
cd /data/projects/new-project-name
```

To use a one-off deploy directory instead of the standard workspace:

```bash
yeet project use new-project-name public
```

## Preview Deploys

```bash
yeet project deploy --preview
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
Rows marked `rollback-ready` can be redeployed or promoted.

## Website Form Behavior

Static site forms can post to TinyFat's built-in form ingress:

```html
<form method="post" action="/__tinyfat/form">
  <input name="name" autocomplete="name">
  <input name="email" type="email" autocomplete="email">
  <textarea name="message"></textarea>
  <button type="submit">Send</button>
</form>
```

By default, submissions are saved and routed to the agent. Use `yeet project
form` to inspect or change what happens after ingress:

```bash
yeet project form
yeet project form --no-run-agent --notify-owner
yeet project form --notify-email client@example.com --subject "New lead from {site}"
yeet project form --run-agent
```

Use `--no-run-agent` when the form should only save and notify instead of
starting an agent turn. Use `--notify-owner` to email the site owner from the
agent's TinyFat email domain. Extra recipients can be added with repeated
`--notify-email EMAIL` flags.

## Site Resources

TinyFat site projects can provision Cloudflare resources and attach them to the
Workers for Platforms user Worker on the next deploy.

```bash
yeet project resources add d1
yeet project resources add kv
yeet project resources add r2
yeet project resources ls
yeet project deploy
```

Default bindings are `env.DB` for D1, `env.SESSION` for KV, and `env.MEDIA` for
R2. Use a custom binding when the code expects a different name:

```bash
yeet project resources add kv CACHE
yeet project resources add r2 UPLOADS
```

Resources are `shared` by default, so they attach to both canonical and preview
deploys. Use `--preview` or `--production` only when the user needs separate
data stores for each deploy target. After adding a resource, redeploy before
expecting the binding to exist in the Worker runtime.

## Rollback and Promote Deploys

Use `info` first when the user asks to restore an earlier version:

```bash
yeet project info my-business
yeet project rollback my-business <deployment-id>
```

If you omit the deployment id, `rollback` chooses the most recent previous
rollback-ready deploy.

Preview deploys can be promoted to the canonical project URL:

```bash
yeet project promote my-business <preview-deployment-id>
```

Only deploys created after bundle retention shipped are rollback-ready. Older
history rows stay inspectable but cannot be safely restored without redeploying
the source.

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
