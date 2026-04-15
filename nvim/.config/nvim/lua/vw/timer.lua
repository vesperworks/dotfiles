-- lua/vw/timer.lua
-- タスクタイマーのメイン機能

local M = {}

local storage = require('vw.timer.storage')
local display = require('vw.timer.display')

-- グローバル状態
local active_timers = {}
local update_timer = nil

--- アクティブタイマーを公開API経由で取得
function M.get_active_timers()
  return active_timers
end

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
  if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
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
    if bufnr ~= -1 and vim.api.nvim_buf_is_valid(bufnr) then
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

  if new_state == '>' then
    -- 実行中状態になった場合、タイマー開始
    M.start_timer(task_id, file_path, task_content)
  elseif old_state == '>' and new_state ~= '>' then
    -- 実行中状態から他の状態に変わった場合、タイマー停止
    M.stop_timer(task_id)
  end
end

-- 更新ループ開始（1秒間隔）
function M.start_update_loop()
  if update_timer then
    update_timer:stop()
  end

  update_timer = vim.uv.new_timer()
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

  -- ノーマルモードで yy/p してそのまま :w するケースもカバー
  vim.api.nvim_create_autocmd("BufWritePost", {
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
    if line:match('-%s*%[>%]') then
      local task_id = display.generate_task_id(file_path, line)
      found_tasks = found_tasks + 1

      if not active_timers[task_id] then
        -- タイマーがない実行中タスクを発見した場合、タイマーを開始
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

-- 🎯 新機能: アクティブタイマー選択ジャンプ（leader-c方式UI統一版）
function M.jump_to_active_timer()
  -- デバッグ: 関数開始ログ（現在ファイル情報付き）
  local current_file = vim.api.nvim_buf_get_name(0)

  if vim.tbl_isempty(active_timers) then
    vim.notify("📊 アクティブなタイマーはありません", vim.log.levels.WARN)
    return
  end

  -- デバッグ: タイマー数確認
  local timer_count = vim.tbl_count(active_timers)

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

    -- leader-c方式のオプション形式に変換
    table.insert(timer_options, { task_id, display_text, tostring(#timer_options + 1) })
    timer_data_map[task_id] = timer_data

    -- デバッグ: 各タイマー情報（ファイルパス付き）
  end

  -- デバッグ: 選択肢数確認

  -- leader-c方式の専用バッファUIを表示
  M.show_timer_selection_buffer(timer_options, timer_data_map)

  -- デバッグ: 関数終了ログ
end

-- 📟 leader-c方式の専用バッファタイマー選択UI
function M.show_timer_selection_buffer(timer_options, timer_data_map)
  -- デバッグ: 関数開始ログ

  -- 選択キー（最大9個まで表示）
  local selection_keys = { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l' }

  -- 表示する項目数を制限（9個まで）
  local display_count = math.min(#timer_options, #selection_keys)

  -- デバッグ: 表示数確認

  -- 専用バッファ作成
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = { "🎯 稼働中タイマーにジャンプ:", "" }

  -- 選択肢を表示用に整形
  local key_to_task_id = {}
  for i = 1, display_count do
    local key = selection_keys[i]
    local option = timer_options[i]
    local task_id = option[1]
    local display_text = option[2]

    table.insert(lines, string.format("  %s: %s", key, display_text))
    key_to_task_id[key] = task_id

    -- デバッグ: 各選択肢（ファイルパス付き）
    local timer_data = timer_data_map[task_id]
  end

  -- 残りの項目がある場合は通知
  if #timer_options > display_count then
    table.insert(lines, string.format("  ... 他 %d個のタイマー", #timer_options - display_count))
  end

  table.insert(lines, "")
  table.insert(lines, "  x: 🗑️ 見失ったタスクを削除 | Enter: デフォルト | Esc: キャンセル")
  table.insert(lines, "")
  table.insert(lines, "  ▶ キーを入力してください...")

  -- バッファにコンテンツを設定
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'

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
    title = ' 🎯 タイマージャンプ ',
    title_pos = 'center'
  })

  -- ウィンドウオプション設定
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false

  -- クローズ処理
  local function close_and_callback(result)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if result then
      result()
    end
  end

  -- Insert modeでの文字入力受付（LSP風）
  local function setup_input_handler()
    -- Insert modeに切り替え
    vim.cmd('startinsert')

    -- InsertCharPre autocmdで文字入力をキャッチ
    local group = vim.api.nvim_create_augroup('TimerSelectionInput', { clear = true })

    vim.api.nvim_create_autocmd('InsertCharPre', {
      buffer = buf,
      group = group,
      callback = function()
        local char = vim.v.char

        -- 改行は処理しない
        if char == '\n' or char == '\r' then
          return
        end

        -- 入力をキャンセル（文字を表示させない）
        vim.v.char = ''

        -- 非同期で処理（InsertCharPre中の制限を回避）
        vim.schedule(function()
          -- 見失ったタスク削除機能
          if char == 'x' then
            vim.api.nvim_del_augroup_by_id(group)
            close_and_callback(function()
              M.remove_lost_tasks()
            end)
            return
          end

          -- 各選択肢の文字をチェック
          local task_id = key_to_task_id[char]
          if task_id then
            local timer_data = timer_data_map[task_id]
            if timer_data then
              vim.api.nvim_del_augroup_by_id(group)
              close_and_callback(function()
                -- 文字列ベースのジャンプ機能を使用
                M.jump_to_file_and_line_by_content(timer_data.file_path, task_id)
              end)
              return
            end
          end
        end)
      end
    })

    -- Enterキーの処理
    vim.keymap.set('i', '<CR>', function()
      vim.api.nvim_del_augroup_by_id(group)
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

-- 🔒 改良されたジャンプ機能（iCloudパス対応版）
function M.jump_to_file_and_line_by_content(file_path, task_id)
  -- パス展開とアクセス性チェック
  local expanded_path = vim.fn.expand(file_path)
  local full_path = vim.fn.fnamemodify(expanded_path, ':p')

  -- ファイルが存在するかチェック
  if vim.fn.filereadable(expanded_path) == 0 then
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local dir_path = vim.fn.fnamemodify(expanded_path, ":h")

    -- ディレクトリが存在するかチェック
    if vim.fn.isdirectory(dir_path) == 0 then
      vim.notify(string.format("⚠️ ディレクトリが存在しません: %s", dir_path), vim.log.levels.ERROR)
      vim.notify("📝 環境変数OBSIDIAN_VAULT_PATHが正しく設定されているか確認してください", vim.log.levels.INFO)
    else
      vim.notify(string.format("⚠️ ファイルが見つかりません: %s", file_name), vim.log.levels.ERROR)
      vim.notify(string.format("📝 フルパス: %s", full_path), vim.log.levels.INFO)

      -- このタイマーを削除するか確認
      local choice = vim.fn.confirm(
        string.format("タイマーを削除しますか？\nファイル: %s", file_name),
        "&d: 削除する\n&c: キャンセル",
        2
      )

      if choice == 1 then
        M.stop_timer(task_id)
        vim.notify("🗑️ タイマーを削除しました", vim.log.levels.INFO)
      end
    end
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

  -- 🔒 iCloudパス対応の安全なファイルオープン
  local success, error_msg = pcall(function()
    -- 1. バッファが既に開いているかチェック（複数の方法で確認）
    local existing_bufnr = vim.fn.bufnr(expanded_path)

    -- 既存バッファが見つかった場合の安全な処理
    if existing_bufnr ~= -1 then

      if vim.api.nvim_buf_is_valid(existing_bufnr) then

        -- より安全なバッファ切り替え（複数の方法で試行）
        local buffer_switch_success = pcall(function()
          -- まずシンプルなbufferコマンドを試す
          vim.cmd('buffer ' .. existing_bufnr)
        end)

        if not buffer_switch_success then
          -- bufferコマンドが失敗した場合、dropコマンドを試す
          buffer_switch_success = pcall(function()
            vim.cmd('drop ' .. vim.fn.fnameescape(expanded_path))
          end)
        end

        if buffer_switch_success then
          return true
        end
      end
    end

    -- 🔒 iCloudパス対応の直接ファイルオープン（swapチェックスキップ）
    local escaped_path = vim.fn.fnameescape(expanded_path)

    local open_success = pcall(function()
      vim.cmd('drop ' .. escaped_path)
    end)

    if not open_success then
      vim.cmd('edit! ' .. escaped_path)
    end

    return true
  end)

  if not success then
    vim.notify(string.format("⚠️ ファイルオープンエラー: %s", error_msg), vim.log.levels.ERROR)
    return
  end

  -- 🔍 ファイルオープン成功後の処理

  local bufnr = vim.api.nvim_get_current_buf()

  -- 文字列ベースでタスクを検索
  local line_number, found_line = display.find_task_by_content(bufnr, task_id)

  if line_number then
    -- タスクが見つかった場合
    vim.api.nvim_win_set_cursor(0, {line_number, 0})
    vim.cmd('normal! zz')  -- 画面中央にスクロール

    local file_name = vim.fn.fnamemodify(expanded_path, ":t")
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

-- 🗑️ 見失ったタスクを削除する機能（iCloudパス対応版）
function M.remove_lost_tasks()
  local removed_count = 0
  local lost_tasks = {}

  -- 各アクティブタイマーのタスクが存在するかチェック
  for task_id, timer_data in pairs(active_timers) do
    local file_path = timer_data.file_path

    -- ファイルが存在するかチェック
    if vim.fn.filereadable(file_path) == 0 then
      table.insert(lost_tasks, {
        task_id = task_id,
        reason = "ファイルが見つからない",
        file_name = vim.fn.fnamemodify(file_path, ":t")
      })
    else
      -- ファイルを開いてタスクが存在するかチェック
      local bufnr = vim.fn.bufnr(file_path)
      local should_check_task = true

      if bufnr == -1 then
        -- 🔒 swapファイル生成回避: ファイル内容を直接読み込み
        local file_handle = io.open(file_path, 'r')
        if not file_handle then
          should_check_task = false
        else
          local file_lines = {}
          for line in file_handle:lines() do
            table.insert(file_lines, line)
          end
          file_handle:close()

          -- 直接文字列検索（バッファ作成なし）
          local found, line_num, found_line = display.find_task_in_file_lines(file_lines, file_path, task_id)

          if not found then
            table.insert(lost_tasks, {
              task_id = task_id,
              reason = "タスクが見つからない（内容が変更された可能性）",
              file_name = vim.fn.fnamemodify(file_path, ":t"),
              task_preview = timer_data.task_content:gsub("-.*%[.-%]", ""):gsub("^%s+", ""):sub(1, 30)
            })
          end
          should_check_task = false  -- 既に処理済み
        end
      elseif not vim.api.nvim_buf_is_valid(bufnr) then
        -- バッファが存在するが無効な場合はスキップ（E94エラー対策）
        should_check_task = false
      end

      if should_check_task then
        -- 文字列ベースでタスクを検索
        local ok, line_number, found_line = pcall(display.find_task_by_content, bufnr, task_id)

        if not ok then
          -- 検索エラーの場合はスキップ
        elseif not line_number then
          -- タスクが見つからない場合は削除対象
          table.insert(lost_tasks, {
            task_id = task_id,
            reason = "タスクが見つからない（内容が変更された可能性）",
            file_name = vim.fn.fnamemodify(file_path, ":t"),
            task_preview = timer_data.task_content:gsub("-.*%[.-%]", ""):gsub("^%s+", ""):sub(1, 30)
          })
        end
      end

      -- 注意: 直接ファイル読み込みに変更したためneed_load変数は不要
    end
  end

  -- 見失ったタスクを削除
  if #lost_tasks > 0 then
    local confirmation_lines = {
      string.format("🗑️ %d個の見失ったタスクが見つかりました:", #lost_tasks),
      ""
    }

    for i, lost_task in ipairs(lost_tasks) do
      local reason_text = lost_task.reason
      local file_name = lost_task.file_name
      local preview = lost_task.task_preview and (" (" .. lost_task.task_preview .. "...)") or ""
      table.insert(confirmation_lines, string.format("  %d. [%s] %s%s", i, file_name, reason_text, preview))
    end

    table.insert(confirmation_lines, "")
    table.insert(confirmation_lines, "これらのタスクタイマーを削除しますか？")

    -- 確認ダイアログを表示
    local choice = vim.fn.confirm(
      table.concat(confirmation_lines, "\n"),
      "&d: 削除する\n&c: キャンセル",
      2
    )

    if choice == 1 then
      -- 削除実行
      for _, lost_task in ipairs(lost_tasks) do
        M.stop_timer(lost_task.task_id)
        removed_count = removed_count + 1
      end

      -- 表示を更新
      display.clear_all_displays()
      display.update_all_displays(active_timers)

      vim.notify(string.format("🗑️ %d個の見失ったタスクタイマーを削除しました", removed_count), vim.log.levels.INFO)
    else
      vim.notify("削除をキャンセルしました", vim.log.levels.INFO)
    end
  else
    vim.notify("✅ 見失ったタスクはありませんでした", vim.log.levels.INFO)
  end
end

-- 🗑️ 現在のバッファ内の全実行中タスク[>]を中断中[/]に変換
function M.cancel_all_in_progress_tasks()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)

  if vim.bo[bufnr].filetype ~= 'markdown' then
    vim.notify("📊 Markdownファイルでのみ実行できます", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local count = 0
  local stopped_timers = {}

  -- 変換前にタイマーを特定して停止
  for line_num, line in ipairs(lines) do
    if line:match('-%s*%[>%]') then
      -- タスクIDを生成（変換前の内容で）
      local task_id = display.generate_task_id(file_path, line)

      -- タイマーが動いている場合は記録
      if active_timers[task_id] then
        table.insert(stopped_timers, task_id)
      end

      -- [>]を[/]に置換
      local new_line = line:gsub('%[>%]', '[/]')
      lines[line_num] = new_line
      count = count + 1
    end
  end

  if count > 0 then
    -- バッファを更新
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- タイマーを停止
    for _, task_id in ipairs(stopped_timers) do
      M.stop_timer(task_id)
    end

    vim.notify(string.format("🗑️ %d個のタスクを中止しました（タイマー停止: %d個）", count, #stopped_timers), vim.log.levels.INFO)
  else
    vim.notify("📊 進行中のタスクはありません", vim.log.levels.INFO)
  end
end

-- 同一 content_hash を持つ既存タイマーから start_time を複製
-- ファイル間コピペで「同じ内容のタスク」を別ファイルに貼った時、
-- 元のタイマーから経過時間を引き継ぐためのヘルパー
local function find_inheritable_start_time(target_task_id, saved_timers)
  local target_hash = display.extract_content_hash(target_task_id)
  if not target_hash then return nil end

  -- まず active_timers から検索（最新の状態）
  for existing_id, existing_data in pairs(active_timers) do
    if existing_id ~= target_task_id
      and display.extract_content_hash(existing_id) == target_hash then
      return existing_data.start_time
    end
  end

  -- 次に saved_timers から検索（再起動後でも引き継げるように）
  if saved_timers then
    for existing_id, existing_data in pairs(saved_timers) do
      if existing_id ~= target_task_id
        and display.extract_content_hash(existing_id) == target_hash then
        return existing_data.start_time
      end
    end
  end

  return nil
end

-- Insertモードから抜けた時のタイマー自動復元（デバッグ版）
function M.auto_restore_timers(bufnr)
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  if file_path == "" then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local restored_count = 0
  local new_timer_count = 0
  local inherited_count = 0
  local saved_timers = nil  -- 遅延ロード（[>] 行があった時だけ読む）

  for _, line in ipairs(lines) do
    if line:match('-%s*%[>%]') then
      local task_id = display.generate_task_id(file_path, line)

      if not active_timers[task_id] then
        if saved_timers == nil then
          saved_timers = storage.load_timers()
        end

        if saved_timers[task_id] then
          -- 既存タイマーの復元
          active_timers[task_id] = saved_timers[task_id]
          restored_count = restored_count + 1
        else
          -- 同一 content_hash を持つ別 task_id から start_time を複製
          local inherited_start = find_inheritable_start_time(task_id, saved_timers)
          if inherited_start then
            active_timers[task_id] = {
              start_time = inherited_start,
              file_path = file_path,
              task_content = line,
            }
            storage.save_timer_safe(task_id, active_timers[task_id])
            inherited_count = inherited_count + 1
          else
            -- 完全新規
            M.start_timer(task_id, file_path, line)
            new_timer_count = new_timer_count + 1
          end
        end
      end
    end
  end

  if restored_count > 0 or new_timer_count > 0 or inherited_count > 0 then
    display.update_buffer_display(bufnr, active_timers)
    if inherited_count > 0 then
      vim.notify(
        string.format("📊 %d個のタイマーをコピー元から引き継ぎました", inherited_count),
        vim.log.levels.INFO
      )
    end
  end
end

return M
