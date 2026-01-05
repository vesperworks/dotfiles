-- ~/.config/nvim/lua/user-plugins/obsidian-hover-preview.lua
-- [[wikilink]]ホバープレビュー

local M = {}

-- 設定
M.config = {
  delay = 500, -- プレビュー表示までの遅延（ms）
  max_width = 80, -- 最大幅
  max_height = 20, -- 最大高さ
  border = "rounded", -- ボーダースタイル
  preview_lines = 50, -- プレビュー行数（多めに読み込み）
}

-- 状態管理
M.state = {
  win = nil,
  buf = nil,
  timer = nil,
  last_link = nil,
  source_win = nil, -- 元のウィンドウを記録
  preview_file_path = nil, -- プレビュー中のファイルパス
}

-- [[wikilink]]を検出
local function get_wikilink_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  -- パターン: [[任意のテキスト]] または [[テキスト|表示名]]
  for start_pos, link_text in line:gmatch("()%[%[([^%]|]+)") do
    local end_pos = line:find("%]%]", start_pos)
    if end_pos and col >= start_pos - 1 and col < end_pos + 1 then
      return link_text
    end
  end
  return nil
end

-- リンクからファイルパスを解決（obsidian.nvim連携）
local function resolve_link_path(link_text)
  local ok, obsidian = pcall(require, "obsidian")
  if not ok then
    return nil
  end

  local client_ok, client = pcall(obsidian.get_client)
  if not client_ok or not client then
    return nil
  end

  -- obsidian.nvimのresolve_note機能を使用（エラーハンドリング付き）
  local resolve_ok, note = pcall(function()
    return client:resolve_note(link_text)
  end)
  if resolve_ok and note then
    return tostring(note.path)
  end
  return nil
end

-- ウィンドウを閉じる
function M.close_preview()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  if M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    vim.api.nvim_buf_delete(M.state.buf, { force = true })
  end
  -- 元のウィンドウにフォーカスを戻す
  if M.state.source_win and vim.api.nvim_win_is_valid(M.state.source_win) then
    vim.api.nvim_set_current_win(M.state.source_win)
  end
  M.state.win = nil
  M.state.buf = nil
  M.state.last_link = nil
  M.state.source_win = nil
  M.state.preview_file_path = nil
end

-- タイマーをクリア
local function clear_timer()
  if M.state.timer then
    M.state.timer:stop()
    M.state.timer:close()
    M.state.timer = nil
  end
end

-- プレビューウィンドウのキーマップ設定
local function setup_preview_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- ZZ/ZQ/q/Esc で閉じる
  vim.keymap.set("n", "ZZ", function()
    M.close_preview()
  end, opts)
  vim.keymap.set("n", "ZQ", function()
    M.close_preview()
  end, opts)
  vim.keymap.set("n", "q", function()
    M.close_preview()
  end, opts)
  vim.keymap.set("n", "<Esc>", function()
    M.close_preview()
  end, opts)

  -- gf でリンク先を実際に開く（プレビューから本編集へ）
  vim.keymap.set("n", "gf", function()
    local file_path = M.state.preview_file_path
    M.close_preview()
    if file_path then
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    end
  end, opts)
end

-- プレビューを表示
function M.show_preview(file_path)
  M.close_preview()

  -- 元のウィンドウを記録
  M.state.source_win = vim.api.nvim_get_current_win()

  -- ファイル読み込み
  local lines = {}
  local f = io.open(file_path, "r")
  if not f then
    vim.notify("ファイルを開けません: " .. file_path, vim.log.levels.WARN)
    return
  end

  local count = 0
  for line in f:lines() do
    table.insert(lines, line)
    count = count + 1
    if count >= M.config.preview_lines then
      table.insert(lines, "")
      table.insert(lines, "... (truncated, press gf to open full file)")
      break
    end
  end
  f:close()

  if #lines == 0 then
    lines = { "(empty file)" }
  end

  -- バッファ作成
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })

  -- ファイルパスをstate変数に保存（gfで使用）
  M.state.preview_file_path = file_path

  -- ウィンドウサイズ計算
  local width = math.min(M.config.max_width, vim.o.columns - 4)
  local height = math.min(M.config.max_height, #lines)

  -- フローティングウィンドウ作成（フォーカスあり: 第2引数 true）
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    width = width,
    height = height,
    row = -height - 1,
    col = 0,
    style = "minimal",
    border = M.config.border,
    title = " " .. vim.fn.fnamemodify(file_path, ":t") .. " [ZZ/q to close, gf to open] ",
    title_pos = "center",
  })

  -- ウィンドウオプション
  vim.api.nvim_set_option_value("wrap", true, { win = win })
  vim.api.nvim_set_option_value("cursorline", true, { win = win })
  vim.api.nvim_set_option_value("number", true, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })

  M.state.win = win
  M.state.buf = buf

  -- キーマップ設定
  setup_preview_keymaps(buf)
end

-- ホバーチェック
function M.check_hover()
  -- プレビューウィンドウ内にいる場合は何もしない
  if M.state.win and vim.api.nvim_get_current_win() == M.state.win then
    return
  end

  local link = get_wikilink_under_cursor()

  if not link then
    return -- リンク外ではプレビューを閉じない（フォーカス移動後のため）
  end

  -- 同じリンクなら何もしない
  if link == M.state.last_link and M.state.win then
    return
  end

  M.state.last_link = link

  -- ファイルパス解決
  local file_path = resolve_link_path(link)
  if file_path and vim.fn.filereadable(file_path) == 1 then
    M.show_preview(file_path)
  end
end

-- 遅延付きホバーチェック
function M.schedule_hover()
  clear_timer()
  local timer = vim.uv.new_timer()
  M.state.timer = timer
  timer:start(
    M.config.delay,
    0,
    vim.schedule_wrap(function()
      M.check_hover()
    end)
  )
end

-- セットアップ
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  local group = vim.api.nvim_create_augroup("ObsidianHoverPreview", { clear = true })

  -- カーソル移動時にタイマー開始（プレビューウィンドウ外のみ）
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = group,
    pattern = "*.md",
    callback = function()
      -- プレビューウィンドウ内では何もしない
      if M.state.win and vim.api.nvim_get_current_win() == M.state.win then
        return
      end
      -- 既存のプレビューがある場合は閉じてからタイマー開始
      if M.state.win then
        M.close_preview()
      end
      M.schedule_hover()
    end,
  })

  -- InsertEnter時にクリーンアップ
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    pattern = "*.md",
    callback = function()
      clear_timer()
      M.close_preview()
    end,
  })

  -- WinClosed時にクリーンアップ（プレビューウィンドウが閉じられた時）
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(args)
      if tonumber(args.match) == M.state.win then
        M.state.win = nil
        M.state.buf = nil
        M.state.last_link = nil
        -- 元のウィンドウにフォーカスを戻す
        if M.state.source_win and vim.api.nvim_win_is_valid(M.state.source_win) then
          vim.api.nvim_set_current_win(M.state.source_win)
        end
        M.state.source_win = nil
      end
    end,
  })
end

return M
