return {
  -- true-zen.nvim - Narrow(ズーム)機能のみ使用
  {
    "pocco81/true-zen.nvim",
    keys = {
      { "<leader>zn", "<cmd>TZNarrow<cr>", desc = "ズーム (Narrow)", mode = "n" },
      { "<leader>zn", ":'<,'>TZNarrow<cr>", desc = "選択範囲ズーム", mode = "v" },
    },
    opts = {
      modes = {
        narrow = {
          folds_style = "informative",
          run_ataraxis = false, -- ataraxisを無効化してエラー回避
          callbacks = {
            open_pre = nil,
            open_pos = nil,
            close_pre = nil,
            close_pos = nil,
          },
        },
      },
    },
  },

  -- twilight.nvim ─ 周辺減光
  { "folke/twilight.nvim", opts = { context = 2 } },

  -- typewriter.nvim ─ カーソル常時センター
  {
    "joshuadanpeterson/typewriter.nvim",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
    },
    keys = {
      { "<leader>zt", "<cmd>TWToggle<cr>", desc = "Typewriter トグル" },
    },
    opts = {
      keep_cursor_position = true,
      enable_notifications = false,
    },
  },
}
