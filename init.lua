vim.g.mapleader = " "          -- <- Space をリーダーに
vim.g.maplocalleader = " "     -- VSCode統合でも統一

if vim.g.vscode then
  require("vscode-config")
  return
end

-- 起動時 lazy.nvim を読み込む
require("config.lazy")

-- filetype plugin を確実に有効化
vim.cmd('filetype plugin on')

vim.o.conceallevel = 2
vim.o.confirm = false


vim.cmd [[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
]]

-- タスクチェックボックスのハイライト設定
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- 未完了タスク: 通常の文字色
    vim.api.nvim_set_hl(0, "TaskTodo", { fg = "#ffffff" })
    -- 実行中タスク: 指定の明るいオレンジ色
    vim.api.nvim_set_hl(0, "TaskInProgress", { fg = "#F5CA81" })  -- 指定のオレンジ色
    -- 完了タスク: 暗い文字色 + ストライクスルー
    vim.api.nvim_set_hl(0, "TaskCompleted", { fg = "#6b7280", strikethrough = true })
    -- キャンセルタスク: 明るい赤色（2段階アップ）、ストライクスルーなし
    vim.api.nvim_set_hl(0, "TaskCancelled", { fg = "#f87171" })  -- 明るい赤色
    
    -- マッチングルールを設定
    vim.fn.matchadd("TaskTodo", "^\\s*[-*]\\s*\\[ \\].*$")
    vim.fn.matchadd("TaskInProgress", "^\\s*[-*]\\s*\\[-\\].*$")
    vim.fn.matchadd("TaskCompleted", "^\\s*[-*]\\s*\\[x\\].*$")
    vim.fn.matchadd("TaskCancelled", "^\\s*[-*]\\s*\\[/\\].*$")
  end,
})

-- Markdownファイルだけに反映（おすすめ）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- ① まず不要な 't' を確実に外しておく
    vim.opt_local.formatoptions:remove("t")

    -- ② リスト継続に必要な 'o','r','n' をまとめて追加
    vim.opt_local.formatoptions:append("orn")

    -- もし自動折り返しも欲しいなら（行が割れて良いなら）こちら
    -- vim.opt_local.formatoptions:append("tor n")  -- ← t も入れる
  end,
})

vim.keymap.set({ "n", "v" }, "L", "$", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "H", "^", { noremap = true, silent = true })

-- システムクリップボードにyank
vim.opt.clipboard:append("unnamedplus")
-- 次の飛び先も記録
vim.opt.jumpoptions:append("stack")

-- User plugins (markdown helper, obsidian zoom etc.)
require('user-plugins.markdown-helper').setup_keymaps()
require('user-plugins.obsidian-zoom-v2')

-- タスクタイマーシステムを初期化
local ok, task_timer = pcall(require, 'user-plugins.task-timer')
if ok then
  task_timer.setup()
  
  -- タイマー関連キーマップ（競合回避のため<leader>T*を使用）
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
  vim.keymap.set('n', '<leader>TD', function() task_timer.toggle_debug_mode() end, 
    { desc = "🔍 デバッグモード切替", silent = true })
  vim.keymap.set('n', '<leader>Tr', function() task_timer.show_raw_timer_data() end, 
    { desc = "📄 タイマーJSONデータ表示", silent = true })
  vim.keymap.set('n', '<leader>Tb', function() 
    local stats = require('user-plugins.task-timer-storage').get_storage_stats()
    local backup_status = stats.backup_exists and "💾 あり" or "❌ なし"
    vim.notify(string.format("📋 ストレージ統計:\n総タイマー数: %d個\nバックアップ: %s", stats.total_timers, backup_status), vim.log.levels.INFO)
  end, { desc = "📋 ストレージ統計", silent = true })
vim.keymap.set('n', '<leader>j', function() task_timer.jump_to_active_timer() end, 
    { desc = "🎯 稼働中タイマーにジャンプ", silent = true })
end

-- Move the current visual selection to the end of the file in native Neovim
vim.keymap.set("v", "<leader>m", ":move $<CR>gv=gv", { desc = "Move selection to end", silent = true })

-- Cmd+S で保存
vim.keymap.set('n', '<C-s>', ':w<CR>', { desc = "ファイル保存", silent = true })
vim.keymap.set('i', '<leader>s', '<Esc>:w<CR>a', { desc = "ファイル保存（挿入モード）", silent = true })
vim.keymap.set('v', '<leader>s', '<Esc>:w<CR>gv', { desc = "ファイル保存（ビジュアルモード）", silent = true })
