---
date: 2026-01-12
topic: nvim-ui-plugins
type: atomic
tags: [neovim, ui, plugin]
status: completed
---

# NeoVim UI系プラグインの調査

## Q: NeoVimのコマンドバー・起動メニュー・通知UIを担当するプラグインは何か？

## A:

| UI要素 | プラグイン | 状態 |
|--------|-----------|------|
| コマンドバー（上部ポップアップ） | [noice.nvim](https://github.com/folke/noice.nvim) | インストール済み |
| 通知UI | noice.nvim または [nvim-notify](https://github.com/rcarriga/nvim-notify) | インストール済み |
| 起動メニュー/ダッシュボード | [alpha-nvim](https://github.com/goolord/alpha-nvim) または [dashboard-nvim](https://github.com/nvimdev/dashboard-nvim) | 未インストール |

## 補足

- **noice.nvim** は3つの機能（コマンドライン、メッセージ、通知）を統合的にモダンUIに置き換える
- 依存: `nui.nvim`, `nvim-notify`
- 設定ファイル: `lua/plugins/noice.lua`
