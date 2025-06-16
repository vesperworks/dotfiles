-- ~/.config/nvim/lua/user-plugins/task-timer-storage.lua
-- タスクタイマーのデータ永続化モジュール

local M = {}

-- データファイルのパス
local data_file = vim.fn.stdpath('data') .. '/task_timers.json'

-- タイマーデータを保存
function M.save_timers(timers)
  local file = io.open(data_file, 'w')
  if file then
    file:write(vim.json.encode(timers))
    file:close()
    return true
  end
  return false
end

-- タイマーデータを読み込み
function M.load_timers()
  local file = io.open(data_file, 'r')
  if file then
    local content = file:read('*all')
    file:close()
    local success, timers = pcall(vim.json.decode, content)
    if success and timers then
      return timers
    end
  end
  return {}
end

-- データファイルが存在するかチェック
function M.data_file_exists()
  local file = io.open(data_file, 'r')
  if file then
    file:close()
    return true
  end
  return false
end

-- データファイルのパスを取得
function M.get_data_file_path()
  return data_file
end

return M
