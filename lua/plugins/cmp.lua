-- lua/plugins/cmp.lua
return {
  "hrsh7th/nvim-cmp",
  lazy = false,
  priority = 1000,
  dependencies = {
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "epwalsh/obsidian.nvim",
  },
  config = function()
    local cmp = require("cmp")

    cmp.setup({
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-c>"] = cmp.mapping.abort(),
      }),
      sources = cmp.config.sources({
        { name = "obsidian" },
        { name = "buffer"   },
        { name = "path"     },
      }),
    })

    -- Markdown 用：<CR> だけ上書き
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
    })
  end,
}
