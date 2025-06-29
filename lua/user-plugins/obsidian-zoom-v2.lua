-- obsidian-zoom-v2.lua
-- 標準fold機能を活用したシンプルなMarkdown見出しズーム

local M = {}

-- ズーム状態を管理
local zoom_state = {
  is_zoomed = false,
  original_foldlevel = nil,
}

-- 現在のカーソル位置の見出しレベルを取得
local function get_current_heading_level()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
  
  -- 現在行から上に向かって見出しを探す
  for row = cursor_row, 0, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    local _, _, hashes = line:find("^(#+)")
    if hashes then
      return #hashes, row + 1 -- レベルと行番号(1-indexed)を返す
    end
  end
  
  return nil, nil
end

-- ズーム実行（親見出しも表示）
function M.zoom_current_heading()
  if zoom_state.is_zoomed then
    vim.notify("📍 既にズーム中です。<leader>ZZで解除してください", vim.log.levels.INFO)
    return
  end
  
  local level, line_num = get_current_heading_level()
  
  if not level then
    vim.notify("📍 見出し内にいません", vim.log.levels.WARN)
    return
  end
  
  -- foldmethodチェック
  local current_foldmethod = vim.opt_local.foldmethod:get()
  if current_foldmethod ~= 'expr' then
    vim.notify(string.format("📍 foldmethod=%sのため、ズーム機能は使用できません", current_foldmethod), vim.log.levels.WARN)
    return
  end
  
  -- 元のfoldlevelを保存
  zoom_state.original_foldlevel = vim.opt_local.foldlevel:get()
  
  -- 1. 全ての見出しを閉じる
  vim.opt_local.foldlevel = 0
  
  -- 2. 現在レベルの親見出しを全て開く
  local bufnr = vim.api.nvim_get_current_buf()
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  
  -- 現在位置より上の見出しで、現在レベルより浅いものを開く
  for row = line_num - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
    local _, _, hashes = line:find("^(#+)")
    if hashes and #hashes < level then
      vim.api.nvim_win_set_cursor(0, {row, 0})
      vim.cmd("normal! zo")
    end
  end
  
  -- 3. 現在のセクションも開く
  vim.api.nvim_win_set_cursor(0, {line_num, 0})
  vim.cmd("normal! zo")
  vim.cmd("normal! zz")
  
  -- 状態を保存
  zoom_state.is_zoomed = true
  
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1] or ""
  local heading_text = line:gsub("^#+%s*", "")
  vim.notify(string.format("📍 階層ズーム: %s (レベル%d)", heading_text, level), vim.log.levels.INFO)
end

-- ズーム解除
function M.unzoom()
  if not zoom_state.is_zoomed then
    vim.notify("📍 ズーム中ではありません", vim.log.levels.INFO)
    return
  end
  
  -- 元のfoldlevelに戻す
  if zoom_state.original_foldlevel then
    vim.opt_local.foldlevel = zoom_state.original_foldlevel
  else
    vim.opt_local.foldlevel = 99 -- デフォルトで全て開く
  end
  
  -- 状態をリセット
  zoom_state.is_zoomed = false
  zoom_state.original_foldlevel = nil
  
  vim.notify("📍 ズーム解除", vim.log.levels.INFO)
end

-- 現在の状態を表示
function M.show_zoom_status()
  if zoom_state.is_zoomed then
    vim.notify("📍 ズーム中", vim.log.levels.INFO)
  else
    vim.notify("📍 ズームなし", vim.log.levels.INFO)
  end
end

-- ズーム状態を取得（API用）
function M.get_zoom_state()
  return {
    is_zoomed = zoom_state.is_zoomed,
    original_foldlevel = zoom_state.original_foldlevel,
  }
end

-- キーマップ設定
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- 基本ズーム操作（親見出しも表示）
    vim.keymap.set("n", "<leader>zz", M.zoom_current_heading, { 
      buffer = true, 
      desc = "📍 現在見出しでズーム（親も表示）" 
    })
    vim.keymap.set("n", "<leader>ZZ", M.unzoom, { 
      buffer = true, 
      desc = "📍 ズーム解除" 
    })
    
    -- 状態確認
    vim.keymap.set("n", "<leader>zs", M.show_zoom_status, { 
      buffer = true, 
      desc = "📍 ズーム状態表示" 
    })
  end,
})

return M
