return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.5", -- 安定版を指定（または最新版）
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-fzf-native.nvim", -- 高速化（後述）
  },
  build = "make", -- fzf-native用
  config = function()
    require("telescope").setup {
      defaults = {
        layout_config = {
          vertical = { width = 0.5 },
        },
        sorting_strategy = "ascending",
      },
    }
    require("telescope").load_extension("fzf")
    
    -- キーマッピング設定
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<D-p>', builtin.commands, { desc = "コマンド検索" })
    vim.keymap.set('n', '<D-S-p>', builtin.find_files, { desc = "ファイル検索" })
  end,
}
