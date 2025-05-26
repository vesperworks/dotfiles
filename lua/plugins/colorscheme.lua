return {
  "folke/tokyonight.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    transparent = true,
    on_highlights = function(hl)
      for name, def in pairs(hl) do
        if name:match("^RenderMarkdown") and type(def) == "table" then
          def.bg      = "NONE"
          def.ctermbg = "NONE"
        end
      end
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight")
  end,
}
