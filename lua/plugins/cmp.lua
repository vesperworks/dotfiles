-- lua/plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  lazy = false,
  priority = 1000,
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "obsidian-nvim/obsidian.nvim",
  },
  config = function()
    local cmp = require("cmp")

    cmp.setup({
      completion = {
        keyword_length = 0, -- トリガー文字で即座に補完開始
        autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged },
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-;>"] = cmp.mapping.complete(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-c>"] = cmp.mapping.abort(),
      }),
      sources = cmp.config.sources({
        { name = "buffer" },
        { name = "path" },
      }),
    })

    -- Markdown 用：obsidianソースを追加 + <CR> 上書き
    cmp.setup.filetype("markdown", {
      mapping = {
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() and cmp.get_selected_entry() then
            cmp.confirm({ select = false })      -- 補完を確定
          else
            -- fallback()を使用してマッピングチェーンを継続
            fallback()
          end
        end, { "i", "s" }),
      },
      sources = cmp.config.sources({
        { name = "obsidian", keyword_length = 0 },      -- [[ で即座に補完
        { name = "obsidian_new" },                       -- 新規ノート作成用
        { name = "obsidian_tags" },                      -- # タグ補完用
        { name = "buffer" },
        { name = "path" },
      }),
    })
  end,
}
