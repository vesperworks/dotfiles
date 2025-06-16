-- ~/.config/nvim/lua/user-plugins/task-timer-storage.lua
-- タスクタイマーのデータ永続化モジュール

local M = {}

-- データファイルのパス
local data_file = vim.fn.stdpath('data') .. '/task_timers.json'

-- ユーザーディレクトリを~に正規化する関数
local function normalize_path_for_storage(path)
  -- まずOBSIDIAN_VAULT環境変数でVaultパス部分を置き換え
  local vault_path = vim.env.OBSIDIAN_VAULT
  if vault_path then
    -- パスを絶対パスに展開してから比較
    local expanded_vault = vim.fn.expand(vault_path)
    if path:sub(1, #expanded_vault) == expanded_vault then
      return '$OBSIDIAN_VAULT' .. path:sub(#expanded_vault + 1)
    end
  end
  
  -- 次にユーザーディレクトリを~で置き換え
  local home = vim.fn.expand('~')
  if path:sub(1, #home) == home then
    return '~' .. path:sub(#home + 1)
  end
  
  return path
end

-- 環境変数とチルダを絶対パスに展開する関数
local function expand_path_from_storage(path)
  -- 環境変数の展開
  if path:sub(1, 15) == '$OBSIDIAN_VAULT' then
    local vault_path = vim.env.OBSIDIAN_VAULT
    if vault_path then
      return vim.fn.expand(vault_path) .. path:sub(16)
    end
  end
  
  -- チルダの展開
  if path:sub(1, 1) == '~' then
    return vim.fn.expand('~') .. path:sub(2)
  end
  
  return path
end

-- JSONを美しく整形する関数
local function format_json(json_str)
  -- 簡易JSON整形（可読性向上）
  json_str = json_str:gsub('{"', '{\n  "')
  json_str = json_str:gsub(',"', ',\n  "')
  json_str = json_str:gsub('},"', '},\n  "')
  json_str = json_str:gsub('}}$', '}\n}')
  json_str = json_str:gsub('":"', '": "')
  json_str = json_str:gsub('":(%d)', '": %1')
  return json_str
end

-- タイマーデータを保存（危険：完全上書き）
function M.save_timers(timers)
  -- ⚠️ 警告: この関数は完全上書きするため危険
  -- 新しいsave_timer_safe()またはremove_timer_safe()を使用してください
  
  -- file_pathを環境変数と~で正規化してからJSONに保存
  local normalized_timers = {}
  for task_id, timer_data in pairs(timers) do
    normalized_timers[task_id] = {
      start_time = timer_data.start_time,
      file_path = normalize_path_for_storage(timer_data.file_path),
      line_number = timer_data.line_number,
      task_content = timer_data.task_content
    }
  end
  
  local file = io.open(data_file, 'w')
  if file then
    -- インデント付きJSON出力で可読性向上
    local json_str = vim.json.encode(normalized_timers)
    json_str = format_json(json_str)
    
    file:write(json_str)
    file:close()
    return true
  end
  return false
end

-- 🔒 安全な単一タイマー保存（マージ機能付き）
function M.save_timer_safe(task_id, timer_data)
  -- 既存データを読み込み
  local existing_timers = M.load_timers()
  
  -- 新しいタイマーデータを追加/更新
  existing_timers[task_id] = {
    start_time = timer_data.start_time,
    file_path = normalize_path_for_storage(timer_data.file_path),
    line_number = timer_data.line_number,
    task_content = timer_data.task_content,
    last_updated = os.time()  -- 更新時刻を記録
  }
  
  -- マージされたデータを保存
  return M.save_timers_internal(existing_timers)
end

-- 🔒 安全な単一タイマー削除（マージ機能付き）
function M.remove_timer_safe(task_id)
  -- 既存データを読み込み
  local existing_timers = M.load_timers()
  
  -- 指定されたタイマーを削除
  local was_present = existing_timers[task_id] ~= nil
  existing_timers[task_id] = nil
  
  -- マージされたデータを保存
  local success = M.save_timers_internal(existing_timers)
  return success, was_present
end

-- 🔒 内部用：安全なバッチ保存
function M.save_timers_internal(timers)
  -- バックアップを作成（安全性向上）
  M.create_backup()
  
  -- file_pathを環境変数と~で正規化してからJSONに保存
  local normalized_timers = {}
  for task_id, timer_data in pairs(timers) do
    normalized_timers[task_id] = {
      start_time = timer_data.start_time,
      file_path = normalize_path_for_storage(timer_data.file_path),
      line_number = timer_data.line_number,
      task_content = timer_data.task_content,
      last_updated = timer_data.last_updated or os.time()  -- 更新時刻を保持
    }
  end
  
  local file = io.open(data_file, 'w')
  if file then
    -- インデント付きJSON出力で可読性向上
    local json_str = vim.json.encode(normalized_timers)
    json_str = format_json(json_str)
    
    file:write(json_str)
    file:close()
    return true
  end
  return false
end

-- 💾 バックアップ作成機能
function M.create_backup()
  if not M.data_file_exists() then
    return true  -- ファイルがない場合はバックアップ不要
  end
  
  local backup_file = data_file .. '.backup'
  local source_file = io.open(data_file, 'r')
  if not source_file then return false end
  
  local content = source_file:read('*all')
  source_file:close()
  
  local backup = io.open(backup_file, 'w')
  if backup then
    backup:write(content)
    backup:close()
    return true
  end
  return false
end

-- 📋 統計情報取得
function M.get_storage_stats()
  local timers = M.load_timers()
  local file_count = {}
  local total_timers = 0
  
  for task_id, timer_data in pairs(timers) do
    total_timers = total_timers + 1
    local file_path = timer_data.file_path
    file_count[file_path] = (file_count[file_path] or 0) + 1
  end
  
  return {
    total_timers = total_timers,
    file_count = file_count,
    data_file_path = data_file,
    file_exists = M.data_file_exists(),
    backup_exists = M.backup_exists()
  }
end

-- バックアップファイルの存在チェック
function M.backup_exists()
  local backup_file = data_file .. '.backup'
  local file = io.open(backup_file, 'r')
  if file then
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
      -- file_pathを絶対パスに展開
      local expanded_timers = {}
      for task_id, timer_data in pairs(timers) do
        expanded_timers[task_id] = {
          start_time = timer_data.start_time,
          file_path = expand_path_from_storage(timer_data.file_path),
          line_number = timer_data.line_number,
          task_content = timer_data.task_content
        }
      end
      return expanded_timers
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
