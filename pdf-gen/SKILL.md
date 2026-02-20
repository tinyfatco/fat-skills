---
name: pdf-gen
description: Generate PDFs from HTML using Chromium headless. Use when asked to create a PDF, print to PDF, generate PDF, HTML to PDF, document generation, or one-pager.
---

# PDF Generation via Chromium

**Generate polished PDFs from standalone HTML files using Chrome's headless print-to-PDF.**

---

## The Pattern

1. Create a standalone `index.html` with inline CSS
2. Add `@media print` and `@page` rules for print layout
3. Run Chrome headless to print it to PDF
4. Done. No build step, no dependencies, no framework.

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

## HTML Template

The HTML file should be self-contained with inline `<style>`. Key CSS for print:

```css
@page {
  size: Letter;          /* or A4 */
  margin: 0.5in;         /* page margins */
}

@media print {
  body { background: #fff; }
  .no-print { display: none !important; }
}

/* Force page breaks */
h2 { page-break-before: always; }

/* Prevent orphaned content */
.section { break-inside: avoid; }
```

### Page Size Reference

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
| `--no-sandbox` | Required in containers |
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
- **Verify**: Write the HTML first, then generate the PDF. Iterate on the HTML until the PDF looks right.
