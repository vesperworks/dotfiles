-- lua/vw/callout.lua
-- Callout の挿入・種類変更・解除

local util = require("vw._util")

local M = {}

-- Callout 種類定義（一元管理）
local CALLOUT_TYPES = {
  { "note", "📝 Note", "n" },
  { "warning", "⚠️ Warning", "s" },
  { "error", "❌ Error", "d" },
  { "info", "ℹ️ Info", "f" },
  { "tip", "💡 Tip", "g" },
  { "success", "✅ Success", "h" },
  { "question", "❓ Question", "r" },
  { "think", "🤔 Think", "t" },
  { "idea", "💡 Idea", "i" },
  { "ai", "🤖 AI", "a" },
  { "prompt", "💬 Prompt", "p" },
  { "plan", "📋 Plan", "l" },
  { "journaling", "📓 Journaling", "j" },
  { "quote", "🗣️ Quote (タイトル付き)", "q" },
  { "blockquote", "📎 Blockquote (>のみ)", "b" },
  { "code", "💻 Code Block", "c" },
}

-- Callout ヘッダー生成（tag 付与ロジックの一元化）
local CALLOUT_TAGS = { think = "#think", idea = "#idea", ai = "#ai", journaling = "#journaling" }

local function build_callout_header(indent, callout_type)
  local tag = CALLOUT_TAGS[callout_type]
  if tag then
    return indent .. "> [!" .. callout_type .. "] " .. tag
  end
  return indent .. "> [!" .. callout_type .. "]"
end

--- 汎用選択UI（Insert mode文字入力受付）
function M.show_selection_buffer(options, prompt, default_key, callback)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = { prompt, "" }

  for _, option in ipairs(options) do
    local key = option[3] ~= "" and option[3] or "Space"
    local display = option[2]
    table.insert(lines, string.format("  %s: %s", key, display))
  end

  table.insert(lines, "")
  table.insert(lines, "  Enter: デフォルト | Esc: キャンセル")
  table.insert(lines, "")
  table.insert(lines, "  ▶ キーを入力してください...")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 4, vim.o.columns - 10)
  local height = math.min(#lines + 2, vim.o.lines - 10)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'cursor',
    width = width,
    height = height,
    row = 1,
    col = 1,
    border = 'rounded',
    style = 'minimal',
    title = ' 選択してください ',
    title_pos = 'center'
  })

  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false

  local function close_and_callback(result)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    callback(result)
  end

  local function setup_input_handler()
    vim.cmd('startinsert')

    local group = vim.api.nvim_create_augroup('SelectionInput', { clear = true })

    vim.api.nvim_create_autocmd('InsertCharPre', {
      buffer = buf,
      group = group,
      callback = function()
        local char = vim.v.char

        if char == '\n' or char == '\r' then
          return
        end

        vim.v.char = ''

        vim.schedule(function()
          if char == ' ' then
            for _, option in ipairs(options) do
              if option[1] == "" then
                vim.api.nvim_del_augroup_by_id(group)
                close_and_callback(option)
                return
              end
            end
            vim.api.nvim_del_augroup_by_id(group)
            close_and_callback(nil)
            return
          end

          for _, option in ipairs(options) do
            if option[3] == char then
              vim.api.nvim_del_augroup_by_id(group)
              close_and_callback(option)
              return
            end
          end
        end)
      end
    })

    vim.keymap.set('i', '<CR>', function()
      vim.api.nvim_del_augroup_by_id(group)
      if default_key then
        for _, option in ipairs(options) do
          if option[1] == default_key then
            close_and_callback(option)
            return
          end
        end
      end
      close_and_callback(nil)
    end, { buffer = buf, silent = true })

    vim.keymap.set('i', '<Esc>', function()
      vim.api.nvim_del_augroup_by_id(group)
      close_and_callback(nil)
    end, { buffer = buf, silent = true })

    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(win),
      group = group,
      callback = function()
        vim.api.nvim_del_augroup_by_id(group)
      end
    })
  end

  vim.defer_fn(setup_input_handler, 10)
end

--- Callout選択UI
function M.show_callout_selection(callout_types, prompt, callback)
  M.show_selection_buffer(callout_types, "🔟 " .. prompt, "quote", callback)
end

--- 言語選択UI
function M.show_language_selection(languages, prompt, callback)
  M.show_selection_buffer(languages, "💻 " .. prompt, "", callback)
end

--- コードブロックを挿入する
function M.insert_code_block()
  local start_row, end_row = util.get_visual_range()
  if not start_row then return end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

  local common_indent = ""
  for _, line in ipairs(lines) do
    if line ~= "" then
      local indent = string.match(line, "^(%s*)")
      if common_indent == "" or #indent < #common_indent then
        common_indent = indent
      end
    end
  end

  local languages = {
    { "markdown", "📝 Markdown", "m" },
    { "lua", "🌙 Lua", "l" },
    { "javascript", "🟨 JavaScript", "j" },
    { "typescript", "🔷 TypeScript", "t" },
    { "python", "🐍 Python", "p" },
    { "bash", "💻 Bash", "b" },
    { "json", "📄 JSON", "n" },
    { "yaml", "🔧 YAML", "y" },
    { "css", "🎨 CSS", "c" },
    { "html", "🌐 HTML", "h" },
    { "", "⚪ No language", "" },
  }

  M.show_language_selection(languages, "コードブロックの言語を選択:", function(choice)
    if not choice then return end

    local language = choice[1]
    local new_lines = {}

    table.insert(new_lines, common_indent .. "```" .. language)

    for _, line in ipairs(lines) do
      if line == "" then
        table.insert(new_lines, "")
      else
        local content_line = string.gsub(line, "^" .. common_indent, "")
        table.insert(new_lines, common_indent .. content_line)
      end
    end

    table.insert(new_lines, common_indent .. "```")

    vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
    vim.api.nvim_win_set_cursor(0, {start_row + 1, #common_indent})
  end)
end

--- Calloutを解除する
function M.remove_callout(start_row, end_row)
  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
  local new_lines = {}

  for _, line in ipairs(lines) do
    if string.match(line, "^%s*>%s*%[!") then
      -- Calloutヘッダー行を削除
    elseif string.match(line, "^%s*>") then
      local indent = string.match(line, "^(%s*)")
      local content = string.gsub(line, "^%s*>%s*", "")
      table.insert(new_lines, indent .. content)
    else
      table.insert(new_lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
end

--- 新しいCalloutを作成する
function M.create_new_callout(start_row, end_row)
  local total_lines = vim.api.nvim_buf_line_count(0)

  if start_row < 1 or end_row > total_lines or start_row > end_row then
    return
  end

  M.show_callout_selection(CALLOUT_TYPES, "Calloutの種類を選択:", function(choice)
    if not choice then return end

    local callout_type = choice[1]

    if callout_type == "code" then
      M.insert_code_block()
      return
    end
    local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
    local new_lines = {}

    local common_indent = ""
    for _, line in ipairs(lines) do
      if line ~= "" then
        local indent = string.match(line, "^(%s*)")
        if common_indent == "" or #indent < #common_indent then
          common_indent = indent
        end
      end
    end

    if callout_type == "blockquote" then
      for _, line in ipairs(lines) do
        if line == "" then
          table.insert(new_lines, common_indent .. ">")
        elseif string.match(line, "^%s*>") then
          table.insert(new_lines, line)
        else
          local content = string.gsub(line, "^" .. common_indent, "")
          table.insert(new_lines, common_indent .. "> " .. content)
        end
      end
    else
      table.insert(new_lines, build_callout_header(common_indent, callout_type))

      for _, line in ipairs(lines) do
        if line == "" then
          table.insert(new_lines, common_indent .. ">")
        elseif string.match(line, "^%s*>") then
          table.insert(new_lines, line)
        else
          local content = string.gsub(line, "^" .. common_indent, "")
          table.insert(new_lines, common_indent .. "> " .. content)
        end
      end
    end

    local success, err = pcall(function()
      vim.api.nvim_buf_set_lines(0, start_row - 1, end_row, false, new_lines)
    end)

    if not success then
      return
    end

    if callout_type == "blockquote" then
      vim.api.nvim_win_set_cursor(0, {start_row, #(common_indent .. "> ")})
    else
      vim.api.nvim_win_set_cursor(0, {start_row + 1, #(common_indent .. "> ")})
    end
  end)
end

--- Calloutメイン関数（挿入 or 解除）
function M.insert_callout()
  local start_row, end_row = util.get_visual_range()
  if not start_row then return end

  local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)

  local has_quote = false
  for _, line in ipairs(lines) do
    if string.match(line, "^%s*>") then
      has_quote = true
      break
    end
  end

  if has_quote then
    M.remove_callout(start_row, end_row)
  else
    M.create_new_callout(start_row, end_row)
  end
end

--- キーマップを設定
function M.setup()
  local opts = { noremap = true, silent = true }

  vim.keymap.set('n', '<leader>c', M.insert_callout,
    vim.tbl_extend('force', opts, { desc = "Insert/toggle/remove Callout" }))
  vim.keymap.set('v', '<leader>c', M.insert_callout,
    vim.tbl_extend('force', opts, { desc = "Insert/toggle/remove Callout (Visual)" }))
end

return M
