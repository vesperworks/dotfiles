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
    require("vw.blink-obsidian-headings")
    require("vw.blink-obsidian-refs")
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
        markdown = { "obsidian_headings", "obsidian_refs_cached", "obsidian_tags_cached", "buffer", "path" },
      },
      providers = {
        obsidian_headings = {
          name = "obsidian_headings",
          module = "vw.blink-obsidian-headings",
          score_offset = 1000,
          async = false,
          enabled = function()
            return vim.bo.filetype == "markdown"
          end,
        },
        obsidian_refs_cached = {
          name = "obsidian_refs_cached",
          module = "vw.blink-obsidian-refs",
          async = false,
          enabled = function()
            return vim.bo.filetype == "markdown"
          end,
        },
        obsidian_tags_cached = {
          name = "obsidian_tags_cached",
          module = "vw.blink-obsidian-tags",
          async = false,
          enabled = function()
            return vim.bo.filetype == "markdown"
          end,
        },
        -- obsidian.nvim が自動注入するソースを無効化（自前 source で代替済み）。
        -- per_filetype から名前を消しても inject_sources が再挿入するため、
        -- provider 定義ごと enabled=false で殺す必要がある
        obsidian = {
          name = "obsidian",
          module = "obsidian.completion.sources.blink.refs",
          enabled = false,
        },
        obsidian_tags = {
          name = "obsidian_tags",
          module = "obsidian.completion.sources.blink.tags",
          enabled = false,
        },
      },
    },
  },
}
