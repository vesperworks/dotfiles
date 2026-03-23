-- H/L で行頭/行末
vim.keymap.set({ "n", "v" }, "L", "$", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "H", "^", { noremap = true, silent = true })

-- Escで検索ハイライトをクリア
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { noremap = true, silent = true })

-- システムクリップボードにyank
vim.opt.clipboard:append("unnamedplus")
-- 次の飛び先も記録
vim.opt.jumpoptions:append("stack")

-- Cmd+S で保存
vim.keymap.set('n', '<C-s>', ':w<CR>', { desc = "ファイル保存", silent = true })
vim.keymap.set('i', '<leader>s', '<Esc>:w<CR>a', { desc = "ファイル保存（挿入モード）", silent = true })
vim.keymap.set('v', '<leader>s', '<Esc>:w<CR>gv', { desc = "ファイル保存（ビジュアルモード）", silent = true })

-- Emacs風キーバインド（インサート/コマンドラインモード）
vim.keymap.set('i', '<C-a>', '<Home>', { desc = "行頭へ移動" })
vim.keymap.set('i', '<C-e>', '<End>', { desc = "行末へ移動" })
vim.keymap.set('c', '<C-a>', '<Home>', { desc = "行頭へ移動" })
vim.keymap.set('c', '<C-e>', '<End>', { desc = "行末へ移動" })
vim.keymap.set('i', '<C-k>', '<C-o>D', { desc = "行末まで削除" })

-- Raycast File Search: 現在のファイルをRaycastで開く
vim.keymap.set('n', '<leader>ro', function()
  local path = vim.fn.expand('%:p')
  if path == '' then
    vim.notify('No file open', vim.log.levels.WARN)
    return
  end
  local encoded = path:gsub(' ', '%%20'):gsub('#', '%%23')
  vim.fn.system('open "raycast://extensions/raycast/file-search/search-files?fallbackText=' .. encoded .. '"')
end, { desc = 'Open in Raycast' })

-- ファイルパスをクリップボードにコピー
vim.keymap.set('n', '<leader>cp', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path)
  vim.notify('Copied: ' .. path, vim.log.levels.INFO)
end, { desc = 'Copy full path' })
