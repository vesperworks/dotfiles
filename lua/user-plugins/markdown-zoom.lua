-- 📁 Markdown見出しzoom機能
-- 現在の見出しセクションだけを表示（他は折りたたみ）
-- zM + zO ベースのシンプル実装

local M = {}

-- 状態管理
M.is_zoomed = false
M.saved_cursor = nil

-- 見出しレベル取得（#の数）
local function get_heading_level(line)
  if not line:match("^#+%s") then
    return 0
  end
  local level = #line:match("^#+")
  return math.min(level, 6)
end

-- 現在のカーソル位置から親見出しを検出
local function get_current_heading()
  local cursor_line = vim.fn.line(".")

  -- 現在行から上に向かって見出しを探す
  for lnum = cursor_line, 1, -1 do
    local line = vim.fn.getline(lnum)
    local level = get_heading_level(line)
    if level > 0 then
      return lnum, level
    end
  end

  return nil, nil
end

-- zoom: 現在セクションのみ表示
function M.zoom()
  local heading_line, level = get_current_heading()

  if not heading_line then
    vim.notify("見出しが見つかりません", vim.log.levels.WARN)
    return
  end

  -- foldが有効か確認
  if not vim.wo.foldenable then
    vim.wo.foldenable = true
  end

  -- 見出し行に移動してから、全て閉じて現在位置を開く
  vim.api.nvim_win_set_cursor(0, { heading_line, 0 })
  vim.cmd("normal! zM")  -- 全て閉じる
  vim.cmd("normal! zv")  -- 現在位置のfoldだけ開く

  M.is_zoomed = true
  vim.notify(string.format("Zoom: %s", vim.fn.getline(heading_line):sub(1, 50)), vim.log.levels.INFO)
end

-- unzoom: 全て開く
function M.unzoom()
  if not M.is_zoomed then
    vim.notify("Zoomされていません", vim.log.levels.INFO)
    return
  end

  vim.cmd("normal! zR")
  M.is_zoomed = false
  vim.notify("Unzoom", vim.log.levels.INFO)
end

-- toggle: zoom/unzoom切り替え
function M.toggle()
  if M.is_zoomed then
    M.unzoom()
  else
    M.zoom()
  end
end

-- セットアップ
function M.setup()
  -- Markdownファイルでのみ有効なキーマップ
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      local opts = { buffer = true, silent = true }
      vim.keymap.set("n", "<leader>zz", M.toggle, vim.tbl_extend("force", opts, { desc = "Zoom toggle" }))
    end,
  })
end

return M
