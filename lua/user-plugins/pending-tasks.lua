-- ~/.config/nvim/lua/user-plugins/pending-tasks.lua
-- 現在のファイル内の「- [-]」行をフローティングウィンドウに表示

local M = {}

-- 設定
M.config = {
  pattern = "^%s*%-%s*%[%-%]", -- "- [-]" にマッチ
  max_items = 5, -- 最大表示件数
  min_height = 1, -- 最小高さ
  border = "rounded", -- ボーダースタイル
}

-- 状態管理
M.state = {
  win = nil, -- フローティングウィンドウID
  buf = nil, -- バッファID
  visible = false,
  tasks = {}, -- { lnum, text, elapsed, elapsed_text, heading } のリスト
  source_buf = nil, -- 元のバッファID
}

-- 親見出しを取得（テキスト含む）
local function get_parent_heading(lines, task_lnum)
  for i = task_lnum - 1, 1, -1 do
    local line = lines[i]
    local level = line:match("^(#+)%s")
    if level then
      local text = line:gsub("^#+%s*", "")
      return {
        level = #level,
        text = text,
        prefix = level, -- "##" など
      }
    end
  end
  return nil -- 見出しなし
end

-- 現在のバッファから "- [-]" 行を収集（タイマー連携付き）
function M.collect_pending_tasks()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local tasks = {}

  -- task-timer連携
  local ok_display, timer_display = pcall(require, "user-plugins.task-timer-display")
  local ok_storage, timer_storage = pcall(require, "user-plugins.task-timer-storage")
  local active_timers = {}
  if ok_storage then
    active_timers = timer_storage.load_timers()
  end

  for lnum, line in ipairs(lines) do
    if line:match(M.config.pattern) then
      -- チェックボックス以降のテキストを抽出
      local text = line:gsub("^%s*%-%s*%[%-%]%s*", "")

      local task = {
        lnum = lnum,
        text = text,
        full_line = line,
        elapsed = nil,
        elapsed_text = nil,
        heading = get_parent_heading(lines, lnum),
      }

      -- タイマー情報を取得
      if ok_display and file_path ~= "" then
        local task_id = timer_display.generate_task_id(file_path, line)
        if active_timers[task_id] then
          task.elapsed = os.time() - active_timers[task_id].start_time
          task.elapsed_text = timer_display.format_elapsed_time(active_timers[task_id].start_time)
          -- タイマー稼働中のみ追加
          table.insert(tasks, task)
        end
      end
    end
  end

  -- ソート（経過時間が短い順）
  table.sort(tasks, function(a, b)
    return a.elapsed < b.elapsed
  end)

  -- 最大件数で切り詰め
  if #tasks > M.config.max_items then
    local trimmed = {}
    for i = 1, M.config.max_items do
      trimmed[i] = tasks[i]
    end
    tasks = trimmed
  end

  M.state.tasks = tasks
  M.state.source_buf = bufnr
  return tasks
end

-- ウィンドウを閉じる
function M.close_window()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
  end
  M.state.win = nil
  M.state.buf = nil
  M.state.visible = false
end

-- フローティングウィンドウを描画
function M.render_window()
  -- 既存のウィンドウを閉じる
  M.close_window()

  local tasks = M.collect_pending_tasks()

  -- タスクがない場合はメッセージ表示して終了
  if #tasks == 0 then
    vim.notify("進行中のタスク (- [-]) はありません", vim.log.levels.INFO)
    return
  end

  -- バッファ作成
  local buf = vim.api.nvim_create_buf(false, true)
  M.state.buf = buf

  -- 表示内容を作成（ハイライト位置も記録）
  local display_lines = {}
  local highlight_info = {} -- { heading_start, heading_end, heading_level } or nil
  for i, task in ipairs(tasks) do
    local time_str = task.elapsed_text or ""
    local heading_str = ""
    if task.heading then
      heading_str = task.heading.prefix .. " " .. task.heading.text .. " > "
    end

    local line
    local prefix_len -- 見出し部分の開始位置
    if time_str ~= "" then
      prefix_len = #string.format(" %d. %s ", i, time_str)
      line = string.format(" %d. %s %s%s  (L:%d)", i, time_str, heading_str, task.text, task.lnum)
    else
      prefix_len = #string.format(" %d. ", i)
      line = string.format(" %d. %s%s  (L:%d)", i, heading_str, task.text, task.lnum)
    end
    table.insert(display_lines, line)

    -- ハイライト位置情報を記録
    if task.heading then
      table.insert(highlight_info, {
        heading_start = prefix_len,
        heading_end = prefix_len + #heading_str,
        heading_level = task.heading.level,
      })
    else
      table.insert(highlight_info, nil)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)

  -- 各行にハイライトを適用（見出し部分とタスク部分で色分け）
  for i, info in ipairs(highlight_info) do
    local line_idx = i - 1
    if info then
      -- 見出し部分: Treesitterの見出し色
      local heading_hl = "@markup.heading." .. info.heading_level
      vim.api.nvim_buf_add_highlight(buf, -1, heading_hl, line_idx, info.heading_start, info.heading_end)
      -- タスク部分: TaskInProgress色
      vim.api.nvim_buf_add_highlight(buf, -1, "TaskInProgress", line_idx, info.heading_end, -1)
    else
      -- 見出しなし: 全体をTaskInProgress色
      vim.api.nvim_buf_add_highlight(buf, -1, "TaskInProgress", line_idx, 0, -1)
    end
  end

  -- バッファオプション
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "pending-tasks")

  -- ウィンドウサイズ計算
  local width = vim.o.columns
  local height = math.max(M.config.min_height, #tasks)

  -- 画面下部に配置（ステータスライン + コマンドライン分を考慮）
  local row = vim.o.lines - height - 4

  -- フローティングウィンドウ作成（フォーカスあり）
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width - 2,
    height = height,
    row = row,
    col = 0,
    style = "minimal",
    border = M.config.border,
    title = " 進行中タスク [-] ",
    title_pos = "center",
  })
  M.state.win = win
  M.state.visible = true

  -- ウィンドウオプション
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,CursorLine:Visual")

  -- キーマップ設定（ウィンドウ内操作）
  M.setup_window_keymaps(buf)
end

-- ウィンドウ内のキーマップ設定
function M.setup_window_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- q または Esc で閉じる
  vim.keymap.set("n", "q", function()
    M.close_window()
  end, opts)
  vim.keymap.set("n", "<Esc>", function()
    M.close_window()
  end, opts)

  -- Enter または 数字キーでジャンプ
  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    local task_index = cursor[1]
    M.jump_to_task(task_index)
  end, opts)

  -- 数字キーで直接ジャンプ
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      M.jump_to_task(i)
    end, opts)
  end

  -- j/k でカーソル移動時に本文もプレビュー
  vim.keymap.set("n", "j", function()
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    local next_line = math.min(cursor[1] + 1, #M.state.tasks)
    vim.api.nvim_win_set_cursor(M.state.win, { next_line, 0 })
    M.preview_task(next_line)
  end, opts)

  vim.keymap.set("n", "k", function()
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    local prev_line = math.max(cursor[1] - 1, 1)
    vim.api.nvim_win_set_cursor(M.state.win, { prev_line, 0 })
    M.preview_task(prev_line)
  end, opts)
end

-- タスクをプレビュー（ウィンドウを閉じずに本文側を移動）
function M.preview_task(task_index)
  local task = M.state.tasks[task_index]
  if not task then return end

  -- 元のバッファを表示しているウィンドウを探してカーソル移動
  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == M.state.source_buf then
        vim.api.nvim_win_set_cursor(win, { task.lnum, 0 })
        -- 画面中央に表示
        vim.api.nvim_win_call(win, function()
          vim.cmd("normal! zz")
        end)
        break
      end
    end
  end
end

-- 指定したタスクへジャンプ
function M.jump_to_task(task_index)
  local task = M.state.tasks[task_index]
  if not task then
    vim.notify("タスクが見つかりません", vim.log.levels.WARN)
    return
  end

  -- ウィンドウを閉じる
  M.close_window()

  -- 元のバッファに戻って行へジャンプ
  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    -- 元のバッファを表示しているウィンドウを探す
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == M.state.source_buf then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
    vim.api.nvim_win_set_cursor(0, { task.lnum, 0 })
    -- 画面中央に表示
    vim.cmd("normal! zz")
  end
end

-- 表示/非表示トグル
function M.toggle()
  if M.state.visible then
    M.close_window()
  else
    M.render_window()
  end
end

-- 自動更新（リアルタイム）
function M.refresh()
  if M.state.visible then
    M.render_window()
  end
end

-- 初期化とautocmd設定
function M.setup(opts)
  -- 設定をマージ
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- autocmdグループ作成
  local group = vim.api.nvim_create_augroup("PendingTasks", { clear = true })

  -- テキスト変更時に更新（表示中のみ）
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = "*.md",
    callback = function()
      if M.state.visible then
        -- デバウンス：少し待ってから更新
        vim.defer_fn(function()
          M.refresh()
        end, 100)
      end
    end,
  })

  -- バッファ切り替え時に閉じる
  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    pattern = "*.md",
    callback = function()
      if M.state.visible then
        M.close_window()
      end
    end,
  })

  -- キーマップ設定
  vim.keymap.set("n", "<leader>j", M.toggle, {
    noremap = true,
    silent = true,
    desc = "Toggle pending tasks window (- [-])",
  })
end

return M
