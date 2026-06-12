-- lua/vw/qmd.lua
-- QMD (Quick Markdown Search) Telescope picker
-- 3層カスケード検索: RG(即座) → BM25(やや遅れ) → Hybrid(Enter)

local M = {}

local qmd_bin = vim.fn.exepath("qmd")
if qmd_bin == "" then qmd_bin = vim.fn.expand("~/.bun/bin/qmd") end

-- キャッシュ
-- collection_cache: { name → path }。qmd CLI は 1 呼び出し ~100-300ms かかる
-- （bun 起動コスト）ため、picker 起動時の同期呼び出しは禁止。JSON に永続化し、
-- 起動時はキャッシュ読みのみ + バックグラウンドで非同期更新する
local collection_cache = {}
local collection_names = {} -- 表示順を保持した name 配列
local preview_cache = {}
local PREVIEW_CACHE_MAX = 100 -- preview_cache の上限（超えたら全クリア）
local collections_file = vim.fn.stdpath("cache") .. "/qmd-collections.json"

-- ソース別の表示設定
local SOURCE_CONFIG = {
  rg     = { label = "RG",  hl = "DiagnosticInfo" },  -- 青
  bm25   = { label = "BM",  hl = "DiagnosticWarn" },  -- 黄
  hybrid = { label = "QMD", hl = "DiagnosticOk" },    -- 緑
}

-------------------------------------------------------------------------------
-- ヘルパー: コレクション・パス解決
-- すべてメモリキャッシュ参照のみ。CLI 呼び出しは refresh_collections_async に
-- 集約（picker のホットパスから qmd プロセス起動を完全排除）
-------------------------------------------------------------------------------

--- qmd collection list の出力から name 配列を抽出
function M._parse_collection_list(stdout)
  local names = {}
  for name in (stdout or ""):gmatch("(%S+)%s+%(qmd://") do
    table.insert(names, name)
  end
  return names
end

--- qmd collection show の出力から Path を抽出
function M._parse_collection_show(stdout)
  for line in (stdout or ""):gmatch("[^\n]+") do
    local path = line:match("Path:%s+(.+)")
    if path then return vim.trim(path) end
  end
  return nil
end

--- JSON キャッシュ読み込み（成功で true）
local function load_collections_file()
  local f = io.open(collections_file, "r")
  if not f then return false end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if ok and type(data) == "table" and type(data.names) == "table" and type(data.paths) == "table" then
    collection_names = data.names
    collection_cache = data.paths
    return true
  end
  return false
end

--- JSON キャッシュ書き出し（非同期）
local function save_collections_file()
  local raw = vim.json.encode({ names = collection_names, paths = collection_cache })
  vim.uv.fs_open(collections_file, "w", 438, function(err, fd)
    if err or not fd then return end
    vim.uv.fs_write(fd, raw, nil, function()
      vim.uv.fs_close(fd)
    end)
  end)
end

--- コレクション情報を非同期で再取得（list 1 回 + show を全コレクション並列）
--- 完了時に on_done（任意）を main loop で呼ぶ
local refreshing = false
local function refresh_collections_async(on_done)
  if refreshing then return end
  refreshing = true
  vim.system({ qmd_bin, "collection", "list" }, { text = true }, function(list_result)
    if list_result.code ~= 0 then
      refreshing = false
      return
    end
    local names = M._parse_collection_list(list_result.stdout)
    if #names == 0 then
      refreshing = false
      return
    end
    local paths = {}
    local pending = #names
    for _, name in ipairs(names) do
      vim.system({ qmd_bin, "collection", "show", name }, { text = true }, function(show_result)
        if show_result.code == 0 then
          paths[name] = M._parse_collection_show(show_result.stdout)
        end
        pending = pending - 1
        if pending == 0 then
          collection_names = names
          collection_cache = paths
          save_collections_file()
          refreshing = false
          if on_done then vim.schedule(on_done) end
        end
      end)
    end
  end)
end

--- JSON キャッシュが古い場合のみ非同期更新（stale-while-revalidate）
local COLLECTIONS_STALE_SEC = 300
local function refresh_collections_if_stale(on_done)
  local stat = vim.uv.fs_stat(collections_file)
  if stat and (os.time() - stat.mtime.sec) < COLLECTIONS_STALE_SEC and #collection_names > 0 then
    return
  end
  refresh_collections_async(on_done)
end

local function get_collection_path(name)
  return collection_cache[name]
end

--- 他のパスに包含されるパスを除外する
--- （コレクションの大半が MainVault のサブディレクトリなので、全部
--- 並べて rg に渡すと同じファイルを二重に read してしまう）
function M._dedup_paths(paths)
  local sorted = {}
  for _, p in ipairs(paths) do
    table.insert(sorted, p)
  end
  table.sort(sorted)
  local out = {}
  for _, p in ipairs(sorted) do
    local covered = false
    for _, kept in ipairs(out) do
      if p == kept or p:sub(1, #kept + 1) == kept .. "/" then
        covered = true
        break
      end
    end
    if not covered then table.insert(out, p) end
  end
  return out
end

local function get_search_paths(collection)
  local paths = {}
  if collection then
    local p = collection_cache[collection]
    if p then table.insert(paths, p) end
  else
    for _, name in ipairs(collection_names) do
      local p = collection_cache[name]
      if p then table.insert(paths, p) end
    end
  end
  return M._dedup_paths(paths)
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
    local ok, files = pcall(vim.fn.readdir, dir)
    if ok then
      for _, fname in ipairs(files) do
        if fname:gsub("%.md$", ""):gsub("%-", "_"):gsub("_$", "") == norm then
          return dir .. "/" .. fname
        end
      end
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

--- 検索結果に未知のコレクションがあれば裏でキャッシュを更新する
--- （同期 CLI は呼ばない。次の resolve から効けば十分）
local function preload_collections(results)
  for _, entry in ipairs(results) do
    local col = (entry.file or ""):match("^qmd://([^/]+)/")
    if col and not collection_cache[col] then
      refresh_collections_async()
      return
    end
  end
end

-------------------------------------------------------------------------------
-- ヘルパー: プレビューキャッシュ（上限付き）
-------------------------------------------------------------------------------

local preview_cache_count = 0
local function put_preview_cache(key, lines)
  if not preview_cache[key] then
    if preview_cache_count >= PREVIEW_CACHE_MAX then
      preview_cache = {}
      preview_cache_count = 0
    end
    preview_cache_count = preview_cache_count + 1
  end
  preview_cache[key] = lines
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
  if #entries > 20 then
    local trimmed = {}
    for i = 1, 20 do trimmed[i] = entries[i] end
    entries = trimmed
  end
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

local function make_entry_maker()
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

      -- バッファに描画 + ハイライト + チャンク先頭へスクロール
      local function render(lines)
        if not vim.api.nvim_buf_is_valid(self.state.bufnr) then return end
        if cache_key then put_preview_cache(cache_key, lines) end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].syntax = "markdown"
        highlight_preview(self.state.bufnr, lines, query, val.chunk_range)

        local target_line = entry.lnum or 1
        if val.chunk_range then
          target_line = math.max(val.chunk_range.start, 1)
        end
        if target_line > 1 then
          pcall(vim.api.nvim_win_set_cursor, self.state.winid, { math.min(target_line, #lines), 0 })
          -- チャンクが画面上部に来るよう調整
          pcall(vim.api.nvim_win_call, self.state.winid, function() vim.cmd("normal! zt") end)
        end
      end

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
        -- qmd get（CLI ~100ms+）は同期 wait するとカーソル移動毎にブロック
        -- するため非同期で取得し、完了時にまだ同じバッファなら描画する
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "読み込み中…" })
        vim.system({ qmd_bin, "get", val.qmd_uri, "-l", "200" }, { text = true }, function(result)
          if result.code ~= 0 or not result.stdout or result.stdout == "" then return end
          vim.schedule(function()
            render(vim.split(result.stdout, "\n"))
          end)
        end)
        return
      end

      if not lines then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "プレビューを取得できません" })
        return
      end

      render(lines)
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

  -- コレクション（メモリ/JSON キャッシュから即時利用。CLI は裏で非同期更新）
  -- col_idx: 0 = All、1..N = collection_names のインデックス
  if #collection_names == 0 then
    load_collections_file()
  end
  local col_idx = 0
  local current_col = nil

  -- 検索状態
  local current_query = ""
  local results = { rg = {}, bm25 = {}, hybrid = {} }
  local jobs = { rg = nil, bm25 = nil, hybrid = nil }
  local status = { rg = "—", bm25 = "—", hybrid = "—" }
  local gen = { rg = 0, bm25 = 0, hybrid = 0 }  -- 世代カウンタ（古い結果を無視）
  -- 単一の uv timer を使い回す（vim.defer_fn を stop で捨てると
  -- 発火しなかった timer ハンドルが close されず毎打鍵リークする）
  local debounce_timer = vim.uv.new_timer()
  local rg_timeout_timer = vim.uv.new_timer()

  --- ジョブ停止
  local function stop_job(key)
    if jobs[key] then pcall(vim.fn.jobstop, jobs[key]); jobs[key] = nil end
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
      entry_maker = make_entry_maker(),
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

    local cmd = { "rg", "-c", "-i", "--glob", "*.md", query }
    vim.list_extend(cmd, paths)

    -- streaming 受信 + タイムアウト打ち切り。
    -- iCloud の dataless ファイルは read がオンデマンドダウンロード待ちで
    -- ハングすることがあり（実測 8s+）、rg ワーカーが 1 つでも掴むと
    -- プロセスが終了しない。stdout_buffered（exit 時一括）だとヒットが
    -- 857 件出ていても 1 件も届かないため、行を逐次取り込み、
    -- RG_TIMEOUT_MS 経過時点で jobstop してそれまでの結果を確定する
    local RG_TIMEOUT_MS = 2000
    local out_lines = {}
    local pending_line = ""
    local function finalize()
      if my_gen ~= gen.rg then return end
      if pending_line ~= "" then
        table.insert(out_lines, pending_line)
        pending_line = ""
      end
      results.rg = normalize_rg(out_lines)
      status.rg = "done"
      update_title()
      refresh()
    end

    jobs.rg = vim.fn.jobstart(cmd, {
      on_stdout = function(_, data)
        if my_gen ~= gen.rg then return end
        -- チャンク境界で割れた行を連結する（:h channel-lines）
        pending_line = pending_line .. (data[1] or "")
        for i = 2, #data do
          table.insert(out_lines, pending_line)
          pending_line = data[i]
        end
      end,
      on_exit = function()
        jobs.rg = nil
        rg_timeout_timer:stop()
        vim.schedule(finalize)
      end,
    })

    rg_timeout_timer:stop()
    rg_timeout_timer:start(RG_TIMEOUT_MS, 0, vim.schedule_wrap(function()
      if my_gen ~= gen.rg then return end
      stop_job("rg") -- SIGTERM → on_exit 経由で finalize される
    end))
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
    local cmd = { qmd_bin, "query", query, "--json", "-n", "20" }
    if current_col then
      table.insert(cmd, "-c")
      table.insert(cmd, current_col)
    end

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

    debounce_timer:stop()
    debounce_timer:start(300, 0, vim.schedule_wrap(function()
      run_bm25(query)
    end))
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

      -- Tab → コレクション切替（0 = All に一周で戻る）
      map("i", "<Tab>", function()
        col_idx = (col_idx + 1) % (#collection_names + 1)
        current_col = col_idx == 0 and nil or collection_names[col_idx]
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

      -- picker 終了時のクリーンアップ:
      -- uv timer の解放 + 走行中ジョブの停止（閉じた後も hybrid が
      -- 走り続けて CPU を食う孤児ジョブ化を防ぐ）
      vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = prompt_bufnr,
        once = true,
        callback = function()
          debounce_timer:stop()
          debounce_timer:close()
          rg_timeout_timer:stop()
          rg_timeout_timer:close()
          stop_job("rg")
          stop_job("bm25")
          stop_job("hybrid")
        end,
      })

      return true
    end,
  })

  -- コレクション情報が古ければ裏で更新（picker 起動はブロックしない）
  refresh_collections_if_stale(function()
    update_title()
  end)

  picker:find()
end

function M.setup()
  vim.api.nvim_set_hl(0, "QmdChunk", { bg = "#4a5080", default = true })
  vim.keymap.set("n", "<leader>q", M.search, { desc = "QMD セマンティック検索" })
  -- 起動時に JSON キャッシュを温めておく（読みのみ、CLI は呼ばない）
  load_collections_file()
end

--- テスト用: 内部状態の注入・内部関数の公開（内部 API）
function M._set_collections(names, paths)
  collection_names = names
  collection_cache = paths
end
M._get_search_paths = function(col) return get_search_paths(col) end
M._load_collections_file = load_collections_file
M._collections_file = collections_file
M._refresh_collections_async = refresh_collections_async
M._merge_results = merge_results
M._normalize_rg = normalize_rg
M._parse_qmd_json = parse_qmd_json
M._extract_chunk_range = extract_chunk_range

return M
