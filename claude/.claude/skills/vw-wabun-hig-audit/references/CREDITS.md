# CREDITS

このスキルは以下の先行成果物から思想・構造・参考記述を借りている。

## 直接フォーク元（references から部分流用）

**Ashutos1997/claude-design-auditor-skill**

- リポジトリ: https://github.com/Ashutos1997/claude-design-auditor-skill
- 参照バージョン: v1.2.13
- 参照コミット SHA: `e7a1f3153d8e7cbf485924a1b92b6110aa0be299`
- 取得日: 2026-05-19
- ライセンス: MIT

借りた要素:

- 採点式（`100 - (Critical×12 + Serious×8 + Moderate×4 + Tip×1)`）
- カテゴリ分類（Color / Typography / Spacing / Corner Radius / Elevation / States / Heuristics / Tokens 等）の骨子
- 信頼度宣言（Step 1.5）のパターン
- references/typography.md、color.md、spacing.md、corner-radius.md、states.md、heuristics.md からの個別記述

落とした要素（このスキルでは扱わない）:

- Figma MCP 連携（`get_design_context` 等、10ツール）
- 多言語自動検出 + 韓国語層
- 入力収集ステップの多段化

## 規範文書（ルーブリックの一次出典）

- **Apple Human Interface Guidelines (HIG)** — https://developer.apple.com/design/human-interface-guidelines/
  - Typography / Color / Layout / Materials / Components 章を参照
- **W3C JLREQ - 日本語組版処理の要件** — https://w3c.github.io/jlreq/?lang=ja
  - 本文行間 / 行頭禁則 / 約物処理 / 縦中横
- **Design Tokens Community Group Format Module 2025.10** — https://www.designtokens.org/tr/drafts/format/
  - DTCG JSON 入力スキーマ

## 実装参考

- **tak-dcxi/kiso.css** — https://github.com/tak-dcxi/kiso.css
  - 和文ベースライン CSS（text-autospace / text-spacing-trim / line-break / text-wrap）の期待値
- **PetriLahdelma/stylelint-plugin-rhythmguard** — https://github.com/PetriLahdelma/stylelint-plugin-rhythmguard
  - スケール一貫性 + Tailwind 連携の検証パターン
- **jeddy3/stylelint-scales** — https://github.com/jeddy3/stylelint-scales
  - 11 スケールルール
- **darwintantuco/stylelint-8-point-grid** — https://github.com/darwintantuco/stylelint-8-point-grid
  - 8pt 検証

## dotfiles 内の参考スキル（構造の真似元）

- `claude/.claude/skills/html-md-equivalence/SKILL.md` — 多軸採点 + 出力形式厳守
- `claude/.claude/skills/vw-tokscale-audit/SKILL.md` — カテゴリ別異常検出 + research report 保存規約
- `claude/.claude/skills/html/SKILL.md` + `references/` — 複数 references の整理パターン

## MIT 表記（フォーク元）

```
MIT License

Copyright (c) 2025 Ashutos1997

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE OTHER DEALINGS IN THE
SOFTWARE.
```
