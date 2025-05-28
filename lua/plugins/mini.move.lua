return {
  "echasnovski/mini.move",
  config = function()
    require("mini.move").setup({
	    mappings = {
	    -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
	    left = '<M-h>',
	    right = '<M-l>',
	    down = '<M-j>',
	    up = '<M-k>',

	    -- Move current line in Normal mode
	    line_left = '<M-h>',
	    line_right = '<M-l>',
	    line_down = '<M-j>',
	    line_up = '<M-k>',
	  }  
    })
    
    -- 追加のカスタムキーバインド
    -- nモードでの上下移動: Cmd-Ctrl-n,p,j,k
    vim.keymap.set('n', '<D-C-n>', function() require('mini.move').move_line('down') end, { desc = 'Move line down (Cmd-Ctrl-n)' })
    vim.keymap.set('n', '<D-C-p>', function() require('mini.move').move_line('up') end, { desc = 'Move line up (Cmd-Ctrl-p)' })
    vim.keymap.set('n', '<D-C-j>', function() require('mini.move').move_line('down') end, { desc = 'Move line down (Cmd-Ctrl-j)' })
    vim.keymap.set('n', '<D-C-k>', function() require('mini.move').move_line('up') end, { desc = 'Move line up (Cmd-Ctrl-k)' })
    
    -- nモードでの左右移動: Cmd-Ctrl-h/l
    vim.keymap.set('n', '<D-C-h>', function() require('mini.move').move_line('left') end, { desc = 'Move line left (Cmd-Ctrl-h)' })
    vim.keymap.set('n', '<D-C-l>', function() require('mini.move').move_line('right') end, { desc = 'Move line right (Cmd-Ctrl-l)' })
    
    -- ctrl-iを明示的に復元（jump forward）
    vim.keymap.set('n', '<C-i>', '<C-i>', { desc = 'Jump forward', noremap = true })

    -- ビジュアルモードでも同様のキーバインド
    vim.keymap.set('v', '<D-C-n>', function() require('mini.move').move_selection('down') end, { desc = 'Move selection down (Cmd-Ctrl-n)' })
    vim.keymap.set('v', '<D-C-p>', function() require('mini.move').move_selection('up') end, { desc = 'Move selection up (Cmd-Ctrl-p)' })
    vim.keymap.set('v', '<D-C-j>', function() require('mini.move').move_selection('down') end, { desc = 'Move selection down (Cmd-Ctrl-j)' })
    vim.keymap.set('v', '<D-C-k>', function() require('mini.move').move_selection('up') end, { desc = 'Move selection up (Cmd-Ctrl-k)' })
    
    vim.keymap.set('v', '<D-C-h>', function() require('mini.move').move_selection('left') end, { desc = 'Move selection left (Cmd-Ctrl-h)' })
    vim.keymap.set('v', '<D-C-l>', function() require('mini.move').move_selection('right') end, { desc = 'Move selection right (Cmd-Ctrl-l)' })
  end,
}
