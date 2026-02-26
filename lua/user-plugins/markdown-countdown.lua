local M = {}

local ns_id = vim.api.nvim_create_namespace('markdown_countdown')
local countdown_timer = nil

local function parse_target_time(line)
  local h_str, m_str = line:match('(%d+):(%d+)')
  if h_str then
    local h, m = tonumber(h_str), tonumber(m_str)
    if h >= 0 and h <= 23 and m >= 0 and m <= 59 then
      local t = os.date("*t")
      t.hour, t.min, t.sec = h, m, 0
      return os.time(t)
    end
  end

  local hour_str = line:match('(%d+)h%f[%A]')
  if hour_str then
    local h = tonumber(hour_str)
    if h >= 0 and h <= 23 then
      local t = os.date("*t")
      t.hour, t.min, t.sec = h, 0, 0
      return os.time(t)
    end
  end

  return nil
end

local function format_remaining(target_time)
  local diff = target_time - os.time()
  if diff <= 0 then
    return nil, true
  end

  local h = math.floor(diff / 3600)
  local m = math.floor((diff % 3600) / 60)
  local s = diff % 60

  if h > 0 then
    return string.format(" ⏳%dh%dm ", h, m), false
  elseif m > 0 then
    return string.format(" ⏳%dm%ds ", m, s), false
  else
    return string.format(" ⏳%ds ", s), false
  end
end

function M.update_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].filetype ~= 'markdown' then return end

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local target_time = parse_target_time(line)
    if target_time then
      local text, is_limit = format_remaining(target_time)
      if is_limit then
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, 0, {
          line_hl_group = 'MarkdownCountdownLimit',
          priority = 8000,
        })
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, 0, {
          virt_text = { { ' LIMIT ', 'MarkdownCountdownLimit' } },
          virt_text_pos = 'eol',
          priority = 8000,
        })
      elseif text then
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, 0, {
          line_hl_group = 'MarkdownCountdownActiveLine',
          priority = 8000,
        })
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, 0, {
          virt_text = { { text, 'MarkdownCountdownActive' } },
          virt_text_pos = 'eol',
          priority = 8000,
        })
      end
    end
  end
end

function M.update_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].filetype == 'markdown' then
      M.update_buffer(bufnr)
    end
  end
end

function M.setup()
  countdown_timer = vim.uv.new_timer()
  countdown_timer:start(0, 1000, vim.schedule_wrap(function()
    M.update_all()
  end))

  local group = vim.api.nvim_create_augroup('MarkdownCountdown', { clear = true })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
    group = group,
    pattern = '*.md',
    callback = function(ev)
      vim.schedule(function()
        M.update_buffer(ev.buf)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    group = group,
    pattern = '*.md',
    callback = function(ev)
      vim.schedule(function()
        M.update_buffer(ev.buf)
      end)
    end,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if countdown_timer then
        countdown_timer:stop()
        countdown_timer:close()
        countdown_timer = nil
      end
    end,
  })
end

return M
