-- Obsidian-style ![[note]] / ![[note#heading]] transclusion via virt_lines.
-- Phase 1 (full file expansion) + Phase 2 (heading section slicing).
local M = {}

local ns = vim.api.nvim_create_namespace('vw_transclusion')

local enabled = true
---@type table<string, {mtime:number, lines:string[]}>
local file_cache = {}
---@type table<integer, userdata>
local debounce_timers = {}

-- vault root: obsidian.nvim の API → 環境変数 → デフォルト の順
local function vault_dir()
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

local function read_file_cached(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then return nil end
  local cached = file_cache[path]
  if cached and cached.mtime == stat.mtime.sec then
    return cached.lines
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return nil end
  file_cache[path] = { mtime = stat.mtime.sec, lines = lines }
  return lines
end

-- name → 絶対パス解決（vault relative / basename anywhere）
local function resolve_path(name)
  if not name or name == '' then return nil end
  name = vim.trim(name)

  -- absolute / home
  if name:sub(1, 1) == '/' or name:sub(1, 1) == '~' then
    local expanded = vim.fn.expand(name)
    if vim.fn.filereadable(expanded) == 1 then return expanded end
  end

  local root = vault_dir()

  -- vault root relative（拡張子付き/なし両対応）
  local candidate = root .. '/' .. name
  if vim.fn.filereadable(candidate) == 1 then return candidate end
  local with_md = candidate .. '.md'
  if vim.fn.filereadable(with_md) == 1 then return with_md end

  -- basename anywhere in vault
  local basename = vim.fs.basename(name)
  if not basename:match('%.md$') then basename = basename .. '.md' end
  local found = vim.fs.find(basename, { path = root, type = 'file', limit = 1 })
  if found and found[1] then return found[1] end

  return nil
end

local function normalize_heading(text)
  return (text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')):lower()
end

-- Obsidian 準拠: target heading から次の同レベル以上の heading 直前まで
local function slice_section(lines, heading)
  if not heading or heading == '' then return lines end

  local target = normalize_heading(heading)
  local start_idx, start_level

  for i, line in ipairs(lines) do
    local hashes, text = line:match('^(#+)%s+(.+)$')
    if hashes and normalize_heading(text) == target then
      start_idx = i
      start_level = #hashes
      break
    end
  end

  if not start_idx then return nil end

  local end_idx = #lines
  for i = start_idx + 1, #lines do
    local hashes = lines[i]:match('^(#+)%s+')
    if hashes and #hashes <= start_level then
      end_idx = i - 1
      break
    end
  end

  local out = {}
  for i = start_idx, end_idx do
    out[#out + 1] = lines[i]
  end
  return out
end

local function build_virt_lines(content)
  local virt = {}
  for _, line in ipairs(content) do
    virt[#virt + 1] = { { '│ ' .. line, 'Comment' } }
  end
  return virt
end

local function render(bufnr)
  if not enabled then return end
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].filetype ~= 'markdown' then return end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local link = line:match('!%[%[([^%]]+)%]%]')
    if link then
      local self_ref = link:sub(1, 1) == '#'
      local name, heading
      if self_ref then
        heading = link:sub(2)
        -- ![[#]] や ![[#  ]] のような空 heading は無限視覚ループになるので skip
        if heading == '' or heading:match('^%s*$') then goto continue end
      else
        name, heading = link:match('^([^#]+)#(.+)$')
        if not name then name = link end
      end

      local file_lines
      if self_ref then
        file_lines = lines
      else
        local path = resolve_path(name)
        if path then file_lines = read_file_cached(path) end
      end

      if file_lines then
        local content
        if heading then
          content = slice_section(file_lines, heading)
        else
          content = file_lines
        end
        if content and #content > 0 then
          vim.api.nvim_buf_set_extmark(bufnr, ns, lnum - 1, 0, {
            virt_lines = build_virt_lines(content),
            virt_lines_above = false,
          })
        end
      end
    end
    ::continue::
  end
end

local function schedule_render(bufnr)
  local existing = debounce_timers[bufnr]
  if existing then
    existing:stop()
    existing:close()
    debounce_timers[bufnr] = nil
  end
  local timer = vim.uv.new_timer()
  debounce_timers[bufnr] = timer
  timer:start(
    200,
    0,
    vim.schedule_wrap(function()
      render(bufnr)
      local t = debounce_timers[bufnr]
      if t then
        t:close()
        debounce_timers[bufnr] = nil
      end
    end)
  )
end

function M.setup()
  local group = vim.api.nvim_create_augroup('VwTransclusion', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'TextChanged', 'InsertLeave' }, {
    group = group,
    pattern = '*.md',
    callback = function(ev)
      schedule_render(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'markdown',
    callback = function(ev)
      vim.keymap.set('n', '<leader>!', function()
        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, { '![[#]]' })
        vim.api.nvim_win_set_cursor(0, { row, col + 4 })
        vim.cmd('startinsert')
      end, { buffer = ev.buf, desc = 'Insert ![[#]] embed self-ref + completion' })
    end,
  })

  vim.api.nvim_create_user_command('VwTransclusionRefresh', function()
    file_cache = {}
    render(vim.api.nvim_get_current_buf())
  end, { desc = 'Refresh ![[]] embed transclusion (clears cache)' })

  vim.api.nvim_create_user_command('VwTransclusionToggle', function()
    enabled = not enabled
    local buf = vim.api.nvim_get_current_buf()
    if enabled then
      render(buf)
      vim.notify('Transclusion: ON')
    else
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      vim.notify('Transclusion: OFF')
    end
  end, { desc = 'Toggle ![[]] embed transclusion' })
end

return M
