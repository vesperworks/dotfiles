-- ~/.config/nvim/lua/user-plugins/task-timer-display.lua
-- タスクタイマーのUI表示モジュール

local M = {}

-- 名前空間を作成
local ns_id = vim.api.nvim_create_namespace('task_timer')

-- 経過時間を人間が読みやすい形式に変換
function M.format_elapsed_time(start_time)
  local current_time = os.time()
  local elapsed = current_time - start_time
  
  -- 負の値をチェック（デバッグ用）
  if elapsed < 0 then
    return "(--)"
  end
  
  local hours = math.floor(elapsed / 3600)
  local minutes = math.floor((elapsed % 3600) / 60)
  local seconds = elapsed % 60
  
  -- デバッグ情報（一時的）
  -- vim.notify(string.format("DEBUG: elapsed=%d, hours=%d, minutes=%d, seconds=%d", elapsed, hours, minutes, seconds), vim.log.levels.DEBUG)
  
  if hours > 0 then
    return string.format("(%dh%dm)", hours, minutes)
  elseif minutes > 0 then
    return string.format("(%dm)", minutes)
  else
    -- 60秒未満は秒単位で表示
    return string.format("(%ds)", seconds)
  end
end

-- タスクIDを生成（ファイルパス + タスク内容の文字列ベース）
function M.generate_task_id(file_path, task_content)
  local file_name = vim.fn.fnamemodify(file_path, ":t")
  -- タスク内容を正規化（空白を統一、チェックボックス部分を除去）
  local normalized_content = task_content
    :gsub("%s+", " ")                    -- 連続空白を1つに
    :gsub("^%s*-%s*%[.-%]%s*", "")        -- チェックボックス部分を除去
    :gsub("^%s+", "")                    -- 先頭空白を除去
    :gsub("%s+$", "")                    -- 末尾空白を除去
  
  -- より精密なハッシュ生成
  local content_hash = vim.fn.sha256(normalized_content)
  return string.format("%s::%s", file_name, content_hash:sub(1, 12))
end

-- タスクを文字列で検索する新機能
function M.find_task_by_content(bufnr, target_task_id)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  
  -- 完全マッチを探す
  for line_num, line in ipairs(lines) do
    if line:match('-%s*%[>%]') then
      local current_task_id = M.generate_task_id(file_path, line)
      if current_task_id == target_task_id then
        return line_num, line
      end
    end
  end

  -- 完全マッチがない場合、部分マッチを試行
  local target_hash = target_task_id:match("::(.+)$")
  if target_hash then
    for line_num, line in ipairs(lines) do
      if line:match('-%s*%[>%]') then
        local current_task_id = M.generate_task_id(file_path, line)
        local current_hash = current_task_id:match("::(.+)$")
        -- ハッシュの前半が一致する場合（部分マッチ）
        if current_hash and target_hash:sub(1, 8) == current_hash:sub(1, 8) then
          return line_num, line
        end
      end
    end
  end
  
  return nil, nil -- 見つからない場合
end

-- 特定バッファの表示更新
function M.update_buffer_display(bufnr, active_timers)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  
  -- デバッグ情報（必要時のみ有効化）
  -- vim.notify(string.format("DEBUG: update_buffer_display bufnr=%d, active_timers_count=%d", bufnr, vim.tbl_count(active_timers)), vim.log.levels.DEBUG)
  
  -- 既存のvirtual textをクリア
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  if file_path == "" then
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  for line_num, line in ipairs(lines) do
    -- 実行中タスク（- [>]）を検出
    if line:match('-%s*%[>%]') then
      local task_id = M.generate_task_id(file_path, line)
      local timer_data = active_timers[task_id]
      
      if timer_data then
        local elapsed_text = M.format_elapsed_time(timer_data.start_time)
        
        -- Virtual textとして経過時間を表示（重複防止のためIDを設定）
        local mark_id = timer_data.start_time + line_num -- ユニークなID生成
        local success, err = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line_num - 1, -1, {
          id = mark_id,  -- 重複防止のためIDを設定
          virt_text = {{ elapsed_text, 'DiagnosticWarn' }},
          virt_text_pos = 'eol',
          ephemeral = false,  -- ファイル保存時に消えない
          invalidate = true,  -- キャッシュを無効化
          strict = false,     -- 柔軟な配置
          undo_restore = false, -- undo時に復元しない
          right_gravity = true  -- 右寄せで表示
        })
        
        if not success then
          -- エラーハンドリング（デバッグ用）
          -- vim.notify("Virtual text display error: " .. tostring(err), vim.log.levels.DEBUG)
        end
      end
    end
  end
end

-- 全てのMarkdownバッファの表示更新
function M.update_all_displays(active_timers)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == 'markdown' then
      M.update_buffer_display(bufnr, active_timers)
    end
  end
end

-- 特定のタスクのvirtual textをクリア
function M.clear_task_display(bufnr, line_number)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_number - 1, line_number)
  end
end

-- 全てのvirtual textをクリア
function M.clear_all_displays()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    end
  end
end

-- 🔒 swapファイル生成を避けるための直接ファイル読み込み用ヘルパー関数
function M.find_task_in_file_lines(file_lines, file_path, target_task_id)
  -- 完全マッチを探す
  for line_num, line in ipairs(file_lines) do
    if line:match('-%s*%[>%]') then
      local current_task_id = M.generate_task_id(file_path, line)
      if current_task_id == target_task_id then
        return true, line_num, line
      end
    end
  end

  -- 完全マッチがない場合、部分マッチを試行
  local target_hash = target_task_id:match("::(.+)$")
  if target_hash then
    for line_num, line in ipairs(file_lines) do
      if line:match('-%s*%[>%]') then
        local current_task_id = M.generate_task_id(file_path, line)
        local current_hash = current_task_id:match("::(.+)$")
        -- ハッシュの前半が一致する場合（部分マッチ）
        if current_hash and target_hash:sub(1, 8) == current_hash:sub(1, 8) then
          return true, line_num, line
        end
      end
    end
  end
  
  return false, nil, nil -- 見つからない場合
end

return M
