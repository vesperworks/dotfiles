-- キャッシュ付き obsidian ノート名（[[リンク]]）補完 blink.cmp プロバイダ
--
-- obsidian.nvim 標準の refs source は「rg 検索 → 全ヒットを Note.from_file で
-- パース」する構造で、5,000 ファイル規模の vault では 1 文字クエリが 30 秒
-- 超かかり実用にならない（しかも can_complete が空クエリを弾くので
-- min_chars=0 でも [[ 直後には何も出ない）。
--
-- ここでは blink-obsidian-tags と同じ方式を取る:
--   rg --files で全ノート名を非同期取得 → JSON キャッシュ → 打鍵時はメモリ走査のみ
-- [[ 直後（0 文字）から全ノート名を即表示できる。

local M = {}

local ob = require("vw._obsidian")

---@class vw.ObsidianNoteEntry
---@field name string ノート名（拡張子なしの basename）
---@field dir string vault からの相対親ディレクトリ（"" = ルート直下）

---@type vw.ObsidianNoteEntry[]
local note_cache = {}
local cache_file = vim.fn.stdpath("cache") .. "/obsidian-notes.json"
local STALE_SEC = 300 -- 5分

--- JSON からノート一覧を読み込み
local function load_from_file()
  local f = io.open(cache_file, "r")
  if not f then return false end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if ok and type(data) == "table" then
    note_cache = data
    return true
  end
  return false
end

--- JSON にノート一覧を書き出し（非同期）
local function save_to_file(notes)
  local raw = vim.json.encode(notes)
  vim.uv.fs_open(cache_file, "w", 438, function(err, fd)
    if err or not fd then return end
    vim.uv.fs_write(fd, raw, nil, function()
      vim.uv.fs_close(fd)
    end)
  end)
end

--- rg --files の出力（1 行 1 パス）からノートエントリ一覧を作る
---@param stdout string
---@param vault_dir string
---@return vw.ObsidianNoteEntry[]
function M._parse_file_list(stdout, vault_dir)
  local prefix = vault_dir:gsub("/+$", "") .. "/"
  local notes = {}
  for path in stdout:gmatch("[^\n]+") do
    if path:sub(-3) == ".md" then
      local rel = path
      if rel:sub(1, #prefix) == prefix then
        rel = rel:sub(#prefix + 1)
      end
      local dir = rel:match("^(.*)/[^/]*$") or ""
      local name = rel:match("([^/]+)%.md$")
      if name then
        notes[#notes + 1] = { name = name, dir = dir }
      end
    end
  end
  table.sort(notes, function(a, b)
    return a.name < b.name
  end)
  return notes
end

--- rg --files で vault の全ノート名を取得（完全非同期）
local function full_refresh()
  local dir = ob.vault_dir()
  vim.system(
    { "rg", "--no-config", "--files", "-g", "*.md", dir },
    { text = true },
    function(result)
      if result.code ~= 0 then return end
      local notes = M._parse_file_list(result.stdout, dir)
      note_cache = notes
      save_to_file(notes)
    end
  )
end

--- 起動時: JSON があれば即座に読み、古ければバックグラウンドで再構築
local function refresh_if_stale()
  load_from_file()
  local stat = vim.uv.fs_stat(cache_file)
  if stat and (os.time() - stat.mtime.sec) < STALE_SEC then
    return
  end
  full_refresh()
end

--- BufWritePost: 保存されたファイルが vault 内の新規ノートならキャッシュに追加
local function incremental_update(ev)
  local path = (ev and ev.file ~= "" and ev.file) or vim.api.nvim_buf_get_name(0)
  if path == "" or path:sub(-3) ~= ".md" then return end
  local vault = ob.vault_dir():gsub("/+$", "")
  if path:sub(1, #vault + 1) ~= vault .. "/" then return end

  local rel = path:sub(#vault + 2)
  local dir = rel:match("^(.*)/[^/]*$") or ""
  local name = rel:match("([^/]+)%.md$")
  if not name then return end

  for _, entry in ipairs(note_cache) do
    if entry.name == name and entry.dir == dir then return end
  end
  note_cache[#note_cache + 1] = { name = name, dir = dir }
  table.sort(note_cache, function(a, b)
    return a.name < b.name
  end)
  save_to_file(note_cache)
end

-- autocmd 登録
vim.api.nvim_create_autocmd("User", {
  pattern = "ObsidianNoteEnter",
  once = true,
  callback = refresh_if_stale,
})
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.md",
  callback = incremental_update,
})

-- ユーザーコマンド: 強制リフレッシュ
vim.api.nvim_create_user_command("ObsidianNotesRefresh", full_refresh, {})

--- カーソル前テキストから [[リンク 補完の文脈を切り出す
--- 戻り値が nil の場合は補完対象外:
---   - [[ が無い / 既に ]] で閉じている
---   - '#' を含む（[[note# 以降は blink-obsidian-headings の領分）
---@param line string カーソルまでの行テキスト
---@return integer|nil query_start query 開始の 1-indexed バイト位置
---@return string|nil query [[ より後ろのクエリ文字列
function M._find_ref_context(line)
  local _, bracket_end = line:find(".*%[%[")
  if not bracket_end then return nil end
  local query = line:sub(bracket_end + 1)
  if query:find("%]%]") then return nil end
  if query:find("#", 1, true) then return nil end
  return bracket_end + 1, query
end

--- テスト用: ノートキャッシュを直接差し替える（内部 API）
function M._set_note_cache(notes)
  note_cache = notes
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { "[" }
end

function M:get_completions(context, resolve)
  local empty = function()
    resolve({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
  end

  local line = context.line:sub(1, context.cursor[2])
  local query_start, raw_query = M._find_ref_context(line)
  if not query_start then return empty() end

  -- コードフェンス内の [[ は補完しない
  local row = context.cursor[1]
  local head = vim.api.nvim_buf_get_lines(context.bufnr, 0, row, false)
  if ob.is_in_code_fence(head, row) then return empty() end

  local query = raw_query:lower()

  -- カーソル直後に ]] が既にあれば閉じを付けない
  local after_cursor = context.line:sub(context.cursor[2] + 1, context.cursor[2] + 2)
  local closing = after_cursor == "]]" and "" or "]]"

  -- textEdit の character は UTF-16 単位（バイト値のままだと日本語行でズレる）
  local edit_start = ob.utf16_col(context.line, query_start - 1)
  local edit_end = ob.utf16_col(context.line, context.cursor[2])

  local items = {}
  for _, entry in ipairs(note_cache) do
    if query == "" or entry.name:lower():find(query, 1, true) then
      items[#items + 1] = {
        label = entry.name,
        labelDetails = entry.dir ~= "" and { description = entry.dir } or nil,
        kind = vim.lsp.protocol.CompletionItemKind.File,
        insertText = entry.name .. closing,
        filterText = entry.name,
        textEdit = {
          newText = entry.name .. closing,
          range = {
            start = { line = row - 1, character = edit_start },
            ["end"] = { line = row - 1, character = edit_end },
          },
        },
      }
    end
  end

  -- 日本語クエリ入力中も打鍵ごとに再クエリさせる（tags 側と同じ理由）
  resolve({
    is_incomplete_forward = true,
    is_incomplete_backward = false,
    items = items,
  })
end

return M
