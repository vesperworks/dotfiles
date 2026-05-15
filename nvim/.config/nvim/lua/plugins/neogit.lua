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
    auto_refresh = true,
    filewatcher = { enabled = true },
    integrations = {
      diffview = true,
    },
    sections = {
      recent = { folded = false, hidden = false },
    },
  },
  config = function(_, opts)
    require("neogit").setup(opts)

    -- ワンショット起動: Neogit の q を qa に直接マップ
    -- 当初は BufWipeout/BufUnload autocmd で qa する設計だったが、ファイルを
    -- <CR> で開いた瞬間に NeogitStatus buffer が unload されて誤発火し、
    -- nvim が即終了する問題が起きた（ファイル選択 = 終了になってしまう）。
    -- buffer-local の `q` キーマップなら q 押下時のみ qa が走り、
    -- <CR>/<Tab>/d によるファイル選択・diff 展開・diffview 連携には影響しない。
    vim.api.nvim_create_user_command("NeogitOneshot", function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NeogitStatus",
        once = true,
        callback = function(args)
          -- Neogit が自前の q マップを後から上書きしてくるので vim.schedule で
          -- 初期化完了後に再上書き、nowait=true で確実に優先させる
          vim.schedule(function()
            vim.keymap.set("n", "q", function() vim.cmd("qa") end, {
              buffer = args.buf,
              nowait = true,
              desc = "Neogit oneshot: quit nvim",
            })
          end)
        end,
      })
      require("neogit").open()
    end, { desc = "Neogit oneshot mode (q = quit nvim)" })
  end,
}
