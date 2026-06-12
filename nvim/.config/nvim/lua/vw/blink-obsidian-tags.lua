-- キャッシュ付き obsidian タグ補完 blink.cmp プロバイダ
-- ファイルキャッシュ方式: ~/.cache/nvim/obsidian-tags.json
-- 複数 nvim インスタンスでキャッシュを共有。rg は必要時のみ実行

local M = {}

local ob = require("vw._obsidian")

---@type string[]
local tag_cache = {}
local cache_file = vim.fn.stdpath("cache") .. "/obsidian-tags.json"
local STALE_SEC = 300 -- 5分

-- タグ抽出の正規表現（rg / Rust regex、Unicode 対応）
-- \w は Unicode word（日本語等のマルチバイト文字を含む）。
-- full_refresh と incremental_update の両方がこの 1 本を使う
local TAG_RG_PATTERN = "#[\\w/-]+"

--- rg -oN の出力（1 行 1 マッチ "#tag" 形式）からタグ集合を抽出
---@param stdout string
---@return table<string, boolean> seen
function M._parse_rg_tags(stdout)
  local seen = {}
  for line in stdout:gmatch("[^\n]+") do
    local tag = line:match("^#(.+)$")
    if tag then seen[tag] = true end
  end
  return seen
end

--- JSON からタグを読み込み
local function load_from_file()
  local f = io.open(cache_file, "r")
  if not f then return false end
  local raw = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, raw)
  if ok and type(data) == "table" then
    tag_cache = data
    return true
  end
  return false
end

--- JSON にタグを書き出し（非同期）
local function save_to_file(tags)
  local raw = vim.json.encode(tags)
  vim.uv.fs_open(cache_file, "w", 438, function(err, fd)
    if err or not fd then return end
    vim.uv.fs_write(fd, raw, nil, function()
      vim.uv.fs_close(fd)
    end)
  end)
end

--- Vault パスを取得
local function get_vault_dir()
  local ok, api = pcall(require, "obsidian.api")
  if ok then
    local ok_root, root = pcall(api.resolve_workspace_dir)
    if ok_root and root then return tostring(root) end
  end
  -- フォールバック
  return vim.fn.expand(vim.env.OBSIDIAN_VAULT_PATH or "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault")
end

--- rg を直接叩いてタグ抽出（完全非同期、Note パースなし）
local function full_refresh()
  local dir = get_vault_dir()
  vim.system(
    { "rg", "--no-config", "--type=md", "-oN", TAG_RG_PATTERN, dir },
    { text = true },
    function(result)
      if result.code ~= 0 then return end
      local seen = M._parse_rg_tags(result.stdout)
      local tags = vim.tbl_keys(seen)
      table.sort(tags)
      tag_cache = tags
      save_to_file(tags)
    end
  )
end

--- 起動時: JSON があれば即座に読み、古ければバックグラウンドで rg
local function refresh_if_stale()
  load_from_file() -- 古くてもまず読む（フリーズ回避）
  local stat = vim.uv.fs_stat(cache_file)
  if stat and (os.time() - stat.mtime.sec) < STALE_SEC then
    return -- 新鮮なのでフル走査不要
  end
  -- キャッシュが無い or 古い → バックグラウンドでフル走査
  full_refresh()
end

--- BufWritePost: 保存されたファイルのタグを差分でキャッシュに追加
--- full_refresh と同じ rg 正規表現を使うことで、Lua パターン（%w が
--- ASCII のみで日本語タグを取りこぼす）との抽出結果のズレを根絶する
local function incremental_update(ev)
  local path = (ev and ev.file ~= "" and ev.file) or vim.api.nvim_buf_get_name(0)
  if path == "" then return end
  vim.system(
    { "rg", "--no-config", "-oN", TAG_RG_PATTERN, path },
    { text = true },
    function(result)
      if result.code ~= 0 then return end -- マッチなし (code 1) も含む
      local seen = {}
      for _, tag in ipairs(tag_cache) do
        seen[tag] = true
      end
      local added = false
      for tag in pairs(M._parse_rg_tags(result.stdout)) do
        if not seen[tag] then
          seen[tag] = true
          tag_cache[#tag_cache + 1] = tag
          added = true
        end
      end
      if added then
        table.sort(tag_cache)
        save_to_file(tag_cache)
      end
    end
  )
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
vim.api.nvim_create_user_command("ObsidianTagsRefresh", full_refresh, {})

--- カーソル前テキストから補完対象タグを切り出す
--- 「最後の '#' から行末まで」に空白（半角・タブ・全角）を含まない場合のみ有効。
--- バイト単位の逆走査だが、判定対象が ASCII（# / space / tab）のみなので
--- UTF-8 マルチバイト文字を壊さない。全角スペースは plain find で別途検出
--- （Lua の文字クラスはバイト単位のため [　] のような書き方は不可）。
---@param line string カーソルまでの行テキスト
---@return integer|nil hash_pos '#' の 1-indexed バイト位置
---@return string|nil query '#' より後ろのクエリ文字列
function M._find_tag_context(line)
  local hash_pos
  for i = #line, 1, -1 do
    local b = line:byte(i)
    if b == 35 then -- '#'
      hash_pos = i
      break
    elseif b == 32 or b == 9 then -- ' ' / '\t' が先に出たらタグ入力中ではない
      return nil
    end
  end
  if not hash_pos then return nil end
  local query = line:sub(hash_pos + 1)
  if query:find("　", 1, true) then return nil end
  return hash_pos, query
end

--- テスト用: タグキャッシュを直接差し替える（内部 API）
function M._set_tag_cache(tags)
  tag_cache = tags
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { "#" }
end

function M:get_completions(context, resolve)
  local line = context.line:sub(1, context.cursor[2])
  local hash_pos, raw_query = M._find_tag_context(line)
  if not hash_pos then
    return resolve({ is_incomplete_forward = false, items = {} })
  end

  local query = raw_query:lower()

  -- frontmatter / コードフェンス判定（カーソルまでの行を 1 回で取得）
  local row = context.cursor[1]
  local head = vim.api.nvim_buf_get_lines(context.bufnr, 0, row, false)
  if ob.is_in_code_fence(head, row) then
    -- コードブロック内の '# comment' 等での誤発火を防ぐ
    return resolve({ is_incomplete_forward = false, items = {} })
  end
  local in_frontmatter = ob.is_in_frontmatter(head, row)

  -- textEdit の character は UTF-16 単位（バイト値のままだと日本語行でズレる）
  local edit_start = ob.utf16_col(context.line, hash_pos - 1)
  local edit_end = ob.utf16_col(context.line, context.cursor[2])

  local items = {}
  for _, tag in ipairs(tag_cache) do
    if query == "" or tag:lower():find(query, 1, true) then
      local insert_text = in_frontmatter and tag or ("#" .. tag)
      items[#items + 1] = {
        label = "#" .. tag,
        kind = vim.lsp.protocol.CompletionItemKind.Keyword,
        insertText = insert_text,
        filterText = "#" .. tag,
        textEdit = {
          newText = insert_text,
          range = {
            start = { line = row - 1, character = edit_start },
            ["end"] = { line = row - 1, character = edit_end },
          },
        },
      }
    end
  end

  -- is_incomplete_forward = true: 日本語は blink の keyword 文字でないため、
  -- '#' の後に日本語を打っても source が自動再起動しない。打鍵ごとに
  -- 再クエリさせて候補の stale 化を防ぐ（コストはキャッシュ走査のみ）
  resolve({
    is_incomplete_forward = true,
    is_incomplete_backward = false,
    items = items,
  })
end

return M
