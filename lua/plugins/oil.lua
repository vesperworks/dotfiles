return {
  "stevearc/oil.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "refractalize/oil-git-status.nvim",
  },
  lazy = false,  -- nvim . で開くために起動時に読み込む
  keys = {
    { "<leader>e", "<cmd>Oil<cr>", desc = "Explorer (oil.nvim)" },
  },
  config = function()
    require("oil").setup({
      default_file_explorer = true,
      columns = {
        "icon",
      },
      sort = {
        { "mtime", "desc" },  -- 更新日時の降順（上ほど最新）
      },
      view_options = {
        show_hidden = true,
      },
      keymaps = {
        ["<CR>"] = "actions.select",
        ["<C-v>"] = "actions.select_vsplit",
        ["<C-s>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["q"] = "actions.close",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
      },
      win_options = {
        signcolumn = "yes:2",
      },
    })

    -- oil-git-status.nvim
    require("oil-git-status").setup({
      show_ignored = true,
    })
  end,
}
