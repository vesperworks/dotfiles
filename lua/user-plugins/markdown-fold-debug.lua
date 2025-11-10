-- 📁 Markdown見出し + Callout折りたたみ機能（デバッグ版）
-- 見出しfold（#～######: foldlevel 1-6）とcalloutfold（親見出しと同じレベル）を両立

local M = {}

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
}

-- calloutパターン判定
local function is_callout_start(line)
  return line:match("^%s*>%s*%[!%w+%]")
end

-- calloutの継続行判定
local function is_callout_body(line)
  return line:match("^%s*>") and not is_callout_start(line)
end

local function getline_or_empty(lnum)
  if lnum < 1 or lnum > vim.fn.line("$") then
    return ""
  end
  return vim.fn.getline(lnum)
end

-- 見出しレベル取得
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

-- 親見出しレベル取得
local function get_parent_heading_level(lnum)
  for i = lnum - 1, 1, -1 do
    local prev_line = vim.fn.getline(i)
    local level = get_heading_level(prev_line)
    if level > 0 then
      return level
    end
  end
  return 1
end

-- foldexpr: 各行のfoldレベルを計算（デバッグ版）
function M.foldexpr()
  local lnum = vim.v.lnum
  local line = vim.fn.getline(lnum)
  local prev_line = getline_or_empty(lnum - 1)
  local next_line = getline_or_empty(lnum + 1)
  
  -- 全行デバッグ（最初の30行のみ）
  if lnum <= 30 then
    vim.schedule(function()
      local heading = get_heading_level(line)
      local is_co_start = is_callout_start(line) and "YES" or "NO"
      local is_co_body = is_callout_body(line) and "YES" or "NO"
      print(string.format("L%02d: H=%d CS=%s CB=%s | %s", 
        lnum, heading, is_co_start, is_co_body, line:sub(1, 40)))
    end)
  end
  
  -- 見出し検出
  local heading_level = get_heading_level(line)
  if heading_level > 0 then
    return ">" .. heading_level
  end
  
  -- callout開始行検出
  if is_callout_start(line) then
    local parent_level = get_parent_heading_level(lnum)
    vim.schedule(function()
      print(string.format(">>> CALLOUT START at L%d: returning >%d", lnum, parent_level))
    end)
    return ">" .. parent_level
  end
  
  -- callout本体
  if is_callout_body(line) then
    local parent_level = get_parent_heading_level(lnum)
    if not is_callout_body(next_line) then
      vim.schedule(function()
        print(string.format("<<< CALLOUT END at L%d: returning <%d", lnum, parent_level))
      end)
      return "<" .. parent_level
    end
    return parent_level
  end
  
  -- callout終了後
  if (is_callout_body(prev_line) or is_callout_start(prev_line)) and not is_callout_body(line) then
    local parent_level = get_parent_heading_level(lnum)
    return parent_level
  end
  
  return "="
end

-- foldtext
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

return M
