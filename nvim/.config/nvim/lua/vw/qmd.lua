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

  -- "  Path:     /path/to/dir" の形式をパース
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

--- qmd:// URI を実ファイルパスに変換
local function resolve_qmd_uri(uri)
  local collection, rel_path = uri:match("^qmd://([^/]+)/(.+)$")
  if not collection or not rel_path then return nil end

  local base = get_collection_path(collection)
  if not base then return nil end

  return base .. "/" .. rel_path
end

--- JSON 部分のみ抽出（stderr 混入や進捗テキスト対策）
local function parse_qmd_json(stdout, stderr)
  -- stdout が空なら stderr にJSON が入ってるケースもチェック
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

--- Telescope picker を表示
local function show_picker(results, query)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
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
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Preview",
      define_preview = function(self, entry)
        if not entry.path then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "パスが解決できません" })
          return
        end
        local f = io.open(entry.path, "r")
        if not f then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "ファイルを開けません: " .. entry.path })
          return
        end
        local content = f:read("*a")
        f:close()
        local lines = vim.split(content, "\n")
        if #lines > 200 then lines = { unpack(lines, 1, 200) } end
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "markdown"
        if entry.lnum and entry.lnum > 1 then
          pcall(vim.api.nvim_win_set_cursor, self.state.winid, { math.min(entry.lnum, #lines), 0 })
        end
      end,
    }),
  }):find()
end

--- qmd query を非同期実行して Telescope に表示
function M.search()
  vim.ui.input({ prompt = "QMD> " }, function(query)
    if not query or query == "" then return end

    vim.notify("QMD 検索中...")

    vim.system(
      { qmd_bin, "query", query, "--json", "-n", "20" },
      { text = true },
      function(result)
        vim.schedule(function()
          if result.code ~= 0 then
            vim.notify("QMD エラー: " .. (result.stderr or "unknown"), vim.log.levels.ERROR)
            return
          end

          local data = parse_qmd_json(result.stdout, result.stderr)
          if not data or #data == 0 then
            vim.notify("QMD: 結果なし", vim.log.levels.WARN)
            return
          end

          -- コレクションパスを事前解決
          preload_collections(data)

          -- デバッグ: 最初のエントリのパス解決を確認
          local first = data[1]
          local resolved = resolve_qmd_uri(first.file)
          if not resolved then
            vim.notify("QMD: パス解決失敗 — " .. (first.file or "nil"), vim.log.levels.WARN)
          end

          -- 通知をクリアしてから picker 表示
          vim.cmd("echon ''")
          show_picker(data, query)
        end)
      end
    )
  end)
end

--- デバッグ用: パス解決テスト
function M.debug()
  local result = vim.system({ qmd_bin, "collection", "list" }, { text = true }):wait()
  vim.notify("stdout:\n" .. (result.stdout or "nil") .. "\nstderr:\n" .. (result.stderr or "nil"))
end

function M.setup()
  vim.keymap.set("n", "<leader>q", M.search, { desc = "QMD セマンティック検索" })
end

return M
