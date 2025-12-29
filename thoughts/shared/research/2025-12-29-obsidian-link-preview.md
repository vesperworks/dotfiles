---
date: 2025-12-29T13:45:00+09:00
researcher: Claude Code
topic: "Obsidianリンク（[[wikilink]]）のgxジャンプ＆ホバープレビュー実現可能性調査"
tags: [research, neovim, obsidian, wikilink, floating-window, hover-preview]
status: complete
iteration: 1
---

# Research: Obsidianリンクのgxジャンプ＆ホバープレビュー

**調査日時**: 2025-12-29 13:45
**依頼内容**: VimでカーソルがObsidianリンク（`[[wikilink]]`）上にある時、gxでジャンプ＆500msホバーでプレビューを実現したい

## サマリー

**gxジャンプ**: obsidian.nvimの既存機能（`gf`マッピング）で実現可能。`gx`にバインド変更も可能。
**ホバープレビュー**: 既存プラグインでは直接対応なし。カスタム実装が必要だが、既存の`pending-tasks.lua`のフローティングウィンドウ実装を参考にすれば十分実現可能。

## 詳細な調査結果

### 1. 現在のnvim設定状況

#### obsidian.nvim設定
- `lua/plugins/obsidian.lua:31-39` - `gf`でリンクジャンプ設定済み

```lua
mappings = {
  ["gf"] = {
    action = function()
      return require("obsidian").util.gf_passthrough()
    end,
    opts = { noremap = true, expr = true, buffer = true },
  },
},
```

#### フローティングウィンドウ実装例
- `lua/user-plugins/pending-tasks.lua:122-224` - `nvim_open_win`を使った完全なフローティングウィンドウ実装
  - バッファ作成: `nvim_create_buf(false, true)`
  - ウィンドウ作成: `nvim_open_win(buf, true, opts)`
  - キーマップ設定: q/Escで閉じる
  - ハイライト適用

### 2. 既存プラグイン調査

#### obsidian.nvim（現在使用中）
- **gfジャンプ**: ✅ 対応済み
- **gxジャンプ**: ⚠️ 標準はgf。gxにリマップ可能
- **ホバープレビュー**: ❌ 非対応

#### コミュニティフォーク obsidian-nvim/obsidian.nvim
- **追加機能**: `[o`/`]o`でリンク間移動、`:Obsidian follow_link [STRATEGY]`で分割オープン
- **ホバープレビュー**: ❌ 非対応

#### hover.nvim
- **用途**: LSPホバー情報のフレームワーク
- **ファイルプレビュー**: ❌ 非対応（LSP向け）

#### goto-preview
- **用途**: LSP定義のフローティングプレビュー
- **wikiリンク**: ❌ 非対応（LSP専用）

#### mkdnflow.nvim
- **wikiリンク**: ✅ `[[link]]`ナビゲーション対応
- **ホバープレビュー**: ❌ 非対応

#### render-markdown.nvim（現在使用中）
- **wikiリンク表示**: ✅ アイコン＆ハイライト
- **ホバープレビュー**: ❌ 非対応

### 3. 実装アプローチ

#### 方法A: obsidian.nvimのgfをgxにリマップ（推奨度: 90%）

```lua
-- lua/plugins/obsidian.lua
mappings = {
  ["gx"] = {  -- gf → gx に変更
    action = function()
      return require("obsidian").util.gf_passthrough()
    end,
    opts = { noremap = true, expr = true, buffer = true },
  },
},
```

#### 方法B: カスタムホバープレビュー実装（推奨度: 80%）

`CursorHold`イベントとフローティングウィンドウを組み合わせる:

```lua
-- lua/user-plugins/obsidian-hover-preview.lua (構想)
local M = {}
local ns_id = vim.api.nvim_create_namespace("obsidian_hover_preview")

-- [[wikilink]]を検出
local function get_wikilink_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  -- パターン: [[任意のテキスト]]
  local pattern = "%[%[([^%]]+)%]%]"
  -- カーソル位置がリンク内かチェック
  for start_pos, link_text, end_pos in line:gmatch("()%[%[([^%]]+)%]%]()") do
    if col >= start_pos - 1 and col < end_pos - 1 then
      return link_text
    end
  end
  return nil
end

-- ファイル内容をフローティングウィンドウで表示
local function show_preview(file_path)
  -- pending-tasks.luaの実装パターンを参考に
  -- vim.api.nvim_open_win()でプレビュー表示
end

-- CursorHoldで発火（updatetime=500で500ms）
vim.api.nvim_create_autocmd("CursorHold", {
  pattern = "*.md",
  callback = function()
    local link = get_wikilink_under_cursor()
    if link then
      show_preview(link)
    end
  end,
})

return M
```

**キーポイント**:
- `updatetime`設定で遅延制御（デフォルト4000ms→500ms推奨）
- `CursorMoved`でプレビュー自動クローズ
- obsidian.nvimのVault解決機能を活用

### 4. 技術的考慮事項

#### updatetime設定
```lua
vim.opt.updatetime = 500  -- CursorHold発火までの時間（ms）
```
⚠️ 注意: swap書き込みにも影響するため、低すぎると副作用の可能性

#### 代替: vim.defer_fn
```lua
local timer = nil
vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function()
    if timer then vim.fn.timer_stop(timer) end
    timer = vim.defer_fn(function()
      -- プレビュー表示
    end, 500)
  end,
})
```

## 結論

| 機能 | 実現可能性 | 方法 |
|------|-----------|------|
| gxでリンクジャンプ | ✅ 簡単 | obsidian.nvimのマッピング変更 |
| 500msホバープレビュー | ✅ 可能 | カスタム実装（50-100行程度） |

**既存プラグインでホバープレビューを完全にサポートするものはない**が、`pending-tasks.lua`の実装パターンを活用すれば比較的簡単に実現可能。

## 次のステップの提案

1. **Phase 1（簡単）**: obsidian.nvimの`gf`→`gx`リマップ
2. **Phase 2（中程度）**: `obsidian-hover-preview.lua`新規作成
   - `get_wikilink_under_cursor()` - リンク検出
   - `resolve_link_path()` - ファイルパス解決（obsidian.nvim連携）
   - `show_floating_preview()` - プレビュー表示
   - `CursorHold`/`CursorMoved` autocmd設定

## Sources

- [obsidian.nvim (GitHub)](https://github.com/epwalsh/obsidian.nvim)
- [obsidian-nvim/obsidian.nvim (Community Fork)](https://github.com/obsidian-nvim/obsidian.nvim)
- [hover.nvim](https://github.com/lewis6991/hover.nvim)
- [goto-preview](https://neovimcraft.com/plugin/rmagatti/goto-preview/)
- [mkdnflow.nvim](https://neovimcraft.com/plugin/jakewvincent/mkdnflow.nvim/)
- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)
