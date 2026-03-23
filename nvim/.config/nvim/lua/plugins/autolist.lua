-- lua/plugins/autolist.lua
return {
  "gaoDean/autolist.nvim",
  ft = { "markdown", "text", "gitcommit", "tex", "plaintex", "norg" },
  dependencies = { "hrsh7th/nvim-cmp" },

  config = function()
    ------------------------------------------------------------------
    -- ① 内蔵マッピング＆整形を無効化してロード
    ------------------------------------------------------------------
    require("autolist").setup({
      mappings = false,  -- ← ここで i<CR>/Tab/S-Tab の自動マップを殺す
      format   = false,  -- ← 全角折り返しバグを避ける
    })

    ------------------------------------------------------------------
    -- ② Markdown バッファに対して手動でマッピング登録
    ------------------------------------------------------------------
    local function apply_mapping(bufnr)
      local map = function(mode, lhs, rhs)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true })
      end

      -- Insert-mode: <CR> で改行＆箇条再開
      map("i", "<CR>", "<CR><cmd>AutolistNewBullet<CR>")
      map("i", "<Tab>",   "<cmd>AutolistTab<CR>")
      map("i", "<S-Tab>", "<cmd>AutolistShiftTab<CR>")

      -- Normal-mode
      map("n", "o",  "o<cmd>AutolistNewBullet<CR>")
      map("n", "O",  "O<cmd>AutolistNewBulletBefore<CR>")
      -- Enterキーで3状態循環（独自機能）
      map("n", "<CR>", function() require('vw.checkbox').toggle_checkbox_state() end)
      -- Visual modeでも3状態循環対応
      map("v", "<CR>", function() require('vw.checkbox').toggle_checkbox_state() end)
      map("n", "<leader>r", "<cmd>AutolistRecalculate<CR>")
      -- 再計算系
      map("n", ">>", ">><cmd>AutolistRecalculate<CR>")
      map("n", "<<", "<<<cmd>AutolistRecalculate<CR>")
      map("n", "dd", "dd<cmd>AutolistRecalculate<CR>")
      map("v", "d",  "d<cmd>AutolistRecalculate<CR>")
    end

    -- 今開いているバッファにもすぐ適用
    if vim.bo.filetype == "markdown" then
      apply_mapping(0)
    end

    -- 今後開く Markdown バッファにも適用
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "markdown", "text", "gitcommit", "tex", "plaintex", "norg" },
      callback = function(args)
        apply_mapping(args.buf)
      end,
    })
  end,
}
