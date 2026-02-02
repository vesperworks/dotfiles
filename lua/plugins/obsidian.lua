return {
  "obsidian-nvim/obsidian.nvim", -- community fork（キャッシュ機能あり）
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    legacy_commands = false, -- 新コマンド形式を使用（Obsidian backlinks等）

    workspaces = {
      {
        name = "main",
        path = vim.env.OBSIDIAN_VAULT_PATH or "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault",
      },
    },

    -- キャッシュ有効化（補完高速化）
    cache = {
      enable = true,
    },

    -- frontmatter自動追加を無効化
    frontmatter = {
      enabled = false,
    },

    -- footer無効化
    footer = { enabled = false },

    -- 新規ノートの保存先
    new_notes_location = "notes_subdir",
    notes_subdir = "Inbox",

    -- UI無効化（render-markdown.nvimと独自設定を使用）
    ui = {
      enable = false,
    },

    -- チェックボックス無効化（独自タスクステータスを使用）
    checkbox = {
      enabled = false,
    },

    -- 補完設定
    completion = {
      nvim_cmp = true,
      min_chars = 0, -- [[だけで補完開始
      create_new = false, -- 補完から新規ノート作成を無効化
    },

    -- キーマップ（enter_noteコールバックで設定）
    callbacks = {
      enter_note = function(note)
        -- gfでリンクジャンプ
        vim.keymap.set("n", "gf", require("obsidian.api").smart_action, {
          buffer = true,
          desc = "Follow link",
        })
        -- <CR>を独自タスクステータスに再設定（obsidianのマッピングを上書き）
        vim.keymap.set("n", "<CR>", function()
          require("user-plugins.markdown-helper").toggle_checkbox_state()
        end, { buffer = true, desc = "Toggle task checkbox" })
        vim.keymap.set("v", "<CR>", function()
          require("user-plugins.markdown-helper").toggle_checkbox_state()
        end, { buffer = true, desc = "Toggle task checkbox" })
      end,
    },
  },
}
