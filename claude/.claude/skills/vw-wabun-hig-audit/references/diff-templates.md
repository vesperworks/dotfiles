# Refactor Diff Templates

Critical / Serious 違反には必ず diff を出す。Moderate 以下はサマリだけで OK（ユーザが「diff も出して」と言ったら追加出力）。

## 出力フォーマット（必須）

```
Issue: [一行で違反内容]
File:  [path] · Line [N]（行が特定できれば）
Tag:   [Critical|Serious|Moderate|Tip] / Category #N

Before:
  [元コード 1〜5 行]

After:
  [修正コード]

Why:   [一文。rule の出典は hig-foundations.md §X / wabun-typography.md §Y で参照]
```

行が特定できない場合 `Line —`。フレームワーク（Vanilla / Tailwind / React inline / styled-components）で書式を切り替える。

---

## 1. Color: ハードコード hex → semantic token

### Vanilla CSS

```diff
- color: #333333;
+ color: var(--color-text-primary);  /* HIG label 相当 */
```

### Tailwind

```diff
- className="text-[#333]"
+ className="text-primary"  /* tailwind.config の semantic token */
```

### React inline

```diff
- style={{ color: '#333' }}
+ style={{ color: 'var(--color-text-primary)' }}
```

---

## 2. Spacing: 任意値 → 8pt grid

```diff
- padding: 13px;
+ padding: 12px;  /* 4pt grid に丸め、可能なら 16px */
```

Tailwind:

```diff
- className="p-[13px]"
+ className="p-3"  /* 12px */
```

5 箇所以上重複する場合:

```
Fix shown for line 23. Apply the same pattern to lines 31, 47, 89, 102.
```

---

## 3. Typography: 本文サイズ < 14px

```diff
- body { font-size: 12px; }
+ body { font-size: 1rem; }  /* 16px、HIG Body 17pt に近い妥協値 */
```

---

## 4. Line-height: 和文本文 < 1.5

```diff
- p { line-height: 1.4; }
+ p { line-height: 1.75; }  /* JLREQ 推奨レンジ、kiso.css 既定値 */
```

---

## 5. 和文フォントスタック欠落

```diff
- body { font-family: Arial, sans-serif; }
+ body {
+   font-family:
+     -apple-system, BlinkMacSystemFont,
+     "SF Pro Text",
+     "Hiragino Sans", "Hiragino Kaku Gothic ProN",
+     "Yu Gothic UI", "Noto Sans JP",
+     sans-serif;
+ }
```

---

## 6. 和文約物アキ（text-spacing-trim / text-autospace / palt）

```diff
  body {
    font-family: ...;
+   font-feature-settings: "palt" 1;
+   text-spacing-trim: trim-start;
+   text-autospace: normal;
+   line-break: strict;
  }
```

---

## 7. Touch Target < 44pt

```diff
- .icon-button { width: 32px; height: 32px; }
+ .icon-button {
+   min-width: 44px;
+   min-height: 44px;
+   /* アイコンサイズは内側で調整、ヒット領域を確保 */
+ }
```

---

## 8. focus-visible（`outline: none` 単独）

```diff
- button:focus { outline: none; }
+ button:focus-visible {
+   outline: 2px solid var(--color-accent);
+   outline-offset: 2px;
+ }
```

---

## 9. Dark Mode 未対応

```diff
  :root {
    --color-bg-primary: #ffffff;
    --color-text-primary: #000000;
  }
+
+ @media (prefers-color-scheme: dark) {
+   :root {
+     --color-bg-primary: #1c1c1e;       /* HIG systemBackground (dark) */
+     --color-text-primary: rgba(255,255,255,0.92);
+   }
+ }
+
+ html { color-scheme: light dark; }
```

---

## 10. prefers-reduced-motion 未対応

```diff
  .modal { transition: opacity 200ms ease-out; }
+
+ @media (prefers-reduced-motion: reduce) {
+   *, *::before, *::after {
+     animation-duration: 0.01ms !important;
+     transition-duration: 0.01ms !important;
+   }
+ }
```

---

## 11. Viewport meta 欠落

```diff
  <head>
    <meta charset="UTF-8" />
+   <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>…</title>
  </head>
```

---

## 12. safe-area-inset 未対応（固定フッタ）

```diff
- .footer { position: fixed; bottom: 0; padding: 16px; }
+ .footer {
+   position: fixed;
+   bottom: 0;
+   padding: 16px;
+   padding-bottom: max(16px, env(safe-area-inset-bottom));
+ }
```

---

## 13. ボタンラベルが動詞でない

```diff
- <button>OK</button>
+ <button>変更を保存</button>
```

---

## 14. アイコン単独 `<button>` の aria-label

```diff
- <button><CloseIcon /></button>
+ <button aria-label="閉じる"><CloseIcon /></button>
```

---

## 15. 入力 type 不一致

```diff
- <input type="text" placeholder="メールアドレス" />
+ <input type="email" autocomplete="email" placeholder="メールアドレス" />
```

---

## diff 出力の運用ルール

1. **Critical / Serious は必ず diff を出す**。Moderate / Tip はサマリのみ、要望時に展開
2. 同一 fix の繰り返しは 1 つだけ出して `Apply the same pattern to lines …`
3. Tailwind / React inline / Vanilla CSS の **どの形で書かれているかを diff の中で踏襲する**
4. `Why:` 行は必ず付け、参照する rubric を `hig-foundations.md §N` / `wabun-typography.md §M` で示す
5. 出力先のレポートには diff だけでなく **Before / After のフルパス・行番号** を残し、後から手で適用できるようにする
