-- plugins/render-markdown.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("render-markdown").setup {
        -- オプション設定（必要に応じて）
	render_modes = { 'n', 'c', 't' },
      }
    end,
  },
}
