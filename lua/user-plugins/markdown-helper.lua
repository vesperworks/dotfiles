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
  local start_row, end_row
  
  -- Visual modeの判定と範囲取得
  local mode = vim.fn.mode()
  
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode中の現在の選択範囲を直接取得
    local visual_start = vim.fn.getpos("v")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    
    start_row = visual_start[2]
    end_row = cursor_pos[1]
    
    -- 選択方向によって開始と終了を整理
    if start_row > end_row then
      start_row, end_row = end_row, start_row
    end
    
    -- Visual modeを終了
    vim.cmd('normal! \\<Esc>')
    
    -- 範囲が無効な場合のフォールバック
    if start_row == 0 or end_row == 0 then
      local cursor_pos_fallback = vim.api.nvim_win_get_cursor(0)
      start_row = cursor_pos_fallback[1]
      end_row = cursor_pos_fallback[1]
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
  
  -- ファイルパスを取得
  local file_path = vim.api.nvim_buf_get_name(0)
  
  -- 選択範囲の行を取得
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local new_lines = {}
  
  -- 各行に対してチェックボックス状態変更を実行
  for i, line in ipairs(lines) do
    local line_number = start_row + i - 1
    local old_line = line
    local new_line
    
    if string.match(line, "^%s*[%*%-]%s*%[%s%]") then
      -- 未完了 → 実行中 (スペースを確実にマッチ)
      new_line = string.gsub(line, "(%[)%s(%])", "%1-%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[%-%]") then
      -- 実行中 → 完了
      new_line = string.gsub(line, "(%[)%-(%])", "%1x%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[x%]") then
      -- 完了 → 未完了
      new_line = string.gsub(line, "(%[)x(%])", "%1 %2")
    else
      -- チェックボックスがない場合はそのまま
      new_line = line
    end
    
    -- タイマー統合: 状態変更を検出してタイマーに通知
    if old_line ~= new_line then
      local old_state = old_line:match('%[([%s%-x])%]')
      local new_state = new_line:match('%[([%s%-x])%]')
      
      -- デバッグ情報（必要時のみ有効化）
      -- vim.notify(string.format("DEBUG: state change line=%d, old='%s', new='%s'", line_number, old_state or "nil", new_state or "nil"), vim.log.levels.DEBUG)
      
      if old_state and new_state then
        -- 状態文字を正規化（スペースを明示的に処理）
        local normalized_old = old_state == ' ' and ' ' or old_state
        local normalized_new = new_state == ' ' and ' ' or new_state
        
        -- タスクタイマーに状態変更を通知
        local ok, timer = pcall(require, 'user-plugins.task-timer')
        if ok then
          timer.on_checkbox_change(file_path, line_number, normalized_old, normalized_new, new_line)
        end
      end
    end
    
    table.insert(new_lines, new_line)
  end
  
  -- 行を更新
  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
  
  -- カーソル位置を適切に調整（最初の行に戻す）
  vim.api.nvim_win_set_cursor(0, {start_row, 0})
end

-- リストアイテムを追加する関数（複数行対応）
function M.insert_list_item(marker)
  marker = marker or "*"
  local start_row, end_row
  
  -- Visual modeの判定と範囲取得
  local mode = vim.fn.mode()
  
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode中の現在の選択範囲を直接取得
    local visual_start = vim.fn.getpos("v")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    
    start_row = visual_start[2]
    end_row = cursor_pos[1]
    
    -- 選択方向によって開始と終了を整理
    if start_row > end_row then
      start_row, end_row = end_row, start_row
    end
    
    -- Visual modeを終了
    vim.cmd('normal! \\<Esc>')
    
    -- 範囲が無効な場合のフォールバック
    if start_row == 0 or end_row == 0 then
      local cursor_pos_fallback = vim.api.nvim_win_get_cursor(0)
      start_row = cursor_pos_fallback[1]
      end_row = cursor_pos_fallback[1]
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
  local new_lines = {}
  
  -- 各行に対してリストアイテムの挿入/削除を実行
  for _, line in ipairs(lines) do
    local new_line
    
    -- 既存のリストマーカーがある場合は削除、ない場合は追加
    if string.match(line, "^%s*[%*%-]%s") then
      -- 既にリストアイテムがある場合は削除
      new_line = string.gsub(line, "^(%s*)[%*%-]%s*", "%1")
    else
      -- リストアイテムがない場合は追加
      local indent = string.match(line, "^(%s*)") or ""
      local content = string.gsub(line, "^%s*", "")
      new_line = indent .. marker .. " " .. content
    end
    
    table.insert(new_lines, new_line)
  end
  
  -- 行を更新
  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
  
  -- カーソル位置を適切に調整（最初の行のリストマーカー後に移動）
  if #new_lines > 0 then
    local first_line = new_lines[1]
    local marker_end = string.match(first_line, "^%s*" .. marker .. " ?()") or 1
    vim.api.nvim_win_set_cursor(0, {start_row, marker_end})
  end
end

-- Calloutメイン関数
function M.insert_callout()
  local start_row, end_row
  
  -- Visual modeの判定と範囲取得
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode中の現在の選択範囲を直接取得
    local visual_start = vim.fn.getpos("v")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    
    start_row = visual_start[2]
    end_row = cursor_pos[1]
    
    -- 選択方向によって開始と終了を整理
    if start_row > end_row then
      start_row, end_row = end_row, start_row
    end
    
    -- Visual modeを終了
    vim.cmd('normal! \\<Esc>')
    
    -- マークが無効な場合のフォールバック
    if start_row == 0 or end_row == 0 then
      local cursor_pos_fallback = vim.api.nvim_win_get_cursor(0)
      start_row = cursor_pos_fallback[1]
      end_row = cursor_pos_fallback[1]
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
    { "note", "📝 Note", "a" },
    { "warning", "⚠️ Warning", "s" },
    { "error", "❌ Error", "d" },
    { "info", "ℹ️ Info", "f" },
    { "tip", "💡 Tip", "g" },
    { "success", "✅ Success", "h" },
    { "question", "❓ Question", "j" },
    { "quote", "💬 Quote (普通のクオート)", "k" },
    { "code", "💻 Code Block", "c" },
  }
  
  M.show_callout_selection(callout_types, "Calloutの種類を選択:", function(choice)
    if not choice then return end
    
    local callout_type = choice[1]
    
    -- コードブロックの場合は専用関数を呼び出し
    if callout_type == "code" then
      M.insert_code_block()
      return
    end
    
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

-- コードブロックを挿入する関数
function M.insert_code_block()
  local start_row, end_row
  
  -- Visual modeの判定と範囲取得
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode中の現在の選択範囲を直接取得
    local visual_start = vim.fn.getpos("v")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    
    start_row = visual_start[2]
    end_row = cursor_pos[1]
    
    -- 選択方向によって開始と終了を整理
    if start_row > end_row then
      start_row, end_row = end_row, start_row
    end
    
    -- Visual modeを終了
    vim.cmd('normal! \\<Esc>')
    
    -- マークが無効な場合のフォールバック
    if start_row == 0 or end_row == 0 then
      local cursor_pos_fallback = vim.api.nvim_win_get_cursor(0)
      start_row = cursor_pos_fallback[1]
      end_row = cursor_pos_fallback[1]
    end
  else
    -- Normal mode: 現在の行のみ
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    start_row = cursor_pos[1]
    end_row = cursor_pos[1]
  end
  
  -- 選択した内容を取得
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local content = table.concat(lines, "\n")
  
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
  
  -- 言語選択
  local languages = {
    { "markdown", "📝 Markdown", "m" },
    { "lua", "🌙 Lua", "l" },
    { "javascript", "🟨 JavaScript", "j" },
    { "typescript", "🔷 TypeScript", "t" },
    { "python", "🐍 Python", "p" },
    { "bash", "💻 Bash", "b" },
    { "json", "📄 JSON", "n" },
    { "yaml", "🔧 YAML", "y" },
    { "css", "🎨 CSS", "c" },
    { "html", "🌐 HTML", "h" },
    { "", "⚪ No language", "" },
  }
  
  M.show_language_selection(languages, "コードブロックの言語を選択:", function(choice)
    if not choice then return end
    
    local language = choice[1]
    local new_lines = {}
    
    -- コードブロック開始
    table.insert(new_lines, common_indent .. "```" .. language)
    
    -- 選択された内容を追加（インデントを調整）
    for _, line in ipairs(lines) do
      if line == "" then
        table.insert(new_lines, "")
      else
        local content_line = string.gsub(line, "^" .. common_indent, "")
        table.insert(new_lines, common_indent .. content_line)
      end
    end
    
    -- コードブロック終了
    table.insert(new_lines, common_indent .. "```")
    
    -- 行を置換
    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
    
    -- カーソルをコードブロック内に移動
    vim.api.nvim_win_set_cursor(0, {start_row + 1, #common_indent})
  end)
end

-- 言語選択UI
function M.show_language_selection(languages, prompt, callback)
  -- メッセージを表示
  local message_lines = { "💻 " .. prompt }
  
  for i, lang in ipairs(languages) do
    local key = lang[3] ~= "" and lang[3] or "Space"
    local display = lang[2]
    table.insert(message_lines, string.format("  %s: %s", key, display))
  end
  
  table.insert(message_lines, "")
  table.insert(message_lines, "  Enter: No language (デフォルト) | Esc: キャンセル")
  
  -- メッセージを通知として表示
  vim.notify(table.concat(message_lines, "\n"), vim.log.levels.INFO, { title = "Language Selection" })
  
  -- 一文字入力を待機
  local char = vim.fn.getchar()
  local input = vim.fn.nr2char(char)
  
  -- Enter（13）またはESC（27）の処理
  if char == 13 then -- Enter
    -- デフォルトで言語なしを選択
    for _, lang in ipairs(languages) do
      if lang[1] == "" then
        callback(lang)
        return
      end
    end
  elseif char == 27 then -- ESC
    callback(nil)
    return
  elseif char == 32 then -- Space
    -- 言語なしを選択
    for _, lang in ipairs(languages) do
      if lang[1] == "" then
        callback(lang)
        return
      end
    end
  end
  
  -- 入力されたキーに対応する言語を探す
  for _, lang in ipairs(languages) do
    if lang[3] == input then
      callback(lang)
      return
    end
  end
  
  -- 見つからない場合はキャンセル
  callback(nil)
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
    { "note", "📝 Note", "a" },
    { "warning", "⚠️ Warning", "s" },
    { "error", "❌ Error", "d" },
    { "info", "ℹ️ Info", "f" },
    { "tip", "💡 Tip", "g" },
    { "success", "✅ Success", "h" },
    { "question", "❓ Question", "j" },
    { "quote", "💬 Quote (普通のクオート)", "k" },
    { "code", "💻 Code Block", "c" },
  }
  
  M.show_callout_selection(callout_types, "Calloutの種類を選択:", function(choice)
    if not choice then return end
    
    local callout_type = choice[1]
    
    -- コードブロックの場合は専用関数を呼び出し
    if callout_type == "code" then
      M.insert_code_block()
      return
    end
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

-- Callout選択UI（asdfghjk;対応）
function M.show_callout_selection(callout_types, prompt, callback)
  -- メッセージを表示
  local message_lines = { "🔟 " .. prompt }
  
  for i, callout in ipairs(callout_types) do
    local key = callout[3] or tostring(i)
    local display = callout[2]
    table.insert(message_lines, string.format("  %s: %s", key, display))
  end
  
  table.insert(message_lines, "")
  table.insert(message_lines, "  Enter: Quote (デフォルト) | Esc: キャンセル")
  
  -- メッセージを通知として表示
  vim.notify(table.concat(message_lines, "\n"), vim.log.levels.INFO, { title = "Callout Selection" })
  
  -- 一文字入力を待機
  local char = vim.fn.getchar()
  local input = vim.fn.nr2char(char)
  
  -- Enter（13）またはESC（27）の処理
  if char == 13 then -- Enter
    -- デフォルトでquoteを選択
    for _, callout in ipairs(callout_types) do
      if callout[1] == "quote" then
        callback(callout)
        return
      end
    end
  elseif char == 27 then -- ESC
    callback(nil)
    return
  end
  
  -- 入力されたキーに対応するcalloutを探す
  for _, callout in ipairs(callout_types) do
    if callout[3] == input then
      callback(callout)
      return
    end
  end
  
  -- 見つからない場合はキャンセル
  callback(nil)
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
  
  -- リストアイテム関連のキーマップ（Normal & Visual mode）
  vim.keymap.set({'n', 'v'}, '<leader>*', function()
    M.insert_list_item("*")
  end, vim.tbl_extend('force', opts, { desc = "Toggle bullet list (*)" }))
  
  vim.keymap.set({'n', 'v'}, '<leader>-', function()
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
