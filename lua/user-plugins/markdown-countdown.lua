local M = {}

local ns_id = vim.api.nvim_create_namespace('markdown_countdown')
local countdown_timer = nil
local start_times = {} -- { [bufnr] = { [line_content] = timestamp } }

-- 相対時間パターン: Nh, Nm, Ns（組み合わせ可: 1h30m, 2m30s 等）
local function parse_duration_seconds(line)
  local hours = line:match('(%d+)h%f[%A]')
  local mins = line:match('(%d+)m%f[%A]')
  local secs = line:match('(%d+)s%f[%A]')

  if not hours and not mins and not secs then
    return nil
  end

  local total = 0
  if hours then total = total + tonumber(hours) * 3600 end
  if mins then total = total + tonumber(mins) * 60 end
  if secs then total = total + tonumber(secs) end

  return total > 0 and total or nil
end

-- URLを除去した行を返す
local function strip_urls(line)
  return line:gsub('https?://[%S]+', '')
end

-- 行から目標時刻（UNIX time）を取得
local function parse_target_time(line, bufnr)
  local clean = strip_urls(line)

  -- パターン1: HH:MM 絶対時刻（優先）
  local h_str, m_str = clean:match('(%d+):(%d+)')
  if h_str then
    local h, m = tonumber(h_str), tonumber(m_str)
    if h >= 0 and h <= 23 and m >= 0 and m <= 59 then
      local t = os.date("*t")
      t.hour, t.min, t.sec = h, m, 0
      return os.time(t)
    end
  end

  -- パターン2: 相対時間（Nh, Nm, Ns）- 初回検出時刻からカウントダウン
  local duration = parse_duration_seconds(clean)
  if duration then
    if not start_times[bufnr] then start_times[bufnr] = {} end
    if not start_times[bufnr][line] then
      start_times[bufnr][line] = os.time()
    end
    return start_times[bufnr][line] + duration
  end

  return nil
end

-- 残り時間を表示用テキストに変換
-- @return (text, state) state: "limit" / "warn" / "active"
local function format_remaining(target_time)
  local diff = target_time - os.time()
  if diff <= 0 then
    return nil, "limit"
  end

  local h = math.floor(diff / 3600)
  local m = math.floor((diff % 3600) / 60)
  local s = diff % 60

  local text
  if h > 0 then
    text = string.format(" ⏳%dh%dm ", h, m)
  elseif m > 0 then
    text = string.format(" ⏳%dm%ds ", m, s)
  else
    text = string.format(" ⏳%ds ", s)
  end

  if diff < 3600 then
    return text, "warn"
  end
  return text, "active"
end

-- ハイライトグループとextmarkの設定マップ
local state_config = {
  limit = {
    line_hl = 'MarkdownCountdownLimit',
    virt_hl = 'MarkdownCountdownLimit',
    virt_text = ' LIMIT ',
  },
  warn = {
    line_hl = 'MarkdownCountdownWarnLine',
    virt_hl = 'MarkdownCountdownWarn',
  },
  active = {
    line_hl = 'MarkdownCountdownActiveLine',
    virt_hl = 'MarkdownCountdownActive',
  },
}

function M.update_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  if vim.bo[bufnr].filetype ~= 'markdown' then return end

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local seen_lines = {}

  for lnum, line in ipairs(lines) do
    seen_lines[line] = true
    local target_time = parse_target_time(line, bufnr)
    if target_time then
      local text, state = format_remaining(target_time)
      local cfg = state_config[state]
      if cfg then
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, 0, {
          line_hl_group = cfg.line_hl,
          priority = 8000,
        })
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, lnum - 1, 0, {
          virt_text = { { cfg.virt_text or text, cfg.virt_hl } },
          virt_text_pos = 'eol',
          priority = 8000,
        })
      end
    end
  end

  -- 消えた行のstart_timesをクリーンアップ
  if start_times[bufnr] then
    for content in pairs(start_times[bufnr]) do
      if not seen_lines[content] then
        start_times[bufnr][content] = nil
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

  -- バッファ削除時のクリーンアップ
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    callback = function(ev)
      start_times[ev.buf] = nil
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
