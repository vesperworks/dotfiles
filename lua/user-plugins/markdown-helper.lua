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
  
  if string.match(current_line, "^%s*[%*%-]%s*%[%s%]") then
    -- 未完了 → 実行中 (スペースを確実にマッチ)
    new_line = string.gsub(current_line, "(%[)%s(%])", "%1-%2")
  elseif string.match(current_line, "^%s*[%*%-]%s*%[%-%]") then
    -- 実行中 → 完了
    new_line = string.gsub(current_line, "(%[)%-(%])", "%1x%2")
  elseif string.match(current_line, "^%s*[%*%-]%s*%[x%]") then
    -- 完了 → 未完了
    new_line = string.gsub(current_line, "(%[)x(%])", "%1 %2")
  else
    -- チェックボックスがない場合は何もしない
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

-- Calloutメイン関数
function M.insert_callout()
  local start_row, end_row
  
  -- Visual modeの判定と範囲取得
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode: 選択範囲を取得
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    local start_line = start_pos[2]
    local end_line = end_pos[2]
    
    -- Visual modeを終了
    vim.cmd('normal! \\<Esc>')
    
    -- マークが無効な場合のフォールバック
    if start_line == 0 or end_line == 0 then
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      start_row = cursor_pos[1]
      end_row = cursor_pos[1]
    else
      start_row = start_line
      end_row = end_line
      
      -- 行番号の順序を修正
      if start_row > end_row then
        start_row, end_row = end_row, start_row
      end
    end
  else
    -- Normal mode: 現在の行のみ
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    start_row = cursor_pos[1]
    end_row = cursor_pos[1]
  end
  
  -- 総行数チェック
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- 行番号の有効性をチェック
  if start_row < 1 or end_row > total_lines or start_row > end_row then
    return
  end
  
  -- 選択範囲の行を取得
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  
  -- 既にcalloutかどうかをチェック
  local has_callout = false
  for _, line in ipairs(lines) do
    if string.match(line, "^%s*>%s*%[!") then
      has_callout = true
      break
    end
  end
  
  if has_callout then
    -- 既にcalloutがある場合は選択メニューを表示
    vim.ui.select({"1. Remove Callout", "2. Change Callout Type"}, {
      prompt = "既存のCalloutがあります:",
    }, function(choice)
      if choice == "1. Remove Callout" then
        M.remove_callout(start_row, end_row)
      elseif choice == "2. Change Callout Type" then
        M.change_callout_type(start_row, end_row)
      end
    end)
  else
    -- 新しいcalloutを作成
    M.create_new_callout(start_row, end_row)
  end
end

-- Calloutを解除する関数
function M.remove_callout(start_row, end_row)
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local new_lines = {}
  
  for _, line in ipairs(lines) do
    -- Calloutヘッダー行を検出して削除
    if string.match(line, "^%s*>%s*%[!") then
      -- この行は削除（new_linesに追加しない）
    -- 通常のクオート行の>を削除
    elseif string.match(line, "^%s*>") then
      -- インデントを保持して>を削除
      local indent = string.match(line, "^(%s*)")
      local content = string.gsub(line, "^%s*>%s*", "")
      table.insert(new_lines, indent .. content)
    else
      -- 通常の行はそのまま
      table.insert(new_lines, line)
    end
  end
  
  -- 行を置き換え
  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
end

-- Calloutの種類を変更する関数
function M.change_callout_type(start_row, end_row)
  local callout_types = {
    { "note", "📝 Note" },
    { "warning", "⚠️ Warning" },
    { "error", "❌ Error" },
    { "info", "ℹ️ Info" },
    { "tip", "💡 Tip" },
    { "success", "✅ Success" },
    { "question", "❓ Question" },
    { "quote", "💬 Quote (普通のクオート)" },
  }
  
  vim.ui.select(callout_types, {
    prompt = "Calloutの種類を選択:",
    format_item = function(item)
      return item[2]
    end,
  }, function(choice)
    if not choice then return end
    
    local callout_type = choice[1]
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local new_lines = {}
    
    if callout_type == "quote" then
      -- quoteの場合はCalloutヘッダーを削除
      for _, line in ipairs(lines) do
        if string.match(line, "^%s*>%s*%[!") then
          -- Calloutヘッダー行を削除（何も追加しない）
        else
          table.insert(new_lines, line)
        end
      end
    else
      -- 通常のCalloutの場合
      for _, line in ipairs(lines) do
        if string.match(line, "^%s*>%s*%[!") then
          -- Calloutヘッダーを置き換え
          local indent = string.match(line, "^(%s*)")
          table.insert(new_lines, indent .. "> [!" .. callout_type .. "]")
        else
          table.insert(new_lines, line)
        end
      end
    end
    
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
  end)
end

-- 新しいCalloutを作成する関数
function M.create_new_callout(start_row, end_row)
  -- バッファ情報チェック
  local total_lines = vim.api.nvim_buf_line_count(0)
  
  -- 行番号の妥当性を再チェック
  if start_row < 1 or end_row > total_lines or start_row > end_row then
    return
  end
  
  local callout_types = {
    { "note", "📝 Note" },
    { "warning", "⚠️ Warning" },
    { "error", "❌ Error" },
    { "info", "ℹ️ Info" },
    { "tip", "💡 Tip" },
    { "success", "✅ Success" },
    { "question", "❓ Question" },
    { "quote", "💬 Quote (普通のクオート)" },
  }
  
  vim.ui.select(callout_types, {
    prompt = "Calloutの種類を選択:",
    format_item = function(item)
      return item[2]
    end,
  }, function(choice)
    if not choice then return end
    
    local callout_type = choice[1]
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local new_lines = {}
    
    -- 共通のインデントを検出
    local common_indent = ""
    for _, line in ipairs(lines) do
      if line ~= "" then
        local indent = string.match(line, "^(%s*)")
        if common_indent == "" or #indent < #common_indent then
          common_indent = indent
        end
      end
    end
    
    -- quoteの場合は特別処理（Calloutヘッダーなし）
    if callout_type == "quote" then
      for _, line in ipairs(lines) do
        if line == "" then
          table.insert(new_lines, common_indent .. ">")
        elseif string.match(line, "^%s*>") then
          table.insert(new_lines, line)
        else
          local content = string.gsub(line, "^" .. common_indent, "")
          table.insert(new_lines, common_indent .. "> " .. content)
        end
      end
    else
      -- 通常のCalloutの場合
      table.insert(new_lines, common_indent .. "> [!" .. callout_type .. "]")
      
      for _, line in ipairs(lines) do
        if line == "" then
          table.insert(new_lines, common_indent .. ">")
        elseif string.match(line, "^%s*>") then
          table.insert(new_lines, line)
        else
          local content = string.gsub(line, "^" .. common_indent, "")
          table.insert(new_lines, common_indent .. "> " .. content)
        end
      end
    end
    
    -- 安全な行置換
    local success, err = pcall(function()
      vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
    end)
    
    if not success then
      return
    end
    
    -- カーソルを適切な位置に移動
    if callout_type == "quote" then
      vim.api.nvim_win_set_cursor(0, {start_row, #(common_indent .. "> ")})
    else
      vim.api.nvim_win_set_cursor(0, {start_row + 1, #(common_indent .. "> ")})
    end
  end)
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
  vim.keymap.set('n', '<leader>x', M.toggle_checkbox, 
    vim.tbl_extend('force', opts, { desc = "Toggle checkbox" }))
  
  -- リストアイテム関連のキーマップ
  vim.keymap.set('n', '<leader>*', function()
    M.insert_list_item("*")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (*)" }))
  
  vim.keymap.set('n', '<leader>-', function()
    M.insert_list_item("-")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (-)" }))
  
  -- Callout関連のキーマップ（Normal & Visual mode）
  vim.keymap.set('n', '<leader>c', M.insert_callout, 
    vim.tbl_extend('force', opts, { desc = "Insert/toggle/remove Callout" }))
  vim.keymap.set('v', '<leader>c', M.insert_callout, 
    vim.tbl_extend('force', opts, { desc = "Insert/toggle/remove Callout (Visual)" }))
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
