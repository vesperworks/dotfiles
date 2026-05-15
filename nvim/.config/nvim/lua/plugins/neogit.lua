return {
  "NeogitOrg/neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim",
    -- telescope は依存に含めない: 既存 telescope.lua の lazy load が
    -- Neogit ロード時に強制発火してしまい、`gd` 起動が重くなる。
    -- Neogit は vim.ui.select に fallback するので機能上問題なし。
  },
  cmd = { "Neogit", "NeogitOneshot" },
  keys = {
    { "<leader>G", "<cmd>Neogit<cr>", desc = "Neogit: Git ステータスを開く" },
  },
  opts = {
    kind = "tab",
    graph_style = "unicode",
    integrations = {
      diffview = true,
    },
    sections = {
      recent = { folded = false, hidden = false },
    },
  },
  config = function(_, opts)
    require("neogit").setup(opts)

    -- ワンショット起動の q→qa を Neogit 初期化後に登録する。
    -- vim.schedule + nowait=true で Neogit 自前の q マップに優先勝ちさせる
    -- （BufWipeout/BufUnload 方式は <CR> でファイルを開いた瞬間に誤発火する）。
    local function setup_oneshot_quit(args)
      vim.schedule(function()
        vim.keymap.set("n", "q", function() vim.cmd("qa") end, {
          buffer = args.buf,
          nowait = true,
          desc = "Neogit oneshot: quit nvim",
        })
      end)
    end

    vim.api.nvim_create_user_command("NeogitOneshot", function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NeogitStatus",
        once = true,
        callback = setup_oneshot_quit,
      })
      require("neogit").open()
    end, { desc = "Neogit oneshot mode (q = quit nvim)" })
  end,
}
