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

-- vw.* シリーズ初期化（個別 require + setup）
require('vw.checkbox').setup()
require('vw.callout').setup()
require('vw.list').setup()
require('vw.extract').setup()
require('vw.header').setup()
require('vw.migemo').setup()
require('vw.typewriter').setup()

local ok_fold, vw_fold = pcall(require, 'vw.fold')
if ok_fold then vw_fold.setup() end

local ok_countdown, vw_countdown = pcall(require, 'vw.countdown')
if ok_countdown then vw_countdown.setup() end

local ok_heading, vw_heading = pcall(require, 'vw.heading')
if ok_heading then vw_heading.setup() end

local ok_hover, vw_hover = pcall(require, 'vw.hover')
if ok_hover then
  vw_hover.setup({ delay = 500, max_height = 15, preview_lines = 50 })
end

local ok_timer, vw_timer = pcall(require, 'vw.timer')
if ok_timer then
  vw_timer.setup()

  vim.keymap.set('n', '<leader>Ta', function() vw_timer.show_active_timers() end,
    { desc = "📊 アクティブタイマー表示", silent = true })
  vim.keymap.set('n', '<leader>Tq', function() vw_timer.stop_all_timers() end,
    { desc = "📊 全タイマー停止", silent = true })
  vim.keymap.set('n', '<leader>Ts', function() vw_timer.rescan_current_buffer() end,
    { desc = "📊 タイマー再スキャン", silent = true })
  vim.keymap.set('n', '<leader>Ti', function() vw_timer.show_timer_data_info() end,
    { desc = "📊 タイマーデータ情報", silent = true })
  vim.keymap.set('n', '<leader>Td', function() vw_timer.debug_timer_comparison() end,
    { desc = "🔍 タイマーデバッグ", silent = true })
  vim.keymap.set('n', '<leader>Tc', function() vw_timer.clear_saved_timers() end,
    { desc = "🗑️ タイマーデータクリア", silent = true })
  vim.keymap.set('n', '<leader>Tr', function() vw_timer.show_raw_timer_data() end,
    { desc = "📄 タイマーJSONデータ表示", silent = true })
  vim.keymap.set('n', '<leader>Tb', function()
    local stats = require('vw.timer.storage').get_storage_stats()
    local backup_status = stats.backup_exists and "💾 あり" or "❌ なし"
    vim.notify(string.format("📋 ストレージ統計:\n総タイマー数: %d個\nバックアップ: %s", stats.total_timers, backup_status), vim.log.levels.INFO)
  end, { desc = "📋 ストレージ統計", silent = true })
  vim.keymap.set('n', '<leader>t', function() vw_timer.jump_to_active_timer() end,
    { desc = "🎯 稼働中タイマーにジャンプ", silent = true })
end

local ok_tasks, vw_tasks = pcall(require, 'vw.tasks')
if ok_tasks then vw_tasks.setup() end

local ok_qmd, vw_qmd = pcall(require, 'vw.qmd')
if ok_qmd then vw_qmd.setup() end

-- 全進行中タスク中止（timer 依存のため init.lua で定義）
vim.keymap.set('n', '<leader>/', function()
  local ok, timer = pcall(require, 'vw.timer')
  if ok then timer.cancel_all_in_progress_tasks() end
end, { noremap = true, silent = true, desc = "Cancel all in-progress tasks [>] to [/]" })
