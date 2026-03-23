# CONTINUITY LEDGER

> Session briefing designed to survive context compaction
> 詳細な実装履歴は `logs.md` を参照

## Goal

Neovimで快適なnote taking環境を作りながら、カスタマイズを楽しむ。
- Obsidian連携、Zen Mode、タスク管理などの執筆支援
- 日々の改善、プラグイン探索、vimバインド調整

## Active Constraints

- YAGNI/DRY/SOLID/KISS原則を遵守
- 既存機能 → インストール済みプラグイン → 新規実装の順で検討
- ファイル変更時はdiff提示 → 承認後に実行
- logs.mdに作業記録を残す

## Core Features（実装済み）

### 執筆支援
| キー | 機能 | 備考 |
|------|------|------|
| `<leader>z` | Zen + Typewriter トグル | Alacritty透明化連動 |
| `<leader>Z` | Zen Writing Mode | 新規ファイル自動作成 → Zen起動 |
| `<leader>h` | 見出しジャンプ | fuzzy検索、プレビュー付き |
| `<leader>j` | 進行中タスク表示 | タイマー連携 |
| `<leader>c` | Callout/コードブロック作成 | think, idea含む |
| `<leader>x` | タスク化トグル | 複数行対応 |
| `<CR>` | タスク状態循環 | タイマー自動開始/停止 |

### LLMプロンプト（gp.nvim）
| キー | 機能 |
|------|------|
| `<leader>la` | ノート整理 |
| `<leader>ls` | シンプル化 |
| `<leader>ld` | タスク分解 |
| `<leader>lf` | ツリー化 |
| `<leader>le` | ToDo抽出 |

### ファイル操作
| キー | 機能 |
|------|------|
| `<leader>e` | oil.nvim（エクスプローラー） |
| `<leader>o` | smart-open.nvim |
| `<leader>do` | DiffviewOpen |

## Known Limitations

- **virt_lines_above**: 行0で動作しない（Neovim Issue #16166、未解決）
- **typewriter先頭**: ファイル先頭でカーソル中央化不可（scrolloff制限）

## Current State

- **Working on**: なし（待機中）
- **Blockers**: なし
- **Next**: ユーザーからの次のリクエスト待ち

## Files to Know

| ファイル | 役割 |
|----------|------|
| `logs.md` | 実装履歴（最重要） |
| `lua/plugins/zen-modes.lua` | Zen Mode、Typewriter、twilight |
| `lua/plugins/gp.lua` | LLMプロンプト |
| `lua/user-plugins/heading-jump.lua` | 見出しジャンプ |
| `lua/user-plugins/pending-tasks.lua` | 進行中タスク表示 |
| `lua/user-plugins/task-timer.lua` | タスクタイマー |
| `lua/user-plugins/markdown-helper.lua` | Markdown編集支援 |
| `thoughts/shared/research/` | 調査記録 |
