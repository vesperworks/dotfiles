---
name: grid-systems
description: 9 種のグリッドシステムからエディトリアル/UI/書籍レイアウトを構築する skill。Müller-Brockmann、Vignelli、Gerstner、Tschichold、Bootstrap、Material Design、8-Point Grid、Golden Ratio、Classical Canons を網羅。ユーザーが「グリッドシステムで」「editorial layout で」「Swiss design で」「bootstrap grid で」「material grid で」「黄金比で」「書籍レイアウトで」と言ったときに使う。
---

<!--
  Grid Systems — 9 Systems, One Discipline
  Müller-Brockmann reference ported from HyperAgent skill by alexmcdonnell-airtable
    https://github.com/alexmcdonnell-airtable/hyperagent-public-skills
  Other systems researched and compiled for Codex skill format.
-->

# Grid Systems — 9 Systems, One Discipline

## Use When

- ユーザーが `グリッドシステムで` と言ったとき
- ユーザーが `editorial layout` `Swiss design` `magazine spread` を要求したとき
- ユーザーが `bootstrap grid` `material design grid` `黄金比レイアウト` を要求したとき
- ユーザーが `grid overlay` `align to the grid` `ベースライングリッド` を要求したとき
- HTML/CSS でレイアウトを構築する際に、体系的なグリッドシステムに基づきたいとき

## Trigger Phrases

- `グリッドシステムで`
- `editorial layout`
- `Swiss design`
- `magazine spread`
- `bootstrap grid で`
- `material grid で`
- `黄金比で`
- `8-point grid で`
- `書籍レイアウトで`
- `Vignelli`
- `Tschichold`
- `Gerstner`

## Do Not Use

- 非レイアウト作業（ロジック実装、API 設計等）
- Figma / Sketch 等のデザインツール操作

## System Selection Guide

| Use case | System | Key trait |
|----------|--------|-----------|
| Magazine / report | **Müller-Brockmann** | 12-col + 8px baseline + optical alignment + verify harness |
| Information design / signage | **Vignelli Canon** | 12-col fixed-px + horizontal bands + 6-typeface limit |
| Variable layout | **Gerstner Programme** | 60 micro-columns (2–6 col simultaneously) |
| Book / text-heavy | **Tschichold** | Asymmetric margins + strong left axis |
| General website | **Bootstrap** | 12-col + 6 breakpoints |
| App UI | **Material Design** | 4→8→12 variable columns + 8dp |
| Spacing discipline | **8-Point Grid** | All dimensions = multiples of 8 (composable) |
| Proportion-driven | **Golden Ratio** | φ/√2 proportions + modular type scale |
| Classical book | **Classical Canons** | Single text block + margin ratio 2:3:4:6 |

## Common Principles (all systems)

1. **One source of truth**: all grid params in `:root` CSS variables
2. **8px baseline unit**: universal across all systems
3. **Spacing = 8× multiples**: margin, padding, gap, media heights
4. **Line-height in px**: never unitless for display type (prevents baseline drift)
5. **Overlay toggle**: `G` key shows the grid (available for column-grid systems)

## Workflow

1. Choose a system from the table above (or ask — describe the use case)
2. Read the corresponding reference file for full rules + CSS scaffold
3. Set `:root` variables and build the layout
4. For Müller-Brockmann: `scripts/grid_tokens.py --scaffold` generates a full page; `scripts/verify_grid.js` proves 0px adherence

## Cross-System Comparison

| System | Columns | Unit | Typeface | Margins | Alignment | Era |
|--------|---------|------|----------|---------|-----------|-----|
| Müller-Brockmann | 12 | 8px BL | Grotesque sans | Sym 72px | Flush-left | 1981 |
| Vignelli | 12 fixed-px | 78px col | Helvetica only | Sym 48px | Flush-left | 2010 |
| Gerstner | 60 micro | 8px | Akzidenz-Grotesk | Sym 48px | Flush-left | 1964 |
| Tschichold | 2-split | 8px | Sans preference | Asym 64/192 | Flush-left | 1928 |
| Bootstrap | 12 | rem | Any | BP-dependent | Any | 2011 |
| Material | 4→12 | 8dp | Roboto | BP-dependent | Any | 2014 |
| 8-Point | N/A | 8px | Any | 8× multiples | Any | 2016 |
| Golden Ratio | φ-split | φ ratio | Any | Any | Any | ancient |
| Classical | none | ratio | Serif | 2:3:4:6 | Justify | medieval |

## References

- [Müller-Brockmann](./references/muller-brockmann.md) — Modular grid, 12-col + baseline + optical alignment
- [Vignelli Canon](./references/vignelli-canon.md) — Unigrid + 6-typeface discipline
- [Gerstner Programme](./references/gerstner-programme.md) — 60 micro-column programmable grid
- [Tschichold](./references/tschichold-neue-typo.md) — Asymmetric typography
- [Bootstrap](./references/bootstrap.md) — 12-col responsive web grid
- [Material Design](./references/material-design.md) — Adaptive column grid + 8dp
- [8-Point Grid](./references/8-point-grid.md) — Spacing discipline system
- [Golden Ratio](./references/golden-ratio.md) — Proportional system + modular scale
- [Classical Canons](./references/classical-canons.md) — Medieval page construction

## Scripts

- **`scripts/grid_tokens.py`** — Müller-Brockmann scaffold generator (`:root` tokens, `.grid`/`.band` subgrid, `.guides` overlay, toggle JS, optical-alignment JS)
- **`scripts/verify_grid.js`** — Puppeteer verification harness (column adherence, overlay match, baseline, optical ink)
