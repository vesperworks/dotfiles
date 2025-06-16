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

-- タスクIDを生成（ファイルパス + 行番号 + タスク内容のハッシュ）
function M.generate_task_id(file_path, line_number, task_content)
  local file_name = vim.fn.fnamemodify(file_path, ":t")
  -- gsub の戻り値を明示的に1つに制限
  local normalized_content = (task_content:gsub("%s+", " "))
  local content_hash = vim.fn.sha256(normalized_content)
  return string.format("%s:%d:%s", file_name, line_number, content_hash:sub(1, 8))
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
    -- 進行中タスク（- [-]）を検出
    if line:match('-%s*%[%-%]') then
      local task_id = M.generate_task_id(file_path, line_num, line)
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

return M
