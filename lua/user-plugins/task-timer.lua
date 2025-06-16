-- ~/.config/nvim/lua/user-plugins/task-timer.lua
-- タスクタイマーのメイン機能

local M = {}

local storage = require('user-plugins.task-timer-storage')
local display = require('user-plugins.task-timer-display')

-- グローバル状態
local active_timers = {}
local update_timer = nil

-- 初期化
function M.setup()
  -- 保存されたタイマーデータを読み込み
  active_timers = storage.load_timers()
  
  -- 更新ループを開始
  M.start_update_loop()
  
  -- autocmdを設定
  M.setup_autocmds()
  
  -- 初回表示更新
  display.update_all_displays(active_timers)
end

-- タイマー開始
function M.start_timer(task_id, file_path, line_number, task_content)
  active_timers[task_id] = {
    start_time = os.time(),
    file_path = file_path,
    line_number = line_number,
    task_content = task_content
  }
  
  -- データを保存
  storage.save_timers(active_timers)
  
  -- 表示を更新
  local bufnr = vim.fn.bufnr(file_path)
  if bufnr ~= -1 then
    display.update_buffer_display(bufnr, active_timers)
  end
end

-- タイマー停止
function M.stop_timer(task_id)
  if active_timers[task_id] then
    local timer_data = active_timers[task_id]
    local elapsed = os.time() - timer_data.start_time
    
    -- TODO: 完了時間ログを保存（将来の統計機能用）
    
    -- タイマーを削除
    active_timers[task_id] = nil
    storage.save_timers(active_timers)
    
    -- virtual textをクリア
    local bufnr = vim.fn.bufnr(timer_data.file_path)
    if bufnr ~= -1 then
      display.clear_task_display(bufnr, timer_data.line_number)
    end
  end
end

-- チェックボックス状態変更時のコールバック
function M.on_checkbox_change(file_path, line_number, old_state, new_state, task_content)
  local task_id = display.generate_task_id(file_path, line_number, task_content)
  
  if new_state == '-' then
    -- 進行中状態になった場合、タイマー開始
    M.start_timer(task_id, file_path, line_number, task_content)
  elseif old_state == '-' and new_state ~= '-' then
    -- 進行中状態から他の状態に変わった場合、タイマー停止
    M.stop_timer(task_id)
  end
end

-- 更新ループ開始（1秒間隔）
function M.start_update_loop()
  if update_timer then
    update_timer:stop()
  end
  
  update_timer = vim.loop.new_timer()
  update_timer:start(0, 1000, vim.schedule_wrap(function()
    display.update_all_displays(active_timers)
  end))
end

-- 更新ループ停止
function M.stop_update_loop()
  if update_timer then
    update_timer:stop()
    update_timer = nil
  end
end

-- autocmdを設定
function M.setup_autocmds()
  -- Neovim終了時にデータを保存
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      storage.save_timers(active_timers)
      M.stop_update_loop()
    end,
  })
  
  -- Markdownバッファが開かれた時に表示を更新
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.md",
    callback = function()
      vim.schedule(function()
        local bufnr = vim.api.nvim_get_current_buf()
        display.update_buffer_display(bufnr, active_timers)
      end)
    end,
  })
end

-- デバッグ用: 現在のアクティブタイマーを表示
function M.show_active_timers()
  if vim.tbl_isempty(active_timers) then
    vim.notify("アクティブなタイマーはありません", vim.log.levels.INFO)
  else
    local messages = {"アクティブなタイマー:"}
    for task_id, timer_data in pairs(active_timers) do
      local elapsed_text = display.format_elapsed_time(timer_data.start_time)
      table.insert(messages, string.format("- %s %s", timer_data.task_content, elapsed_text))
    end
    vim.notify(table.concat(messages, "\n"), vim.log.levels.INFO)
  end
end

-- デバッグ用: 全タイマーを停止
function M.stop_all_timers()
  active_timers = {}
  storage.save_timers(active_timers)
  display.clear_all_displays()
  vim.notify("全てのタイマーを停止しました", vim.log.levels.INFO)
end

-- 手動でタイマーをリセット
function M.reset_timer(task_id)
  if active_timers[task_id] then
    active_timers[task_id].start_time = os.time()
    storage.save_timers(active_timers)
    display.update_all_displays(active_timers)
    vim.notify("タイマーをリセットしました", vim.log.levels.INFO)
  end
end

return M
