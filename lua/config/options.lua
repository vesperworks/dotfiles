-- filetype plugin を確実に有効化
vim.cmd('filetype plugin on')

vim.o.conceallevel = 2
vim.o.confirm = false

vim.cmd [[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
]]
