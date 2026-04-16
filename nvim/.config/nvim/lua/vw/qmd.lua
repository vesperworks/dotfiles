-- lua/vw/qmd.lua
-- QMD (Quick Markdown Search) Telescope picker
-- 3層カスケード検索: RG(即座) → BM25(やや遅れ) → Hybrid(Enter)

local M = {}

local qmd_bin = vim.fn.exepath("qmd")
if qmd_bin == "" then qmd_bin = vim.fn.expand("~/.bun/bin/qmd") end

-- キャッシュ
local collection_cache = {}
local preview_cache = {}

-- チャンクハイライト（default=true でカラースキームで上書き可）
vim.api.nvim_set_hl(0, "QmdChunk", { bg = "#4a5080", default = true })

-- ソース別の表示設定
local SOURCE_CONFIG = {
  rg     = { label = "RG",  hl = "DiagnosticInfo" },  -- 青
  bm25   = { label = "BM",  hl = "DiagnosticWarn" },  -- 黄
  hybrid = { label = "QMD", hl = "DiagnosticOk" },    -- 緑
}

-------------------------------------------------------------------------------
-- ヘルパー: コレクション・パス解決
-------------------------------------------------------------------------------

local function get_collection_path(name)
  if collection_cache[name] then return collection_cache[name] end
  local result = vim.system({ qmd_bin, "collection", "show", name }, { text = true }):wait()
  if result.code ~= 0 then return nil end
  for line in result.stdout:gmatch("[^\n]+") do
    local path = line:match("Path:%s+(.+)")
    if path then
      path = vim.trim(path)
      collection_cache[name] = path
      return path
    end
  end
  return nil
end

local function get_collection_names()
  local result = vim.system({ qmd_bin, "collection", "list" }, { text = true }):wait()
  if result.code ~= 0 then return {} end
  local names = {}
  for name in result.stdout:gmatch("(%S+)%s+%(qmd://") do
    table.insert(names, name)
  end
  return names
end

local function get_search_paths(collection)
  local paths = {}
  if collection then
    local p = get_collection_path(collection)
    if p then table.insert(paths, p) end
  else
    for _, name in ipairs(get_collection_names()) do
      local p = get_collection_path(name)
      if p then table.insert(paths, p) end
    end
  end
  return paths
end

local function resolve_qmd_uri(uri)
  local col, rel = uri:match("^qmd://([^/]+)/(.+)$")
  if not col or not rel then return nil end
  local base = get_collection_path(col)
  if not base then return nil end

  local path = base .. "/" .. rel
  local f = io.open(path, "r")
  if f then f:close(); return path end

  local alt = base .. "/" .. rel:gsub("%-", "_")
  f = io.open(alt, "r")
  if f then f:close(); return alt end

  local dir = base .. "/" .. (rel:match("^(.+)/") or "")
  local stem = rel:match("([^/]+)%.md$")
  if stem then
    local norm = stem:gsub("%-", "_"):gsub("_$", "")
    local p = io.popen('ls "' .. dir .. '" 2>/dev/null')
    if p then
      for line in p:lines() do
        if line:gsub("%.md$", ""):gsub("%-", "_"):gsub("_$", "") == norm then
          p:close()
          return dir .. "/" .. line
        end
      end
      p:close()
    end
  end
  return nil
end

local function path_to_display(real_path)
  for _, base in pairs(collection_cache) do
    if real_path:sub(1, #base) == base then
      return real_path:sub(#base + 2)
    end
  end
  return vim.fn.fnamemodify(real_path, ":t")
end

local function parse_qmd_json(output)
  if not output then return nil end
  local json_str = output:match("%[.+%]")
  if not json_str then return nil end
  local ok, data = pcall(vim.json.decode, json_str)
  if not ok then return nil end
  return data
end

local function extract_line_from_snippet(snippet)
  if not snippet then return 1 end
  return tonumber(snippet:match("@@ %-(%d+)")) or 1
end

--- snippet からチャンク範囲を抽出 { start_line, line_count }
local function extract_chunk_range(snippet)
  if not snippet then return nil end
  local start, count = snippet:match("@@ %-(%d+),(%d+)")
  if start and count then
    return { start = tonumber(start), count = tonumber(count) }
  end
  return nil
end

local function preload_collections(results)
  local seen = {}
  for _, entry in ipairs(results) do
    local col = (entry.file or ""):match("^qmd://([^/]+)/")
    if col and not seen[col] then
      seen[col] = true
      get_collection_path(col)
    end
  end
end

-------------------------------------------------------------------------------
-- ヘルパー: プレビューハイライト
-------------------------------------------------------------------------------

--- プレビューバッファにキーワードハイライト + チャンク範囲ハイライト
local function highlight_preview(bufnr, lines, query, chunk_range)
  local ns = vim.api.nvim_create_namespace("qmd_preview_hl")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  -- チャンク範囲に背景色ハイライト
  if chunk_range then
    local s = math.max(chunk_range.start - 1, 0)
    local e = math.min(s + chunk_range.count, #lines)
    for row = s, e - 1 do
      vim.api.nvim_buf_add_highlight(bufnr, ns, "QmdChunk", row, 0, -1)
    end
  end

  -- キーワードハイライト
  local words = {}
  for w in query:gmatch("%S+") do
    if #w >= 2 then table.insert(words, w) end
  end
  if #words == 0 then return end

  for i, line in ipairs(lines) do
    local ll = line:lower()
    for _, word in ipairs(words) do
      local lw = word:lower()
      local s_pos = 0
      while true do
        local s, e = ll:find(lw, s_pos + 1, true)
        if not s then break end
        vim.api.nvim_buf_add_highlight(bufnr, ns, "Search", i - 1, s - 1, e)
        s_pos = e
      end
    end
  end
end

-------------------------------------------------------------------------------
-- エントリの正規化・マージ
-------------------------------------------------------------------------------

--- rg の出力を正規化エントリに変換
local function normalize_rg(data)
  local entries = {}
  for _, line in ipairs(data) do
    if line ~= "" then
      local file, count = line:match("^(.+):(%d+)$")
      if file and count then
        table.insert(entries, {
          source = "rg",
          title = vim.fn.fnamemodify(file, ":t:r"),
          display_path = path_to_display(file),
          real_path = file,
          score = nil,
          lnum = 1,
        })
      end
    end
  end
  if #entries > 20 then entries = { unpack(entries, 1, 20) } end
  return entries
end

--- qmd JSON を正規化エントリに変換
local function normalize_qmd(data, source)
  local entries = {}
  for _, e in ipairs(data or {}) do
    local rp = resolve_qmd_uri(e.file)
    table.insert(entries, {
      source = source,
      title = e.title or (e.file or ""):gsub("^qmd://[^/]+/", ""):gsub("%.md$", ""),
      display_path = (e.file or ""):gsub("^qmd://[^/]+/", ""),
      real_path = rp,
      score = e.score,
      lnum = extract_line_from_snippet(e.snippet),
      chunk_range = extract_chunk_range(e.snippet),
      qmd_uri = e.file,
    })
  end
  return entries
end

--- 3ソースのエントリをマージ（重複はソース優先順で除去）
local function merge_results(rg, bm25, hybrid)
  local merged = {}
  local seen = {}

  -- 優先順: hybrid > bm25 > rg
  for _, group in ipairs({ hybrid, bm25, rg }) do
    for _, entry in ipairs(group) do
      local key = entry.real_path or entry.display_path
      if key and not seen[key] then
        seen[key] = true
        table.insert(merged, entry)
      end
    end
  end

  return merged
end

-------------------------------------------------------------------------------
-- Telescope: エントリメーカー・プレビュワー
-------------------------------------------------------------------------------

local function make_entry_maker(current_query)
  local entry_display = require("telescope.pickers.entry_display")
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 5 },  -- [RG] [BM] [QMD]
      { width = 4 },  -- score
      { remaining = true },
    },
  })

  return function(entry)
    local cfg = SOURCE_CONFIG[entry.source] or SOURCE_CONFIG.rg
    local score_str = entry.score and (math.floor(entry.score * 100) .. "%") or ""

    return {
      value = entry,
      display = function()
        return displayer({
          { "[" .. cfg.label .. "]", cfg.hl },
          { score_str, "TelescopeResultsNumber" },
          { entry.title .. "  " .. entry.display_path, cfg.hl },
        })
      end,
      ordinal = entry.title .. " " .. entry.display_path,
      path = entry.real_path,
      lnum = entry.lnum,
      filename = entry.real_path,
    }
  end
end

local function make_previewer(get_query)
  local previewers = require("telescope.previewers")
  return previewers.new_buffer_previewer({
    title = "Preview",
    define_preview = function(self, entry)
      local val = entry.value
      if not val then return end
      local query = get_query()
      local cache_key = val.real_path or val.qmd_uri or val.display_path

      -- コンテンツ取得（キャッシュ or 読み取り）
      local lines = cache_key and preview_cache[cache_key]

      if not lines and val.real_path then
        local f = io.open(val.real_path, "r")
        if f then
          lines = vim.split(f:read("*a"), "\n")
          f:close()
          if #lines > 200 then lines = { unpack(lines, 1, 200) } end
        end
      end

      if not lines and val.qmd_uri then
        local result = vim.system({ qmd_bin, "get", val.qmd_uri, "-l", "200" }, { text = true }):wait()
        if result.code == 0 and result.stdout and result.stdout ~= "" then
          lines = vim.split(result.stdout, "\n")
        end
      end

      if not lines then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "プレビューを取得できません" })
        return
      end

      if cache_key then preview_cache[cache_key] = lines end
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.bo[self.state.bufnr].syntax = "markdown"
      highlight_preview(self.state.bufnr, lines, query, val.chunk_range)

      -- チャンク範囲の先頭にスクロール（なければ lnum）
      local target_line = entry.lnum or 1
      if val.chunk_range then
        target_line = math.max(val.chunk_range.start, 1)
      end
      if target_line > 1 then
        pcall(vim.api.nvim_win_set_cursor, self.state.winid, { math.min(target_line, #lines), 0 })
        -- チャンクが画面上部に来るよう調整
        pcall(vim.api.nvim_win_call, self.state.winid, function() vim.cmd("normal! zt") end)
      end
    end,
  })
end

-------------------------------------------------------------------------------
-- ステージ通知パターン
-------------------------------------------------------------------------------

local stage_patterns = {
  { pattern = "Expanding", msg = "クエリ展開中" },
  { pattern = "Searching", msg = "検索中" },
  { pattern = "Embedding", msg = "埋め込み中" },
  { pattern = "Reranking", msg = "リランキング中" },
}

-------------------------------------------------------------------------------
-- メイン検索
-------------------------------------------------------------------------------

function M.search()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local sorters = require("telescope.sorters")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  -- コレクション
  local col_names = get_collection_names()
  local col_list = { nil } -- nil = All
  for _, n in ipairs(col_names) do table.insert(col_list, n) end
  local col_idx = 1
  local current_col = nil

  -- 検索状態
  local current_query = ""
  local results = { rg = {}, bm25 = {}, hybrid = {} }
  local jobs = { rg = nil, bm25 = nil, hybrid = nil }
  local status = { rg = "—", bm25 = "—", hybrid = "—" }
  local gen = { rg = 0, bm25 = 0, hybrid = 0 }  -- 世代カウンタ（古い結果を無視）
  local debounce_timer = nil

  --- ジョブ停止
  local function stop_job(key)
    if jobs[key] then pcall(vim.fn.jobstop, jobs[key]); jobs[key] = nil end
  end

  local function stop_all()
    stop_job("rg"); stop_job("bm25"); stop_job("hybrid")
  end

  -- picker 前方宣言
  local picker

  --- ステータス文字列生成
  local function status_str()
    local icons = { ["—"] = "—", running = "⟳", done = "✓" }
    local col_label = current_col or "All"
    return string.format("QMD [RG%s BM%s QMD%s] %s",
      icons[status.rg] or status.rg,
      icons[status.bm25] or status.bm25,
      icons[status.hybrid] or status.hybrid,
      col_label)
  end

  --- picker タイトル更新
  local function update_title()
    pcall(function() picker.prompt_border:change_title(status_str()) end)
  end

  --- マージして picker 更新
  local function refresh()
    if not picker or not picker.refresh then return end
    local merged = merge_results(results.rg, results.bm25, results.hybrid)
    pcall(picker.refresh, picker, finders.new_table({
      results = merged,
      entry_maker = make_entry_maker(current_query),
    }), { reset_prompt = false })
  end

  --- rg 実行
  local function run_rg(query)
    stop_job("rg")
    gen.rg = gen.rg + 1
    local my_gen = gen.rg
    status.rg = "running"
    update_title()

    local paths = get_search_paths(current_col)
    if #paths == 0 then
      status.rg = "done"; results.rg = {}; update_title(); return
    end

    local cmd = vim.tbl_flatten({ "rg", "-c", "-i", "--glob", "*.md", query, paths })
    jobs.rg = vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        vim.schedule(function()
          if my_gen ~= gen.rg then return end
          results.rg = normalize_rg(data)
          status.rg = "done"
          update_title()
          refresh()
        end)
      end,
      on_exit = function() jobs.rg = nil end,
    })
  end

  --- BM25 実行
  local function run_bm25(query)
    stop_job("bm25")
    gen.bm25 = gen.bm25 + 1
    local my_gen = gen.bm25
    status.bm25 = "running"
    update_title()

    local cmd = { qmd_bin, "search", query, "--json", "-n", "20" }
    if current_col then
      table.insert(cmd, "-c")
      table.insert(cmd, current_col)
    end

    jobs.bm25 = vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        vim.schedule(function()
          if my_gen ~= gen.bm25 then return end
          local raw = table.concat(data, "\n")
          local parsed = parse_qmd_json(raw) or {}
          preload_collections(parsed)
          results.bm25 = normalize_qmd(parsed, "bm25")
          status.bm25 = "done"
          update_title()
          refresh()
        end)
      end,
      on_exit = function() jobs.bm25 = nil end,
    })
  end

  --- Hybrid 実行
  local function run_hybrid(query)
    stop_job("hybrid")
    gen.hybrid = gen.hybrid + 1
    local my_gen = gen.hybrid
    status.hybrid = "running"
    update_title()

    local stdout_chunks = {}
    local cmd = vim.tbl_flatten({
      qmd_bin, "query", query, "--json", "-n", "20",
      current_col and { "-c", current_col } or {},
    })

    jobs.hybrid = vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stdout_chunks, line) end
        end
      end,
      on_stderr = function(_, data)
        if my_gen ~= gen.hybrid then return end
        for _, line in ipairs(data) do
          for _, st in ipairs(stage_patterns) do
            if line:find(st.pattern) then
              vim.schedule(function()
                if my_gen ~= gen.hybrid then return end
                status.hybrid = st.msg
                update_title()
              end)
              break
            end
          end
        end
      end,
      on_exit = function(_, code)
        jobs.hybrid = nil
        vim.schedule(function()
          if my_gen ~= gen.hybrid then return end
          if code ~= 0 then
            status.hybrid = "—"
            update_title()
            return
          end
          local raw = table.concat(stdout_chunks, "\n")
          local parsed = parse_qmd_json(raw) or {}
          preload_collections(parsed)
          results.hybrid = normalize_qmd(parsed, "hybrid")
          status.hybrid = "done"
          update_title()
          refresh()
          vim.cmd("stopinsert")
        end)
      end,
    })
  end

  --- キーストロークで rg + BM25 を発火
  local function on_input_change(query)
    if not query or #query < 2 then return end
    current_query = query

    -- hybrid はクリア
    results.hybrid = {}
    status.hybrid = "—"

    run_rg(query)

    if debounce_timer then debounce_timer:stop() end
    debounce_timer = vim.defer_fn(function()
      run_bm25(query)
    end, 300)
  end

  -- Picker 構築
  picker = pickers.new({}, {
    prompt_title = status_str(),
    results_title = "Results",
    initial_mode = "insert",
    sorting_strategy = "ascending",
    finder = finders.new_table({ results = {}, entry_maker = make_entry_maker("") }),
    sorter = sorters.empty(),
    previewer = make_previewer(function() return current_query end),
    attach_mappings = function(prompt_bufnr, map)
      -- INSERT Enter → ハイブリッド検索
      map("i", "<CR>", function()
        local prompt = action_state.get_current_line()
        if not prompt or prompt == "" then return end
        current_query = prompt
        run_hybrid(prompt)
      end)

      -- NORMAL Enter → ファイルを開く
      map("n", "<CR>", actions.select_default)

      -- C-j/C-k → 結果移動
      map("i", "<C-j>", actions.move_selection_next)
      map("i", "<C-k>", actions.move_selection_previous)
      map("n", "<C-j>", actions.move_selection_next)
      map("n", "<C-k>", actions.move_selection_previous)

      -- C-n/C-p → プレビュースクロール
      map("i", "<C-n>", actions.preview_scrolling_down)
      map("i", "<C-p>", actions.preview_scrolling_up)
      map("n", "<C-n>", actions.preview_scrolling_down)
      map("n", "<C-p>", actions.preview_scrolling_up)

      -- Tab → コレクション切替
      map("i", "<Tab>", function()
        col_idx = (col_idx % #col_list) + 1
        current_col = col_list[col_idx]
        -- 結果クリアして再検索
        results = { rg = {}, bm25 = {}, hybrid = {} }
        status = { rg = "—", bm25 = "—", hybrid = "—" }
        update_title()
        refresh()
        local prompt = action_state.get_current_line()
        if prompt and #prompt >= 2 then
          on_input_change(prompt)
        end
      end)

      -- プロンプト変更でカスケード検索（vim.schedule で Telescope 内部更新後に読み取り）
      vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
        buffer = prompt_bufnr,
        callback = function()
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(prompt_bufnr) then return end
            local prompt = action_state.get_current_line()
            on_input_change(prompt)
          end)
        end,
      })

      return true
    end,
  })

  picker:find()
end

function M.setup()
  vim.keymap.set("n", "<leader>q", M.search, { desc = "QMD セマンティック検索" })
end

return M
