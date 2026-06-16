# Material Design Grid (M3)

## Origin

Google が 2014 年に発表したデザイン言語 Material Design の第 3 世代 (M3, 2021)。物理メタファ（紙とインク、影による階層）を基盤に、レスポンシブグリッドと 8dp ベースラインを規定する。正典は [m3.material.io/foundations/layout](https://m3.material.io/foundations/layout)。Android / Web / Flutter を横断する Google 公式のレイアウト規範。

## Grid Structure

核心は**列数が可変**であること。画面幅に応じてマージン・列数が切り替わる（Bootstrap の「列固定・幅可変」とは逆の発想）。

| デバイス | 発火幅 | 列数 | margin | gutter |
|---------|--------|------|--------|--------|
| Phone | <600dp | 4 | 16dp | 16dp |
| Tablet | 600–904dp | 8 | 24dp | 24dp |
| Desktop | 905dp+ | 12 | 24dp | 24dp |

M3 の **window size class**（レイアウト判断の正典区分）:

| class | 幅 | 想定列数 |
|-------|-----|---------|
| Compact | <600dp | 4 |
| Medium | 600–839dp | 12（8 列運用も可） |
| Expanded | 840dp+ | 12 |

- ベースライン **8dp グリッド**。小要素（アイコン、チップ内余白）は 4dp サブグリッドを許可。
- 1296px コンテナは Expanded（≥840）に入り、12 列 / margin 24 / gutter 24。実コンテンツ幅 = 1296 − 48(margin) = 1248px、列幅 ≈ (1248 − 24×11)/12 ≈ 82px。

## Typography Rules

書体は **Roboto**（M3 既定。ブランドフォントへの差し替え可）。type scale は role ベース。

| role | size | line-height |
|------|------|-------------|
| Display Large | 57px | 64px |
| Headline Large | 32px | 40px |
| Title Large | 22px | 28px |
| Body Large | 16px | 24px |
| Label Large | 14px | 20px |

- 本文 Body Large 16/24（line-height は 8 の倍数に整列）。
- **タッチターゲット最小 48dp**（アクセシビリティ必須要件）。
- 整列は left-align 基調、中央寄せは限定的に使用。

## Palette

M3 baseline（light scheme）。実運用では tonal palette を seed から生成する。

| token | hex |
|-------|-----|
| Primary | `#6750A4` |
| On-Primary | `#FFFFFF` |
| Surface | `#FFFBFE` |
| On-Surface | `#1C1B1F` |
| Secondary | `#625B71` |
| Outline | `#79747E` |

## CSS Implementation

ブレークポイントごとに `repeat(N,1fr)` を切り替えるスキャフォールド。コピペで動作する。

```css
:root {
  --md-baseline: 8px;
  --md-primary: #6750A4;
  --md-on-primary: #ffffff;
  --md-surface: #FFFBFE;
  --md-on-surface: #1C1B1F;
  --md-outline: #79747E;
  font-family: Roboto, system-ui, sans-serif;
}

* { box-sizing: border-box; }
body { margin: 0; background: var(--md-surface); color: var(--md-on-surface); }

/* type scale */
.display-large  { font-size: 57px; line-height: 64px; }
.headline-large { font-size: 32px; line-height: 40px; }
.title-large    { font-size: 22px; line-height: 28px; }
.body-large     { font-size: 16px; line-height: 24px; }
.label-large    { font-size: 14px; line-height: 20px; }

/* min touch target */
.touch { min-width: 48px; min-height: 48px; }

/* responsive grid — columns change per breakpoint */
.md-grid {
  display: grid;
  /* Compact <600: 4 columns, 16dp margin/gutter */
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-inline: 16px;
}

/* Medium 600–904: 8 columns, 24dp */
@media (min-width: 600px) {
  .md-grid {
    grid-template-columns: repeat(8, 1fr);
    gap: 24px;
    margin-inline: 24px;
  }
}

/* Expanded 905+: 12 columns, 24dp */
@media (min-width: 905px) {
  .md-grid {
    grid-template-columns: repeat(12, 1fr);
    gap: 24px;
    margin-inline: 24px;
  }
}

/* span helpers (work within whatever column count is active) */
.span-4  { grid-column: span 4; }
.span-6  { grid-column: span 6; }
.span-8  { grid-column: span 8; }
.span-12 { grid-column: span 12; }
```

```html
<div class="md-grid">
  <section class="span-8">main</section>
  <aside class="span-4">rail</aside>
</div>
```

## Key Differentiators

- **列数が可変**: 4 → 8 → 12 と画面幅で増える。Bootstrap（常時 12 列）と根本的に異なるレスポンシブ哲学。
- **8dp ベースライン**: すべての寸法・行送りを 8 の倍数に整列（小要素のみ 4dp 許可）。8-point grid と同じスペーシング規律を内蔵。
- **window size class**: Compact / Medium / Expanded という意味論的区分でレイアウト分岐を判断する。px 直書きより設計意図が明確。
- **48dp タッチターゲット**: アクセシビリティを寸法規格に組み込んでいる点が他システムにない。
- **tonal palette 生成**: 単一 seed 色から HCT 色空間でトーン段階を自動生成する動的カラーが前提。固定 hex リストではない。
