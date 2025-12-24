return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "+" },
      change       = { text = "~" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
    },
    current_line_blame = true,  -- 現在行のblameを常に表示
    current_line_blame_opts = {
      virt_text = true,
      delay = 500,
    },
    word_diff = true,  -- word単位のインラインdiff表示
    show_deleted = true,  -- 削除行をバーチャルテキストで表示
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Hunk移動
      map("n", "]d", function()
        if vim.wo.diff then return "]c" end
        vim.schedule(function() gs.next_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "次のhunk" })

      map("n", "[d", function()
        if vim.wo.diff then return "[c" end
        vim.schedule(function() gs.prev_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "前のhunk" })

      -- Hunk操作（<leader>d*）
      map("n", "<leader>dp", gs.preview_hunk, { desc = "Hunkプレビュー" })
      map("n", "<leader>ds", gs.stage_hunk, { desc = "Hunkをステージ" })
      map("n", "<leader>dr", gs.reset_hunk, { desc = "Hunkをリセット" })
      map("v", "<leader>ds", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "選択範囲をステージ" })
      map("v", "<leader>dr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "選択範囲をリセット" })

      -- Blame
      map("n", "<leader>db", gs.blame_line, { desc = "Blame（この行）" })
      map("n", "<leader>dB", function() gs.blame_line({ full = true }) end, { desc = "Blame（詳細）" })
    end,
  },
}
