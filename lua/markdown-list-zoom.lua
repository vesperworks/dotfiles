-- markdown-list-zoom.lua
-- Markdownリストの現在のサブリスト全体をズームする機能

local M = {}

-- Treesitterを使ってMarkdownのリスト構造を解析
local function get_list_range()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1] - 1 -- 0-indexed
  
  -- Treesitterパーサーを取得
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if not parser then
    vim.notify("Markdownパーサーが見つかりません", vim.log.levels.ERROR)
    return nil
  end
  
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- 現在のカーソル位置のノードを取得
  local node = root:descendant_for_range(cursor_row, 0, cursor_row, -1)
  
  -- リスト項目を探す
  local list_item = nil
  local current_node = node
  
  while current_node do
    local node_type = current_node:type()
    if node_type == "list_item" then
      list_item = current_node
      break
    end
    current_node = current_node:parent()
  end
  
  if not list_item then
    vim.notify("現在の位置はリスト項目内ではありません", vim.log.levels.WARN)
    return nil
  end
  
  -- 親リスト全体を取得（同じレベルのリスト項目を含む）
  local parent_list = list_item:parent()
  if parent_list and parent_list:type() == "list" then
    local start_row, _, end_row, _ = parent_list:range()
    return { start_row + 1, end_row + 1 } -- 1-indexed
  else
    -- 単一のリスト項目の場合
    local start_row, _, end_row, _ = list_item:range()
    return { start_row + 1, end_row + 1 } -- 1-indexed
  end
end

-- リストをズームする（他の部分をfolding）
function M.zoom_current_list()
  local range = get_list_range()
  if not range then
    return
  end
  
  local start_line, end_line = range[1], range[2]
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- 既存のfoldを削除
  vim.cmd("normal! zE")
  
  -- リスト範囲の前をfold
  if start_line > 1 then
    vim.cmd(string.format("1,%d fold", start_line - 1))
  end
  
  -- リスト範囲の後をfold
  if end_line < total_lines then
    vim.cmd(string.format("%d,%d fold", end_line + 1, total_lines))
  end
  
  -- リスト範囲の最初にカーソルを移動
  vim.api.nvim_win_set_cursor(0, {start_line, 0})
  
  -- 画面を中央に
  vim.cmd("normal! zz")
  
  vim.notify(string.format("リスト項目 (行 %d-%d) をズーム", start_line, end_line))
end

-- ズームを解除
function M.unzoom()
  vim.cmd("normal! zR")
  vim.notify("ズーム解除")
end

-- 自動コマンドでMarkdownファイルでのみ有効化
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- キーマップを設定
    vim.keymap.set("n", "<leader>zz", M.zoom_current_list, { 
      buffer = true, 
      desc = "リストズーム" 
    })
    vim.keymap.set("n", "<leader>ZZ", M.unzoom, { 
      buffer = true, 
      desc = "ズーム解除" 
    })
  end,
})

return M
