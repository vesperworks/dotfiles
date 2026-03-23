-- lua/vw/heading.lua
-- 見出しジャンプ・セクション移動
-- heading-jump.lua + move-to-heading.lua を統合

local M = {}

-- =============================================
-- 見出しジャンプ (heading-jump)
-- =============================================

M.config = {
  pattern = "^(#+)%s+(.+)",
  max_items = 100,
  min_height = 1,
  border = "rounded",
}

M.state = {
  win = nil,
  buf = nil,
  visible = false,
  headings = {},
  source_buf = nil,
  preview_extmark = nil,
  input_text = "",
  input_group = nil,
}

M.ns_id = vim.api.nvim_create_namespace("heading_jump_preview")

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

function M.find_parent_heading_index(current_lnum)
  local headings = M.state.headings
  if #headings == 0 then return 1 end

  local parent_idx = 1
  for i, h in ipairs(headings) do
    if h.lnum <= current_lnum then
      parent_idx = i
    else
      break
    end
  end
  return parent_idx
end

function M.close_window()
  if M.state.input_group then
    pcall(vim.api.nvim_del_augroup_by_id, M.state.input_group)
    M.state.input_group = nil
  end
  M.state.input_text = ""

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

function M.render_window()
  local current_lnum = vim.api.nvim_win_get_cursor(0)[1]
  M.close_window()

  local headings = M.collect_headings()
  if #headings == 0 then
    vim.notify("見出し (#～######) はありません", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  M.state.buf = buf

  local display_lines = {}
  local highlight_info = {}
  for i, h in ipairs(headings) do
    local indent = string.rep("  ", h.level - 1)
    local line = string.format(" %d.%s %s %s  (L:%d)", i, indent, h.prefix, h.text, h.lnum)
    table.insert(display_lines, line)
    table.insert(highlight_info, {
      level = h.level,
      start_col = #string.format(" %d.%s ", i, indent),
    })
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)

  for i, info in ipairs(highlight_info) do
    local line_idx = i - 1
    local heading_hl = "HeadingJumpH" .. info.level
    vim.api.nvim_buf_add_highlight(buf, -1, heading_hl, line_idx, info.start_col, -1)
  end

  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].filetype = 'heading-jump'

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

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].winhl = 'Normal:NormalFloat,CursorLine:Visual'

  M.setup_window_keymaps(buf)

  local default_idx = M.find_parent_heading_index(current_lnum)
  vim.api.nvim_win_set_cursor(win, { default_idx, 0 })
  M.preview_heading(default_idx)
end

function M.find_fuzzy_match(input)
  if input == "" then return nil end
  local texts = {}
  for i, h in ipairs(M.state.headings) do
    texts[i] = h.text
  end
  local matches = vim.fn.matchfuzzy(texts, input)
  if #matches == 0 then return nil end
  for i, h in ipairs(M.state.headings) do
    if h.text == matches[1] then
      return i
    end
  end
  return nil
end

function M.setup_fuzzy_input(buf)
  M.state.input_text = ""
  M.state.input_group = vim.api.nvim_create_augroup("HeadingJumpInput", { clear = true })
  vim.cmd("startinsert")

  vim.api.nvim_create_autocmd("InsertCharPre", {
    buffer = buf,
    group = M.state.input_group,
    callback = function()
      local char = vim.v.char
      if char == "\n" or char == "\r" then return end
      vim.v.char = ""
      vim.schedule(function()
        M.state.input_text = M.state.input_text .. char
        local match_idx = M.find_fuzzy_match(M.state.input_text)
        if match_idx then
          if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
            vim.api.nvim_win_set_cursor(M.state.win, { match_idx, 0 })
            M.preview_heading(match_idx)
          end
        end
      end)
    end,
  })

  vim.keymap.set("i", "<CR>", function()
    vim.api.nvim_del_augroup_by_id(M.state.input_group)
    vim.cmd("stopinsert")
    local cursor = vim.api.nvim_win_get_cursor(M.state.win)
    M.jump_to_heading(cursor[1])
  end, { buffer = buf, silent = true })

  vim.keymap.set("i", "<Esc>", function()
    vim.api.nvim_del_augroup_by_id(M.state.input_group)
    vim.cmd("stopinsert")
    M.close_window()
  end, { buffer = buf, silent = true })

  vim.keymap.set("i", "<BS>", function()
    if #M.state.input_text > 0 then
      M.state.input_text = M.state.input_text:sub(1, -2)
      local match_idx = M.find_fuzzy_match(M.state.input_text)
      if match_idx and M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
        vim.api.nvim_win_set_cursor(M.state.win, { match_idx, 0 })
        M.preview_heading(match_idx)
      end
    end
  end, { buffer = buf, silent = true })
end

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

  vim.keymap.set("n", "i", function()
    M.setup_fuzzy_input(buf)
  end, opts)
end

function M.clear_preview_highlight()
  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    vim.api.nvim_buf_clear_namespace(M.state.source_buf, M.ns_id, 0, -1)
  end
end

function M.preview_heading(index)
  local heading = M.state.headings[index]
  if not heading then return end

  if M.state.source_buf and vim.api.nvim_buf_is_valid(M.state.source_buf) then
    M.clear_preview_highlight()
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

function M.toggle()
  if M.state.visible then
    M.close_window()
  else
    M.render_window()
  end
end

-- =============================================
-- セクション移動 (move-to-heading)
-- =============================================

local function move_selection_to_heading(pattern, to_bottom)
  local v_start = vim.fn.line("v")
  local v_end = vim.fn.line(".")
  if v_start > v_end then
    v_start, v_end = v_end, v_start
  end
  local line_count = v_end - v_start + 1

  local target_line = nil
  for i = 1, vim.fn.line('$') do
    local line = vim.fn.getline(i)
    if line:match(pattern) then
      target_line = i
      break
    end
  end

  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  local dest
  if target_line then
    if to_bottom then
      local next_heading = nil
      for i = target_line + 1, vim.fn.line('$') do
        if vim.fn.getline(i):match("^#+ ") then
          next_heading = i
          break
        end
      end
      dest = (next_heading and next_heading - 1) or vim.fn.line('$')
    else
      dest = target_line
    end
  else
    dest = 0
  end

  vim.cmd(string.format(":%d,%dmove %d", v_start, v_end, dest))

  local new_start = dest + 1
  vim.fn.append(new_start - 1, "")

  local new_end = new_start + line_count
  vim.cmd(string.format("normal! %dGV%dG=", new_start + 1, new_end))

  local return_line
  if dest >= v_end then
    return_line = v_start - 1
  else
    return_line = v_start - 1 + line_count + 1
  end
  if return_line < 1 then return_line = 1 end
  vim.api.nvim_win_set_cursor(0, {return_line, 0})
end

-- =============================================
-- setup
-- =============================================

function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- 見出しレベル別のハイライトを定義
  local heading_colors = {
    "#7aa2f7", "#e0af68", "#9ece6a", "#1abc9c", "#bb9af7", "#fca7ea",
  }
  local bg_dark = "#1a1b26"
  for i = 1, 6 do
    vim.api.nvim_set_hl(0, "HeadingJumpH" .. i, { fg = heading_colors[i], bold = true })
    vim.api.nvim_set_hl(0, "HeadingJumpH" .. i .. "Preview", {
      fg = bg_dark, bg = heading_colors[i], bold = true,
    })
  end

  local group = vim.api.nvim_create_augroup("HeadingJump", { clear = true })
  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    pattern = "*.md",
    callback = function()
      if M.state.visible then M.close_window() end
    end,
  })

  -- 見出しジャンプ
  vim.keymap.set("n", "<leader>h", M.toggle, {
    noremap = true, silent = true,
    desc = "Toggle heading jump window (#～######)",
  })

  -- セクション移動キーマップ
  vim.keymap.set("v", "<leader>mn", function() move_selection_to_heading("^# NEXT", false) end, { desc = "Move to # NEXT", silent = true })
  vim.keymap.set("v", "<leader>mw", function() move_selection_to_heading("^## WANTS", false) end, { desc = "Move to ## WANTS", silent = true })
  vim.keymap.set("v", "<leader>md", function() move_selection_to_heading("^# DONE", true) end, { desc = "Move to # DONE (bottom)", silent = true })
  vim.keymap.set("v", "<leader>ms", function() move_selection_to_heading("^## SHOULD", false) end, { desc = "Move to ## SHOULD", silent = true })
  vim.keymap.set("v", "<leader>mm", function() move_selection_to_heading("^## MUST", false) end, { desc = "Move to ## MUST", silent = true })
  vim.keymap.set("v", "<leader>mb", function() move_selection_to_heading("^# BACKLOG", false) end, { desc = "Move to # BACKLOG", silent = true })
  vim.keymap.set("v", "<leader>mi", function() move_selection_to_heading("^# WIP", false) end, { desc = "Move to # WIP", silent = true })
end

return M
