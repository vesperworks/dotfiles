-- tests/minimal_init.lua
-- plenary.nvim を使ったテスト用の最小設定
-- lazy.nvim 管理のプラグインをロードし、user-plugins を利用可能にする

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- lazy.nvim のパスを追加
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- plenary のパスを追加（テストフレームワーク）
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
vim.opt.rtp:prepend(plenary_path)

-- nvim config のパスを追加（user-plugins が require できるように）
vim.opt.rtp:prepend(vim.fn.expand("~/.config/nvim"))

-- plenary のコマンドを明示的にロード（--noplugin 対応）
vim.cmd("runtime plugin/plenary.vim")
