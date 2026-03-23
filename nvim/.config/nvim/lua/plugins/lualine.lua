-- ~/.config/nvim/lua/plugins/lualine.lua
return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- アイコン
  event = "VeryLazy",
  opts = {
    options = {
      theme = "tokyonight",       -- ← 別テーマでも OK
      icons_enabled = true,
      section_separators = { "", "" },  -- 両端三角
      component_separators = { "", "" }, -- 中央仕切り
      disabled_filetypes = { "NvimTree", "lazy" },
    },
    sections = {
      lualine_a = { { "mode", upper = true } },
      lualine_b = { { "branch", icon = "" } },      -- git ブランチ
      lualine_c = {
        { "filename", symbols = { modified = "●", readonly = "" } },
      },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = {
        { function() return os.date("%H:%M") end, icon = "" },
      },
    },
    inactive_sections = { -- 分割時の非アクティブ窓
      lualine_a = {},
      lualine_b = {},
      lualine_c = { "filename" },
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    },
  },
}
