---
date: 2025-12-11T00:00:00+09:00
researcher: Claude Code
topic: "nvimで特定の行（- [-]）をフローティングウィンドウで常時表示する機能の調査"
tags: [research, nvim, floating-window, todo, plugin]
status: active
iteration: 1
---

# Research: Pending Tasks Floating Window

**調査日時**: 2025-12-11
**依頼内容**: nvimで特定の行をフローティングで表示し続けるプラグインの調査。`- [-]`形式の未完了タスク行をまとめて表示する機能の実現方法。

## サマリー

「`- [-]`形式の行をフローティングで常時表示」というドンピシャのプラグインは存在しない。ただし、関連機能を持つプラグインと、Neovim APIを使ったカスタム実装で実現可能。

## 詳細な調査結果

### 1. 既存プラグイン調査

#### フローティングウィンドウ系

| プラグイン | 特徴 | フィット度 |
|-----------|------|----------|
| [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) | 画面上部に「今どの関数内にいるか」をsticky表示 | ★★★☆☆ |
| [snacks.nvim (scratch)](https://github.com/folke/snacks.nvim/blob/main/docs/scratch.md) | フローティングのスクラッチバッファ | ★★☆☆☆ |
| [incline.nvim](https://neovimcraft.com/plugin/b0o/incline.nvim/) | 各ウィンドウ用の軽量フローティングステータスライン | ★★☆☆☆ |

#### TODO/タスク管理系

| プラグイン | 特徴 | フィット度 |
|-----------|------|----------|
| [dooing](https://github.com/atiladefreitas/dooing) | ミニマルなフローティングTODOリスト | ★★☆☆☆ |
| [todo.nvim](https://github.com/Ackeraa/todo.nvim) | プロジェクトベースのTODO管理 | ★★☆☆☆ |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | TODO/HACK/BUGなどのハイライトと検索 | ★☆☆☆☆ |

#### 付箋・スティッキーノート系

| プラグイン | 特徴 | フィット度 |
|-----------|------|----------|
| [fusen.nvim](https://neovimcraft.com/plugin/walkersumida/fusen.nvim/) | Gitブランチ別の付箋機能 | ★★☆☆☆ |

#### Quickfix強化系

| プラグイン | 特徴 | フィット度 |
|-----------|------|----------|
| [nvim-bqf](https://github.com/kevinhwang91/nvim-bqf) | quickfixをフローティングプレビュー付きで強化 | ★★☆☆☆ |
| [quicker.nvim](https://github.com/stevearc/quicker.nvim) | quickfixのUI/UX改善 | ★★☆☆☆ |

### 2. 実現可能なアプローチ

#### A. Telescope + quickfix連携（既存プラグイン活用）

```
live_grep で "- \[-\]" を検索
    ↓
Ctrl-q でquickfixに送る
    ↓
nvim-bqfでフローティングプレビュー
```

**利点**: 新規コード不要
**欠点**: 常時表示ではなく手動更新が必要

#### B. treesitter-contextを応用（ハック的）

markdownパーサーでTODO行をcontextとして認識させる

**利点**: 既存の安定したプラグインを活用
**欠点**: 本来の用途と異なるためハック的

#### C. カスタムLua実装（推奨）

`nvim_open_win` APIでフローティングウィンドウを作成し、autocmdで自動更新

**利点**: 完全にカスタマイズ可能、軽量
**欠点**: 自前での実装が必要（50-100行程度）

### 3. Neovim API参考情報

フローティングウィンドウ作成の基本API:

```lua
-- バッファ作成
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"line1", "line2"})

-- ウィンドウ作成
local win = vim.api.nvim_open_win(buf, false, {
  relative = 'editor',
  width = vim.o.columns,
  height = 3,
  row = vim.o.lines - 5,  -- 下部に配置
  col = 0,
  style = 'minimal',
  border = 'single',
})
```

## 結論

既存プラグインでドンピシャの機能はないため、**カスタムLua実装が最適解**。Neovimの`nvim_open_win` APIを使えば50-100行程度で実現可能。

## 設計案（壁打ちで決定）

### 要件

| 項目 | 決定事項 |
|------|---------|
| 表示位置 | 画面下部（全幅）、ステータスライン上 |
| 更新タイミング | リアルタイム（TextChanged等） |
| 対象範囲 | 現在のファイルのみ |
| 操作 | トグル、行クリックでジャンプ、件数制限 |

### 実装構成

```lua
-- lua/pending-tasks.lua
local M = {}

M.config = {
  pattern = "^%s*%- %[%-%]",  -- "- [-]" にマッチ
  max_items = 5,               -- 最大表示件数
  height = 3,                  -- ウィンドウの高さ
}

-- 主要関数
-- 1. collect_pending_tasks() - 現在のバッファから該当行を収集
-- 2. render_window()         - フローティングウィンドウを描画
-- 3. toggle()                - 表示/非表示トグル
-- 4. jump_to_line(lnum)      - 元の行へジャンプ
-- 5. setup(opts)             - 初期化とautocmd設定

return M
```

## 次のステップ

1. `lua/pending-tasks.lua` を実装
2. キーマップ設定
3. テスト・調整

## Sources

- [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context)
- [snacks.nvim scratch](https://github.com/folke/snacks.nvim/blob/main/docs/scratch.md)
- [dooing](https://github.com/atiladefreitas/dooing)
- [nvim-bqf](https://github.com/kevinhwang91/nvim-bqf)
- [fusen.nvim](https://neovimcraft.com/plugin/walkersumida/fusen.nvim/)
- [todo-comments.nvim](https://github.com/folke/todo-comments.nvim)
- [Neovim API docs](https://neovim.io/doc/user/api.html)
