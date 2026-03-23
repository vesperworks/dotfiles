-- lua/vw/header.lua
-- 見出しレベルの挿入・削除

local M = {}

--- markdownヘッダーを挿入する
function M.insert_markdown_header(level)
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]

  local header_prefix = string.rep("#", level) .. " "

  local new_line
  if string.match(current_line, "^#+%s") then
    new_line = string.gsub(current_line, "^#+%s", header_prefix)
  else
    new_line = header_prefix .. current_line
  end

  vim.api.nvim_set_current_line(new_line)

  local new_col = #header_prefix + (cursor_pos[2] - (current_line:len() - current_line:gsub("^#+%s", ""):len()))
  vim.api.nvim_win_set_cursor(0, {row, math.max(0, new_col)})
end

--- ヘッダーを削除する
function M.remove_markdown_header()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]

  if string.match(current_line, "^#+%s") then
    local new_line = string.gsub(current_line, "^#+%s", "")
    vim.api.nvim_set_current_line(new_line)

    local header_length = current_line:len() - new_line:len()
    local new_col = math.max(0, cursor_pos[2] - header_length)
    vim.api.nvim_win_set_cursor(0, {row, new_col})
  end
end

--- キーマップを設定
function M.setup()
  local opts = { noremap = true, silent = true }

  for i = 1, 6 do
    vim.keymap.set('n', '<leader>' .. i, function()
      M.insert_markdown_header(i)
    end, vim.tbl_extend('force', opts, { desc = "Insert H" .. i .. " header" }))
  end

  vim.keymap.set('n', '<leader>0', M.remove_markdown_header,
    vim.tbl_extend('force', opts, { desc = "Remove header" }))
end

return M
