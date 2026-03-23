-- Markdownファイルの formatoptions 設定
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- 不要な 't' を外す
    vim.opt_local.formatoptions:remove("t")
    -- リスト継続に必要な 'o','r','n' を追加
    vim.opt_local.formatoptions:append("orn")
  end,
})

-- 音声入力で挿入される壊れたCSI uシーケンスを改行に置換
vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
  pattern = "*",
  callback = function()
    local line = vim.api.nvim_get_current_line()
    local seq = "\27[27;5;106~"
    if line:find(seq, 1, true) then
      local row = vim.api.nvim_win_get_cursor(0)[1] - 1
      local parts = {}
      local rest = line
      while true do
        local s, e = rest:find(seq, 1, true)
        if not s then
          table.insert(parts, rest)
          break
        end
        table.insert(parts, rest:sub(1, s - 1))
        rest = rest:sub(e + 1)
      end
      vim.api.nvim_buf_set_lines(0, row, row + 1, false, parts)
    end
  end,
})
