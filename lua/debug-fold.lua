-- デバッグ用スクリプト：各行のfoldexpr結果を表示

local M = require('user-plugins.markdown-fold')

vim.api.nvim_create_user_command('DebugFold', function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  print("=== Fold Debug ===")
  
  for i, line in ipairs(lines) do
    -- 一時的にv.lnumを設定
    vim.v.lnum = i
    local result = M.foldexpr()
    
    -- 行の内容を短縮表示
    local display_line = line:sub(1, 40)
    if #line > 40 then
      display_line = display_line .. "..."
    end
    
    print(string.format("Line %3d: foldexpr=%-5s | %s", i, tostring(result), display_line))
  end
end, {})

print("コマンド :DebugFold を実行してfoldlevelを確認してください")
