-- Obsidian vault 共通ヘルパー（transclusion / blink-obsidian-headings で共用）
-- - vault root 解決
-- - note 名 → 絶対パス解決（解決結果キャッシュ付き）
-- - mtime キャッシュ付きファイル読み込み
-- - heading 抽出
local M = {}

---@type table<string, {path: string|false, at: number}> note 名 → 解決結果（false = 解決失敗）
local resolve_cache = {}
---@type table<string, {mtime:number, lines:string[]}>
local file_cache = {}

-- 解決失敗のキャッシュ保持秒数。[[note# をタイプ中（未確定の名前）に
-- 毎打鍵で vault 全走査が走るのを防ぎつつ、新規ノートは TTL 後に解決される
local RESOLVE_NEGATIVE_TTL_SEC = 5

-- vault root: obsidian.nvim の API → 環境変数 → デフォルト の順
function M.vault_dir()
  local ok, api = pcall(require, 'obsidian.api')
  if ok and api.resolve_workspace_dir then
    local ok2, root = pcall(api.resolve_workspace_dir)
    if ok2 and root then return tostring(root) end
  end
  return vim.fn.expand(
    vim.env.OBSIDIAN_VAULT_PATH
      or '~/Library/Mobile Documents/iCloud~md~obsidian/Documents/MainVault'
  )
end

-- name → 絶対パス解決（vault relative / basename anywhere）
-- basename フォールバックは vault 全体の再帰探索なので、解決結果を
-- 成功・失敗の両方ともキャッシュする:
--   成功: filereadable で stale 検出（ファイル削除で自動無効化）
--   失敗: TTL 付きネガティブキャッシュ（補完タイプ中の全走査連打を防止）
function M.resolve_path(name)
  if not name or name == '' then return nil end
  name = vim.trim(name)

  local cached = resolve_cache[name]
  if cached then
    if cached.path then
      if vim.fn.filereadable(cached.path) == 1 then
        return cached.path
      end
    elseif os.time() - cached.at < RESOLVE_NEGATIVE_TTL_SEC then
      return nil
    end
  end

  local resolved

  -- absolute / home
  if name:sub(1, 1) == '/' or name:sub(1, 1) == '~' then
    local expanded = vim.fn.expand(name)
    if vim.fn.filereadable(expanded) == 1 then resolved = expanded end
  end

  if not resolved then
    local root = M.vault_dir()

    -- vault root relative（拡張子付き/なし両対応）
    local candidate = root .. '/' .. name
    if vim.fn.filereadable(candidate) == 1 then
      resolved = candidate
    elseif vim.fn.filereadable(candidate .. '.md') == 1 then
      resolved = candidate .. '.md'
    else
      -- basename anywhere in vault
      local basename = vim.fs.basename(name)
      if not basename:match('%.md$') then basename = basename .. '.md' end
      local found = vim.fs.find(basename, { path = root, type = 'file', limit = 1 })
      if found and found[1] then resolved = found[1] end
    end
  end

  resolve_cache[name] = { path = resolved or false, at = os.time() }
  return resolved
end

-- mtime キャッシュ付きファイル読み込み
function M.read_file_cached(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then return nil end
  local cached = file_cache[path]
  if cached and cached.mtime == stat.mtime.sec then
    return cached.lines
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return nil end
  file_cache[path] = { mtime = stat.mtime.sec, lines = lines }
  return lines
end

-- lines から heading 一覧を抽出 → { {level, text}, ... }
function M.extract_headings(lines)
  local out = {}
  for _, line in ipairs(lines) do
    local hashes, text = line:match('^(#+)%s+(.+)$')
    if hashes and text then
      out[#out + 1] = { level = #hashes, text = vim.trim(text) }
    end
  end
  return out
end

-- カーソル行（1-indexed row）が YAML frontmatter 内かを判定
-- head_lines: バッファ先頭からの行配列（row-1 行以上あること）
-- 条件: 1 行目が '---' 単独行で、2〜row-1 行に閉じ（'---' / '...'）が無い
function M.is_in_frontmatter(head_lines, row)
  if row <= 1 then return false end
  if not (head_lines[1] or ''):match('^%-%-%-%s*$') then return false end
  for i = 2, math.min(#head_lines, row - 1) do
    local l = head_lines[i]
    if l:match('^%-%-%-%s*$') or l:match('^%.%.%.%s*$') then
      return false -- カーソルより前に閉じがある → frontmatter の外
    end
  end
  return true
end

-- カーソル行（1-indexed row）がコードフェンス（``` / ~~~）内かを判定
-- row-1 行目までのフェンス開始/終了行の偶奇で判定する
function M.is_in_code_fence(head_lines, row)
  local in_fence = false
  for i = 1, math.min(#head_lines, row - 1) do
    local l = head_lines[i]
    if l:match('^%s*```') or l:match('^%s*~~~') then
      in_fence = not in_fence
    end
  end
  return in_fence
end

-- バイトカラム（0-indexed）を UTF-16 オフセットへ変換（LSP Position 用）
-- blink.cmp は textEdit の range.character を offset_encoding（既定 utf-16）
-- として再変換するため、バイト値をそのまま渡すと日本語行で範囲がズレる
function M.utf16_col(line, byte_col)
  byte_col = math.max(0, math.min(byte_col, #line))
  return vim.str_utfindex(line, 'utf-16', byte_col, false)
end

-- 全キャッシュをクリア（VwTransclusionRefresh などから呼ぶ）
function M.clear_cache()
  resolve_cache = {}
  file_cache = {}
end

return M
