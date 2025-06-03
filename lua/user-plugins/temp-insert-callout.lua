-- 🔧 Calloutメイン関数（Visual mode完全修正版）
function M.insert_callout()
  local start_row, end_row
  
  -- Visual modeの判定と範囲取得を改善
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode: 選択範囲を取得
    print("Debug: Detected Visual mode: " .. mode)
    
    -- ❗️ 新しいアプローチ: getpos()で選択範囲を取得
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    print(string.format("Debug: getpos results - start_pos: [%d,%d,%d], end_pos: [%d,%d,%d]", 
      start_pos[1], start_pos[2], start_pos[3], end_pos[1], end_pos[2], end_pos[3]))
    
    -- 行番号を抽出
    local start_line = start_pos[2]
    local end_line = end_pos[2]
    
    print("Debug: Extracted line numbers - start_line=" .. start_line .. ", end_line=" .. end_line)
    
    -- 同期的なVisual mode終了
    vim.cmd('normal! \\<Esc>')
    print("Debug: Visual mode exited using vim.cmd with escaped Esc")
    
    -- マークが無効な場合のフォールバック
    if start_line == 0 or end_line == 0 then
      print("Debug: getpos marks invalid, using current line")
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      start_row = cursor_pos[1]
      end_row = cursor_pos[1]
    else
      start_row = start_line
      end_row = end_line
      
      -- 行番号の順序を修正
      if start_row > end_row then
        print("Debug: Swapping start_row and end_row")
        start_row, end_row = end_row, start_row
      end
    end
  else
    -- Normal mode: 現在の行のみ
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    start_row = cursor_pos[1]
    end_row = cursor_pos[1]
    print("Debug: Normal mode - start_row=" .. start_row .. ", end_row=" .. end_row)
  end
  
  print("Debug: Final range - start_row=" .. start_row .. ", end_row=" .. end_row)
  
  -- 総行数チェック
  local total_lines = vim.api.nvim_buf_line_count(0)
  print("Debug: Total buffer lines=" .. total_lines)
  
  -- 行番号の有効性をチェック
  if start_row < 1 or end_row > total_lines or start_row > end_row then
    print("Error: Invalid line numbers - start_row=" .. start_row .. ", end_row=" .. end_row .. ", total_lines=" .. total_lines)
    return
  end
  
  -- 選択範囲の行を取得
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  print("Debug: Retrieved " .. #lines .. " lines")
  
  -- 📟 デバッグ強化: 各行の詳細情報を出力
  for i, line in ipairs(lines) do
    print(string.format("Debug: Line %d: [%s] (length: %d)", i, line, #line))
    
    -- 各文字を16進数で表示（制御文字チェック）
    local hex_chars = {}
    for j = 1, #line do
      local char = line:sub(j, j)
      local byte_val = string.byte(char)
      table.insert(hex_chars, string.format("%02x(%s)", byte_val, char))
    end
    print(string.format("Debug: Line %d hex: %s", i, table.concat(hex_chars, " ")))
  end
  
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
