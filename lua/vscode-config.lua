local vscode = require("vscode")
local markdown_helper = require("user-plugins.markdown-helper")

-- VSCode側でもMarkdownリーダー系ショートカットを有効化
markdown_helper.setup_keymaps()

local function vscode_action(action)
  return function()
    vscode.action(action)
  end
end

-- VSCodeが管理する領域はNeovim側で無効化
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"

-- VSCode連携キーマップ
vim.keymap.set("n", "<leader>ff", vscode_action("workbench.action.quickOpen"))
vim.keymap.set("n", "<leader>fg", vscode_action("workbench.action.findInFiles"))
vim.keymap.set("n", "<leader>fb", vscode_action("workbench.action.showAllEditors"))

vim.keymap.set("n", "<leader>d", vscode_action("editor.action.showHover"))
vim.keymap.set("n", "<leader>a", vscode_action("editor.action.quickFix"))
vim.keymap.set("n", "gd", vscode_action("editor.action.revealDefinition"))
vim.keymap.set("n", "gr", vscode_action("editor.action.goToReferences"))
vim.keymap.set("n", "<leader>rn", vscode_action("editor.action.rename"))

vim.keymap.set("n", "<C-h>", vscode_action("workbench.action.navigateLeft"))
vim.keymap.set("n", "<C-j>", vscode_action("workbench.action.navigateDown"))
vim.keymap.set("n", "<C-k>", vscode_action("workbench.action.navigateUp"))
vim.keymap.set("n", "<C-l>", vscode_action("workbench.action.navigateRight"))

vim.keymap.set({ "n", "v" }, "<leader>/", vscode_action("editor.action.commentLine"))
-- Move the current visual selection to the end of the file
vim.keymap.set("v", "<leader>m", ":move $<CR>gv=gv", { desc = "Move selection to end" })

-- VSCode用の限定プラグインセット
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "echasnovski/mini.move",
    config = function()
      require("mini.move").setup({
        mappings = {
          left = "<M-h>",
          right = "<M-l>",
          down = "<M-j>",
          up = "<M-k>",
          line_left = "<M-h>",
          line_right = "<M-l>",
          line_down = "<M-j>",
          line_up = "<M-k>",
        },
      })
    end,
  },
  {
    "echasnovski/mini.surround",
    config = function()
      require("mini.surround").setup()
    end,
  },
  {
    "echasnovski/mini.comment",
    config = function()
      require("mini.comment").setup()
    end,
  },
  {
    "ggandor/leap.nvim",
    config = function()
      require("leap").create_default_mappings()
    end,
  },
})
