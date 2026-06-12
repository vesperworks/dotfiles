# Classical Page Canons

## Origin

The medieval manuscript tradition for proportioning the text block on the page:
the **Van de Graaf canon**, the **Villard de Honnecourt diagram**, and **Jan
Tschichold's golden canon** (reconstructed in *The Form of the Book*, 1975).
These are not column grids but geometric constructions that place a single text
block in harmonic relationship to a 2:3 page — the same ratios found in Gutenberg
and incunabula. (This is the *late* Tschichold, after he recanted the New
Typography of `tschichold-neue-typo.md`.)

## Grid Structure

A **single justified block**, not a multi-column grid. The block is *similar* to
the page (same 2:3 ratio) and positioned by the margin proportion
**inner : top : outer : bottom = 2 : 3 : 4 : 6**.

| Property          | Value          | Notes                                  |
|-------------------|----------------|----------------------------------------|
| Page ratio        | 2 : 3          | 720 × 1080px                           |
| Page width        | 720px          |                                        |
| Page height       | 1080px         |                                        |
| Text block        | 480 × 720px    | 2:3 — similar to the page              |
| Margin inner      | 160px          | unit ×2                                 |
| Margin top        | 120px          | unit ×3 (×40px base)                    |
| Margin outer      | 320px          | unit ×4 — wait, see note               |
| Margin bottom     | 240px          | unit ×6                                 |

Practical single-page padding (top right bottom left) used in CSS below resolves
the 2:3:4:6 family to **`120px 160px 240px 80px`** — bottom is the deepest, the
outer edge wider than the inner (gutter) edge. On a **spread**, inner and outer
margins **swap** between the left (verso) and right (recto) page.

## Typography Rules

Serif faces, set for sustained reading: **EB Garamond**, **Garamond**, **Georgia**.

| Role     | Size  | Leading | Style                |
|----------|-------|---------|----------------------|
| Title    | 32px  | 40px    | Garamond, small caps |
| Heading  | 21px  | 28px    | Garamond Italic      |
| Body     | 16px  | 26px    | Garamond Regular     |
| Caption  | 13px  | 20px    | Garamond Italic      |

**Justified** body (`text-align: justify`) with automatic hyphenation — the
opposite of the New Typography's mandatory ragged-right. Even measure, generous
leading, no widows.

## Palette

| Token        | Hex      | Use                       |
|--------------|----------|---------------------------|
| Ink black    | `#1A1A1A`| Body text (soft, not pure)|
| Cream paper  | `#FBF7EF`| Ground — warm laid paper  |
| Vermilion    | `#A41E22`| Rubrication / initials    |

Soft black ink on warm cream, with vermilion ("rubric") for initials and headings.

## CSS Implementation

```css
:root {
  --cc-page-w: 720px;
  --cc-page-h: 1080px;

  /* margins: top right bottom left = 3:4:6:2 family */
  --cc-mt: 120px;
  --cc-mr: 160px;
  --cc-mb: 240px;
  --cc-ml: 80px;

  --cc-ink:   #1A1A1A;
  --cc-paper: #FBF7EF;
  --cc-rubric:#A41E22;

  --cc-font: "EB Garamond", Garamond, Georgia, serif;
}

/* No CSS Grid needed — a single proportioned block */
.cc-page {
  width: var(--cc-page-w);
  min-height: var(--cc-page-h);
  margin-inline: auto;
  padding: var(--cc-mt) var(--cc-mr) var(--cc-mb) var(--cc-ml);
  background: var(--cc-paper);
  color: var(--cc-ink);
  font-family: var(--cc-font);
  box-sizing: border-box;
}

.cc-body {
  font: 400 16px/26px var(--cc-font);
  text-align: justify;
  hyphens: auto;
}
.cc-title  { font: 400 32px/40px var(--cc-font); font-variant: small-caps; }
.cc-rubric { color: var(--cc-rubric); }

/* Spread: verso/recto swap inner & outer margins */
.cc-spread .cc-verso {
  padding: var(--cc-mt) var(--cc-ml) var(--cc-mb) var(--cc-mr); /* outer left */
}
.cc-spread .cc-recto {
  padding: var(--cc-mt) var(--cc-mr) var(--cc-mb) var(--cc-ml); /* outer right */
}
```

## Key Differentiators

- **No column grid at all** — a single text block proportioned to the page, where
  every other system here is a multi-column or split mesh.
- **Self-similar block:** the 2:3 text block echoes the 2:3 page, the geometric
  core of the Van de Graaf / Villard construction.
- **Justified + hyphenated**, the exact inverse of Tschichold's *New Typography*
  ragged-right rule — and a marker of his later classical reversal.
- **Spread-aware margins:** inner/outer swap across verso and recto; the others
  use symmetric or fixed margins indifferent to page side.
- **Warm, soft palette** (cream paper, soft ink, vermilion) versus the pure
  black/white/red of the modernist systems.
