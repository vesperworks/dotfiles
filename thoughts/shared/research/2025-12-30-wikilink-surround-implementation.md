---
date: 2025-12-30T10:30:00+09:00
researcher: Claude Code
topic: "Visual modeで選択範囲を[[wikilink]]形式にする方法 - surroundプラグインvs自作キーマップの検討"
tags: [research, neovim, surround, wikilink, obsidian, visual-mode]
status: complete
iteration: 1
---

# Research: Wikilink Surround Implementation

**調査日時**: 2025-12-30 10:30
**依頼内容**: leader [でvの時に、選択範囲を[[wikilink]] 形式にしたい。surroundみたいなプラグインもあったと思うんだけれど、どっちがいいか検討したい

## サマリー

現在の環境では**surroundプラグインは未導入**（VSCode環境でのみmini.surround有効）。`[[wikilink]]`専用であれば**シンプルなキーマップ実装（10行程度）が最適**。将来的に括弧操作を増やすなら`mini.surround`のカスタム設定が既存エコシステム（mini.move）と統一されて好ましい。

## 詳細な調査結果

### 1. コードベースの調査

#### 現在のSurround機能状況
- **通常Neovim環境**: surroundプラグイン **未導入**
- **VSCode環境のみ**: `lua/vscode-config.lua:90-95` で `mini.surround` が有効
- `lua/plugins/mini.lua` は `mini.move` のみ設定（6行目）

#### 関連ファイル
- `lua/user-plugins/markdown-helper.lua` - Visual mode処理の参考実装多数（887行）
- `lua/user-plugins/obsidian-hover-preview.lua` - wikilink検出パターン
- `lua/plugins/obsidian.lua:32-39` - `gf`によるwikilink ジャンプ機能
- `init.lua:129-168` - Visual mode選択範囲移動の参考実装（`<leader>m`）

#### 既存のVisual Mode処理パターン（再利用可能）

```lua
-- markdown-helper.lua:53-83 の標準パターン
local mode = vim.fn.mode()
if mode == 'v' or mode == 'V' or mode == '\022' then
  local visual_start = vim.fn.getpos("v")
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  start_row = visual_start[2]
  end_row = cursor_pos[1]
  -- ... 範囲正規化 ...
  vim.cmd('normal! \\<Esc>')
end
```

### 2. 技術調査結果（Web検索）

#### Surround プラグイン比較

| 項目 | nvim-surround | mini.surround | visual-surround.nvim | シンプルキーマップ |
|------|---------------|---------------|----------------------|-------------------|
| **デフォルトキー** | `ys/ds/cs` | `sa/sd/sr` | 1文字キー | 自由設定 |
| **[[]]カスタム** | ✅ 要設定 | ✅ 要設定 | ✅ 関数呼出 | ✅ 即実装 |
| **Delete/Change** | ✅ | ✅ | ❌ | ❌ |
| **Dot-repeat** | ✅ | ✅ | ❌ | ❌ |
| **Tree-sitter統合** | ✅ | ✅ | ❌ | ❌ |
| **導入コスト** | 中 | 低（mini.nvim系列） | 低 | 最低 |

#### nvim-surround での `[[]]` 設定例

```lua
require("nvim-surround").setup({
  surrounds = {
    ["l"] = {  -- 'l' for link
      add = { "[[", "]]" },
      find = "%[%[.-%]%]",
      delete = "^(%[%[)().-(%]%])()$",
    },
  },
})
-- 使用: Visual選択 → Sl
```

#### mini.surround での `[[]]` 設定例

```lua
require('mini.surround').setup({
  custom_surroundings = {
    l = {
      input = { '%[%[().-()%]%]' },
      output = { left = '[[', right = ']]' },
    },
  },
})
-- 使用: Visual選択 → sal
```

#### シンプルキーマップ実装（プラグイン不要）

```lua
-- Visual modeで選択範囲を[[]]で囲む
vim.keymap.set("x", "<leader>[", function()
  -- 現在の選択範囲の終端に ]] を挿入
  vim.cmd('normal! `>')
  vim.cmd('normal! a]]')
  -- 始端に [[ を挿入
  vim.cmd('normal! `<')
  vim.cmd('normal! i[[')
  -- Visual modeを終了
  vim.cmd('normal! \\<Esc>')
end, { desc = "Wrap selection in [[wikilink]]" })
```

### 3. obsidian.nvim の機能確認

- **自動補完**: `[[` 入力で候補表示（nvim-cmp連携）
- **制限**: **Surround機能は未搭載** - 別途実装が必要
- **関連設定**: `lua/plugins/obsidian.lua` で vault path、gfジャンプ設定済み

## 結論

### 推奨アプローチ（確率付き）

| アプローチ | 推奨度 | 理由 |
|-----------|--------|------|
| **シンプルキーマップ** | **70%** | YAGNI原則。wikilink専用なら10行で完結。既存パターンに沿う |
| **mini.surround カスタム** | **25%** | mini.nvim系列で統一。将来的に括弧操作を増やすなら最適 |
| **nvim-surround** | 5% | vim-surround経験者向け。新規導入としてはオーバースペック |

### YAGNI判断基準

**シンプルキーマップで十分な条件（すべて該当）**:
- ✅ `[[wikilink]]` のみ必要
- ✅ Visual modeでの囲み込みのみ使用
- ✅ Delete/Change surround不要（テキスト全体を書き換えればよい）
- ✅ Dot-repeat不要

**プラグイン推奨条件（いずれか該当）**:
- ❌ `()`, `[]`, `""`, `**` など複数の括弧を頻繁に使う
- ❌ `ds[` (delete)、`cs[]()` (change) が必要
- ❌ Dot-repeatで効率化したい

## 次のステップの提案

### 推奨: シンプルキーマップ実装

1. `init.lua` または `lua/user-plugins/markdown-helper.lua` に追加
2. キーバインド: `<leader>[`（Visual mode）
3. 実装コード:

```lua
-- Wikilink surround: Visual modeで選択範囲を[[]]で囲む
vim.keymap.set("x", "<leader>[", function()
  vim.cmd('normal! `>')
  vim.cmd('normal! a]]')
  vim.cmd('normal! `<')
  vim.cmd('normal! i[[')
end, { desc = "Wrap selection in [[wikilink]]" })
```

### 代替案: mini.surround 導入

1. `lua/plugins/mini.lua` を修正
2. `mini.surround` をセットアップに追加
3. wikilink用カスタム設定を追加

## 追加の検討事項

- `<leader>[` は現在未使用（`<leader>1-6` はHeading用）
- 逆操作（wikilink解除）は必要に応じて後から追加可能
- obsidian.nvimの補完と競合なし（補完は`[[`入力時、surroundは選択後）
