# PRP: gitsigns + diffview 導入

## 概要

Claude Codeでの変更を効率的にレビューするため、gitsigns.nvim と diffview.nvim を導入する。

## ゴール

- **コミット前**: 変更ファイル一覧をツリーで見ながら、選択したファイルのdiffを横ペインで確認
- **編集中**: 変更行（hunk）がリアルタイムで可視化される

## 導入プラグイン

| プラグイン | 役割 | Stars |
|-----------|------|-------|
| gitsigns.nvim | 編集中のリアルタイム変更表示、hunk操作 | 5,555+ |
| diffview.nvim | 変更全体の俯瞰・レビュー | 4,866+ |

---

## キーバインド設計

### プレフィックス: `<leader>d*` (diff)

| キー | 機能 | プラグイン |
|------|------|-----------|
| `<leader>do` | DiffviewOpen（変更一覧を開く） | diffview |
| `<leader>dc` | DiffviewClose（閉じる） | diffview |
| `<leader>dh` | DiffviewFileHistory（ファイル履歴） | diffview |
| `<leader>dp` | Preview hunk（変更プレビュー） | gitsigns |
| `<leader>ds` | Stage hunk（変更をステージ） | gitsigns |
| `<leader>dr` | Reset hunk（変更を取り消し） | gitsigns |
| `<leader>db` | Blame line（この行の変更者を表示） | gitsigns |
| `<leader>dB` | Blame buffer（バッファ全体のblame） | gitsigns |

### Hunk移動（プレフィックスなし）

| キー | 機能 |
|------|------|
| `]d` | 次のhunk（変更箇所）へジャンプ |
| `[d` | 前のhunkへジャンプ |

---

## 実装ファイル

### 1. `lua/plugins/gitsigns.lua`

```lua
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "+" },
      change       = { text = "~" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
    },
    current_line_blame = false,  -- 必要ならtrueに
    current_line_blame_opts = {
      virt_text = true,
      delay = 500,
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Hunk移動
      map("n", "]d", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(function() gs.next_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "次のhunk" })

      map("n", "[d", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(function() gs.prev_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "前のhunk" })

      -- Hunk操作（<leader>d*）
      map("n", "<leader>dp", gs.preview_hunk, { desc = "Hunkプレビュー" })
      map("n", "<leader>ds", gs.stage_hunk, { desc = "Hunkをステージ" })
      map("n", "<leader>dr", gs.reset_hunk, { desc = "Hunkをリセット" })
      map("v", "<leader>ds", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "選択範囲をステージ" })
      map("v", "<leader>dr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "選択範囲をリセット" })

      -- Blame
      map("n", "<leader>db", gs.blame_line, { desc = "Blame（この行）" })
      map("n", "<leader>dB", function() gs.blame_line({ full = true }) end, { desc = "Blame（詳細）" })
    end,
  },
}
```

### 2. `lua/plugins/diffview.lua`

```lua
return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
  keys = {
    { "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview: 変更一覧を開く" },
    { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview: 閉じる" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: ファイル履歴" },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      default = {
        layout = "diff2_horizontal",  -- 横並びdiff
      },
    },
    file_panel = {
      listing_style = "tree",  -- ツリー表示
      win_config = {
        position = "left",
        width = 35,
      },
    },
  },
}
```

---

## 使い方

### コミット前のレビューフロー

1. `<leader>do` で DiffviewOpen
2. 左ペインのファイルツリーで変更ファイルを確認
3. `<Tab>` / `<S-Tab>` でファイル間を移動
4. 右ペインでdiffを確認
5. `<leader>dc` で閉じる

### 編集中のhunk操作

1. 変更行に `+` `~` `-` のサインが表示される
2. `]d` / `[d` でhunk間を移動
3. `<leader>dp` でプレビュー
4. `<leader>ds` でステージ、`<leader>dr` でリセット

---

## 確認事項

- [ ] plenary.nvimは既にインストール済み（telescope依存）
- [ ] nvim-web-deviconsは既にインストール済み（lualine依存）

## 注意事項

- `<leader>g` は live_grep で使用中のため、gitプレフィックスは `<leader>d` を採用
- diffviewは遅延読み込み（`:DiffviewOpen` 実行時に初めてロード）
