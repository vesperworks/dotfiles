local M = {}

M._cache = {}

-- 定数
M.CMIGEMO_PATH = "/opt/homebrew/bin/cmigemo"
M.DICT_PATH = "/opt/homebrew/opt/cmigemo/share/migemo/utf-8/migemo-dict"

--- cmigemoが利用可能か判定
--- @return boolean
function M.is_available()
  return vim.fn.executable(M.CMIGEMO_PATH) == 1
end

--- ローマ字→Vim正規表現パターンを取得（キャッシュあり）
--- @param input string ユーザー入力
--- @return string Vim正規表現パターン
function M.query(input)
  if not input or input == "" then return input end
  if M._cache[input] then return M._cache[input] end
  if not M.is_available() then return input end

  local result = vim.fn.system({
    M.CMIGEMO_PATH, "-d", M.DICT_PATH, "-v", "-q", "-w", input,
  })
  result = vim.trim(result)

  if result and result ~= "" then
    M._cache[input] = result
    return result
  end

  return input
end

return M
