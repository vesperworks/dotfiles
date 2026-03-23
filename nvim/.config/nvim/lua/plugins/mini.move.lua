return {
  "echasnovski/mini.move",
  config = function()
    require("mini.move").setup({
      mappings = {
        -- Move visual selection in Visual mode
        left = '<C-h>',        -- Ctrl+h
        right = '<C-l>',       -- Ctrl+l
        down = '<C-j>',        -- Ctrl+j
        up = '<C-k>',          -- Ctrl+k

        -- Move current line in Normal mode
        line_left = '<C-h>',
        line_right = '<C-l>',
        line_down = '<C-j>',
        line_up = '<C-k>',
      }
    })
    
    -- ctrl-iを明示的に復元（jump forward）
    vim.keymap.set('n', '<C-i>', '<C-i>', { desc = 'Jump forward', noremap = true })
  end,
}
