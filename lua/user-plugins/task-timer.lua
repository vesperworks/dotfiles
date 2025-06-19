-- ~/.config/nvim/lua/user-plugins/task-timer.lua
-- タスクタイマーのメイン機能

local M = {}

-- 🔍 デバッグモードのオン/オフ
local debug_mode = false

function M.toggle_debug_mode()
  debug_mode = not debug_mode
  if debug_mode then
    vim.notify("🔍 デバッグモード ON", vim.log.levels.INFO)
  else
    vim.notify("🔍 デバッグモード OFF", vim.log.levels.INFO)
  end
end

-- デバッグログヘルパー関数
local function debug_log(message)
  if debug_mode then
    vim.notify(message, vim.log.levels.INFO)  -- DEBUGではなくINFOで表示
  end
end

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

-- タイマー開始（行番号除外版）
function M.start_timer(task_id, file_path, task_content)
  active_timers[task_id] = {
    start_time = os.time(),
    file_path = file_path,
    task_content = task_content
    -- line_number は削除（文字列ベースなので不要）
  }
  
  -- 🔒 安全な単一タイマー保存（マージ機能付き）
  storage.save_timer_safe(task_id, active_timers[task_id])
  
  -- 表示を更新
  local bufnr = vim.fn.bufnr(file_path)
  if bufnr ~= -1 then
    display.update_buffer_display(bufnr, active_timers)
  end
end

-- タイマー停止（安全版）
function M.stop_timer(task_id)
  if active_timers[task_id] then
    local timer_data = active_timers[task_id]
    local elapsed = os.time() - timer_data.start_time
    
    -- TODO: 完了時間ログを保存（将来の統計機能用）
    
    -- メモリからタイマーを削除
    active_timers[task_id] = nil
    
    -- 🔒 安全な単一タイマー削除（マージ機能付き）
    storage.remove_timer_safe(task_id)
    
    -- virtual textをクリア（バッファ全体を更新）
    local bufnr = vim.fn.bufnr(timer_data.file_path)
    if bufnr ~= -1 then
      display.update_buffer_display(bufnr, active_timers)
    end
  end
end

-- チェックボックス状態変更時のコールバック（文字列ベース修正版）
function M.on_checkbox_change(file_path, line_number, old_state, new_state, task_content)
  -- 新しい文字列ベースのタスクID生成
  local task_id = display.generate_task_id(file_path, task_content)
  
  -- デバッグ情報（必要時のみ有効化）
  -- vim.notify(string.format("DEBUG: on_checkbox_change task_id=%s, old='%s', new='%s'", task_id, old_state, new_state), vim.log.levels.DEBUG)
  
  if new_state == '-' then
    -- 進行中状態になった場合、タイマー開始
    M.start_timer(task_id, file_path, task_content)
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
  -- Neovim終了時にデータを保存（安全版）
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      -- 🔒 各アクティブタイマーを安全に保存
      for task_id, timer_data in pairs(active_timers) do
        storage.save_timer_safe(task_id, timer_data)
      end
      M.stop_update_loop()
    end,
  })
  
  -- バッファ切り替え時の表示更新（Markdownファイルのみ）
  vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "TabEnter"}, {
    callback = function()
      vim.schedule(function()
        local bufnr = vim.api.nvim_get_current_buf()
        -- Markdownファイルかどうかをチェック
        if vim.bo[bufnr].filetype == 'markdown' then
          display.update_buffer_display(bufnr, active_timers)
        end
      end)
    end,
  })
  
  -- ファイルタイプ変更時の表示更新
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      vim.schedule(function()
        local bufnr = vim.api.nvim_get_current_buf()
        display.update_buffer_display(bufnr, active_timers)
      end)
    end,
  })
  
  -- Insertモードから抜けた時にタイマー自動復元
  vim.api.nvim_create_autocmd("InsertLeave", {
    pattern = "*.md",
    callback = function()
      vim.schedule(function()
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].filetype == 'markdown' then
          M.auto_restore_timers(bufnr)
        end
      end)
    end,
  })
end

-- デバッグ用: 現在のアクティブタイマーを表示
function M.show_active_timers()
  if vim.tbl_isempty(active_timers) then
    vim.notify("📊 アクティブなタイマーはありません", vim.log.levels.INFO)
  else
    local messages = {"📊 アクティブなタイマー (" .. vim.tbl_count(active_timers) .. "個):"}
    for task_id, timer_data in pairs(active_timers) do
      local elapsed_text = display.format_elapsed_time(timer_data.start_time)
      local file_name = vim.fn.fnamemodify(timer_data.file_path, ":t")
      table.insert(messages, string.format("  • [%s] %s %s", file_name, timer_data.task_content:gsub("-.*%[.-%]", ""):gsub("^%s+", ""), elapsed_text))
    end
    vim.notify(table.concat(messages, "\n"), vim.log.levels.INFO)
  end
end

-- デバッグ用: 全タイマーを停止（安全版）
function M.stop_all_timers()
  local count = vim.tbl_count(active_timers)
  
  -- 🔒 各タイマーを安全に削除
  for task_id, _ in pairs(active_timers) do
    storage.remove_timer_safe(task_id)
  end
  
  -- メモリをクリア
  active_timers = {}
  display.clear_all_displays()
  vim.notify(string.format("📊 %d個のタイマーを停止しました", count), vim.log.levels.INFO)
end

-- 手動でタイマーをリセット
function M.reset_timer(task_id)
  if active_timers[task_id] then
    active_timers[task_id].start_time = os.time()
    storage.save_timers(active_timers)
    display.update_all_displays(active_timers)
    vim.notify("📊 タイマーをリセットしました", vim.log.levels.INFO)
  end
end

-- デバッグ用: ファイル内のタイマーを強制再スキャン
function M.rescan_current_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  
  if vim.bo[bufnr].filetype ~= 'markdown' then
    vim.notify("📊 Markdownファイルでのみ実行できます", vim.log.levels.WARN)
    return
  end
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found_tasks = 0
  local active_tasks = 0
  
  for line_num, line in ipairs(lines) do
    if line:match('-%s*%[%-%]') then
      local task_id = display.generate_task_id(file_path, line)
      found_tasks = found_tasks + 1
      
      if not active_timers[task_id] then
        -- タイマーがない進行中タスクを発見した場合、タイマーを開始
        M.start_timer(task_id, file_path, line)
        active_tasks = active_tasks + 1
      end
    end
  end
  
  -- 表示を更新
  display.update_buffer_display(bufnr, active_timers)
  
  vim.notify(string.format("📊 スキャン完了: %d個の進行中タスク発見, %d個のタイマーを新規開始", found_tasks, active_tasks), vim.log.levels.INFO)
end

-- 🔍 デバッグ用: タイマーデータの詳細比較
function M.debug_timer_comparison()
  local saved_timers = storage.load_timers()
  
  vim.notify("🔍 デバッグ: タイマーデータ比較", vim.log.levels.INFO)
  vim.notify(string.format("メモリ内: %d個", vim.tbl_count(active_timers)), vim.log.levels.INFO)
  vim.notify(string.format("保存済み: %d個", vim.tbl_count(saved_timers)), vim.log.levels.INFO)
  
  -- メモリ内のタイマー一覧
  vim.notify("\
=== メモリ内タイマー ===", vim.log.levels.INFO)
  for task_id, timer_data in pairs(active_timers) do
    local file_name = vim.fn.fnamemodify(timer_data.file_path, ":t")
    vim.notify(string.format("%s: [%s]", task_id:sub(1, 20), file_name), vim.log.levels.INFO)
  end
  
  -- 保存済みタイマー一覧
  vim.notify("\
=== 保存済みタイマー ===", vim.log.levels.INFO)
  for task_id, timer_data in pairs(saved_timers) do
    local file_name = vim.fn.fnamemodify(timer_data.file_path, ":t")
    vim.notify(string.format("%s: [%s]", task_id:sub(1, 20), file_name), vim.log.levels.INFO)
  end
end

-- 🔍 デバッグ用: JSONファイルの生データを表示
function M.show_raw_timer_data()
  local data_path = storage.get_data_file_path()
  
  vim.notify(string.format("🔍 JSONファイルパス: %s", data_path), vim.log.levels.INFO)
  
  -- ファイルが存在するかチェック
  if not storage.data_file_exists() then
    vim.notify("⚠️ JSONファイルが存在しません", vim.log.levels.WARN)
    return
  end
  
  -- ファイルを直接読み込み
  local file = io.open(data_path, 'r')
  if not file then
    vim.notify("❌ JSONファイルの読み込みに失敗", vim.log.levels.ERROR)
    return
  end
  
  local raw_content = file:read('*all')
  file:close()
  
  vim.notify("🔍 生JSONデータ:", vim.log.levels.INFO)
  vim.notify(raw_content, vim.log.levels.INFO)
  
  -- JSONをパースして構造化表示
  local success, parsed_data = pcall(vim.json.decode, raw_content)
  if success and parsed_data then
    local timer_count = vim.tbl_count(parsed_data)
    vim.notify(string.format("\n🔍 パース結果: %d個のタイマー", timer_count), vim.log.levels.INFO)
    
    local index = 1
    for task_id, timer_data in pairs(parsed_data) do
      vim.notify(string.format("\n[%d] タスクID: %s", index, task_id:sub(1, 30)), vim.log.levels.INFO)
      vim.notify(string.format("    ファイルパス: %s", timer_data.file_path), vim.log.levels.INFO)
      vim.notify(string.format("    開始時刻: %d", timer_data.start_time), vim.log.levels.INFO)
      vim.notify(string.format("    タスク内容: %s", timer_data.task_content:sub(1, 60)), vim.log.levels.INFO)
      index = index + 1
    end
  else
    vim.notify("❌ JSONパースに失敗", vim.log.levels.ERROR)
  end
end

-- 🗑️ デバッグ用: 保存済みタイマーデータをクリア（安全版）
function M.clear_saved_timers()
  local saved_timers = storage.load_timers()
  local count = vim.tbl_count(saved_timers)
  
  -- 🔒 各タイマーを安全に削除
  for task_id, _ in pairs(saved_timers) do
    storage.remove_timer_safe(task_id)
  end
  
  -- メモリ内もクリア
  active_timers = {}
  
  -- 表示をクリア
  display.clear_all_displays()
  
  vim.notify(string.format("🗑️ %d個の保存済みタイマーをクリアしました", count), vim.log.levels.INFO)
end

function M.show_timer_data_info()
  local data_path = storage.get_data_file_path()
  local exists = storage.data_file_exists()
  local timers = storage.load_timers()
  local stats = storage.get_storage_stats()  -- 🆕 新しい統計機能を使用
  
  local info = {
    "📊 タイマーデータ情報:",
    "ファイルパス: " .. data_path,
    "ファイル存在: " .. (exists and "あり" or "なし"),
    "保存済みタイマー: " .. stats.total_timers .. "個",
    "メモリ内タイマー: " .. vim.tbl_count(active_timers) .. "個",
    "バックアップ: " .. (stats.backup_exists and "あり" or "なし"),
  }
  
  -- ファイル別統計を追加
  if stats.total_timers > 0 then
    table.insert(info, "\n📁 ファイル別タイマー数:")
    for file_path, count in pairs(stats.file_count) do
      local file_name = vim.fn.fnamemodify(file_path, ":t")
      table.insert(info, string.format("  • %s: %d個", file_name, count))
    end
  end
  
  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
end

-- 🎯 新機能: アクティブタイマー選択ジャンプ（改良版）
function M.jump_to_active_timer()
  -- デバッグ: 関数開始ログ（現在ファイル情報付き）
  local current_file = vim.api.nvim_buf_get_name(0)
  debug_log("🔍 jump_to_active_timer() 開始")
  debug_log(string.format("🔍   → 現在ファイル: %s", vim.fn.fnamemodify(current_file, ":t")))
  debug_log(string.format("🔍   → 現在フルパス: %s", current_file))
  
  if vim.tbl_isempty(active_timers) then
    vim.notify("📊 アクティブなタイマーはありません", vim.log.levels.WARN)
    return
  end
  
  -- デバッグ: タイマー数確認
  local timer_count = vim.tbl_count(active_timers)
  debug_log(string.format("🔍 アクティブタイマー数: %d個", timer_count))
  
  -- タイマー選択肢を作成
  local timer_options = {}
  local timer_data_map = {}
  
  for task_id, timer_data in pairs(active_timers) do
    local elapsed_text = display.format_elapsed_time(timer_data.start_time)
    local file_name = vim.fn.fnamemodify(timer_data.file_path, ":t")
    local task_preview = timer_data.task_content:gsub("-.*%[.-%]", ""):gsub("^%s+", "")
    
    -- タスクプレビューを短縮（文字化け修正版）
    if vim.fn.strchars(task_preview) > 40 then
      task_preview = vim.fn.strpart(task_preview, 0, vim.fn.byteidx(task_preview, 37)) .. "..."
    end
    
    -- ユーザーに表示する選択肢テキスト（line_number除外版）
    local display_text = string.format("%s %s [%s]", elapsed_text, task_preview, file_name)
    
    table.insert(timer_options, display_text)
    timer_data_map[display_text] = timer_data
    
    -- デバッグ: 各タイマー情報（ファイルパス付き）
    debug_log(string.format("🔍 タイマー追加: %s", display_text))
    debug_log(string.format("🔍   → フルパス: %s", timer_data.file_path))
    debug_log(string.format("🔍   → タスクID: %s", task_id:sub(1, 30)))
  end
  
  -- デバッグ: 選択肢数確認
  debug_log(string.format("🔍 選択肢数: %d個", #timer_options))
  
  -- 独自の選択UIを表示
  M.show_timer_selection(timer_options, timer_data_map)
  
  -- デバッグ: 関数終了ログ
  debug_log("🔍 jump_to_active_timer() 終了")
end

-- 独自のタイマー選択UI（asdfghjklキーで選択）
function M.show_timer_selection(timer_options, timer_data_map)
  -- デバッグ: 関数開始ログ
  debug_log(string.format("🔍 show_timer_selection() 開始 - オプション数: %d", #timer_options))
  
  -- 選択キー（最大9個まで表示）
  local selection_keys = { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l' }
  
  -- 表示する項目数を制限（9個まで）
  local display_count = math.min(#timer_options, #selection_keys)
  
  -- デバッグ: 表示数確認
  debug_log(string.format("🔍 表示予定数: %d個", display_count))
  
  -- 選択肢を構築
  local display_lines = { "🎯 稼働中タイマーにジャンプ:" }
  local key_to_option = {}
  
  for i = 1, display_count do
    local key = selection_keys[i]
    local option = timer_options[i]
    table.insert(display_lines, string.format("%s: %s", key, option))
    key_to_option[key] = option
    
    -- デバッグ: 各選択肢（ファイルパス付き）
    local timer_data = timer_data_map[option]
    debug_log(string.format("🔍 %s: %s", key, option))
    debug_log(string.format("🔍   → フルパス: %s", timer_data.file_path))
  end
  
  -- 残りの項目がある場合は通知
  if #timer_options > display_count then
    table.insert(display_lines, string.format("... 他 %d個のタイマー", #timer_options - display_count))
  end
  
  table.insert(display_lines, "Esc: キャンセル")
  
  -- デバッグ: 表示内容
  debug_log(string.format("🔍 表示行数: %d行", #display_lines))
  
  -- 選択肢を表示
  vim.notify(table.concat(display_lines, "\n"), vim.log.levels.INFO)
  
  -- デバッグ: キー入力待機中
  debug_log("🔍 キー入力待機中...")
  
  -- キー入力を待機
  local char = vim.fn.getchar()
  
  -- ESCキーでキャンセル
  if char == 27 then
    vim.notify("キャンセルしました", vim.log.levels.INFO)
    return
  end
  
  -- 入力された文字を取得
  local input_key = vim.fn.nr2char(char)
  
  -- 選択されたオプションを取得
  local selected_option = key_to_option[input_key]
  if selected_option then
    local selected_timer = timer_data_map[selected_option]
    if selected_timer then
      -- 文字列ベースのジャンプ機能を使用
      local task_id = display.generate_task_id(selected_timer.file_path, selected_timer.task_content)
      M.jump_to_file_and_line_by_content(selected_timer.file_path, task_id)
    end
  else
    vim.notify("無効なキーです", vim.log.levels.WARN)
  end
end

-- 改良されたジャンプ機能（文字列検索ベース）
function M.jump_to_file_and_line_by_content(file_path, task_id)
  -- ファイルが存在するかチェック
  if vim.fn.filereadable(file_path) == 0 then
    vim.notify(string.format("⚠️ ファイルが見つかりません: %s", file_path), vim.log.levels.ERROR)
    return
  end
  
  -- 未保存の変更があるかチェック
  if vim.bo.modified then
    -- ユーザーに確認を求める（s、d、cキー対応）
    local choice = vim.fn.confirm(
      "未保存の変更があります。どうしますか？", 
      "&s: 保存してジャンプ\n&d: 保存せずにジャンプ\n&c: キャンセル", 
      1
    )
    
    if choice == 1 then
      -- 保存してジャンプ
      vim.cmd('write')
    elseif choice == 3 then
      -- キャンセル
      vim.notify("ジャンプをキャンセルしました", vim.log.levels.INFO)
      return
    end
    -- choice == 2 なら保存せずに続行
  end
  
  -- ファイルを開く
  vim.cmd('edit! ' .. vim.fn.fnameescape(file_path))
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- 文字列ベースでタスクを検索
  local line_number, found_line = display.find_task_by_content(bufnr, task_id)
  
  if line_number then
    -- タスクが見つかった場合
    vim.api.nvim_win_set_cursor(0, {line_number, 0})
    vim.cmd('normal! zz')  -- 画面中央にスクロール
    
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    vim.notify(string.format("🎯 %s:%d にジャンプしました", file_name, line_number), vim.log.levels.INFO)
  else
    -- タスクが見つからない場合
    vim.notify("⚠️ 該当するタスクが見つかりません（内容が変更された可能性があります）", vim.log.levels.WARN)
    
    -- タスク内容の一部を表示してヒントを提供
    local timer_data = active_timers[task_id]
    if timer_data then
      local preview = timer_data.task_content:gsub("-.*%[.-%]", ""):gsub("^%s+", "")
      vim.notify(string.format("探していたタスク: %s", preview:sub(1, 50)), vim.log.levels.INFO)
    end
  end
end

-- Insertモードから抜けた時のタイマー自動復元（デバッグ版）
function M.auto_restore_timers(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  if file_path == "" then return end
  
  -- デバッグ: 自動復元開始
  debug_log(string.format("🔍 auto_restore_timers() 開始 - ファイル: %s", vim.fn.fnamemodify(file_path, ":t")))
  debug_log(string.format("🔍 復元前アクティブタイマー数: %d個", vim.tbl_count(active_timers)))
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local restored_count = 0
  local new_timer_count = 0
  
  for line_num, line in ipairs(lines) do
    -- 進行中タスクを検出
    if line:match('-%s*%[%-%]') then
      local task_id = display.generate_task_id(file_path, line)
      
      -- デバッグ: 進行中タスク発見（ファイルパス付き）
      debug_log(string.format("🔍 進行中タスク発見: %d行目 - %s", line_num, task_id:sub(1, 20)))
      debug_log(string.format("🔍   → ファイル: %s", vim.fn.fnamemodify(file_path, ":t")))
      debug_log(string.format("🔍   → フルパス: %s", file_path))
      
      -- メモリ内にタイマーがない場合、保存済みデータから復元を試みる
      if not active_timers[task_id] then
        local saved_timers = storage.load_timers()
        if saved_timers[task_id] then
          -- 保存済みタイマーを復元
          active_timers[task_id] = saved_timers[task_id]
          restored_count = restored_count + 1
          debug_log(string.format("🔍 保存済みタイマー復元: %s", task_id:sub(1, 20)))
        else
          -- 新規タイマーを開始
          M.start_timer(task_id, file_path, line)
          new_timer_count = new_timer_count + 1
          debug_log(string.format("🔍 新規タイマー開始: %s", task_id:sub(1, 20)))
        end
      else
        debug_log(string.format("🔍 既存タイマー: %s", task_id:sub(1, 20)))
      end
    end
  end
  
  -- デバッグ: 結果ログ
  debug_log(string.format("🔍 復元後アクティブタイマー数: %d個", vim.tbl_count(active_timers)))
  debug_log(string.format("🔍 復元数: %d個, 新規: %d個", restored_count, new_timer_count))
  
  -- 表示を更新
  if restored_count > 0 or new_timer_count > 0 then
    display.update_buffer_display(bufnr, active_timers)
    -- サイレントに復元（通知はオプション）
    -- vim.notify(string.format("📊 %d個のタイマーを自動復元しました", restored_count), vim.log.levels.INFO)
  end
end

return M
