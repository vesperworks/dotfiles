# Golden Ratio & Proportional Systems

## Origin

φ (黄金比) = 1.618… を寸法生成の母数とする比例系。Le Corbusier が 1948 年に発表した **Modulor**（人体寸法と黄金比を組み合わせた建築寸法体系）が代表的正典。デジタルでは [modularscale.com](https://www.modularscale.com/) が比率反復によるタイプスケール生成を普及させた。列グリッドではなく、**ひとつの比率を反復適用して寸法列（モジュラースケール）を生む**プロポーション規律。

## Grid Structure

固定列数を持たない。**比率を反復適用**して寸法を導出する。

φ タイプスケール（base 16px、各段に ×1.618）:

| 段 | px |
|----|-----|
| −1 | 9.89 |
| 0 (base) | 16 |
| +1 | 25.89 |
| +2 | 41.89 |
| +3 | 67.77 |
| +4 | 109.66 |

√2 スケール（base 16px、各段に ×1.414 — 紙の A 判比率）:

| 段 | px |
|----|-----|
| −1 | 11.31 |
| 0 | 16 |
| +1 | 22.63 |
| +2 | 32 |
| +3 | 45.25 |
| +4 | 64 |

- **列幅生成例**: 1152px を φ 分割 → 1152 / 1.618 ≈ 712px : 440px の 2 カラム。
- 1296px を φ 分割 → 801px : 495px。再帰すれば 495 を 306:189 へと入れ子分割できる。
- **Le Corbusier Modulor 代表値 (cm)**: 27 / 43 / 70 / 113 / 183 / 226（各隣接が概ね φ 関係。183=平均身長、226=挙手高）。

## Typography Rules

- 書体は自由。重要なのは **size が φ（または √2）の等比数列**を成すこと。
- 行送りも比率で導く（例: line-height = font-size × 1.5、または隣接スケール段を行高に流用）。

| role | size (φ scale) | line-height |
|------|---------------|-------------|
| h1 | 67.77px | 1.1 |
| h2 | 41.89px | 1.15 |
| h3 | 25.89px | 1.2 |
| body | 16px | 1.5 |
| caption | 9.89px | 1.4 |

- 隣接段の比が一定（1.618）なので、見出し階層に視覚的な調和が生まれる。
- 整列ルールは規定しない（プロポーション規律のみ）。

## Palette

パレットは**自由**。黄金比系が規定するのは寸法プロポーションのみで、配色には関与しない。任意のカラーシステムと組み合わせる。

## CSS Implementation

`grid-template-columns: 1.618fr 1fr` で φ 分割、type は `--fs-N` 変数で等比スケールを定義する。コピペで動作する。

```css
:root {
  --phi: 1.618;
  /* φ type scale, base 16px */
  --fs--1: 9.89px;
  --fs-0:  16px;
  --fs-1:  25.89px;
  --fs-2:  41.89px;
  --fs-3:  67.77px;
  --fs-4:  109.66px;
  /* √2 alternative */
  --fs-root2-1: 22.63px;
  --fs-root2-2: 32px;
}

* { box-sizing: border-box; }
body { margin: 0; font-size: var(--fs-0); line-height: 1.5; }

h1 { font-size: var(--fs-3); line-height: 1.1; }
h2 { font-size: var(--fs-2); line-height: 1.15; }
h3 { font-size: var(--fs-1); line-height: 1.2; }
small, .caption { font-size: var(--fs--1); line-height: 1.4; }

/* golden-ratio two-column split: 1.618fr : 1fr */
.phi-split {
  display: grid;
  grid-template-columns: var(--phi, 1.618fr) 1fr;
  /* gutter also from the scale */
  gap: var(--fs-1);
  max-width: 1296px;
  margin-inline: auto;
}
/* 1296px → ≈ 801 : 495 (minus gap) */

/* nested recursive φ division */
.phi-split__minor {
  display: grid;
  grid-template-columns: 1.618fr 1fr; /* split 495 → ~306 : 189 */
  gap: var(--fs-0);
}

/* spacing derived from the same scale */
.section { padding-block: var(--fs-2); }
.stack > * + * { margin-top: var(--fs-1); }
```

```html
<main class="phi-split">
  <article>major (≈ 801px)</article>
  <aside class="phi-split__minor">
    <div>minor-A</div>
    <div>minor-B</div>
  </aside>
</main>
```

## Key Differentiators

- **比例系であって列グリッドではない**: 列数を固定せず、ひとつの比率を反復適用して寸法を導く。
- **fr 単位と相性抜群**: `1.618fr 1fr` だけで黄金分割が成立し、メディアクエリ不要でも比率が保たれる。
- **再帰分割**: 分割した小区画をさらに同じ比率で割れる。フラクタル的な調和が生まれる。
- **複数の母数を選べる**: φ(1.618) / √2(1.414, A 判) / 1.5(完全五度) など比率を差し替えるだけでスケール全体が再生成される。
- **建築由来の系譜**: Le Corbusier Modulor という人体寸法×黄金比の歴史的正典を持ち、8-point grid のような格子規律とは出自が異なる。
- **配色に非干渉**: パレットを規定せず、純粋にプロポーション規律として独立している。
