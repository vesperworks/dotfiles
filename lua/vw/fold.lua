-- lua/vw/fold.lua
-- 見出し・Callout の折りたたみ + Zoom 機能
-- markdown-fold.lua + markdown-zoom.lua を統合

local M = {}

-- =============================================
-- 折りたたみ (foldexpr / foldtext)
-- =============================================

-- calloutは常にfoldlevel 7とする（見出しと独立した階層）
local CALLOUT_LEVEL = 7

-- calloutアイコンマッピング
local callout_icons = {
  note = "📝",
  warning = "⚠️",
  danger = "❌",
  info = "ℹ️",
  tip = "💡",
  success = "✅",
  question = "❓",
  think = "🤔",
  idea = "💡",
  plan = "📋",
  journaling = "📓",
}

-- calloutパターン判定
local function is_callout_start(line)
  return line:match("^%s*>%s*%[!%w+%]")
end

local function is_callout_body(line)
  return line:match("^%s*>") and not is_callout_start(line)
end

local function getline_or_empty(lnum)
  if lnum < 1 or lnum > vim.fn.line("$") then
    return ""
  end
  return vim.fn.getline(lnum)
end

local function get_heading_level(line)
  local level = 0
  for i = 1, #line do
    if line:sub(i, i) == "#" then
      level = level + 1
    else
      break
    end
  end
  if level > 0 and level <= 6 and line:match("^#+%s") then
    return level
  end
  return 0
end

function M.foldexpr()
  local lnum = vim.v.lnum
  local line = vim.fn.getline(lnum)
  local next_line = getline_or_empty(lnum + 1)

  local heading_level = get_heading_level(line)
  if heading_level > 0 then
    return ">" .. heading_level
  end

  if is_callout_start(line) then
    return ">" .. CALLOUT_LEVEL
  end

  if is_callout_body(line) then
    if not is_callout_body(next_line) then
      return "<" .. CALLOUT_LEVEL
    end
    return CALLOUT_LEVEL
  end

  return "="
end

function M.foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart

  if is_callout_start(line) then
    local callout_type = line:match("%[!(%w+)%]")
    if callout_type then
      callout_type = callout_type:lower()
      local icon = callout_icons[callout_type] or "📌"
      local title = line:match("%[!%w+%]%s*(.*)") or ""
      return string.format("%s [!%s] %s (%d lines)", icon, callout_type, title, line_count)
    end
  end

  return line .. string.format(" (%d lines)", line_count)
end

-- =============================================
-- Zoom 機能
-- =============================================

M.is_zoomed = false

local function get_current_heading()
  local cursor_line = vim.fn.line(".")
  for lnum = cursor_line, 1, -1 do
    local line = vim.fn.getline(lnum)
    local level = get_heading_level(line)
    if level > 0 then
      return lnum, level
    end
  end
  return nil, nil
end

function M.zoom()
  local heading_line, level = get_current_heading()
  if not heading_line then
    vim.notify("見出しが見つかりません", vim.log.levels.WARN)
    return
  end

  if not vim.wo.foldenable then
    vim.wo.foldenable = true
  end

  vim.api.nvim_win_set_cursor(0, { heading_line, 0 })
  vim.cmd("normal! zM")
  vim.cmd("normal! zv")

  M.is_zoomed = true
  vim.notify(string.format("Zoom: %s", vim.fn.getline(heading_line):sub(1, 50)), vim.log.levels.INFO)
end

function M.unzoom()
  if not M.is_zoomed then
    vim.notify("Zoomされていません", vim.log.levels.INFO)
    return
  end
  vim.cmd("normal! zR")
  M.is_zoomed = false
  vim.notify("Unzoom", vim.log.levels.INFO)
end

function M.zoom_toggle()
  if M.is_zoomed then
    M.unzoom()
  else
    M.zoom()
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      local opts = { buffer = true, silent = true }
      vim.keymap.set("n", "<leader>zz", M.zoom_toggle, vim.tbl_extend("force", opts, { desc = "Zoom toggle" }))
    end,
  })
end

return M
