---
date: 2025-12-27T00:00:00+09:00
researcher: Claude Code
topic: "Typewriterモードでファイル先頭でもカーソル中央を実現する方法"
tags: [research, neovim, typewriter, zen-mode, extmark]
status: complete
iteration: 1
---

# Research: Typewriterモードでファイル先頭でもカーソル中央を実現する方法

**調査日時**: 2025-12-27
**依頼内容**: typewriter.nvimでファイル先頭にカーソルがある時も中央に保つ方法

## サマリー

typewriter.nvimは`scrolloff`を利用してカーソルを中央に保つが、ファイル先頭ではスクロール余白がないため物理的に中央化できない。解決策として、**go-up.nvim**（仮想行を先頭に追加）または**カスタムextmark実装**が有効。

## 詳細な調査結果

### 1. 問題の本質

typewriter.nvimの仕組み:
- `scrolloff`を画面高の半分に設定してカーソルを中央に維持
- ファイル先頭（行1付近）ではスクロール余白がないため、物理的に中央化不可能
- これはNeovimの仕様による制約

### 2. 解決策の選択肢

#### Option A: go-up.nvim（推奨度: 85%）

**リポジトリ**: [nullromo/go-up.nvim](https://github.com/nullromo/go-up.nvim)

**技術実装**:
- `nvim_buf_set_extmark()` APIで行1の**上**に仮想行を作成
- ファイル内容を変更せず、表示のみで余白を追加
- typewriter.nvimと併用可能

**設定例**:
```lua
{
  'nullromo/go-up.nvim',
  config = function()
    require('go-up').setup({
      mapZZ = false,           -- typewriter.nvimに任せる
      goUpLimit = 'center',    -- 'center' | number | nil
      ignoredFiletypes = {},
    })
  end,
}
```

**メリット**:
- 既存のtypewriter.nvimと完全互換
- 設定が簡単
- メンテナンスされているプラグイン

**デメリット**:
- 仮想行を使う他のプラグインと競合の可能性
- 依存関係が増える

#### Option B: カスタムLua実装（推奨度: 10%）

**技術実装**: extmark APIを直接使用

```lua
-- lua/user-plugins/typewriter-padding.lua
local M = {}
local ns = vim.api.nvim_create_namespace('typewriter_padding')

function M.add_top_padding()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local win_height = vim.api.nvim_win_get_height(0)
  local padding_lines = math.floor(win_height / 2)

  local virt_lines = {}
  for _ = 1, padding_lines do
    table.insert(virt_lines, { { '', '' } })
  end

  vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
    virt_lines_above = true,
    virt_lines = virt_lines,
  })
end

function M.setup()
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'VimResized' }, {
    pattern = '*.md',  -- Markdownファイルのみ
    callback = M.add_top_padding,
  })
end

return M
```

**メリット**:
- 依存関係なし
- 完全なコントロール
- 既存のextmarkパターン（task-timer-display.lua等）と一貫性

**デメリット**:
- 自分でメンテナンス必要
- エッジケースの対応が必要

#### Option C: scrollEOF.nvim（推奨度: 5%）

- ファイル**末尾**の問題を解決（go-up.nvimの逆方向版）
- 先頭への適用は別途実装が必要

### 3. コードベース内の関連パターン

#### 既存のextmark使用例

`lua/user-plugins/task-timer-display.lua:114-123`:
```lua
vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_num - 1, -1, {
  virt_text = {{ elapsed_text, 'DiagnosticWarn' }},
  virt_text_pos = 'eol',
})
```

`lua/user-plugins/pending-tasks.lua:286-292`:
```lua
vim.api.nvim_buf_set_extmark(M.state.source_buf, M.ns_id, task.lnum - 1, 0, {
  virt_lines_above = true,  -- これが仮想行追加のキー
  hl_eol = true,
  line_hl_group = "PendingTaskPreview",
})
```

### 4. 他エディタの実装

| エディタ | 実装方法 |
|----------|----------|
| VSCode | `scroll_past_end`設定 + extension |
| Sublime | `scroll_past_end: true` + Typewriter plugin |

## 結論

**go-up.nvim**の導入が最も簡単で効果的。既存のtypewriter.nvimと併用でき、設定も最小限。

カスタム実装も可能だが、既存プラグインで解決できる問題に時間をかける必要はない（YAGNI原則）。

## 推奨アクション

### 最小限の変更（推奨）

`lua/plugins/zen-modes.lua`に追加:

```lua
-- go-up.nvim - ファイル先頭でもカーソル中央化
{
  'nullromo/go-up.nvim',
  event = 'BufReadPost',
  config = function()
    require('go-up').setup({
      mapZZ = false,
      goUpLimit = 'center',
    })
  end,
},
```

### 動作確認項目

- [ ] `<leader>z`でZen Mode開始時、ファイル先頭でもカーソルが中央に来る
- [ ] 通常編集時に仮想行が邪魔にならない
- [ ] gitsigns等の他プラグインと競合しない

## 追加の検討事項

- Markdownファイルのみに適用したい場合は`ignoredFiletypes`で制御
- 仮想行の数を調整したい場合は`goUpLimit`を数値で指定

## Sources

- [go-up.nvim - GitHub](https://github.com/nullromo/go-up.nvim)
- [typewriter.nvim - GitHub](https://github.com/joshuadanpeterson/typewriter.nvim)
- [stay-centered.nvim - GitHub](https://github.com/arnamak/stay-centered.nvim)
- [Neovim API - Extmarks](https://neovim.io/doc/user/api.html)
