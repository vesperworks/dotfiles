-- lua/vw/_util.lua
-- vw.* シリーズ内部ユーティリティ（外部公開しない）

local M = {}

--- Visual mode の選択範囲を取得する共通ヘルパー
--- Visual mode: 選択範囲の start_row, end_row を返す
--- Normal mode: カーソル行を start_row, end_row として返す
--- 無効な範囲の場合は nil, nil を返す
function M.get_visual_range()
  local start_row, end_row
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '\022' then
    local visual_start = vim.fn.getpos("v")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    start_row = visual_start[2]
    end_row = cursor_pos[1]
    if start_row > end_row then
      start_row, end_row = end_row, start_row
    end
    vim.cmd('normal! \\<Esc>')
    if start_row == 0 or end_row == 0 then
      local fallback = vim.api.nvim_win_get_cursor(0)
      start_row, end_row = fallback[1], fallback[1]
    end
  else
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    start_row, end_row = cursor_pos[1], cursor_pos[1]
  end

  local total_lines = vim.api.nvim_buf_line_count(0)
  if start_row < 1 or end_row > total_lines or start_row > end_row then
    return nil, nil
  end
  return start_row, end_row
end

return M
