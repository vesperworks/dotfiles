local M = {}

M._cache = {}

-- パスを動的に検出（環境非依存）
M.CMIGEMO_PATH = vim.fn.exepath("cmigemo")
M.DICT_PATH = (function()
  local path = vim.fn.exepath("cmigemo")
  if path == "" then return "" end
  local prefix = vim.fn.fnamemodify(path, ":h:h")
  local dict = prefix .. "/share/migemo/utf-8/migemo-dict"
  if vim.fn.filereadable(dict) == 0 then return "" end
  return dict
end)()

--- cmigemoが利用可能か判定
--- @return boolean
function M.is_available()
  return M.CMIGEMO_PATH ~= "" and M.DICT_PATH ~= ""
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
