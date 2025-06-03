return {
  "echasnovski/mini.move",
  config = function()
    require("mini.move").setup({
      mappings = {
        -- Move visual selection in Visual mode
        left = '<D-C-h>',      -- Cmd+Ctrl+h
        right = '<D-C-l>',     -- Cmd+Ctrl+l
        down = '<D-C-j>',      -- Cmd+Ctrl+j
        up = '<D-C-k>',        -- Cmd+Ctrl+k

        -- Move current line in Normal mode
        line_left = '<D-C-h>',
        line_right = '<D-C-l>',
        line_down = '<D-C-j>',
        line_up = '<D-C-k>',
      }
    })
    
    -- ctrl-iを明示的に復元（jump forward）
    vim.keymap.set('n', '<C-i>', '<C-i>', { desc = 'Jump forward', noremap = true })
  end,
}
