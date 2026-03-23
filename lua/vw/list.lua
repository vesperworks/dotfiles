-- lua/vw/list.lua
-- リストアイテムの挿入・トグル

local util = require("vw._util")

local M = {}

--- リストアイテムを追加/削除する（複数行対応）
function M.insert_list_item(marker)
  marker = marker or "*"
  local start_row, end_row = util.get_visual_range()
  if not start_row then return end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local new_lines = {}

  for _, line in ipairs(lines) do
    local new_line

    if string.match(line, "^%s*[%*%-]%s") then
      new_line = string.gsub(line, "^(%s*)[%*%-]%s*", "%1")
    else
      local indent = string.match(line, "^(%s*)") or ""
      local content = string.gsub(line, "^%s*", "")
      new_line = indent .. marker .. " " .. content
    end

    table.insert(new_lines, new_line)
  end

  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)

  if #new_lines > 0 then
    local first_line = new_lines[1]
    local marker_end = string.match(first_line, "^%s*" .. marker .. " ?()") or 1
    vim.api.nvim_win_set_cursor(0, {start_row, marker_end})
  end
end

--- キーマップを設定
function M.setup()
  local opts = { noremap = true, silent = true }

  vim.keymap.set({'n', 'v'}, '<leader>*', function()
    M.insert_list_item("*")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (*)" }))

  vim.keymap.set({'n', 'v'}, '<leader>-', function()
    M.insert_list_item("-")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (-)" }))
end

return M
