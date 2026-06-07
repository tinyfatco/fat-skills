---
name: tinyfat-project-builder
description: Build and update TinyFat Website projects from plain-language user requests. Use when a user asks to create, redesign, edit, deploy, preview, or iterate on a website/project hosted by TinyFat.
---

# TinyFat Project Builder

Use this when the user wants a website or project built on TinyFat. The website
is the product object. `yeet`, workspaces, deploy commands, and agent internals
are implementation details unless the user asks for them.

## Default Workflow

1. Choose or confirm a short project slug.
   - Use lowercase letters, numbers, and dashes.
   - Prefer the business/product name when obvious.
2. Create or open the workspace:

   ```bash
   yeet project init <slug>
   cd /data/projects/<slug>
   ```

   For an existing project where the remote site already exists:

   ```bash
   yeet project use <slug>
   cd /data/projects/<slug>
   ```

3. Read or update project context:
   - `PROJECT.md` is the project brief and current truth.
   - `tasks.md` can track local implementation tasks.
   - `deploys.jsonl` records successful deploy facts.
4. Build or edit the website source in `site/`.
   - Static v1 deploys must include `site/index.html`.
   - Keep assets inside `site/` unless there is a strong reason not to.
   - If using a framework, build it to static files and place/copy the output
     into `site/` before deploying.
5. Deploy the canonical review preview:

   ```bash
   yeet project deploy
   ```

6. Verify the returned URL before presenting it:

   ```bash
   curl -fsSI https://<slug>.preview.tinyfat.dev/
   ```

   If the site has a unique text marker, also fetch the body and confirm it.
7. Tell the user the preview URL, what changed, and one useful next choice.

## Canonical Preview Rule

Use normal `yeet project deploy` for the customer review URL:

`https://<slug>.preview.tinyfat.dev/`

Only use `yeet project deploy --preview` for temporary alternate previews that
should not replace the canonical review surface.

## Updating An Existing Project

When the user asks for edits:

1. `cd /data/projects/<slug>` or run `yeet project use <slug>`.
2. Read `PROJECT.md`, inspect `site/`, and make the requested change.
3. Update `PROJECT.md` if the brief/current state changed.
4. Run `yeet project deploy`.
5. Verify the URL and summarize the change.

Do not rely on an old dev server preview as proof. The durable deployed preview
is the review artifact.

## Failure Handling

- If `yeet project deploy` fails, read the error, fix the source or project
  setup, and retry.
- If verification fails, do not claim the deploy worked.
- If rollback is needed, say that deploy history exists but full self-service
  rollback may need operator help until the rollback slice ships.

## Product Boundary

Do not make sales/support chat, CRM automation, phone/email adapters, or custom
domain launch prerequisites for building the website. Those attach after the
TinyFat Website project loop works.
