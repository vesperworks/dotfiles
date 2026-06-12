# Bootstrap Grid (v5.3)

## Origin

Bootstrap は Mark Otto と Jacob Thornton が Twitter 社内ツールとして開発し、2011 年に OSS 公開したフロントエンドフレームワーク。v5.3 (2023) は jQuery 依存を排し、CSS カスタムプロパティと Flexbox/Grid を基盤とする。正典は公式ドキュメント [getbootstrap.com/docs/5.3/layout/grid](https://getbootstrap.com/docs/5.3/layout/grid/)。世界で最も普及した 12 列レスポンシブグリッドの事実上の標準。

## Grid Structure

12 列固定 + 6 ブレークポイント。コンテナ幅は BP ごとに固定値へスナップする（fluid を除く）。

| BP | 接頭辞 | 発火幅 | container 幅 | 列数 | gutter | container padding |
|----|--------|--------|-------------|------|--------|-------------------|
| Extra small | `xs` | <576px | 100% (fluid) | 12 | 1.5rem (24px) | 12px (左右) |
| Small | `sm` | ≥576px | 540px | 12 | 24px | 12px |
| Medium | `md` | ≥768px | 720px | 12 | 24px | 12px |
| Large | `lg` | ≥992px | 960px | 12 | 24px | 12px |
| Extra large | `xl` | ≥1200px | 1140px | 12 | 24px | 12px |
| Extra extra large | `xxl` | ≥1400px | 1320px | 12 | 24px | 12px |

- gutter は `--bs-gutter-x: 1.5rem`。列の左右に `gutter/2 = 12px` の padding として現れる。
- マージン（container 左右）は padding 12px + row の negative margin で相殺される構造。
- 1296px の親コンテナでは `xxl` が発火し container は 1320px 上限の手前、実コンテンツは 1296 − 24 = 1272px 前後。

## Typography Rules

- ルート 16px。`rem` 基準で全スケールを定義。
- spacer system: `0 / 4 / 8 / 16 / 24 / 48px`（`$spacer = 1rem` の 0, .25, .5, 1, 1.5, 3 倍）。

| 要素 | size | line-height |
|------|------|-------------|
| h1 | 40px (2.5rem) | 1.2 |
| h2 | 32px (2rem) | 1.2 |
| h3 | 28px (1.75rem) | 1.2 |
| body | 16px (1rem) | 1.5 |

- 本文 line-height 1.5、見出しは `$headings-line-height: 1.2`。
- 整列はフレックスユーティリティ（`text-start` / `text-center` / `text-end`）で制御。

## Palette

Bootstrap はパレット自由。デフォルトのテーマカラーを例示する。

| token | hex |
|-------|-----|
| primary (Bootstrap Blue) | `#0d6efd` |
| secondary | `#6c757d` |
| success | `#198754` |
| danger | `#dc3545` |
| body color | `#212529` |
| body bg | `#ffffff` |

## CSS Implementation

CSS Grid で `col-*-N → grid-column: span N` を写したスキャフォールド。コピペで動作する。

```css
:root {
  --bs-gutter-x: 1.5rem;   /* 24px */
  --bs-gutter-y: 0;
  --bs-root-font-size: 16px;
  --bs-primary: #0d6efd;
  --bs-body-color: #212529;
  --bs-body-bg: #ffffff;
  /* spacers */
  --sp-0: 0; --sp-1: 4px; --sp-2: 8px;
  --sp-3: 16px; --sp-4: 24px; --sp-5: 48px;
}

* { box-sizing: border-box; }
body { font-size: 16px; line-height: 1.5; color: var(--bs-body-color); background: var(--bs-body-bg); margin: 0; }
h1 { font-size: 2.5rem; line-height: 1.2; }
h2 { font-size: 2rem;   line-height: 1.2; }
h3 { font-size: 1.75rem; line-height: 1.2; }

.container {
  width: 100%;
  padding-inline: 12px;
  margin-inline: auto;
}
@media (min-width: 576px)  { .container { max-width: 540px; } }
@media (min-width: 768px)  { .container { max-width: 720px; } }
@media (min-width: 992px)  { .container { max-width: 960px; } }
@media (min-width: 1200px) { .container { max-width: 1140px; } }
@media (min-width: 1400px) { .container { max-width: 1320px; } }

/* 12-column CSS Grid row */
.row {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  column-gap: var(--bs-gutter-x);
  row-gap: var(--bs-gutter-y);
}

/* base: full width until a breakpoint sets a span */
[class^="col-"] { grid-column: span 12; }

/* span helpers — N from 1..12 */
.col-1 { grid-column: span 1; } .col-2 { grid-column: span 2; }
.col-3 { grid-column: span 3; } .col-4 { grid-column: span 4; }
.col-6 { grid-column: span 6; } .col-8 { grid-column: span 8; }
.col-9 { grid-column: span 9; } .col-12 { grid-column: span 12; }

/* responsive variant example: md and up */
@media (min-width: 768px) {
  .col-md-4 { grid-column: span 4; }
  .col-md-6 { grid-column: span 6; }
  .col-md-8 { grid-column: span 8; }
}
@media (min-width: 992px) {
  .col-lg-3 { grid-column: span 3; }
  .col-lg-4 { grid-column: span 4; }
  .col-lg-6 { grid-column: span 6; }
}
```

```html
<div class="container">
  <div class="row">
    <div class="col-12 col-md-8 col-lg-9">main</div>
    <div class="col-12 col-md-4 col-lg-3">aside</div>
  </div>
</div>
```

## Key Differentiators

- **コンテナ幅がスナップ式**: 流動ではなく BP ごとに 540/720/960/1140/1320px へ固定ジャンプする。Material のような連続可変ではない。
- **列数は常に 12 固定**: ブレークポイントで変わるのはコンテナ幅と各要素の span であって、列数自体は不変。
- **mobile-first**: 接頭辞なし (`col-`) が最小幅から適用され、上位 BP で上書きする加法的設計。
- **gutter が padding 由来**: 列の内側 padding（12px×2）として gutter を表現するため、negative margin での相殺が必要。CSS Grid 移植では `column-gap` に置換できる。
- **ユーティリティ駆動**: spacing/alignment をクラス（`g-*`, `text-center` 等）で宣言し、独自 CSS を最小化する思想。
