-- キーマップのデバッグ用スクリプト
-- :source ~/.config/nvim/debug_keymaps.lua で実行

-- 現在の<leader>cキーマップを確認
print("=== <leader>c キーマップ確認 ===")
local keymaps = vim.api.nvim_get_keymap('n')
for _, map in ipairs(keymaps) do
  if map.lhs == ' c' or map.lhs:match('<leader>c') then
    print("Found keymap:", vim.inspect(map))
  end
end

-- markdown-helper.luaのロード状況確認
print("\n=== markdown-helper.lua ロード確認 ===")
local ok, helper = pcall(require, 'user-plugins.markdown-helper')
if ok then
  print("✅ markdown-helper.lua loaded successfully")
  if type(helper.insert_callout) == 'function' then
    print("✅ insert_callout function exists")
  else
    print("❌ insert_callout function missing")
  end
else
  print("❌ Failed to load markdown-helper.lua:", helper)
end

-- 競合する可能性のあるキーマップを確認
print("\n=== 競合可能性のあるキーマップ ===")
local potential_conflicts = {'c', 'cb', ' cb', '<leader>cb'}
for _, key in ipairs(potential_conflicts) do
  for _, map in ipairs(keymaps) do
    if map.lhs == key then
      print("Potential conflict:", key, "->", map.rhs or map.callback)
    end
  end
end
