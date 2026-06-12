-- Obsidian-style ![[note]] / ![[note#heading]] transclusion via virt_lines.
-- Phase 1 (full file expansion) + Phase 2 (heading section slicing).
local M = {}

local ob = require('vw._obsidian')

local ns = vim.api.nvim_create_namespace('vw_transclusion')

local enabled = true
---@type table<integer, userdata>
local debounce_timers = {}

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

-- テスト用 export（内部 API）
M._normalize_heading = normalize_heading
M._slice_section = slice_section

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
        local path = ob.resolve_path(name)
        if path then file_lines = ob.read_file_cached(path) end
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
    ob.clear_cache()
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
