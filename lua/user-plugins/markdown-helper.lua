-- ~/.config/nvim/lua/user-plugins/markdown-helper.lua

local M = {}

-- markdownヘッダーを挿入する関数
function M.insert_markdown_header(level)
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  
  -- ヘッダー文字列を生成（レベルに応じて#の数を決定）
  local header_prefix = string.rep("#", level) .. " "
  
  -- 既にヘッダーがある場合は置き換え、ない場合は追加
  local new_line
  if string.match(current_line, "^#+%s") then
    -- 既存のヘッダーを置き換え
    new_line = string.gsub(current_line, "^#+%s", header_prefix)
  else
    -- 新しくヘッダーを追加
    new_line = header_prefix .. current_line
  end
  
  -- 行を更新
  vim.api.nvim_set_current_line(new_line)
  
  -- カーソル位置を調整（ヘッダー文字の後ろに移動）
  local new_col = #header_prefix + (cursor_pos[2] - (current_line:len() - current_line:gsub("^#+%s", ""):len()))
  vim.api.nvim_win_set_cursor(0, {row, math.max(0, new_col)})
end

-- ヘッダーを削除する関数
function M.remove_markdown_header()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  
  if string.match(current_line, "^#+%s") then
    local new_line = string.gsub(current_line, "^#+%s", "")
    vim.api.nvim_set_current_line(new_line)
    
    -- カーソル位置を調整
    local header_length = current_line:len() - new_line:len()
    local new_col = math.max(0, cursor_pos[2] - header_length)
    vim.api.nvim_win_set_cursor(0, {row, new_col})
  end
end

-- チェックボックスを挿入または切り替える関数
function M.toggle_checkbox()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  
  local new_line
  local cursor_offset = 0
  
  -- 既存のチェックボックスの状態をチェック
  if string.match(current_line, "^%s*[%*%-]%s*%[[ x]%]%s") then
    -- 既にチェックボックスがある場合は削除
    new_line = string.gsub(current_line, "^(%s*)[%*%-]%s*%[[ x]%]%s*", "%1")
    cursor_offset = -(current_line:len() - new_line:len())
  elseif string.match(current_line, "^%s*-%s") then
    -- 既存の "- 項目" を "- [ ] 項目" に置き換え
    new_line = string.gsub(current_line, "^(%s*)-%s", "%1- [ ] ")
    cursor_offset = 4 -- "[ ] " の長さ
  else
    -- チェックボックスがない場合は追加
    local indent = string.match(current_line, "^(%s*)") or ""
    local content = string.gsub(current_line, "^%s*", "")
    new_line = indent .. "- [ ] " .. content
    cursor_offset = 6 -- "- [ ] " の長さ
  end
  
  -- 行を更新
  vim.api.nvim_set_current_line(new_line)
  
  -- カーソル位置を調整
  local new_col = math.max(0, cursor_pos[2] + cursor_offset)
  vim.api.nvim_win_set_cursor(0, {row, new_col})
end

-- チェックボックスの完了状態を切り替える関数（未完了 → 実行中 → 完了 → 未完了）
function M.toggle_checkbox_state()
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  
  local new_line
  
  -- デバッグ用（削除可能）
  -- print("Current line: '" .. current_line .. "'")
  
  if string.match(current_line, "^%s*[%*%-]%s*%[%s%]") then
    -- 未完了 → 実行中 (スペースを確実にマッチ)
    new_line = string.gsub(current_line, "(%[)%s(%])", "%1-%2")
    -- print("未完了 → 実行中")
  elseif string.match(current_line, "^%s*[%*%-]%s*%[%-%]") then
    -- 実行中 → 完了
    new_line = string.gsub(current_line, "(%[)%-(%])", "%1x%2")
    -- print("実行中 → 完了")
  elseif string.match(current_line, "^%s*[%*%-]%s*%[x%]") then
    -- 完了 → 未完了
    new_line = string.gsub(current_line, "(%[)x(%])", "%1 %2")
    -- print("完了 → 未完了")
  else
    -- チェックボックスがない場合は何もしない
    -- print("チェックボックスが見つかりません")
    return
  end
  
  -- 行を更新
  vim.api.nvim_set_current_line(new_line)
  
  -- カーソル位置はそのまま
  vim.api.nvim_win_set_cursor(0, cursor_pos)
end

-- リストアイテムを追加する関数
function M.insert_list_item(marker)
  marker = marker or "*"
  local current_line = vim.api.nvim_get_current_line()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row = cursor_pos[1]
  
  local new_line
  local cursor_offset = 0
  
  -- 既存のリストマーカーがある場合は削除、ない場合は追加
  if string.match(current_line, "^%s*[%*%-]%s") then
    -- 既にリストアイテムがある場合は削除
    new_line = string.gsub(current_line, "^(%s*)[%*%-]%s*", "%1")
    cursor_offset = -(current_line:len() - new_line:len())
  else
    -- リストアイテムがない場合は追加
    local indent = string.match(current_line, "^(%s*)") or ""
    local content = string.gsub(current_line, "^%s*", "")
    new_line = indent .. marker .. " " .. content
    cursor_offset = #marker + 1
  end
  
  -- 行を更新
  vim.api.nvim_set_current_line(new_line)
  
  -- カーソル位置を調整
  local new_col = math.max(0, cursor_pos[2] + cursor_offset)
  vim.api.nvim_win_set_cursor(0, {row, new_col})
end

-- キーマップを設定する関数
function M.setup_keymaps()
  local opts = { noremap = true, silent = true }
  
  -- ヘッダー関連のキーマップ
  for i = 1, 6 do
    vim.keymap.set('n', '<leader>' .. i, function()
      M.insert_markdown_header(i)
    end, vim.tbl_extend('force', opts, { desc = "Insert H" .. i .. " header" }))
  end
  
  -- <leader>0 でヘッダーを削除
  vim.keymap.set('n', '<leader>0', M.remove_markdown_header, 
    vim.tbl_extend('force', opts, { desc = "Remove header" }))
  
  -- チェックボックス関連のキーマップ
  vim.keymap.set('n', '<leader>c', M.toggle_checkbox, 
    vim.tbl_extend('force', opts, { desc = "Toggle checkbox" }))
  
  -- Enterキーで3状態循環はautolist.luaで設定済み
  -- vim.keymap.set('n', '<CR>', M.toggle_checkbox_state, 
  --   vim.tbl_extend('force', opts, { desc = "Cycle checkbox state (□ → ▫ → ✓)" }))
  
  -- リストアイテム関連のキーマップ
  vim.keymap.set('n', '<leader>*', function()
    M.insert_list_item("*")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (*)" }))
  
  vim.keymap.set('n', '<leader>-', function()
    M.insert_list_item("-")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (-)" }))
end

-- 便利なヘルプ関数：現在行のmarkdown要素を表示
function M.show_current_element()
  local current_line = vim.api.nvim_get_current_line()
  
  if string.match(current_line, "^#+%s") then
    local level = #string.match(current_line, "^(#+)")
    print("Header level " .. level)
  elseif string.match(current_line, "^%s*[%*%-]%s*%[ %]") then
    print("Unchecked checkbox")
  elseif string.match(current_line, "^%s*[%*%-]%s*%[-%]") then
    print("In-progress checkbox")
  elseif string.match(current_line, "^%s*[%*%-]%s*%[x%]") then
    print("Checked checkbox")
  elseif string.match(current_line, "^%s*[%*%-]%s") then
    print("List item")
  else
    print("Plain text")
  end
end

return M