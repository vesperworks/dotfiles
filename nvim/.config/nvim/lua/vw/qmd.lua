-- lua/vw/qmd.lua
-- QMD (Quick Markdown Search) Telescope picker

local M = {}

-- qmd バイナリパス（vim.fn.exepath で解決、なければ ~/.bun/bin/qmd）
local qmd_bin = vim.fn.exepath("qmd")
if qmd_bin == "" then qmd_bin = vim.fn.expand("~/.bun/bin/qmd") end

-- コレクション名 → ベースパスのキャッシュ
local collection_cache = {}

--- コレクションのベースパスを取得（遅延キャッシュ）
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

--- qmd:// URI を実ファイルパスに変換（ハイフン→アンダースコアのフォールバック付き）
local function resolve_qmd_uri(uri)
  local collection, rel_path = uri:match("^qmd://([^/]+)/(.+)$")
  if not collection or not rel_path then return nil end

  local base = get_collection_path(collection)
  if not base then return nil end

  -- そのまま試す
  local path = base .. "/" .. rel_path
  local f = io.open(path, "r")
  if f then f:close(); return path end

  -- フォールバック: ハイフン→アンダースコア
  local alt_path = base .. "/" .. rel_path:gsub("%-", "_")
  f = io.open(alt_path, "r")
  if f then f:close(); return alt_path end

  -- フォールバック: ディレクトリ内の類似ファイルを検索
  local dir = base .. "/" .. rel_path:match("^(.+)/") or ""
  local filename_stem = rel_path:match("([^/]+)%.md$")
  if filename_stem then
    local norm = filename_stem:gsub("%-", "_"):gsub("_$", "")
    local p = io.popen('ls "' .. dir .. '" 2>/dev/null')
    if p then
      for line in p:lines() do
        local line_stem = line:gsub("%.md$", ""):gsub("%-", "_"):gsub("_$", "")
        if line_stem == norm then
          p:close()
          return dir .. "/" .. line
        end
      end
      p:close()
    end
  end

  return nil
end

--- JSON 部分のみ抽出（進捗テキスト混入対策）
local function parse_qmd_json(stdout, stderr)
  local source = stdout or ""
  if source:find("%[") == nil and stderr and stderr:find("%[") then
    source = stderr
  end
  local json_str = source:match("%[.+%]")
  if not json_str then return nil end
  local ok, data = pcall(vim.json.decode, json_str)
  if not ok then return nil end
  return data
end

--- snippet から開始行番号を抽出
local function extract_line_from_snippet(snippet)
  if not snippet then return 1 end
  local line = snippet:match("@@ %-(%d+)")
  return tonumber(line) or 1
end

--- 結果から必要なコレクションパスを事前解決
local function preload_collections(results)
  local seen = {}
  for _, entry in ipairs(results) do
    local collection = (entry.file or ""):match("^qmd://([^/]+)/")
    if collection and not seen[collection] then
      seen[collection] = true
      get_collection_path(collection)
    end
  end
end

-- プレビューコンテンツのキャッシュ
local preview_cache = {}

--- プレビューバッファ内のクエリ語句をハイライト
local function highlight_query(bufnr, lines, query)
  local words = {}
  for w in query:gmatch("%S+") do
    if #w >= 2 then table.insert(words, w) end
  end
  if #words == 0 then return end

  local ns = vim.api.nvim_create_namespace("qmd_preview_hl")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for i, line in ipairs(lines) do
    local lower_line = line:lower()
    for _, word in ipairs(words) do
      local lower_word = word:lower()
      local start = 0
      while true do
        local s, e = lower_line:find(lower_word, start + 1, true)
        if not s then break end
        vim.api.nvim_buf_add_highlight(bufnr, ns, "Search", i - 1, s - 1, e)
        start = e
      end
    end
  end
end

--- Telescope picker を表示
local function show_picker(results, query)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local actions = require("telescope.actions")
  local entry_display = require("telescope.pickers.entry_display")

  local displayer = entry_display.create({
    separator = "  ",
    items = {
      { width = 4 },
      { remaining = true },
    },
  })

  pickers.new({}, {
    prompt_title = "QMD: " .. query,
    results_title = "Results",
    initial_mode = "normal",
    finder = finders.new_table({
      results = results,
      entry_maker = function(entry)
        local real_path = resolve_qmd_uri(entry.file)
        local display_path = (entry.file or ""):gsub("^qmd://[^/]+/", "")
        local score_pct = math.floor((entry.score or 0) * 100)
        local lnum = extract_line_from_snippet(entry.snippet)
        local title = entry.title or display_path

        return {
          value = entry,
          display = function()
            return displayer({
              { score_pct .. "%", "TelescopeResultsNumber" },
              { title .. "  " .. display_path, "TelescopeResultsIdentifier" },
            })
          end,
          ordinal = title .. " " .. display_path,
          path = real_path,
          lnum = lnum,
          filename = real_path,
        }
      end,
    }),
    sorting_strategy = "ascending",
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      map("n", "<C-n>", actions.preview_scrolling_down)
      map("n", "<C-p>", actions.preview_scrolling_up)
      return true
    end,
    previewer = previewers.new_buffer_previewer({
      title = "Preview",
      define_preview = function(self, entry)
        local qmd_uri = entry.value and entry.value.file
        if not qmd_uri then return end

        -- キャッシュヒット
        if preview_cache[qmd_uri] then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_cache[qmd_uri])
          vim.bo[self.state.bufnr].filetype = "markdown"
          highlight_query(self.state.bufnr, preview_cache[qmd_uri], query)
          if entry.lnum and entry.lnum > 1 then
            pcall(vim.api.nvim_win_set_cursor, self.state.winid, { math.min(entry.lnum, #preview_cache[qmd_uri]), 0 })
          end
          return
        end

        -- 1. io.open で直接読み取り（高速）
        local lines
        if entry.path then
          local f = io.open(entry.path, "r")
          if f then
            local content = f:read("*a")
            f:close()
            lines = vim.split(content, "\n")
            if #lines > 200 then lines = { unpack(lines, 1, 200) } end
          end
        end

        -- 2. フォールバック: qmd get（ファイル名正規化の差異対策）
        if not lines then
          local result = vim.system({ qmd_bin, "get", qmd_uri, "-l", "200" }, { text = true }):wait()
          if result.code == 0 and result.stdout and result.stdout ~= "" then
            lines = vim.split(result.stdout, "\n")
          end
        end

        if not lines then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "プレビューを取得できません" })
          return
        end

        preview_cache[qmd_uri] = lines
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
        highlight_query(self.state.bufnr, lines, query)
        if entry.lnum and entry.lnum > 1 then
          pcall(vim.api.nvim_win_set_cursor, self.state.winid, { math.min(entry.lnum, #lines), 0 })
        end
      end,
    }),
  }):find()
end

--- stderr からステージを検出して通知
local stage_patterns = {
  { pattern = "Expanding", msg = "QMD: クエリ展開中..." },
  { pattern = "Searching", msg = "QMD: 検索中..." },
  { pattern = "Embedding", msg = "QMD: 埋め込み中..." },
  { pattern = "Reranking", msg = "QMD: リランキング中..." },
}

--- qmd query を非同期実行して Telescope に表示
function M.search()
  vim.ui.input({ prompt = "QMD> " }, function(query)
    if not query or query == "" then return end

    vim.notify("QMD: 開始...")

    local stdout_chunks = {}

    vim.fn.jobstart({ qmd_bin, "query", query, "--json", "-n", "20" }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        for _, line in ipairs(data) do
          if line ~= "" then table.insert(stdout_chunks, line) end
        end
      end,
      on_stderr = function(_, data)
        for _, line in ipairs(data) do
          for _, stage in ipairs(stage_patterns) do
            if line:find(stage.pattern) then
              vim.schedule(function() vim.notify(stage.msg) end)
              break
            end
          end
        end
      end,
      on_exit = function(_, code)
        vim.schedule(function()
          if code ~= 0 then
            vim.notify("QMD エラー", vim.log.levels.ERROR)
            return
          end

          local raw = table.concat(stdout_chunks, "\n")
          local data = parse_qmd_json(raw, nil)
          if not data or #data == 0 then
            vim.notify("QMD: 結果なし", vim.log.levels.WARN)
            return
          end

          preload_collections(data)
          vim.cmd("echon ''")
          show_picker(data, query)
        end)
      end,
    })
  end)
end

function M.setup()
  vim.keymap.set("n", "<leader>q", M.search, { desc = "QMD セマンティック検索" })
end

return M
