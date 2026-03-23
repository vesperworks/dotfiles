-- tests/helpers.lua
-- テスト共通ヘルパー関数

local M = {}

--- テスト用バッファを作成し、指定した行を設定する
function M.create_buf(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = "markdown"
  return buf
end

--- バッファの全行を取得する
function M.get_buf_lines(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

--- キーマップが登録されているか確認する
function M.keymap_exists(mode, lhs)
  local maps = vim.api.nvim_get_keymap(mode)
  for _, map in ipairs(maps) do
    if map.lhs == lhs or map.lhs == lhs:gsub("<leader>", " ") then
      return true
    end
  end
  return false
end

--- autocmd グループが存在するか確認する
--- nvim_get_autocmds は存在しないグループでエラーを投げるので、
--- それを利用して存在確認する（create_augroup は副作用で作成してしまうため不可）
function M.augroup_exists(group_name)
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = group_name })
  return ok and autocmds ~= nil
end

--- autocmd が登録されているか確認する
function M.autocmd_exists(group_name, event, pattern)
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, {
    group = group_name,
    event = event,
  })
  if not ok then return false end
  if not pattern then return #autocmds > 0 end
  for _, ac in ipairs(autocmds) do
    if ac.pattern == pattern then return true end
  end
  return false
end

--- テスト用バッファをクリーンアップする
function M.cleanup_buf(buf)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

return M
