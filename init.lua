vim.g.mapleader = " "
vim.g.maplocalleader = " "

if vim.g.vscode then
  require("vscode-config")
  return
end

require("config.lazy")
require("config.options")
require("config.autocmds")
require("config.keymaps")

-- User plugins（lazy.nvim 管理外の自作モジュール初期化）
require('user-plugins.markdown-helper').setup_keymaps()

local ok_pending, pending_tasks = pcall(require, 'user-plugins.pending-tasks')
if ok_pending then
  pending_tasks.setup()
end

local ok_heading, heading_jump = pcall(require, 'user-plugins.heading-jump')
if ok_heading then
  heading_jump.setup()
end

local ok_hover, hover_preview = pcall(require, 'user-plugins.obsidian-hover-preview')
if ok_hover then
  hover_preview.setup({
    delay = 500,
    max_height = 15,
    preview_lines = 50,
  })
end

local ok_zoom, markdown_zoom = pcall(require, 'user-plugins.markdown-zoom')
if ok_zoom then
  markdown_zoom.setup()
end

local ok_countdown, markdown_countdown = pcall(require, 'user-plugins.markdown-countdown')
if ok_countdown then
  markdown_countdown.setup()
end

local ok_move, move_to_heading = pcall(require, 'user-plugins.move-to-heading')
if ok_move then
  move_to_heading.setup_keymaps()
end

local ok, task_timer = pcall(require, 'user-plugins.task-timer')
if ok then
  task_timer.setup()

  vim.keymap.set('n', '<leader>Ta', function() task_timer.show_active_timers() end,
    { desc = "📊 アクティブタイマー表示", silent = true })
  vim.keymap.set('n', '<leader>Tq', function() task_timer.stop_all_timers() end,
    { desc = "📊 全タイマー停止", silent = true })
  vim.keymap.set('n', '<leader>Ts', function() task_timer.rescan_current_buffer() end,
    { desc = "📊 タイマー再スキャン", silent = true })
  vim.keymap.set('n', '<leader>Ti', function() task_timer.show_timer_data_info() end,
    { desc = "📊 タイマーデータ情報", silent = true })
  vim.keymap.set('n', '<leader>Td', function() task_timer.debug_timer_comparison() end,
    { desc = "🔍 タイマーデバッグ", silent = true })
  vim.keymap.set('n', '<leader>Tc', function() task_timer.clear_saved_timers() end,
    { desc = "🗑️ タイマーデータクリア", silent = true })
  vim.keymap.set('n', '<leader>Tr', function() task_timer.show_raw_timer_data() end,
    { desc = "📄 タイマーJSONデータ表示", silent = true })
  vim.keymap.set('n', '<leader>Tb', function()
    local stats = require('user-plugins.task-timer-storage').get_storage_stats()
    local backup_status = stats.backup_exists and "💾 あり" or "❌ なし"
    vim.notify(string.format("📋 ストレージ統計:\n総タイマー数: %d個\nバックアップ: %s", stats.total_timers, backup_status), vim.log.levels.INFO)
  end, { desc = "📋 ストレージ統計", silent = true })
  vim.keymap.set('n', '<leader>t', function() task_timer.jump_to_active_timer() end,
    { desc = "🎯 稼働中タイマーにジャンプ", silent = true })
end
