# Gerstner Programme

## Origin

Karl Gerstner, *Designing Programmes / Programme entwerfen* (1964).
Gerstner's thesis: don't design the *solution*, design the *programme* that
generates all valid solutions. His grid for the magazine **Capital** is the
canonical demonstration — a single underlying mesh on which 2, 3, 4, 5 and 6
column layouts all resolve cleanly, chosen per spread without breaking the system.

## Grid Structure

The trick is **micro-columns**. The least common multiple of 2, 3, 4, 5, 6 is
**60**, so a 60-unit grid lets every column count land on exact unit boundaries.

| Property         | Value           | Notes                               |
|------------------|-----------------|-------------------------------------|
| Container        | 1296px          | 48 + 1200 + 48                      |
| Available width  | 1200px          | The active grid field               |
| Micro-columns    | 60              | LCM(2,3,4,5,6) — `repeat(60, 1fr)`  |
| Gutter           | 8px             | Fine, module-scaled                 |
| Margin (L/R)     | 48px            | Symmetric                           |
| Row module       | 8px             | `grid-auto-rows: 8px`               |

Column-count → span mapping on the 60-unit grid:

| Layout    | Columns | Span each |
|-----------|---------|-----------|
| Halves    | 2       | 30        |
| Thirds    | 3       | 20        |
| Quarters  | 4       | 15        |
| Fifths    | 5       | 12        |
| Sixths    | 6       | 10        |

## Typography Rules

Swiss grotesques only: **Akzidenz-Grotesk**, **Helvetica**, **Univers**.
The type scale is geometric, ratio ≈ 1.5:

| Role     | Size  | Leading | Weight             |
|----------|-------|---------|--------------------|
| Display  | 72px  | 72px    | Bold               |
| Title    | 48px  | 48px    | Bold               |
| Heading  | 32px  | 40px    | Medium / Bold      |
| Subhead  | 24px  | 32px    | Medium             |
| Body     | 16px  | 24px    | Regular            |
| Caption  | 12px  | 16px    | Regular            |

Rules: flush-left. Leading snaps to the 8px row module. The same text can be
re-flowed into any column count without retypesetting — that is the programme.

## Palette

| Token   | Hex      | Use                         |
|---------|----------|-----------------------------|
| Black   | `#000000`| Text, rules                 |
| White   | `#FFFFFF`| Ground                      |
| Red     | `#E30613`| Primary accent              |
| Blue    | `#005BBB`| Alternate single primary    |

Black plus **one** primary (red *or* blue), chosen per programme — never both at full.

## CSS Implementation

```css
:root {
  --gp-container: 1296px;
  --gp-field: 1200px;
  --gp-micro: 60;        /* LCM(2,3,4,5,6) */
  --gp-gutter: 8px;
  --gp-margin: 48px;
  --gp-row: 8px;

  --gp-black: #000000;
  --gp-white: #FFFFFF;
  --gp-red:   #E30613;
  --gp-blue:  #005BBB;

  --gp-font: "Akzidenz-Grotesk", "Helvetica Neue", Helvetica, Arial, sans-serif;
}

.gp-page {
  max-width: var(--gp-container);
  margin-inline: auto;
  padding-inline: var(--gp-margin);
  background: var(--gp-white);
  color: var(--gp-black);
  font-family: var(--gp-font);
}

/* One mesh, every column count resolves on it */
.gp-grid {
  display: grid;
  grid-template-columns: repeat(var(--gp-micro), 1fr);
  grid-auto-rows: var(--gp-row);
  column-gap: var(--gp-gutter);
  row-gap: var(--gp-row);
}

/* Span helpers — same grid, different programmes */
.gp-2 { grid-column: span 30; }  /* halves   */
.gp-3 { grid-column: span 20; }  /* thirds   */
.gp-4 { grid-column: span 15; }  /* quarters */
.gp-5 { grid-column: span 12; }  /* fifths   */
.gp-6 { grid-column: span 10; }  /* sixths   */

.gp-display { font: 700 72px/72px var(--gp-font); }
.gp-body    { font: 400 16px/24px var(--gp-font); text-align: left; }
.gp-accent  { color: var(--gp-red); }
```

## Key Differentiators

- **Programme, not layout.** Gerstner designs the *generator*; Vignelli designs
  the *result*. One mesh yields many valid pages.
- **60 micro-columns** via LCM(2,3,4,5,6) — the mathematical heart that lets
  2–6 column layouts coexist on identical grid lines.
- **Fluid `1fr`, not fixed px** — opposite of Vignelli's rigid `78px` slabs.
- **Two-axis modularity:** `grid-auto-rows: 8px` makes vertical rhythm as
  systematic as the horizontal columns.
- **Fine 8px gutter** scaled to the row module, where Vignelli uses a coarse 24px.
