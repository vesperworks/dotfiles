-- lua/vw/typewriter.lua
-- カーソルを常に画面中央に保つ typewriter モード
-- joshuadanpeterson/typewriter.nvim の代替（ts_utils 依存を排除）

local M = {}
local active = false
local augroup_name = "VwTypewriter"

local function center_cursor()
  if not active then return end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local last_line = vim.api.nvim_buf_line_count(0)

  if line == 1 then
    vim.cmd("normal! zt")
  elseif line == last_line then
    vim.cmd("normal! zb")
  else
    vim.cmd("normal! zz")
  end

  vim.api.nvim_win_set_cursor(0, cursor)
end

function M.enable()
  if active then return end
  active = true
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = vim.api.nvim_create_augroup(augroup_name, { clear = true }),
    callback = center_cursor,
  })
end

function M.disable()
  if not active then return end
  active = false
  vim.api.nvim_del_augroup_by_name(augroup_name)
end

function M.toggle()
  if active then
    M.disable()
  else
    M.enable()
  end
end

function M.is_active()
  return active
end

function M.setup()
  vim.api.nvim_create_user_command("TWToggle", M.toggle, {})
  vim.api.nvim_create_user_command("TWEnable", M.enable, {})
  vim.api.nvim_create_user_command("TWDisable", M.disable, {})
end

return M
