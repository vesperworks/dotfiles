-- dashboard-nvim: 起動時のスタートスクリーン
return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    theme = "hyper",
    config = {
      header = { "", "" },
      shortcut = {
        { desc = " Files", group = "Label", action = "Telescope find_files", key = "f" },
        { desc = " Recent", group = "Number", action = "Telescope oldfiles", key = "r" },
        { desc = " Browser", group = "String", action = "Oil", key = "e" },
        { desc = "󰒲 Lazy", group = "Constant", action = "Lazy", key = "l" },
        { desc = " Quit", group = "Error", action = "qa", key = "q" },
      },
      project = { enable = false },
      mru = { limit = 8 },
      footer = {},
    },
  },
}
