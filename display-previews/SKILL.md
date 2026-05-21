---
name: display-previews
description: Manage TinyFat workspace canvas displays and live app previews. Use when creating display/projects entries, showing a generated UI, running an app preview, or preparing a preview for browser inspection.
---

# Display Previews

TinyFat display projects register things the user can open on the workspace
canvas and top display bar. Use them for live app previews, generated HTML UI,
and other user-facing display surfaces.

## Project Shape

Create one folder per display project:

`/data/display/projects/my-app/display.json`

Live app preview:

```json
{
  "id": "my-app",
  "title": "My App",
  "icon": "briefcase",
  "accent": "#0f766e",
  "kind": "preview",
  "preview": {
    "port": 4321,
    "path": "/"
  }
}
```

Single-file generated UI:

```json
{
  "id": "sales-board",
  "title": "Sales Board",
  "icon": "chart-column",
  "accent": "#2563eb",
  "kind": "html",
  "entry": "index.html"
}
```

For HTML displays, put the entry file next to `display.json`, for example
`/data/display/projects/sales-board/index.html`.

## Running A Preview

Run the app server inside the agent container on localhost. Use a normal app
port such as `4321` for Astro or `5173` for Vite:

```bash
npm run dev -- --port 4321
```

The platform exposes previews through short-lived isolated capability origins,
for example `https://p-...preview.tinyfat.dev/`. Use the URL surfaced by the
workspace UI or preview tools; do not invent public tunnels or expose container
ports directly.

Do not use TinyFat reserved ports: `3000`, `3002`, `6080`, `8765`, `9222`, or
`5900-5999`. Do not bind app previews to `0.0.0.0`.

## Operational Notes

- Display project files define available displays; do not write a global
  active/current file to switch the human's selected display.
- Preview URLs are short-lived capabilities rather than raw container-local
  addresses. Treat them as bearer URLs and avoid sharing them outside the
  workspace session.
- Remote browser tools can inspect public URLs today. They should inspect
  container previews through the platform preview URL once that capability is
  available, not by trying to load `localhost` directly.
