-- lua/vw/checkbox.lua
-- チェックボックスの挿入・状態サイクル

local util = require("vw._util")

local M = {}

--- チェックボックスを挿入または削除する（複数行対応）
function M.toggle_as_task()
  local start_row, end_row = util.get_visual_range()
  if not start_row then return end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local new_lines = {}

  for _, line in ipairs(lines) do
    local new_line

    if string.match(line, "^%s*[%*%-]%s*%[[ x%-/>v@]%]%s") then
      -- 既にチェックボックスがある場合は削除
      new_line = string.gsub(line, "^(%s*)[%*%-]%s*%[[ x%-/>v@]%]%s*", "%1")
    elseif string.match(line, "^%s*-%s") then
      -- 既存の "- 項目" を "- [ ] 項目" に置き換え
      new_line = string.gsub(line, "^(%s*)-%s", "%1- [ ] ")
    else
      -- チェックボックスがない場合は追加
      local indent = string.match(line, "^(%s*)") or ""
      local content = string.gsub(line, "^%s*", "")
      new_line = indent .. "- [ ] " .. content
    end

    table.insert(new_lines, new_line)
  end

  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)

  if #new_lines > 0 then
    local first_line = new_lines[1]
    local checkbox_end = string.match(first_line, "^%s*- %[ %] ()") or
                         string.match(first_line, "^%s*- ()") or 1
    vim.api.nvim_win_set_cursor(0, {start_row, checkbox_end})
  end
end

--- チェックボックスの完了状態を切り替える（未完了 → 実行中 → AI委譲 → 成功 → 中断 → 失敗 → 未完了）
function M.toggle_checkbox_state()
  local start_row, end_row = util.get_visual_range()
  if not start_row then return end

  local file_path = vim.api.nvim_buf_get_name(0)

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local new_lines = {}

  for i, line in ipairs(lines) do
    local line_number = start_row + i - 1
    local old_line = line
    local new_line

    if string.match(line, "^%s*[%*%-]%s*%[%s%]") then
      new_line = string.gsub(line, "(%[)%s(%])", "%1>%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[>%]") then
      new_line = string.gsub(line, "(%[)>(%])", "%1@%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[@%]") then
      new_line = string.gsub(line, "(%[)@(%])", "%1v%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[v%]") then
      new_line = string.gsub(line, "(%[)v(%])", "%1/%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[/%]") then
      new_line = string.gsub(line, "(%[)/(%])", "%1x%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[x%]") then
      new_line = string.gsub(line, "(%[)x(%])", "%1 %2")
    else
      new_line = line
    end

    -- タイマー統合: 状態変更を検出してタイマーに通知
    if old_line ~= new_line then
      local old_state = old_line:match('%[([%s%->vx/@])%]')
      local new_state = new_line:match('%[([%s%->vx/@])%]')

      if old_state and new_state then
        local normalized_old = old_state == ' ' and ' ' or old_state
        local normalized_new = new_state == ' ' and ' ' or new_state

        local ok, timer = pcall(require, 'vw.timer')
        if ok then
          timer.on_checkbox_change(file_path, line_number, normalized_old, normalized_new, new_line)
        end
      end
    end

    table.insert(new_lines, new_line)
  end

  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
  vim.api.nvim_win_set_cursor(0, {start_row, 0})
end

--- キーマップとautocmd を設定
function M.setup()
  local opts = { noremap = true, silent = true }

  vim.keymap.set({'n', 'v'}, '<leader>x', M.toggle_as_task,
    vim.tbl_extend('force', opts, { desc = "Toggle task checkbox (複数行対応)" }))
end

return M
