---
name: pdf-gen
description: Generate PDFs from HTML using Chromium headless. Activate when user mentions PDF, print to PDF, generate PDF, HTML to PDF, document generation, or one-pager.
---

# PDF Generation via Chromium

**Generate polished PDFs from standalone HTML files using Chrome's headless print-to-PDF.**

---

## The Pattern

1. **Ask about style** — Before writing any HTML, ask the user: "Do you have a style preference for this document? (e.g., minimal/professional, bold/colorful, corporate/formal, or a reference URL/file)." If they decline or say "whatever looks good," use the default style below.
2. Create a standalone `index.html` with inline CSS
3. Add `@media print` and `@page` rules for print layout
4. Run Chrome headless to print it to PDF
5. Done. No build step, no dependencies, no framework.

---

## Style Principles (Default)

When no style preference is given, follow these principles:

- **Monochrome base** — Near-black text (`#1a1a1a`) on near-white background (`#fafafa`). Gray for secondary text (`#666`, `#888`).
- **Color is earned** — Only use color to convey meaning (warnings, successes, key callouts). Never decorative.
- **System fonts** — `Segoe UI, system-ui, -apple-system, sans-serif`. No web font dependencies.
- **Breathing room** — Generous margins, `line-height: 1.6`, clear spacing between sections.
- **Flat and honest** — No shadows, no gradients, no rounded-everything. Borders are `1px solid #ddd`. Accent borders are `4px solid`.
- **Hierarchy through weight and size** — Not through color or decoration. Bold headings, clear size steps.

---

## Default Style Template

Use this CSS as the starting point when no style is specified. It produces clean, professional documents.

```css
* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
  line-height: 1.6;
  color: #1a1a1a;
  background: #fafafa;
}

.container {
  max-width: 900px;
  margin: 4rem auto;
  padding: 0 2rem;
}

/* --- Typography --- */

h1 {
  font-size: 2rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}

h2 {
  font-size: 1.4rem;
  font-weight: 600;
  margin-top: 2.5rem;
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #ddd;
}

h3 {
  font-size: 1.1rem;
  font-weight: 600;
  margin-top: 1.5rem;
  margin-bottom: 0.75rem;
}

p { margin-bottom: 1rem; }

ul, ol {
  margin-bottom: 1rem;
  padding-left: 1.5rem;
}

li { margin-bottom: 0.5rem; }

/* --- Secondary text --- */

.subtitle { color: #666; font-size: 1.1rem; }
.date { color: #888; font-size: 0.9rem; margin-top: 0.5rem; }

/* --- Callout boxes (use sparingly, for semantic emphasis) --- */

.highlight {
  padding: 1rem 1.25rem;
  margin: 1.5rem 0;
  border-left: 4px solid;
}

.highlight.warning {
  background: #fefce8;
  border-color: #ca8a04;
}

.highlight.warning strong { color: #a16207; }

.highlight.success {
  background: #d1fae5;
  border-color: #059669;
}

.highlight.success strong { color: #047857; }

/* --- Tables --- */

table {
  width: 100%;
  border-collapse: collapse;
  margin: 1rem 0;
}

th, td {
  border: 1px solid #ddd;
  padding: 0.75rem;
  text-align: left;
}

th {
  background: #f4f4f4;
  font-weight: 600;
}

/* --- Code --- */

code {
  background: #f4f4f4;
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  font-family: 'SF Mono', 'Consolas', monospace;
  font-size: 0.9em;
}

pre {
  background: #1a1a1a;
  color: #f0f0f0;
  padding: 1rem;
  border-radius: 6px;
  overflow-x: auto;
  margin: 1rem 0;
  font-size: 0.9rem;
}

pre code {
  background: none;
  padding: 0;
  color: inherit;
}

/* --- CTA / inverted block --- */

.cta {
  background: #1a1a1a;
  color: #fff;
  padding: 1.5rem;
  border-radius: 8px;
  margin-top: 2rem;
  text-align: center;
}

.cta a { color: #fff; text-decoration: underline; }

/* --- Footer --- */

footer {
  margin-top: 3rem;
  padding-top: 1.5rem;
  border-top: 1px solid #ddd;
  color: #666;
  font-size: 0.9rem;
}

/* --- Print --- */

@page {
  size: Letter;
  margin: 0.5in;
}

@media print {
  body { background: #fff; }
  .no-print { display: none !important; }
  .container { margin: 0; max-width: none; }
}

.section { break-inside: avoid; }
```

### HTML Structure

Wrap content in a `.container` div. Use this skeleton:

```html
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Document Title</title>
  <style>
    /* paste default CSS above */
  </style>
</head>
<body>
<div class="container">
  <header>
    <h1>Title</h1>
    <p class="subtitle">One-line description</p>
    <p class="date">Author / Date</p>
  </header>

  <h2>Section</h2>
  <p>Content here.</p>

  <div class="highlight warning">
    <strong>Note:</strong> Callout text.
  </div>

  <footer>
    <p>&copy; 2026</p>
  </footer>
</div>
</body>
</html>
```

---

## Quick Start

```bash
# Generate PDF from an HTML file
google-chrome \
  --headless \
  --no-sandbox \
  --disable-gpu \
  --print-to-pdf="output.pdf" \
  --no-pdf-header-footer \
  "file://$(pwd)/index.html"
```

---

## Page Size Reference

| Format | CSS `size` value |
|--------|-----------------|
| US Letter | `8.5in 11in` or `Letter` |
| A4 | `210mm 297mm` or `A4` |
| Legal | `8.5in 14in` |
| Custom | Any CSS length pair |

---

## Chrome Flags Reference

| Flag | Purpose |
|------|---------|
| `--headless` | Run without UI |
| `--no-sandbox` | Required on Linux servers |
| `--disable-gpu` | Avoid GPU issues in headless |
| `--print-to-pdf=FILE` | Output path |
| `--no-pdf-header-footer` | Remove default header/footer (date, URL) |
| `--print-to-pdf-no-header` | Alternative for some Chrome versions |

---

## Tips

- **One page?** Use tight `@page` margins, small font sizes (8-9pt), and CSS Grid for multi-column layouts
- **Page breaks**: Use `page-break-before: always` on elements to force new pages, `break-inside: avoid` to keep sections together
- **Fonts**: System fonts render instantly. Web fonts may need a delay or preload
- **Images**: Use `file://` paths or base64-encoded inline images
- **Mermaid diagrams**: Include mermaid via CDN, but note headless Chrome needs `--run-all-compositor-stages-before-draw` for proper rendering
- **Verify**: Open the HTML in a browser first and use Print Preview (Ctrl+P) to check layout before generating

---

## Example: One-Pager

See `~/code/spellcasters-onepager/` for a complete example:
- `index.html` — Standalone HTML with inline CSS, `@page` rules, two-column grid layout
- `generate-pdf.sh` — Shell script wrapper

---

## Serving for Preview

For quick preview before PDF generation:

```bash
# Python (no install needed)
python3 -m http.server 8080

# Or just open directly
google-chrome file://$(pwd)/index.html
```
