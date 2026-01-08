-- 📁 Markdown見出し + Callout折りたたみ機能
-- 見出しfold（#～######: foldlevel 1-6）とcalloutfold（> [!type]: foldlevel 7固定）を両立
-- calloutは見出しとは独立した固定foldlevel 7の構造として扱う

local M = {}

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
}

-- calloutパターン判定
local function is_callout_start(line)
  -- > [!type] の形式を検出
  return line:match("^%s*>%s*%[!%w+%]")
end

-- calloutの継続行判定
local function is_callout_body(line)
  -- > で始まる行（callout開始行以外）
  return line:match("^%s*>") and not is_callout_start(line)
end

local function getline_or_empty(lnum)
  if lnum < 1 or lnum > vim.fn.line("$") then
    return ""
  end
  return vim.fn.getline(lnum)
end

-- 見出しレベル取得（#の数）
local function get_heading_level(line)
  local level = 0
  -- 行頭の#をカウント
  for i = 1, #line do
    if line:sub(i, i) == "#" then
      level = level + 1
    else
      break
    end
  end
  -- 最大6レベルまで（Markdown標準）
  if level > 0 and level <= 6 and line:match("^#+%s") then
    return level
  end
  return 0
end

-- 親見出しレベルを取得（現在行より上の最も近い見出し）
local function get_parent_heading_level(lnum)
  -- 現在行から上に向かって見出しを探す
  for i = lnum - 1, 1, -1 do
    local prev_line = vim.fn.getline(i)
    local level = get_heading_level(prev_line)
    if level > 0 then
      return level
    end
  end
  -- 見出しが見つからない場合はlevel 1（デフォルト）
  return 1
end

-- foldexpr: 各行のfoldレベルを計算
function M.foldexpr()
  local lnum = vim.v.lnum
  local line = vim.fn.getline(lnum)
  local prev_line = getline_or_empty(lnum - 1)
  local next_line = getline_or_empty(lnum + 1)
  
  -- 見出し検出（優先度：高）
  local heading_level = get_heading_level(line)
  if heading_level > 0 then
    return ">" .. heading_level
  end
  
  -- callout開始行検出（専用foldlevel 7）
  if is_callout_start(line) then
    return ">" .. CALLOUT_LEVEL
  end
  
  -- callout本体（専用foldlevel 7を維持、H6より深い階層）
  if is_callout_body(line) then
    if not is_callout_body(next_line) then
      return "<" .. CALLOUT_LEVEL
    end
    return CALLOUT_LEVEL
  end
  
  -- デフォルト：親のfoldレベルを継承
  return "="
end

-- foldtext: 折りたたまれた時の表示テキスト
function M.foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart
  
  -- calloutの場合
  if is_callout_start(line) then
    -- calloutタイプを抽出（例：[!note] → note）
    local callout_type = line:match("%[!(%w+)%]")
    if callout_type then
      callout_type = callout_type:lower()
      local icon = callout_icons[callout_type] or "📌"
      -- タイトル部分を抽出（[!type]の後ろ）
      local title = line:match("%[!%w+%]%s*(.*)") or ""
      return string.format("%s [!%s] %s (%d lines)", icon, callout_type, title, line_count)
    end
  end
  
  -- 見出しの場合（デフォルトの表示）
  return line .. string.format(" (%d lines)", line_count)
end

return M
