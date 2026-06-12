-- Obsidian-style [[note#H]] / [[#H]] / ![[note#H]] / ![[#H]] の
-- # 以降で heading 候補を提示する blink.cmp source。
-- - note 名空（self-ref）はカレントバッファから抽出
-- - score_offset を高めに設定し、ファイル候補より優先表示する

local M = {}

local ob = require('vw._obsidian')

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { '#' }
end

function M:get_completions(context, resolve)
  local empty = function()
    resolve({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end

  local line = context.line:sub(1, context.cursor[2])

  -- カーソル前の最後の '[[' を探す（embed の '![[' も含む）
  local _, bracket_end = line:find('.*%[%[')
  if not bracket_end then return empty() end

  local after = line:sub(bracket_end + 1)
  if after:find('%]%]') then return empty() end -- 既に閉じている

  local hash_pos = after:find('#[^#]*$')
  if not hash_pos then return empty() end

  local note_name = after:sub(1, hash_pos - 1)
  local query = after:sub(hash_pos + 1):lower()

  local lines
  if note_name == '' then
    lines = vim.api.nvim_buf_get_lines(context.bufnr, 0, -1, false)
  else
    local path = ob.resolve_path(note_name)
    if not path then return empty() end
    lines = ob.read_file_cached(path)
    if not lines then return empty() end
  end

  local headings = ob.extract_headings(lines)
  local items = {}
  local row = context.cursor[1]
  -- textEdit の character は UTF-16 単位（バイト値のままだと日本語行でズレる）
  local replace_start_byte = context.cursor[2] - #after:sub(hash_pos + 1)
  local edit_start = ob.utf16_col(context.line, replace_start_byte)
  local edit_end = ob.utf16_col(context.line, context.cursor[2])
  for _, h in ipairs(headings) do
    if query == '' or h.text:lower():find(query, 1, true) then
      items[#items + 1] = {
        label = string.rep('#', h.level) .. ' ' .. h.text,
        kind = vim.lsp.protocol.CompletionItemKind.Reference,
        insertText = h.text,
        filterText = h.text,
        score_offset = 1000,
        textEdit = {
          newText = h.text,
          range = {
            start = { line = row - 1, character = edit_start },
            ['end'] = { line = row - 1, character = edit_end },
          },
        },
      }
    end
  end

  resolve({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

return M
