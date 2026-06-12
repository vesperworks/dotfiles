# 8-Point Grid

## Origin

Bryn Jackson が 2016 年頃に Spec.fm で体系化したスペーシング規律（[spec.fm/specifics/8-pt-grid](https://spec.fm/specifics/8-pt-grid)）。Müller-Brockmann のタイポグラフィにおける 8px ベースライングリッドの思想を、デジタル UI のスペーシング全般へ展開したもの。列グリッドではなく「すべての寸法を 8 の倍数に揃える」という横断的規律であり、他のグリッドシステムと**併用可能**（補完的）。

## Grid Structure

列グリッドを持たない。**全寸法 = 8 の倍数**というスケールが本体。

| step | px |
|------|-----|
| 1 | 8 |
| 2 | 16 |
| 3 | 24 |
| 4 | 32 |
| 5 | 40 |
| 6 | 48 |
| 7 | 56 |
| 8 | 64 |
| 9 | 72 |
| 10 | 80 |
| 12 | 96 |

- **Hard grid**: 8px 方眼を画面に敷き、レイアウトの位置・幅・高をその交点/倍数に乗せる。
- **Soft grid**: コンポーネント内部の padding / gap を 8 の倍数で統制する（方眼に厳密に乗せなくてよい）。
- 小要素（アイコン内余白、ボーダー隣接など）は **4px ハーフステップ**を許可。
- 1296px コンテナでは外周マージン・列間・要素間をすべて 8 系（16/24/32...）で構成する。1296 自体も 162×8 で 8 の倍数。

## Typography Rules

- **行高を 8 に丸める**: 16px 本文の行高は 1.5 = 24px（= 3×8）に設定し、垂直リズムを 8px グリッドに同期させる。
- font-size 自体は 8 倍数でなくてよい（14/16/18 等の慣用値で可）。重要なのは **line-height と margin が 8 系**であること。

| 要素 | size | line-height |
|------|------|-------------|
| body | 16px | 24px (3×8) |
| h3 | 24px | 32px (4×8) |
| h2 | 32px | 40px (5×8) |
| h1 | 40px | 48px (6×8) |

- 段落間マージンは 24px または 16px。見出し前後は 32/48px で 8 系を維持。
- 整列ルールは規定しない（スペーシング規律のみ）。

## Palette

パレットは**自由**。8-point grid が規定するのはスペーシングのみで、配色には一切関与しない。任意のカラーシステム（Material / Catppuccin / ブランド色）と組み合わせる。

## CSS Implementation

spacing token を `--sp-N` で定義し、すべての margin/padding/gap をトークン経由で指定する。コピペで動作する。

```css
:root {
  --sp-1: 8px;
  --sp-2: 16px;
  --sp-3: 24px;
  --sp-4: 32px;
  --sp-5: 40px;
  --sp-6: 48px;
  --sp-7: 56px;
  --sp-8: 64px;
  --sp-9: 72px;
  --sp-10: 80px;
  --sp-12: 96px;
  --sp-half: 4px; /* 小要素専用ハーフステップ */
}

* { box-sizing: border-box; }
body {
  margin: 0;
  font-size: 16px;
  line-height: 24px;          /* 3 × 8 */
  padding: var(--sp-3);       /* 24px */
}

h1 { font-size: 40px; line-height: 48px; margin-block: var(--sp-6); }
h2 { font-size: 32px; line-height: 40px; margin-block: var(--sp-5); }
h3 { font-size: 24px; line-height: 32px; margin-block: var(--sp-4); }
p  { margin-block: var(--sp-3); }

/* soft grid: component-internal spacing in 8-multiples */
.card {
  padding: var(--sp-3);       /* 24px */
  display: grid;
  gap: var(--sp-2);           /* 16px */
}
.card__icon { padding: var(--sp-half); } /* 4px half-step allowed */

/* stack utility — vertical rhythm on the 8px grid */
.stack > * + * { margin-top: var(--sp-2); }
.stack--loose > * + * { margin-top: var(--sp-4); }

/* optional debug overlay: visualize the 8px hard grid */
.grid-debug {
  background-image: repeating-linear-gradient(
    to bottom, rgba(255,0,0,.08) 0 1px, transparent 1px 8px);
}
```

```html
<article class="card stack">
  <h3>Title</h3>
  <p>Body text on a 24px (3×8) baseline.</p>
</article>
```

## Key Differentiators

- **列グリッドではない**: カラム/ガター/マージンの 12 列分割を持たず、スペーシングの倍数規律のみを定める。
- **併用前提**: Bootstrap や Material の列グリッドの上に重ねて使える補完的レイヤー。排他的でない。
- **8 が割り切れる強み**: 多くのディスプレイ密度（@1x/@1.5x/@2x）で整数 px に収まり、半端な小数を生まない。
- **行高ファースト**: font-size より line-height と垂直マージンを 8 系に揃えることを重視し、垂直リズムを担保する。
- **4px ハーフステップ**: 微小要素のみ例外として 4px を許す現実的な逃げ道を持つ。
- **配色に非干渉**: パレットを規定せず、純粋に寸法規律として独立している。
