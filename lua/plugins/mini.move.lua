return {
  "echasnovski/mini.move",
  config = function()
    require("mini.move").setup({
      mappings = {
        -- Move visual selection in Visual mode
        left = '<M-h>',        -- Alt+h
        right = '<M-l>',       -- Alt+l
        down = '<M-j>',        -- Alt+j
        up = '<M-k>',          -- Alt+k

        -- Move current line in Normal mode
        line_left = '<M-h>',
        line_right = '<M-l>',
        line_down = '<M-j>',
        line_up = '<M-k>',
      }
    })
    
    -- ctrl-iを明示的に復元（jump forward）
    vim.keymap.set('n', '<C-i>', '<C-i>', { desc = 'Jump forward', noremap = true })
  end,
}
