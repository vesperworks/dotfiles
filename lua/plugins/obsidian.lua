return {
  "epwalsh/obsidian.nvim",
  enabled = true,  -- 再度有効化してobsidian.nvim側で問題解決
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim", -- 必須依存
  },
  opts = {
    workspaces = {
      {
        name = "main",
        path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault",
      },
    },

    disable_frontmatter = true,
    
    -- UI要素を無効化してrender-markdown.nvimとの競合を回避
    ui = {
      enable = false,  -- Obsidian UI要素を無効化
      checkboxes = {},  -- チェックボックスUIを無効化
    },
    completion = {
      nvim_cmp = true,
      min_chars = 1,  -- @一文字で補完開始
    },

    mappings = {
      -- [[リンク]]ジャンプをgfで使えるように
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = true, expr = true, buffer = true },
      },
    },

    use_advanced_uri = false, -- Obsidian URI連携（不要ならfalseでOK）
  },
}
