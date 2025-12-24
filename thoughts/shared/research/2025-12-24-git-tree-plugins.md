---
date: 2025-12-24T17:00:00+09:00
researcher: Claude Code
topic: "Git graph表示、ファイルツリー、Gitステータス表示のNeovimプラグイン調査"
tags: [research, neovim, git, file-tree, plugins]
status: complete
iteration: 1
---

# Research: Git Graph/ファイルツリー/Gitステータス表示プラグイン

**調査日時**: 2025-12-24 17:00
**依頼内容**: gitのgraph表示や、サイドファイルのツリーを表示して、gitのステータスを表示するようなプラグインや機能はあるか？

## サマリー

Neovimには豊富なGit関連プラグインがあり、用途に応じて選択可能。あなたの現在の設定は**非常にミニマル**で、lualineのブランチ表示のみ。Git操作やファイルツリーの専用プラグインは未導入。

## 詳細な調査結果

### 1. 現在のnvim設定の状況

#### 関連ファイル
- `lua/plugins/lualine.lua` - Gitブランチ表示のみ（`{ "branch", icon = "" }`）
- `lua/plugins/telescope.lua` - ファイル検索（Git機能未使用）
- `lua/plugins/mini.lua` - mini.moveのみ（mini.files未使用）

#### 現状
- **Git専用プラグイン**: 0個
- **ファイルツリープラグイン**: 0個
- **Git情報表示**: lualineのブランチ名のみ

---

### 2. Git Graph可視化プラグイン

| プラグイン | Stars | 特徴 | 推奨度 |
|-----------|-------|------|--------|
| **vim-flog** | ~700+ | Fugitive統合、高速、最も成熟 | ⭐⭐⭐⭐⭐ |
| **gitgraph.nvim** | ~403 | Kittyスタイル、Diffview統合 | ⭐⭐⭐⭐ |
| **Neogit** | ~4,719 | Magitクローン、複数グラフスタイル | ⭐⭐⭐⭐ |
| **fugit2.nvim** | ~444 | libgit2ベース、フルGUI | ⭐⭐⭐ |

#### 詳細: vim-flog
```vim
:Flog        " Gitグラフを開く
:Flogsplit   " 分割で開く
```
- カスタムログフォーマット
- 動的ブランチハイライト（Neovim限定）
- コミット本文の展開/折りたたみ

#### 詳細: gitgraph.nvim
```lua
require('gitgraph').draw({}, { all = true, max_count = 5000 })
```
- Enterでdiffview起動
- ビジュアルモードで範囲diff

---

### 3. ファイルツリー（Gitステータスアイコン付き）

| プラグイン | Stars | 特徴 | 推奨度 |
|-----------|-------|------|--------|
| **nvim-tree.lua** | ~8,260 | 安定・成熟、大規模ユーザーベース | ⭐⭐⭐⭐ |
| **neo-tree.nvim** | ~5,100 | モダン設計、柔軟性高い | ⭐⭐⭐⭐⭐ |
| **oil.nvim** | - | バッファ風ファイル編集 | ⭐⭐⭐ |

#### nvim-tree vs neo-tree

**nvim-tree.lua**
- デフォルトアイコン: ✗ unstaged, ✓ staged, ★ untracked
- 安定版、破壊的変更少ない

**neo-tree.nvim** (推奨)
- モダンアーキテクチャ（nui.nvim, plenary.nvim使用）
- 右寄せアイコン対応
- 専用`git_status`ソース（git statusをツリー表示）
- add/unstage/revert/commit内蔵
- 破壊的変更を避ける方針

---

### 4. Gitステータス・統合プラグイン

| プラグイン | Stars | 使用構成数 | 主要機能 |
|-----------|-------|-----------|---------|
| **gitsigns.nvim** | ~5,555 | 1,506+ | hunk操作、blame、サイン表示 |
| **diffview.nvim** | ~4,866 | 715+ | diff表示、ブランチ比較 |
| **lazygit.nvim** | ~1,990 | 291+ | lazygit TUIラッパー |
| **git-conflict.nvim** | ~1,111 | 201+ | コンフリクト可視化・解決 |

#### gitsigns.nvim（必須級）
```lua
require('gitsigns').setup({
  current_line_blame = true,  -- 現在行のblame表示
})
```
- hunkのステージング/リセット
- インラインblame
- 超高速・非同期

#### diffview.nvim
```vim
:DiffviewOpen     " 変更ファイルのdiff一覧
:DiffviewFileHistory  " ファイル履歴
```

---

### 3. Web調査結果

#### 公式ドキュメント・GitHub
- [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) - 5,555 stars
- [diffview.nvim](https://github.com/sindrets/diffview.nvim) - 4,866 stars
- [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) - 5,100 stars
- [vim-flog](https://github.com/rbong/vim-flog) - 700+ stars
- [gitgraph.nvim](https://github.com/isakbm/gitgraph.nvim) - 403 stars

## 結論

あなたの現在の設定はミニマルで、Git統合機能はほぼない状態。以下の組み合わせを推奨：

### 推奨構成（ミニマリスト向け）
```lua
-- 必須: Git装飾・hunk操作
{ "lewis6991/gitsigns.nvim" }

-- ファイルツリー（Gitステータス付き）
{ "nvim-neo-tree/neo-tree.nvim" }
```

### 推奨構成（フル機能）
```lua
{ "lewis6991/gitsigns.nvim" }    -- Git装飾
{ "nvim-neo-tree/neo-tree.nvim" } -- ファイルツリー
{ "sindrets/diffview.nvim" }      -- diff・履歴
{ "rbong/vim-flog" }              -- Gitグラフ
-- または lazygit.nvim で総合Git UI
```

## 追加の検討事項

- **YAGNI原則**: 本当に必要な機能だけを導入すべき
- **telescopeとの併用**: ファイル検索はtelescopeで十分かも
- **lazygit**: ターミナルで使うなら lazygit.nvim は不要

## 次のステップの提案

1. **gitsigns.nvim**を最初に導入（最も汎用性が高い）
2. 必要に応じて**neo-tree.nvim**を追加
3. コミット履歴の可視化が必要なら**vim-flog**または**gitgraph.nvim**
