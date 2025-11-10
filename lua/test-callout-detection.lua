-- callout検出の簡易テスト

local function is_callout_start(line)
  return line:match("^%s*>%s*%[!%w+%]")
end

local function is_callout_body(line)
  return line:match("^%s*>") and not is_callout_start(line)
end

vim.api.nvim_create_user_command('TestCalloutDetection', function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  print("=== Callout Detection Test ===")
  
  for i, line in ipairs(lines) do
    local is_start = is_callout_start(line)
    local is_body = is_callout_body(line)
    
    if is_start or is_body then
      local type_str = is_start and "[START]" or "[BODY ]"
      print(string.format("Line %3d %s: %s", i, type_str, line))
    end
  end
  
  print("\n上記以外の行はcalloutとして検出されていません")
end, {})

print("コマンド :TestCalloutDetection を実行してcallout検出を確認してください")
