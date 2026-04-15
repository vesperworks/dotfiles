-- キャッシュ付き obsidian タグ補完 blink.cmp プロバイダ
-- ファイルキャッシュ方式: ~/.cache/nvim/obsidian-tags.json
-- 複数 nvim インスタンスでキャッシュを共有。rg は必要時のみ実行

local M = {}

---@type string[]
local tag_cache = {}
local cache_file = vim.fn.stdpath("cache") .. "/obsidian-tags.json"
local STALE_SEC = 300 -- 5分

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
    { "rg", "--no-config", "--type=md", "-oN", "#[a-zA-Z0-9_/-]+", dir },
    { text = true },
    function(result)
      if result.code ~= 0 then return end
      local seen = {}
      for tag in result.stdout:gmatch("#([a-zA-Z0-9_/-]+)") do
        seen[tag] = true
      end
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

--- BufWritePost: 現在バッファのタグを差分でキャッシュに追加
local function incremental_update()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local seen = {}
  for _, tag in ipairs(tag_cache) do
    seen[tag] = true
  end
  local added = false
  for _, line in ipairs(lines) do
    for tag in line:gmatch("#([%w_/-]+)") do
      if not seen[tag] then
        seen[tag] = true
        tag_cache[#tag_cache + 1] = tag
        added = true
      end
    end
  end
  if added then
    table.sort(tag_cache)
    save_to_file(tag_cache)
  end
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

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { "#" }
end

function M:get_completions(context, resolve)
  local line = context.line:sub(1, context.cursor[2])
  local hash_pos = line:find("#[^%s]*$")
  if not hash_pos then
    return resolve({ is_incomplete_forward = false, items = {} })
  end

  local query = line:sub(hash_pos + 1):lower()

  -- frontmatter 判定
  local row = context.cursor[1]
  local in_frontmatter = false
  if row > 1 then
    local first_line = vim.api.nvim_buf_get_lines(context.bufnr, 0, 1, false)[1] or ""
    if first_line:match("^%-%-%-") then
      for i = 1, row - 1 do
        local l = vim.api.nvim_buf_get_lines(context.bufnr, i, i + 1, false)[1] or ""
        if l:match("^%-%-%-") then
          in_frontmatter = i >= row
          break
        end
        if i == row - 1 then
          in_frontmatter = true
        end
      end
    end
  end

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
            start = { line = row - 1, character = hash_pos - 1 },
            ["end"] = { line = row - 1, character = context.cursor[2] },
          },
        },
      }
    end
  end

  resolve({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = items,
  })
end

return M
