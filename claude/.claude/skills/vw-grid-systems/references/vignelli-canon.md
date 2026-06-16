# Vignelli Canon

## Origin

Massimo Vignelli, *The Vignelli Canon* (2010, self-published; later Lars Müller).
Codifies the discipline behind the **Unigrid** system Vignelli designed for the
U.S. National Park Service and the **1972 New York City Subway Map**. The canon
treats the grid as a moral position: rigor, restraint, and the rejection of
decoration in favor of *intellectual elegance*.

## Grid Structure

Vignelli's grids are **fixed-pixel, not fluid** — every column is a measured
slab, never a fraction. This is the defining trait: the grid does not stretch,
the content fits the grid.

| Property        | Value            | Notes                              |
|-----------------|------------------|------------------------------------|
| Container       | 1296px           | 48 + (12×78) + (11×24) + 48        |
| Columns         | 12               | Fixed 78px each                    |
| Column width    | 78px             | Rigid — `repeat(12, 78px)`         |
| Gutter          | 24px             | Constant between all columns        |
| Margin (L/R)    | 48px             | Symmetric                          |
| Section band    | 64px             | Black horizontal band, full bleed  |
| Baseline        | 12px             | All leading is a multiple          |

The black **horizontal band** (64px) is the signature divider — it segments the
page into Unigrid "bands" rather than relying on whitespace alone.

## Typography Rules

Vignelli permitted himself **six typefaces, forever**: Garamond, Bodoni,
Century Expanded, Futura, Times, and Helvetica. For Unigrid signage and
wayfinding the choice collapses to **Helvetica**, used almost exclusively.

| Role     | Size  | Leading | Weight            |
|----------|-------|---------|-------------------|
| Display  | 48px  | 48px    | Helvetica Bold    |
| Heading  | 32px  | 36px    | Helvetica Bold    |
| Subhead  | 24px  | 24px    | Helvetica Medium  |
| Body     | 16px  | 24px    | Helvetica Regular |
| Caption  | 12px  | 12px    | Helvetica Regular |

Rules: flush-left, ragged-right. No italics for emphasis (use weight). Tight,
consistent leading locked to the 12px baseline. Type is set in the band or
hung from a column edge — never centered.

## Palette

| Token   | Hex      | Use                          |
|---------|----------|------------------------------|
| Black   | `#000000`| Bands, text, rules           |
| White   | `#FFFFFF`| Ground, reverse type         |
| Red     | `#E30613`| Single accent — Vignelli Red |

One accent only. Color is information, never ornament.

## CSS Implementation

```css
:root {
  --vc-container: 1296px;
  --vc-columns: 12;
  --vc-col-width: 78px;
  --vc-gutter: 24px;
  --vc-margin: 48px;
  --vc-band: 64px;
  --vc-baseline: 12px;

  --vc-black: #000000;
  --vc-white: #FFFFFF;
  --vc-red:   #E30613;

  --vc-font: "Helvetica Neue", Helvetica, Arial, sans-serif;
}

.vc-page {
  max-width: var(--vc-container);
  margin-inline: auto;
  padding-inline: var(--vc-margin);
  background: var(--vc-white);
  color: var(--vc-black);
  font-family: var(--vc-font);
}

/* Fixed-pixel grid — the columns do NOT stretch */
.vc-grid {
  display: grid;
  grid-template-columns: repeat(var(--vc-columns), var(--vc-col-width));
  column-gap: var(--vc-gutter);
  justify-content: center;
}

/* Signature black section band, full-bleed */
.vc-band {
  height: var(--vc-band);
  background: var(--vc-black);
  color: var(--vc-white);
  display: flex;
  align-items: center;
  padding-inline: var(--vc-margin);
  margin-inline: calc(-1 * var(--vc-margin));
  font: 700 32px/36px var(--vc-font);
}

.vc-display { font: 700 48px/48px var(--vc-font); }
.vc-body    { font: 400 16px/24px var(--vc-font); text-align: left; }
.vc-accent  { color: var(--vc-red); }

/* Span helpers */
.vc-span-3 { grid-column: span 3; }
.vc-span-4 { grid-column: span 4; }
.vc-span-6 { grid-column: span 6; }
```

## Key Differentiators

- **Fixed pixels, not fractions.** `repeat(12, 78px)` — stricter than any `fr`
  layout. Content conforms to the grid; the grid never adapts to content.
- **The black band** is structural, not decorative — it does the work that
  whitespace does in Swiss grids, giving Unigrid its instantly-recognizable look.
- **Six typefaces, one in practice.** Where Gerstner explored variation,
  Vignelli imposed permanent constraint — Helvetica answers nearly everything.
- **One red, ever.** A single accent (`#E30613`) carries all color meaning.
- **Discipline as ideology.** The canon is prescriptive and absolute, contrasting
  with Gerstner's generative *programme* of many valid outcomes.
