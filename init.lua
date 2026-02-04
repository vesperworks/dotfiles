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

-- Markdownファイルだけに反映（おすすめ）
-- ※タスクステータスのハイライトはrender-markdown.luaに移動済み
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

-- Escで検索ハイライトをクリア
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true })

-- システムクリップボードにyank
vim.opt.clipboard:append("unnamedplus")
-- 次の飛び先も記録
vim.opt.jumpoptions:append("stack")

-- User plugins (markdown helper etc.)
require('user-plugins.markdown-helper').setup_keymaps()

-- 進行中タスク表示プラグイン
local ok_pending, pending_tasks = pcall(require, 'user-plugins.pending-tasks')
if ok_pending then
  pending_tasks.setup()
end

-- 見出しジャンプ表示プラグイン
local ok_heading, heading_jump = pcall(require, 'user-plugins.heading-jump')
if ok_heading then
  heading_jump.setup()
end

-- Obsidianリンクホバープレビュー
local ok_hover, hover_preview = pcall(require, 'user-plugins.obsidian-hover-preview')
if ok_hover then
  hover_preview.setup({
    delay = 500,
    max_height = 15,
    preview_lines = 50,
  })
end

-- Markdown見出しzoom
local ok_zoom, markdown_zoom = pcall(require, 'user-plugins.markdown-zoom')
if ok_zoom then
  markdown_zoom.setup()
end

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
vim.keymap.set('n', '<leader>t', function() task_timer.jump_to_active_timer() end, 
    { desc = "🎯 稼働中タイマーにジャンプ", silent = true })
end

-- Move selection to heading (generic function)
-- to_bottom: if true, move to bottom of section; if false, move right after heading
local function move_selection_to_heading(pattern, to_bottom)
  local v_start = vim.fn.line("v")
  local v_end = vim.fn.line(".")
  if v_start > v_end then
    v_start, v_end = v_end, v_start
  end
  local line_count = v_end - v_start + 1

  -- Search for target heading
  local target_line = nil
  for i = 1, vim.fn.line('$') do
    local line = vim.fn.getline(i)
    if line:match(pattern) then
      target_line = i
      break
    end
  end

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  local dest
  if target_line then
    if to_bottom then
      -- Find next heading or end of file
      local next_heading = nil
      for i = target_line + 1, vim.fn.line('$') do
        if vim.fn.getline(i):match("^#+ ") then
          next_heading = i
          break
        end
      end
      dest = (next_heading and next_heading - 1) or vim.fn.line('$')
    else
      dest = target_line  -- Right after the heading
    end
  else
    dest = 0
  end

  -- Move selection
  vim.cmd(string.format(":%d,%dmove %d", v_start, v_end, dest))

  -- Add blank line before moved content
  local new_start = dest + 1
  vim.fn.append(new_start - 1, "")

  -- Re-select and fix indentation
  local new_end = new_start + line_count
  vim.cmd(string.format("normal! %dGV%dG=", new_start + 1, new_end))

  -- Return cursor to original position (one line above)
  local return_line
  if dest >= v_end then
    -- Moved down: original line numbers unchanged
    return_line = v_start - 1
  else
    -- Moved up: original position shifted down
    return_line = v_start - 1 + line_count + 1
  end
  if return_line < 1 then return_line = 1 end
  vim.api.nvim_win_set_cursor(0, {return_line, 0})
end

-- Move selection keymaps
vim.keymap.set("v", "<leader>mn", function() move_selection_to_heading("^# NEXT", false) end, { desc = "Move to # NEXT", silent = true })
vim.keymap.set("v", "<leader>mw", function() move_selection_to_heading("^## WANTS", false) end, { desc = "Move to ## WANTS", silent = true })
vim.keymap.set("v", "<leader>md", function() move_selection_to_heading("^# DONE", true) end, { desc = "Move to # DONE (bottom)", silent = true })
vim.keymap.set("v", "<leader>ms", function() move_selection_to_heading("^## SHOULD", false) end, { desc = "Move to ## SHOULD", silent = true })
vim.keymap.set("v", "<leader>mm", function() move_selection_to_heading("^## MUST", false) end, { desc = "Move to ## MUST", silent = true })
vim.keymap.set("v", "<leader>mb", function() move_selection_to_heading("^# BACKLOG", false) end, { desc = "Move to # BACKLOG", silent = true })
vim.keymap.set("v", "<leader>mi", function() move_selection_to_heading("^# WIP", false) end, { desc = "Move to # WIP", silent = true })

-- Cmd+S で保存
vim.keymap.set('n', '<C-s>', ':w<CR>', { desc = "ファイル保存", silent = true })
vim.keymap.set('i', '<leader>s', '<Esc>:w<CR>a', { desc = "ファイル保存（挿入モード）", silent = true })
vim.keymap.set('v', '<leader>s', '<Esc>:w<CR>gv', { desc = "ファイル保存（ビジュアルモード）", silent = true })

-- Cmd+V ペースト（Bracketed Paste回避）
-- AlacrittyからCSI u形式で送信されたCtrl+Shift+Vをペーストに変換
vim.keymap.set('n', '<C-S-v>', '"+p', { noremap = true, silent = true, desc = "システムクリップボードからペースト" })
vim.keymap.set('i', '<C-S-v>', '<C-r><C-p>+', { noremap = true, silent = true, desc = "システムクリップボードからペースト" })
vim.keymap.set('c', '<C-S-v>', '<C-r>+', { noremap = true, silent = true, desc = "システムクリップボードからペースト" })
vim.keymap.set('v', '<C-S-v>', '"+p', { noremap = true, silent = true, desc = "システムクリップボードからペースト" })

-- Emacs風キーバインド（インサート/コマンドラインモード）
vim.keymap.set('i', '<C-a>', '<Home>', { desc = "行頭へ移動" })
vim.keymap.set('i', '<C-e>', '<End>', { desc = "行末へ移動" })
vim.keymap.set('c', '<C-a>', '<Home>', { desc = "行頭へ移動" })
vim.keymap.set('c', '<C-e>', '<End>', { desc = "行末へ移動" })
vim.keymap.set('i', '<C-k>', '<C-o>D', { desc = "行末まで削除" })

-- Raycast File Search: 現在のファイルをRaycastで開く
vim.keymap.set('n', '<leader>ro', function()
  local path = vim.fn.expand('%:p')
  if path == '' then
    vim.notify('No file open', vim.log.levels.WARN)
    return
  end
  -- URLエンコード
  local encoded = path:gsub(' ', '%%20'):gsub('#', '%%23')
  vim.fn.system('open "raycast://extensions/raycast/file-search/search-files?fallbackText=' .. encoded .. '"')
end, { desc = 'Open in Raycast' })

-- ファイルパスをクリップボードにコピー
vim.keymap.set('n', '<leader>cp', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path, vim.log.levels.INFO)
end, { desc = 'Copy full path' })
