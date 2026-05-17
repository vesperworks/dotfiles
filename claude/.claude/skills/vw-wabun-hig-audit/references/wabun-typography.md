# Wabun Typography Rubric（和文タイポグラフィ）

W3C JLREQ（日本語組版処理の要件）と kiso.css を「和文を含む CSS / Tailwind config 監査時の期待値」に圧縮したもの。

出典:
- W3C JLREQ: https://w3c.github.io/jlreq/?lang=ja
- kiso.css: https://github.com/tak-dcxi/kiso.css

このファイルは SKILL.md の **第 20 カテゴリ「Japanese Typography」** で参照される。

---

## 適用判定

監査対象に **和文文字（U+3040–U+30FF、U+4E00–U+9FFF）が含まれるか**、`lang="ja"` 指定があるか、`font-family` に `Hiragino` / `YuGothic` / `Noto Sans JP` / `BIZ UDPGothic` が含まれる場合のみ、このカテゴリを適用する。

英文のみ対象なら全項目スキップ（採点から除外）。

---

## 1. 行間（line-height）

JLREQ 推奨: 本文行間は **1.5em〜1.75em**（行内行の重なりを避け、可読性を担保する範囲）。kiso.css は `1.75` を採用。

判定:

- 本文 `line-height < 1.5` → **Serious**（和文がぎゅう詰めで読みづらい）
- 本文 `line-height` が 1.5〜1.65 → **Moderate**（最低限だが余裕なし）
- 本文 `line-height` が 1.65〜1.85 → **OK**（推奨レンジ）
- 本文 `line-height > 2.0` → **Tip**（行間ぼけ）
- 数値（無単位）ではなく `px` で固定指定 → **Moderate**（Dynamic Type と相互作用しない）

期待値:

```css
body { line-height: 1.75; }
h1, h2, h3 { line-height: 1.35; }  /* 見出しは詰め気味 */
```

---

## 2. 文字間（letter-spacing / 約物）

### 2.1 letter-spacing

JLREQ: 和文に欧文と同じ `letter-spacing` を一律適用すると不自然になる。和文は **0〜0.05em**、欧文混植時は別途調整。

- `letter-spacing > 0.1em` を本文に適用 → **Moderate**（和文がカチカチ）
- 見出しに `letter-spacing` 指定なし → **Tip**（やや締まる方が伝統的に美しい）

### 2.2 約物の半角化（CSS `text-spacing-trim`）

JLREQ §3.1: 行頭・行末・連続する約物（句読点・括弧）はベタ組みでは半角扱い。

```css
body {
  text-spacing-trim: trim-start;        /* 行頭の約物を半角に */
  /* Chromium / Safari 17+ サポート */
}
```

- `text-spacing-trim` 未指定 → **Tip**（JLREQ 準拠の組版は妥協）
- 約物の前後に手動で `margin` を入れて調整している（負債的対応） → **Moderate**

### 2.3 和欧混植のアキ（CSS `text-autospace`）

JLREQ §3.2: 和文と欧文・数字の境界に四分アキ（0.25em 相当）を自動挿入。

```css
body { text-autospace: normal; }  /* CSS Text 4 */
```

- 和欧混植コンテンツで `text-autospace` 未指定 → **Moderate**（境界が窮屈に詰まる）
- 代替として `<span class="latin">` で手動 `padding-inline` を入れる → **Tip**（保守性低）

---

## 3. プロポーショナル化（`font-feature-settings: "palt"`）

`palt`: Proportional Alternate Widths。Hiragino / Yu Gothic が持つメトリクス。和文を欧文と並べる時にアキを詰めて自然化。

```css
body {
  font-feature-settings: "palt" 1;
}
```

- 和欧混植が多い UI で `palt` 未指定 → **Moderate**（漢字 + 括弧 + 数字の組がスカスカ）
- 見出しのみ `palt`、本文は ベタ → **OK**（JLREQ 純然たる本文ではベタ推奨派もあり、運用次第）
- `palt` と `letter-spacing` を併用して意図が衝突 → **Moderate**

---

## 4. 禁則処理

### 4.1 行頭禁則（`line-break`）

```css
body { line-break: strict; }
```

- `line-break` 未指定（デフォルト `auto`） → **Tip**（厳格な禁則を保証できない）
- `line-break: loose` を本文に適用 → **Moderate**（句読点が行頭に来る）

### 4.2 文節改行（`word-break: auto-phrase`）

CSS Text 4 の新機能（Chromium 119+ / Safari 17.4+）。文節境界で自然に折り返す。

```css
h1, h2, .hero-text { word-break: auto-phrase; }
```

- 見出しに `auto-phrase` 未使用 → **Tip**（おまけ）
- 本文に `word-break: break-all` を使用（欧文も漢字も切る） → **Serious**（読みづらい）

---

## 5. 段落折返し（`text-wrap`）

CSS Text 4:

- `text-wrap: pretty` — 寡婦寡夫行（widow / orphan）を回避し、最後の行が不自然にならないよう調整
- `text-wrap: balance` — 見出しの行末を均等に揃える（2-3 行限定）

```css
p   { text-wrap: pretty; }
h1, h2 { text-wrap: balance; }
```

- 本文 `text-wrap` 未指定 → **Tip**
- 長い見出しを `text-wrap: balance` で揃えていない → **Tip**

---

## 6. フォントスタック（和欧混植）

期待されるフォントスタック（HIG SF Pro × Hiragino 混植）:

```css
body {
  font-family:
    -apple-system, BlinkMacSystemFont,
    "SF Pro Text", "Helvetica Neue",
    "Hiragino Sans", "Hiragino Kaku Gothic ProN",
    "Yu Gothic UI", "Meiryo UI", "Yu Gothic",
    "Noto Sans JP", sans-serif;
}
```

判定:

- 英欧文フォントのみで和文フォント未指定 → **Critical**（OS デフォルトに任せると Windows で MS PGothic 等の旧フォントに落ちる）
- 和文フォントが Pro / ProN / Pr6N 等の **ProN 系を使っていない** → **Tip**（JIS2004 字形対応）
- Hiragino Mincho（明朝）を UI 本文に使用 → **Moderate**（HIG 推奨は Gothic 系）

### 6.1 Google Fonts Noto Sans JP の読み込み

- `font-display: swap` 未指定で FOIT 発生 → **Moderate**
- subset (text 引数) 指定なしで全グリフ読み込み → **Tip**（パフォーマンス）

---

## 7. 縦中横（`text-combine-upright`）

縦書きを扱う場合のみ。横書き UI なら N/A。

```css
.tatechuyoko { text-combine-upright: all; }
```

- 縦書きレイアウトで 2 桁数字 / 単位（cm, kg 等）を縦中横化していない → **Tip**

---

## 8. ルビ（`<ruby>`）

教育・読み物系コンテンツのみ。判定対象外（Tip 候補に留める）。

---

## 9. その他の和文配慮

- `letter-spacing` をマイナス値で詰める（`-0.05em` 等） → **Moderate**（フォントメトリクス破壊）
- `font-weight: 400` 以下の細字で本文 → **Tip**（Hiragino Sans W3 は本文には細い、W4 推奨）
- `<wbr>` / `&shy;` を一切使わず長い英単語が和文行を破る → **Tip**

---

## 検出ヒント（コード監査での grep / regex）

```
# line-height の値抽出
grep -E "line-height\s*:" *.css
# → 数値 1.5 未満なら Serious、1.5-1.65 で Moderate

# text-spacing-trim / text-autospace の有無
grep -E "text-spacing-trim|text-autospace" *.css
# → 0 件なら Tip / Moderate

# palt の有無
grep -E 'font-feature-settings.*"palt"' *.css
# → 和欧混植 UI で 0 件なら Moderate

# 和文フォントの有無
grep -E 'Hiragino|Yu Gothic|Noto Sans JP|Meiryo|BIZ UDPGothic' *.css
# → 0 件かつ lang="ja" あり → Critical

# line-break / word-break
grep -E "line-break\s*:|word-break\s*:" *.css

# text-wrap
grep -E "text-wrap\s*:" *.css
```

DTCG JSON の場合:

- `$type: typography` の token に `lineHeight` フィールドがあり、和文本文相当のサイズで 1.5 未満 → 該当判定
- `letterSpacing` が和文本文に 0.1em 超で適用 → Moderate

---

## 推奨デフォルト CSS（kiso.css 由来、最小セット）

```css
:root {
  /* 和文タイポ既定 */
  --font-family-ja:
    "Hiragino Sans", "Hiragino Kaku Gothic ProN",
    "Yu Gothic UI", "Noto Sans JP", sans-serif;
  --line-height-body: 1.75;
  --line-height-heading: 1.35;
}

html { font-family: var(--font-family-ja); }

body {
  line-height: var(--line-height-body);
  font-feature-settings: "palt" 1;
  text-spacing-trim: trim-start;
  text-autospace: normal;
  line-break: strict;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

h1, h2, h3, h4, h5, h6 {
  line-height: var(--line-height-heading);
  text-wrap: balance;
  word-break: auto-phrase;
}

p { text-wrap: pretty; }
```

このセットからの逸脱を「期待値とのギャップ」として diff 出力する。
