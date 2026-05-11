-- Obsidian-style [[note#H]] / [[#H]] / ![[note#H]] / ![[#H]] の
-- # 以降で heading 候補を提示する blink.cmp source。
-- - note 名空（self-ref）はカレントバッファから抽出
-- - score_offset を高めに設定し、ファイル候補より優先表示する

local M = {}

local function get_vault_dir()
  local ok, api = pcall(require, 'obsidian.api')
  if ok and api.resolve_workspace_dir then
    local ok2, root = pcall(api.resolve_workspace_dir)
    if ok2 and root then return tostring(root) end
  end
  return vim.fn.expand(
    vim.env.OBSIDIAN_VAULT_PATH
      or '~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault'
  )
end

local function resolve_path(name)
  if not name or name == '' then return nil end
  name = vim.trim(name)
  if name:sub(1, 1) == '/' or name:sub(1, 1) == '~' then
    local expanded = vim.fn.expand(name)
    if vim.fn.filereadable(expanded) == 1 then return expanded end
  end
  local root = get_vault_dir()
  local candidate = root .. '/' .. name
  if vim.fn.filereadable(candidate) == 1 then return candidate end
  local with_md = candidate .. '.md'
  if vim.fn.filereadable(with_md) == 1 then return with_md end
  local basename = vim.fs.basename(name)
  if not basename:match('%.md$') then basename = basename .. '.md' end
  local found = vim.fs.find(basename, { path = root, type = 'file', limit = 1 })
  if found and found[1] then return found[1] end
  return nil
end

local function extract_headings(lines)
  local out = {}
  for _, line in ipairs(lines) do
    local hashes, text = line:match('^(#+)%s+(.+)$')
    if hashes and text then
      out[#out + 1] = { level = #hashes, text = vim.trim(text) }
    end
  end
  return out
end

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
    local path = resolve_path(note_name)
    if not path then return empty() end
    local ok, file_lines = pcall(vim.fn.readfile, path)
    if not ok then return empty() end
    lines = file_lines
  end

  local headings = extract_headings(lines)
  local items = {}
  local row = context.cursor[1]
  local replace_start = context.cursor[2] - #after:sub(hash_pos + 1)
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
            start = { line = row - 1, character = replace_start },
            ['end'] = { line = row - 1, character = context.cursor[2] },
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
