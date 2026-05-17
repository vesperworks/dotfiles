# HIG Foundations Rubric

Apple Human Interface Guidelines (iOS / macOS / iPadOS) を「CSS / Tailwind config / DTCG JSON 監査時に参照する期待値リスト」に圧縮したもの。

出典: https://developer.apple.com/design/human-interface-guidelines/

各項目に **Critical / Serious / Moderate / Tip** の重み付けタグを付ける。重みの定義は `scoring-rubric.md` を参照。

---

## 1. Typography（HIG Typography 章）

### 1.1 タイプスケール（必須）

HIG iOS のテキストスタイル 11 段階（pt）:

| Style       | Size | Weight   | Line Height | 用途 |
|-------------|------|----------|-------------|------|
| LargeTitle  | 34   | Regular  | 41          | ナビバー大見出し |
| Title1      | 28   | Regular  | 34          | セクション見出し |
| Title2      | 22   | Regular  | 28          | サブ見出し |
| Title3      | 20   | Regular  | 25          | リスト見出し |
| Headline    | 17   | Semibold | 22          | 強調本文 |
| Body        | 17   | Regular  | 22          | **本文（基準値）** |
| Callout     | 16   | Regular  | 21          | サブ本文 |
| Subheadline | 15   | Regular  | 20          | キャプション強 |
| Footnote    | 13   | Regular  | 18          | 補足 |
| Caption1    | 12   | Regular  | 16          | 注釈 |
| Caption2    | 11   | Regular  | 13          | 最小可読 |

判定:

- 本文 `font-size` が **11pt (14.67px @ 1x)** 未満 → **Critical**（可読性下限割れ）
- 本文 `font-size` が **17pt (22.67px @ 1x)** 未満かつ 14pt (≈18.67px) 未満 → **Serious**（HIG Body 未満）
- 使用 `font-size` の総数が **6 段階超** → **Moderate**（スケール冗長）
- 隣接段階の倍率が **1.125 未満** → **Tip**（スケール平坦）

CSS / Tailwind での期待値:

```css
/* HIG Body 相当（Web は 1pt ≒ 1.333px） */
:root {
  --text-body: 17pt;       /* ≒ 22.67px */
  --text-body-line: 1.32;  /* 22/17 */
}
```

Tailwind: `text-base` (16px) は HIG Callout 相当。本文には `text-lg` (18px) または独自 17pt を推奨。

### 1.2 Dynamic Type（必須）

ユーザのアクセシビリティ設定で本文サイズが変動することを前提とする。Web では:

- `font-size` を `px` ハードコードではなく **`rem` / `em`** で指定 → 必須
- レイアウトが本文 200% で崩れる → **Critical**
- レイアウトが本文 150% で崩れる → **Serious**
- `min-height` で行を固定し、サイズ変動を吸収できない → **Moderate**

### 1.3 SF Pro / システムフォントスタック

```css
font-family:
  -apple-system, BlinkMacSystemFont,
  "SF Pro Text", "SF Pro Display",
  "Helvetica Neue", Arial, sans-serif;
```

- システムフォント未指定（任意フォント単独） → **Moderate**
- Display と Text の使い分けを意識していない（28pt 以上は Display） → **Tip**

---

## 2. Color（HIG Color 章）

### 2.1 Semantic Color（必須）

ハードコード hex は **Critical**（ダークモード追従不能）。HIG semantic を CSS variable / DTCG token として定義し、それを参照すること。

期待される semantic color トークン（HIG iOS UIKit 由来）:

| 用途 | UIKit name | CSS var 例 |
|------|-----------|------------|
| 本文 | label | `--color-text-primary` |
| 補助本文 | secondaryLabel | `--color-text-secondary` |
| 三次 | tertiaryLabel | `--color-text-tertiary` |
| プレースホルダ | placeholderText | `--color-text-placeholder` |
| 区切り | separator | `--color-border-default` |
| 区切り（不透明） | opaqueSeparator | `--color-border-opaque` |
| 背景 | systemBackground | `--color-bg-primary` |
| 二次背景 | secondarySystemBackground | `--color-bg-secondary` |
| 三次背景 | tertiarySystemBackground | `--color-bg-tertiary` |
| 充填 | systemFill | `--color-fill-primary` |
| 二次充填 | secondarySystemFill | `--color-fill-secondary` |
| Tint | tintColor | `--color-accent` |

判定:

- 本文色がハードコード hex → **Critical**
- 区切り線色がハードコード → **Serious**
- semantic token 未定義（命名が役割ベースでない、例: `--gray-500` を本文に使用） → **Serious**
- 同役割で 2 種類以上の hex を使い分けている → **Moderate**

### 2.2 WCAG AA コントラスト（必須）

| ペア | 最低比 |
|------|--------|
| 通常テキスト | 4.5:1 |
| 大テキスト（18pt 以上 or 14pt 以上 bold） | 3:1 |
| UI 部品 | 3:1 |

- 通常テキストが **4.5:1 未満** → **Critical**
- 大テキストが **3:1 未満** → **Critical**
- placeholderText 相当の灰色が背景に対し **3:1 未満** → **Serious**

### 2.3 Dark Mode（HIG 必須要件）

```css
:root { --color-bg-primary: #ffffff; --color-text-primary: #000000; }

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg-primary: #000000;
    --color-text-primary: rgba(255,255,255,0.85);
  }
}
```

判定:

- ダークモード未対応（`prefers-color-scheme` 0 件 かつ `.dark` 系セレクタ 0 件） → **Critical**
- ダーク時に hex ハードコードでトークンを介していない → **Serious**
- 純黒 `#000` 背景（HIG は `systemBackground` 経由で僅かに浮かせる推奨） → **Moderate**
- `color-scheme: light dark` 未指定（スクロールバー等が追従しない） → **Tip**

### 2.4 Color Blindness

- 赤 / 緑ペアを「成功 / エラー」の唯一の差として使用 → **Serious**（アイコン併用必須）
- 色相のみで状態を伝達（テキスト・アイコン併用なし） → **Serious**

---

## 3. Layout（HIG Layout 章）

### 3.1 8pt Grid

`padding` / `margin` / `gap` / `width` / `height` は **4 の倍数**、可能なら **8 の倍数**。

- 8 の倍数でも 4 の倍数でもない値（例 `13px`） → **Moderate**
- 4 の倍数だが 8 の倍数でない（例 `12px`） → **Tip**
- Tailwind の `p-[13px]` 等の任意値 → **Moderate**
- 同じ off-grid 値が 5 箇所以上に複製 → **Serious**（一括 fix の好機）

### 3.2 Touch Target

- インタラクティブ要素の `width` × `height` が **44pt × 44pt (≈ 44px × 44px @ 1x)** 未満 → **Critical**（HIG iOS 必須）
- アイコンボタンの `padding` 込みヒット領域が 44pt 未満 → **Critical**
- macOS の場合は 28pt が下限、それ未満 → **Serious**

### 3.3 Safe Area

```css
padding-top: env(safe-area-inset-top);
padding-bottom: env(safe-area-inset-bottom);
```

- Web 配信を iOS Safari で見せる前提なのに `env(safe-area-inset-*)` 0 件 → **Serious**（ノッチ・ホームインジケータに重なる）
- フッタ固定要素に `safe-area-inset-bottom` 未適用 → **Critical**

### 3.4 Margins / Content Width

- 本文コンテナに `max-width` 未指定 → **Tip**（広画面で読みづらい）
- `max-width > 1440px` の本文 → **Tip**
- 端から `padding` ゼロで文字が画面端に接する → **Serious**

---

## 4. Corner Radius

HIG iOS 標準スケール: `4 / 8 / 10 / 12 / 16 / 20 / 22 / 28 / continuous`

- 同種要素（カード / ボタン / モーダル）に **3 種以上の radius 値** → **Moderate**
- スケール外の値（例 `7px`, `11px`, `13px`） → **Tip**
- ボタンと隣接コンテナで「内側 radius > 外側 radius - padding」のはみ出し → **Moderate**
- ラージモーダル（幅 400px 以上）に `radius < 12px` → **Tip**（HIG は大物ほど大 radius 推奨）

---

## 5. Elevation / Materials

HIG は `box-shadow` 多用を嫌い、`material` レイヤ（背景の透過＋ブラー）で階層を表現する。

- カード階層に shadow を 5 段階以上使用 → **Moderate**
- shadow の `blur` / `y-offset` が連続しない（例: 2px → 24px ジャンプ） → **Tip**
- macOS Vibrancy / `backdrop-filter` 未使用で透過パネルを表現 → **Tip**

---

## 6. Iconography

- アイコン単独要素に `aria-label` なし → **Critical**
- アウトライン / フィルが混在 → **Moderate**
- SF Symbols とそれ以外のアイコンセット混在 → **Tip**
- インライン `<svg>` に `aria-hidden="true"` も `role="img"` も無い → **Critical**

---

## 7. Components（HIG Common Components）

HIG が定義する代表コンポーネント:

- Button (Filled / Tinted / Plain / Bordered)
- TextField
- Picker / Wheel
- Toggle (Switch)
- Slider
- SegmentedControl
- TabBar / Sidebar
- Sheet / Popover / Alert

判定:

- 同役割ボタンに 2 種以上の `background-color` → **Critical**
- 同役割ボタンに 2 種以上の `border-radius` → **Moderate**
- TextField の `:focus` / `:focus-visible` 未スタイル → **Critical**

---

## 8. States

ボタン / リンク / 入力に必要な状態:

- `:hover` 未定義 → **Moderate**
- `:focus-visible` 未定義 or `outline: none` 単独 → **Critical**（キーボード操作不能）
- `:active` 未定義 → **Tip**
- `[disabled]` の視覚的差別化なし → **Serious**

---

## 9. Motion

- `prefers-reduced-motion` 未対応で `animation` / `transition` を使用 → **Critical**
- `transition: all` の使用 → **Moderate**（特定プロパティ指定推奨）
- UI 遷移 `duration > 500ms` → **Moderate**
- `animation-iteration-count: infinite` でユーザ停止手段なし → **Moderate**

---

## 10. Tokens（DTCG / CSS variable）

- ハードコード hex が CSS 全体で **20 箇所超** → **Serious**
- 同セマンティック役割に複数 hex が共存 → **Serious**
- DTCG token 命名が役割ベースでない（例 `--gray-500` のまま本文に使用） → **Moderate**

---

## 11. Accessibility（横断）

- `tabindex > 0` → **Moderate**
- `<img>` の `alt` 欠落 → **Critical**
- `<button>` 内テキスト無し かつ `aria-label` 無し → **Critical**
- 入力に `<label for>` も `aria-label` も無し → **Critical**

---

## 12. Forms

- 入力 `type` 不一致（メールに `type="text"`） → **Serious**
- `autocomplete` 属性なし（個人情報入力） → **Moderate**
- エラーメッセージが `aria-describedby` で関連付けされていない → **Moderate**
- ラジオ / チェックボックス群に `<fieldset><legend>` 無し → **Moderate**

---

## 13. Navigation

- TabBar / Sidebar 項目に現在地（`aria-current="page"`）の視覚差別化なし → **Serious**
- スキップリンク（`Skip to main content`）無し → **Moderate**

---

## 14. Responsive / Adaptive

- ビューポート `<meta name="viewport">` 無し → **Critical**
- 固定 `width > 480px` でレスポンシブ未対応 → **Critical**
- 本文 `font-size < 16px` で iOS 入力ズーム発火 → **Serious**
- `100vh` 使用、`dvh` フォールバックなし → **Moderate**

---

## 15. Materials & Vibrancy

（HIG macOS）

- `backdrop-filter` 未使用で疑似 vibrancy を実現 → **Tip**
- 透過層を 3 段以上重ねて読みづらい → **Moderate**

---

## 16-19. その他カテゴリ

- **16. Microcopy**: ボタンラベルが動詞でない（"OK" / "Submit"） → **Moderate**
- **17. Internationalization**: 物理方向プロパティ（`margin-left`）使用 → **Tip**（`margin-inline-start` 推奨）
- **18. Ethics / Dark Patterns**: 必須項目ラジオで「同意する」だけ初期チェック → **Serious**
- **19. Heuristics（Nielsen 10）**: エラー回復手段なし、現在地表示なし等 → **Moderate**

---

## 第 20 カテゴリ「Japanese Typography」

→ `wabun-typography.md` を参照。
