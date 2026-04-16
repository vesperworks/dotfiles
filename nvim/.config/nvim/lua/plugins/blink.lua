-- lua/plugins/blink.lua
return {
  "saghen/blink.cmp",
  version = "1.*",
  lazy = false,
  dependencies = {
    "obsidian-nvim/obsidian.nvim",
  },

  config = function(_, opts)
    -- キャッシュモジュールを早期ロード（autocmd + ユーザーコマンド登録）
    require("vw.blink-obsidian-tags")
    require("blink.cmp").setup(opts)
  end,

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = "none",
      ["<C-;>"] = { "show", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<C-c>"] = { "cancel", "fallback" },
      ["<CR>"] = { "accept", "fallback" },
    },
    completion = {
      documentation = { auto_show = false },
      list = {
        selection = { preselect = false, auto_insert = false },
      },
      menu = {},
    },
    sources = {
      default = { "buffer", "path" },
      per_filetype = {
        markdown = { "obsidian", "obsidian_tags_cached", "buffer", "path" },
      },
      providers = {
        obsidian_tags_cached = {
          name = "obsidian_tags_cached",
          module = "vw.blink-obsidian-tags",
          async = false,
          enabled = function()
            return vim.bo.filetype == "markdown"
          end,
        },
        -- obsidian.nvim が自動注入する rg ベースのタグソースを無効化
        -- （obsidian_tags_cached で代替済み）
        obsidian_tags = {
          name = "obsidian_tags",
          module = "obsidian.completion.sources.blink.tags",
          enabled = false,
        },
      },
    },
  },
}
