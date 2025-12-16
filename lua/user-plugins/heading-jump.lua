-- ~/.config/nvim/lua/user-plugins/heading-jump.lua
-- 現在のファイル内の見出し（# ～ ######）をフローティングウィンドウに表示

local M = {}

-- 設定
M.config = {
  pattern = "^(#+)%s+(.+)", -- 見出しにマッチ
  max_items = 20,           -- 最大表示件数
  min_height = 1,           -- 最小高さ
  border = "rounded",       -- ボーダースタイル
}

-- 状態管理
M.state = {
  win = nil,
  buf = nil,
  visible = false,
  headings = {},    -- { lnum, level, text } のリスト
  source_buf = nil, -- 元のバッファID
  preview_extmark = nil, -- プレビュー用extmark ID
  input_text = "",  -- fuzzy検索用入力文字列
  input_group = nil, -- InsertCharPre用autocmdグループ
}

-- extmark用namespace
M.ns_id = vim.api.nvim_create_namespace("heading_jump_preview")

-- 現在のバッファから見出しを収集
function M.collect_headings()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local headings = {}

  for lnum, line in ipairs(lines) do
    local hashes, text = line:match(M.config.pattern)
    if hashes and #hashes <= 6 then
      table.insert(headings, {
        lnum = lnum,
        level = #hashes,
        text = text,
        prefix = hashes,
      })
    end
  end

  -- 最大件数で切り詰め
  if #headings > M.config.max_items then
    local trimmed = {}
    for i = 1, M.config.max_items do
      trimmed[i] = headings[i]
    end
    headings = trimmed
  end

  M.state.headings = headings
  M.state.source_buf = bufnr
  return headings
end

-- 現在のカーソル行から親見出しのインデックスを取得
function M.find_parent_heading_index(current_lnum)
  local headings = M.state.headings
  if #headings == 0 then return 1 end

  local parent_idx = 1 -- デフォルトは最初の見出し
  for i, h in ipairs(headings) do
    if h.lnum <= current_lnum then
      parent_idx = i
    else
      break
    end
  end
  return parent_idx
end

-- ウィンドウを閉じる
function M.close_window()
  -- fuzzy入力グループをクリーンアップ
  if M.state.input_group then
    pcall(vim.api.nvim_del_augroup_by_id, M.state.input_group)
    M.state.input_group = nil
  end
  M.state.input_text = ""

  -- プレビューハイライトをクリア
  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    vim.api.nvim_buf_clear_namespace(M.state.source_buf, M.ns_id, 0, -1)
  end

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
  -- 現在のカーソル位置を保存（close_window前に取得）
  local current_lnum = vim.api.nvim_win_get_cursor(0)[1]

  M.close_window()

  local headings = M.collect_headings()

  if #headings == 0 then
    vim.notify("見出し (#～######) はありません", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  M.state.buf = buf

  -- 表示内容を作成
  local display_lines = {}
  local highlight_info = {}
  for i, h in ipairs(headings) do
    -- インデント: レベルに応じて2スペースずつ
    local indent = string.rep("  ", h.level - 1)
    local line = string.format(" %d.%s %s %s  (L:%d)", i, indent, h.prefix, h.text, h.lnum)
    table.insert(display_lines, line)
    table.insert(highlight_info, {
      level = h.level,
      -- 見出しテキスト開始位置を計算
      start_col = #string.format(" %d.%s ", i, indent),
    })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)

  -- 各行に見出しレベルに応じたハイライトを適用
  for i, info in ipairs(highlight_info) do
    local line_idx = i - 1
    local heading_hl = "HeadingJumpH" .. info.level
    vim.api.nvim_buf_add_highlight(buf, -1, heading_hl, line_idx, info.start_col, -1)
  end

  -- バッファオプション（pending-tasksと同じAPI）
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "filetype", "heading-jump")

  local width = vim.o.columns
  local height = math.min(math.max(M.config.min_height, #headings), 15)
  local row = vim.o.lines - height - 4

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width - 2,
    height = height,
    row = row,
    col = 0,
    style = "minimal",
    border = M.config.border,
    title = " 見出しジャンプ [#] ",
    title_pos = "center",
  })
  M.state.win = win
  M.state.visible = true

  -- ウィンドウオプション（pending-tasksと同じAPI）
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "winhl", "Normal:NormalFloat,CursorLine:Visual")

  M.setup_window_keymaps(buf)

  -- 親見出しをデフォルトカーソル位置に設定
  local default_idx = M.find_parent_heading_index(current_lnum)
  vim.api.nvim_win_set_cursor(win, { default_idx, 0 })
  M.preview_heading(default_idx)
end

-- fuzzyマッチで見出しを検索し、最初のマッチ行を返す
function M.find_fuzzy_match(input)
  if input == "" then return nil end

  -- 見出しテキストのリストを作成
  local texts = {}
  for i, h in ipairs(M.state.headings) do
    texts[i] = h.text
  end

  -- matchfuzzyでマッチする見出しを検索
  local matches = vim.fn.matchfuzzy(texts, input)
  if #matches == 0 then return nil end

  -- 最初のマッチの元のインデックスを探す
  for i, h in ipairs(M.state.headings) do
    if h.text == matches[1] then
      return i
    end
  end
  return nil
end

-- fuzzy入力ハンドラをセットアップ
function M.setup_fuzzy_input(buf)
  M.state.input_text = ""
  M.state.input_group = vim.api.nvim_create_augroup("HeadingJumpInput", { clear = true })

  -- Insert modeに切り替え
  vim.cmd("startinsert")

  -- InsertCharPreで文字入力をキャッチ
  vim.api.nvim_create_autocmd("InsertCharPre", {
    buffer = buf,
    group = M.state.input_group,
    callback = function()
      local char = vim.v.char

      -- 改行は処理しない
      if char == "\n" or char == "\r" then
        return
      end

      -- 入力をキャンセル（文字を表示させない）
      vim.v.char = ""

      -- 非同期で処理
      vim.schedule(function()
        -- 入力文字列に追加
        M.state.input_text = M.state.input_text .. char

        -- fuzzyマッチを実行
        local match_idx = M.find_fuzzy_match(M.state.input_text)
        if match_idx then
          -- マッチした行にカーソル移動＋プレビュー
          if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
            vim.api.nvim_win_set_cursor(M.state.win, { match_idx, 0 })
            M.preview_heading(match_idx)
          end
        end
      end)
    end,
  })

  -- Enterキーで確定ジャンプ
  vim.keymap.set("i", "<CR>", function()
    vim.api.nvim_del_augroup_by_id(M.state.input_group)
    vim.cmd("stopinsert")
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    M.jump_to_heading(cursor[1])
  end, { buffer = buf, silent = true })

  -- Escキーで閉じる
  vim.keymap.set("i", "<Esc>", function()
    vim.api.nvim_del_augroup_by_id(M.state.input_group)
    vim.cmd("stopinsert")
    M.close_window()
  end, { buffer = buf, silent = true })

  -- BackSpaceで1文字削除
  vim.keymap.set("i", "<BS>", function()
    if #M.state.input_text > 0 then
      M.state.input_text = M.state.input_text:sub(1, -2)
      -- 再検索
      local match_idx = M.find_fuzzy_match(M.state.input_text)
      if match_idx and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_set_cursor(M.state.win, { match_idx, 0 })
        M.preview_heading(match_idx)
      end
    end
  end, { buffer = buf, silent = true })
end

-- ウィンドウ内のキーマップ設定
function M.setup_window_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set("n", "q", function() M.close_window() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close_window() end, opts)

  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    M.jump_to_heading(cursor[1])
  end, opts)

  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      M.jump_to_heading(i)
    end, opts)
  end

  vim.keymap.set("n", "j", function()
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    local next_line = math.min(cursor[1] + 1, #M.state.headings)
    vim.api.nvim_win_set_cursor(M.state.win, { next_line, 0 })
    M.preview_heading(next_line)
  end, opts)

  vim.keymap.set("n", "k", function()
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    local prev_line = math.max(cursor[1] - 1, 1)
    vim.api.nvim_win_set_cursor(M.state.win, { prev_line, 0 })
    M.preview_heading(prev_line)
  end, opts)

  -- i でfuzzy入力モードを開始
  vim.keymap.set("n", "i", function()
    M.setup_fuzzy_input(buf)
  end, opts)
end

-- プレビューハイライトをクリア
function M.clear_preview_highlight()
  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    vim.api.nvim_buf_clear_namespace(M.state.source_buf, M.ns_id, 0, -1)
  end
end

-- 見出しをプレビュー（ウィンドウを閉じずに本文側を移動）
function M.preview_heading(index)
  local heading = M.state.headings[index]
  if not heading then return end

  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    -- 前のハイライトをクリア
    M.clear_preview_highlight()

    -- 反転ハイライトを適用
    local hl_group = "HeadingJumpH" .. heading.level .. "Preview"
    vim.api.nvim_buf_set_extmark(M.state.source_buf, M.ns_id, heading.lnum - 1, 0, {
      end_row = heading.lnum - 1,
      end_col = 0,
      hl_group = hl_group,
      hl_eol = true,
      line_hl_group = hl_group,
    })

    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == M.state.source_buf then
        vim.api.nvim_win_set_cursor(win, { heading.lnum, 0 })
        vim.api.nvim_win_call(win, function()
          vim.cmd("normal! zz")
        end)
        break
      end
    end
  end
end

-- 指定した見出しへジャンプ
function M.jump_to_heading(index)
  local heading = M.state.headings[index]
  if not heading then
    vim.notify("見出しが見つかりません", vim.log.levels.WARN)
    return
  end

  M.close_window()

  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(win) == M.state.source_buf then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
    vim.api.nvim_win_set_cursor(0, { heading.lnum, 0 })
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

-- 初期化
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- 見出しレベル別のハイライトを定義（tokyonight準拠）
  local heading_colors = {
    "#7aa2f7", -- H1: blue
    "#e0af68", -- H2: yellow
    "#9ece6a", -- H3: green
    "#1abc9c", -- H4: teal
    "#bb9af7", -- H5: purple
    "#9d7cd8", -- H6: purple dark
  }
  local bg_dark = "#1a1b26" -- tokyonight背景色
  for i = 1, 6 do
    -- 通常ハイライト
    vim.api.nvim_set_hl(0, "HeadingJumpH" .. i, { fg = heading_colors[i], bold = true })
    -- 反転ハイライト（プレビュー用）
    vim.api.nvim_set_hl(0, "HeadingJumpH" .. i .. "Preview", {
      fg = bg_dark,
      bg = heading_colors[i],
      bold = true,
    })
  end

  local group = vim.api.nvim_create_augroup("HeadingJump", { clear = true })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    pattern = "*.md",
    callback = function()
      if M.state.visible then
        M.close_window()
      end
    end,
  })

  vim.keymap.set("n", "<leader>h", M.toggle, {
    noremap = true,
    silent = true,
    desc = "Toggle heading jump window (#～######)",
  })
end

return M
