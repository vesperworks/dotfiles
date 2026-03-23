return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
  keys = {
    { "<leader>do", "<cmd>DiffviewOpen<cr>", desc = "Diffview: 変更一覧を開く" },
    { "<leader>dc", "<cmd>DiffviewClose<cr>", desc = "Diffview: 閉じる" },
    { "<leader>dh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview: ファイル履歴" },
  },
  opts = {
    enhanced_diff_hl = true,
    view = {
      default = {
        layout = "diff2_horizontal",
      },
    },
    file_panel = {
      listing_style = "tree",
      win_config = {
        position = "left",
        width = 35,
      },
    },
  },
}
