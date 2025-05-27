return {
  -- zen-mode.nvim - 安定したZenモード
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>zm", "<cmd>ZenMode<cr>", desc = "Zen Mode トグル" },
    },
    opts = {
      window = {
        backdrop = 0.95, -- シェード背景
        width = 120, -- 幅
        height = 1, -- 高さ (1 = 100%)
        options = {
          signcolumn = "no", -- サインカラム無効
          number = false, -- 行番号無効
          relativenumber = false, -- 相対行番号無効
          cursorline = false, -- カーソル行ハイライト無効
          cursorcolumn = false, -- カーソル列ハイライト無効
          foldcolumn = "0", -- fold列無効
          list = false, -- 空白文字無効
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false, -- ルーラー無効
          showcmd = false, -- コマンド表示無効
        },
        twilight = { enabled = true }, -- twilight連携
        gitsigns = { enabled = false }, -- gitsigns無効
        tmux = { enabled = false }, -- tmux連携無効
        kitty = {
          enabled = false,
          font = "+4", -- フォントサイズ増加
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
