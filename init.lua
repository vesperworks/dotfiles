-- init.lua / early‐init.lua など、マッピングより前で
vim.g.mapleader = " "          -- <- Space をリーダーに
vim.g.maplocalleader = ","     -- ローカルリーダー（ftplugin 専用など）

-- 起動時 lazy.nvim を読み込む
require("config.lazy")

vim.o.conceallevel = 2
vim.o.confirm = false


vim.cmd [[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight EndOfBuffer guibg=NONE ctermbg=NONE
]]

-- Markdownファイルだけに反映（おすすめ）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- ① まず不要な 't' を確実に外しておく
    vim.opt_local.formatoptions:remove("t")

    -- ② リスト継続に必要な 'o','r','n' をまとめて追加
    vim.opt_local.formatoptions:append("orn")

    -- もし自動折り返しも欲しいなら（行が割れて良いなら）こちら
    -- vim.opt_local.formatoptions:append("tor n")  -- ← t も入れる
  end,
})

vim.keymap.set({ "n", "v" }, "L", "$", { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "H", "^", { noremap = true, silent = true })

-- システムクリップボードにyank
vim.opt.clipboard:append("unnamedplus")
-- 次の飛び先も記録
vim.opt.jumpoptions:append("stack")

-- どこか (after/plugin/keymaps.lua など) に追記
vim.keymap.set(
  "n",
  "<leader>fo",
  "<cmd>Telescope oldfiles<cr>",
  { desc = "最近開いたファイル (oldfiles)" }
)

-- User plugins (markdown helper, obsidian zoom etc.)
require('user-plugins.markdown-helper').setup_keymaps()
require('user-plugins.obsidian-zoom')
