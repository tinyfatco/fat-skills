---
name: websites-for-people-factory
description: "Run TinyFat's safe end-to-end Websites for People pipeline for a qualified local-business lead: source-backed research, business-specific design brief, isolated Codex site build, independent desktop/mobile QA, private repository, exact deployment verification, human-approved Gmail draft through gog, canonical ledger reconciliation, and provider receipt capture after the human sends."
---

# Websites for People Factory

Use this skill when Alex asks to take a qualified Websites for People lead from
research through a ready-to-review website and outreach draft, revise that
draft, or reconcile a human-sent message.

This is an agent-run production workflow with one hard human boundary:
**agents may create and revise Gmail drafts, but must never send prospect
outreach automatically.** Alex reviews and sends from Gmail.

## Sources of Truth

- Canonical CRM/ledger: the configured Websites for People SQLite database.
- Factory implementation: the configured private factory repository.
- One private `site-<slug>` repository per prospect.
- Protected run evidence outside Git, mode `0600`.
- Gmail provider readback, not a local body file or UI impression, is
  authoritative for draft/sent state.

Never put prospect contact data, provider MIME, private evidence, credentials,
or operational host details in a site repository or other public Git history.

## Non-Negotiable Gates

Before research, build, deploy, drafting, or send reconciliation:

1. Resolve one canonical prospect ID.
2. Duplicate-check normalized business name, domain, email, phone, listing
   identity, and prior artifacts/outbound rows.
3. Confirm no active suppression, opt-out, complaint, bounce, prior contact, or
   unresolved reply.
4. Confirm current public-business identity and website/listing source.
5. Require the canonical approval for the next consequential stage.
6. Fail closed on ambiguity. Do not substitute a different lead, sender account,
   domain, claim, image, or contact address.

Every stage must be idempotent. A safe retry either returns the exact existing
artifact or performs one compare-and-swap transition. Preserve append-only
ledger events/evidence when mutable projections are updated.

## End-to-End Workflow

### 1. Qualify and research

- Verify the live Google Business/Maps identity and current Website field.
- Verify business name, operating status, service area/address, phone, public
  email/contact path, hours, and any claims used on the page.
- Treat the current business site and listing as factual sources, not permission
  to invent copy, reviews, certifications, prices, photos, or guarantees.
- Retain source URLs and hashes in protected evidence.

### 2. Produce a business-specific design brief

Separate factual manifest data from design interpretation. Capture the actual
business vibe: tone, palette, type feel, imagery, density, local character,
call/booking behavior, trust signals, and what should not be lost.

Do not reuse a house template across unrelated businesses. The brief may
interpret style; it may not create new public facts.

### 3. Build with the isolated Codex worker

- Scaffold first through `site-factory`.
- Let Codex change only the factory-approved site files.
- Keep the orchestrator responsible for state, approvals, bounded workspaces,
  retries, credential isolation, cleanup, and evidence.
- Reject symlink/path escapes, protected-input mutation, unexpected files,
  unreported filesystem changes, unbounded output, or failed deterministic QA.
- Keep the site repository private and free of prospect contact data.

### 4. Independently QA the site

Codex does not approve its own work. Run deterministic static QA plus an
independent real-Chrome pass.

At minimum verify:

- desktop and mobile render successfully;
- 320px, a common phone width, and desktop have no horizontal overflow;
- mobile content has comfortable left **and right** edge padding;
- no clipped text, overlapping controls, broken anchors, console errors, or
  blocked/unexpected external requests;
- verified phone, directions, and contact links work;
- images, favicon, and referenced assets load;
- all visible copy is in-world business copy, not proposal/design/agent jargon;
- only source-backed facts and assets appear.

Store screenshots and QA results as protected evidence.

### 5. Deploy and verify exact bytes

Deploy only after the required deploy approval. Accept deployment only when the
public HTML/CSS/assets match the approved local build hashes. Record provider
deployment identity, live HTTPS URL, local build hash, and public byte
verification. A successful CLI exit without public readback is not enough.

### 6. Create the Gmail approval draft with `gog`

Read the shared `gog` skill before operating Gmail.

Use the configured TinyFat Workspace sender explicitly. Never substitute a
personal or fallback sender when its authorization fails:

```bash
gog gmail drafts create \
  --account "$WFP_GMAIL_ACCOUNT" \
  --gmail-no-send \
  --dry-run \
  --no-input \
  --to 'prospect@example.com' \
  --subject 'Custom site we made for Example Business' \
  --body-file /protected/path/message.txt \
  --body-html "$(cat /protected/path/message.html)" \
  --json
```

Apply only after the dry run is exact, retaining `--gmail-no-send`.

Default first-touch shape:

```text
Hey [Name] — I came across [Business] and made a custom site for you:

[verified live URL]

[One concise sentence about what was retained and improved.]

Want to see anything changed? Just email me back and I’ll update it for you.

If you like it, we can put it on your domain. After that, whenever you need an update, just email us and we’ll handle it.

Alex
```

Writing rules:

- Use a literal subject such as `Custom site we made for [Business]`.
- Never expose internal terms such as “site agent,” orchestration, Codex,
  dashboard automation, pipeline, or CRM.
- The first CTA invites a reply with requested changes.
- Explain maintenance plainly: they email us and we handle updates.
- Keep both plain text and minimal native-looking HTML.
- Do not add a self-CC unless Alex explicitly requests it.
- Never call `gmail send` or `drafts send` in this workflow.

### 7. Read back and render the provider draft

Immediately fetch the created draft by provider draft ID with `gog` and decode
both MIME alternatives. Verify all of the following exactly:

- sender account;
- recipient(s);
- subject;
- plain-text body;
- HTML body;
- live URL;
- expected draft/thread identity;
- labels equal `DRAFT` with no `SENT`;
- no non-draft prior-contact collision;
- prohibited internal language is absent.

Render the provider HTML in an isolated browser and inspect it. Bind the
canonical content digest to the exact provider fields, not merely local source
files. Only then transition the ledger to `email_ready` / planned outbound.

### 8. Revise drafts safely

A browser compose can autosave stale text over an API edit. Before revision,
close or confirm the absence of an open compose for that draft. Then:

1. read the current provider draft;
2. dry-run `gog gmail drafts update` with `--gmail-no-send`;
3. apply once;
4. fetch and decode the provider MIME again;
5. re-render it;
6. verify `DRAFT`-only and no send;
7. append amendment evidence and compare-and-swap the canonical planned
   outbound hashes/account/thread/artifact without losing prior evidence.

Never claim a revision from the update response alone. Provider readback is the
proof.

### 9. Reconcile a human send

When Alex says he sent the draft, do **not** send anything. Read Gmail instead.

- Locate the exact sent message by authoritative thread/subject/recipient.
- Verify `SENT` and absence of `DRAFT` on the sent provider message.
- Decode the exact plain/HTML content and confirm it matches the last approved
  provider draft (allowing only provider-normalized transport details).
- Record provider message/thread IDs and the provider send timestamp.
- Recheck suppression/reply/bounce state.
- Append sent-receipt evidence and compare-and-swap planned outbound to sent;
  set the prospect/pipeline sent stage and sent date exactly once.
- Re-run the reconciliation as an idempotency test; it must create no duplicate
  run/event/outbound/send count.

If the sent content or recipient differs from the canonical draft, stop and
record an explicit reconciliation exception instead of silently rewriting
history.

## Completion Report

Report only concrete facts:

- qualified prospect and source status;
- private build repository and commit;
- independent QA result;
- exact verified deployment URL;
- Gmail account and `DRAFT`-only status, or provider-verified sent receipt after
  Alex sends;
- canonical stage/version;
- external send count performed by agents (must be zero).

Do not mark the workflow complete while provider and canonical state disagree.
