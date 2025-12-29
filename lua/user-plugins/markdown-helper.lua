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

-- チェックボックスを挿入または切り替える関数（複数行対応）
function M.toggle_as_task()
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
  
  -- 各行に対してチェックボックスの挿入/削除を実行
  for _, line in ipairs(lines) do
    local new_line
    
    -- 既存のチェックボックスの状態をチェック
    if string.match(line, "^%s*[%*%-]%s*%[[ x%-/]%]%s") then
      -- 既にチェックボックスがある場合は削除
      new_line = string.gsub(line, "^(%s*)[%*%-]%s*%[[ x%-/]%]%s*", "%1")
    elseif string.match(line, "^%s*-%s") then
      -- 既存の "- 項目" を "- [ ] 項目" に置き換え
      new_line = string.gsub(line, "^(%s*)-%s", "%1- [ ] ")
    else
      -- チェックボックスがない場合は追加
      local indent = string.match(line, "^(%s*)") or ""
      local content = string.gsub(line, "^%s*", "")
      new_line = indent .. "- [ ] " .. content
    end
    
    table.insert(new_lines, new_line)
  end
  
  -- 行を更新
  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
  
  -- カーソル位置を適切に調整（最初の行のチェックボックス後に移動）
  if #new_lines > 0 then
    local first_line = new_lines[1]
    -- チェックボックスがある場合とない場合で適切な位置を計算
    local checkbox_end = string.match(first_line, "^%s*- %[ %] ()") or 
                         string.match(first_line, "^%s*- ()") or 1
    vim.api.nvim_win_set_cursor(0, {start_row, checkbox_end})
  end
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
      -- 完了 → キャンセル
      new_line = string.gsub(line, "(%[)x(%])", "%1/%2")
    elseif string.match(line, "^%s*[%*%-]%s*%[/%]") then
      -- キャンセル → 未完了
      new_line = string.gsub(line, "(%[)/(%])", "%1 %2")
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
  
  -- 既にcallout/quoteかどうかをチェック
  local has_quote = false
  for _, line in ipairs(lines) do
    if string.match(line, "^%s*>") then
      has_quote = true
      break
    end
  end

  if has_quote then
    -- 既にquote/calloutがある場合は直接解除
    M.remove_callout(start_row, end_row)
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
    { "note", "📝 Note", "n" },
    { "warning", "⚠️ Warning", "s" },
    { "error", "❌ Error", "d" },
    { "info", "ℹ️ Info", "f" },
    { "tip", "💡 Tip", "g" },
    { "success", "✅ Success", "h" },
    { "question", "❓ Question", "j" },
    { "think", "🤔 Think", "t" },
    { "idea", "💡 Idea", "i" },
    { "ai", "🤖 AI", "a" },
    { "quote", "💬 Quote (タイトル付き)", "q" },
    { "blockquote", "📎 Blockquote (>のみ)", "b" },
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
    
    if callout_type == "blockquote" then
      -- blockquoteの場合はCalloutヘッダーを削除
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
          local callout_header
          if callout_type == "think" then
            callout_header = indent .. "> [!" .. callout_type .. "] #think"
          elseif callout_type == "idea" then
            callout_header = indent .. "> [!" .. callout_type .. "] #idea"
          elseif callout_type == "ai" then
            callout_header = indent .. "> [!" .. callout_type .. "] #ai"
          else
            callout_header = indent .. "> [!" .. callout_type .. "]"
          end
          table.insert(new_lines, callout_header)
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

-- 汎用選択UI（Insert mode文字入力受付）
function M.show_selection_buffer(options, prompt, default_key, callback)
  -- 専用バッファ作成
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = { prompt, "" }
  
  -- 選択肢を表示用に整形
  for _, option in ipairs(options) do
    local key = option[3] ~= "" and option[3] or "Space"
    local display = option[2]
    table.insert(lines, string.format("  %s: %s", key, display))
  end
  
  table.insert(lines, "")
  table.insert(lines, "  Enter: デフォルト | Esc: キャンセル")
  table.insert(lines, "")
  table.insert(lines, "  ▶ キーを入力してください...")
  
  -- バッファにコンテンツを設定
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  
  -- ウィンドウサイズを計算
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 4, vim.o.columns - 10)
  local height = math.min(#lines + 2, vim.o.lines - 10)
  
  -- フローティングウィンドウ作成
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    width = width,
    height = height,
    row = 1,
    col = 1,
    border = 'rounded',
    style = 'minimal',
    title = ' 選択してください ',
    title_pos = 'center'
  })
  
  -- ウィンドウオプション設定
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', false)
  
  -- クローズ処理
  local function close_and_callback(result)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    callback(result)
  end
  
  -- Insert modeでの文字入力受付（LSP風）
  local function setup_input_handler()
    -- Insert modeに切り替え
    vim.cmd('startinsert')
    
    -- InsertCharPre autocmdで文字入力をキャッチ
    local group = vim.api.nvim_create_augroup('SelectionInput', { clear = true })
    
    vim.api.nvim_create_autocmd('InsertCharPre', {
      buffer = buf,
      group = group,
      callback = function()
        local char = vim.v.char
        
        -- 改行やスペースは処理しない
        if char == '\n' or char == '\r' then
          return
        end
        
        -- 入力をキャンセル（文字を表示させない）
        vim.v.char = ''
        
        -- 非同期で処理（InsertCharPre中の制限を回避）
        vim.schedule(function()
          -- Spaceキーの処理
          if char == ' ' then
            for _, option in ipairs(options) do
              if option[1] == "" then
                vim.api.nvim_del_augroup_by_id(group)
                close_and_callback(option)
                return
              end
            end
            vim.api.nvim_del_augroup_by_id(group)
            close_and_callback(nil)
            return
          end
          
          -- 各選択肢の文字をチェック
          for _, option in ipairs(options) do
            if option[3] == char then
              vim.api.nvim_del_augroup_by_id(group)
              close_and_callback(option)
              return
            end
          end
        end)
      end
    })
    
    -- Enterキーの処理
    vim.keymap.set('i', '<CR>', function()
      vim.api.nvim_del_augroup_by_id(group)
      if default_key then
        for _, option in ipairs(options) do
          if option[1] == default_key then
            close_and_callback(option)
            return
          end
        end
      end
      close_and_callback(nil)
    end, { buffer = buf, silent = true })
    
    -- ESCキーの処理
    vim.keymap.set('i', '<Esc>', function()
      vim.api.nvim_del_augroup_by_id(group)
      close_and_callback(nil)
    end, { buffer = buf, silent = true })
    
    -- ウィンドウが閉じられた時のクリーンアップ
    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(win),
      group = group,
      callback = function()
        vim.api.nvim_del_augroup_by_id(group)
      end
    })
  end
  
  -- 少し遅延してからInput modeセットアップ（ウィンドウが完全に表示されてから）
  vim.defer_fn(setup_input_handler, 10)
end

-- 言語選択UI（専用バッファモード版）
function M.show_language_selection(languages, prompt, callback)
  M.show_selection_buffer(languages, "💻 " .. prompt, "", callback)
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
    { "note", "📝 Note", "n" },
    { "warning", "⚠️ Warning", "s" },
    { "error", "❌ Error", "d" },
    { "info", "ℹ️ Info", "f" },
    { "tip", "💡 Tip", "g" },
    { "success", "✅ Success", "h" },
    { "question", "❓ Question", "j" },
    { "think", "🤔 Think", "t" },
    { "idea", "💡 Idea", "i" },
    { "ai", "🤖 AI", "a" },
    { "quote", "💬 Quote (タイトル付き)", "q" },
    { "blockquote", "📎 Blockquote (>のみ)", "b" },
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
    
    -- blockquoteの場合は特別処理（Calloutヘッダーなし、>のみ）
    if callout_type == "blockquote" then
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
      local callout_header
      if callout_type == "think" then
        callout_header = common_indent .. "> [!" .. callout_type .. "] #think"
      elseif callout_type == "idea" then
        callout_header = common_indent .. "> [!" .. callout_type .. "] #idea"
      elseif callout_type == "ai" then
        callout_header = common_indent .. "> [!" .. callout_type .. "] #ai"
      else
        callout_header = common_indent .. "> [!" .. callout_type .. "]"
      end
      table.insert(new_lines, callout_header)

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
    if callout_type == "blockquote" then
      vim.api.nvim_win_set_cursor(0, {start_row, #(common_indent .. "> ")})
    else
      vim.api.nvim_win_set_cursor(0, {start_row + 1, #(common_indent .. "> ")})
    end
  end)
end

-- Callout選択UI（専用バッファモード版）
function M.show_callout_selection(callout_types, prompt, callback)
  M.show_selection_buffer(callout_types, "🔟 " .. prompt, "quote", callback)
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
  
  -- チェックボックス関連のキーマップ（Normal & Visual mode対応）
  vim.keymap.set({'n', 'v'}, '<leader>x', M.toggle_as_task, 
    vim.tbl_extend('force', opts, { desc = "Toggle task checkbox (複数行対応)" }))
  
  -- 全進行中タスクを中止に変換（Normal mode）
  vim.keymap.set('n', '<leader>/', function()
    local timer = require('user-plugins.task-timer')
    timer.cancel_all_in_progress_tasks()
  end, vim.tbl_extend('force', opts, { desc = "Cancel all in-progress tasks [-] to [/]" }))
  
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
  elseif string.match(current_line, "^%s*[%*%-]%s*%[/%]") then
    print("Cancelled checkbox")
  elseif string.match(current_line, "^%s*[%*%-]%s") then
    print("List item")
  else
    print("Plain text")
  end
end

return M
