# CLAUDE.md

This file provides guidance to Claude Code when working in the dotfiles project.

## プロジェクト概要

macOS 開発環境の dotfiles を GNU Stow + jj (Jujutsu VCS) で管理する公開リポジトリ。

- **リポジトリ**: https://github.com/vesperworks/dotfiles
- **VCS**: jj (Jujutsu) v0.38.0 — **git コマンドではなく jj を使うこと**
- **symlink管理**: GNU Stow（`--no-folding`）
- **OS**: macOS (Darwin)

## VCS: jj (Jujutsu)

このプロジェクトは jj（colocate モード）で管理している。

| 操作 | コマンド |
|------|---------|
| 状態確認 | `jj status` / `jj log` |
| コミット | `jj commit -m "message"` |
| push | `jj git push --bookmark main` |
| diff | `jj diff` |
| ブックマーク確認 | `jj bookmark list` |

**注意**: git コマンドも動作するが、jj を正とする。

## ディレクトリ構造

```
~/dotfiles/
├── claude/          ← stow パッケージ (完了)
│   ├── CLAUDE.md    ← パッケージ固有（stow 除外）
│   └── .claude/     ← → ~/.claude/
├── scripts/         ← セットアップスクリプト（stow 対象外）
├── install.sh       ← stow ベースセットアップ
├── .brain/          ← gitignore 対象（PRP・中間成果物）
├── .gitignore
└── CLAUDE.md        ← このファイル（プロジェクト固有）
```

### CLAUDE.md 3層構造

| レイヤー | ファイル | 用途 |
|---------|---------|------|
| グローバル | `claude/.claude/CLAUDE.md` | 全プロジェクト共通（stow で `~/.claude/CLAUDE.md` に） |
| パッケージ固有 | `claude/CLAUDE.md` | claude パッケージ開発時のみ |
| プロジェクト固有 | `CLAUDE.md`（このファイル） | dotfiles プロジェクト全体 |

## stow パッケージ

### 追加手順

1. `~/dotfiles/<package>/` ディレクトリを作成
2. ホームからの相対パスでファイルを配置
   例: `~/.config/ghostty/config` → `ghostty/.config/ghostty/config`
3. `install.sh` の `STOW_PACKAGES` 配列に追加
4. `stow -t ~ --no-folding <package>` でリンク作成

### パッケージ一覧

| パッケージ | リンク先 | 状態 |
|-----------|---------|------|
| `claude` | `~/.claude/` | 完了 |
| `zsh` | `~/.zshrc` 等 | 未着手 |
| `git` | `~/.gitconfig` 等 | 未着手 |
| `brew` | `~/.Brewfile` | 未着手 |
| `codex` | `~/.codex/` | 未着手 |
| `ghostty` | `~/.config/ghostty/` | 未着手 |
| `aerospace` | `~/.config/aerospace/` | 未着手 |
| `sketchybar` | `~/.config/sketchybar/` | 未着手 |
| `tmux` | `~/.config/tmux/` | 未着手 |
| `nvim` | `~/.config/nvim/` | 未着手（octopus merge） |

## 重要コマンド

```bash
# stow 適用（単体）
stow -t ~ --no-folding <package>

# stow 解除
stow -t ~ -D <package>

# 全パッケージセットアップ
./install.sh

# スクリプト品質チェック
shellcheck install.sh scripts/*.sh
```

## セキュリティ（公開リポ前提）

- **機密情報は絶対にコミットしない**
- APIキー・トークン → `~/.secrets.zsh` に分離（.gitignore 対象）
- `settings.local.json` → .gitignore 対象
- `.brain/` → .gitignore 対象

## 進捗状況

| Phase | 内容 | 状態 |
|-------|------|------|
| 0 | jj 初期化 + claude 移植（226コミット履歴付き） | 完了 |
| 1 | .gitignore + install.sh + GitHub 登録 | 完了 |
| 2 | zsh パッケージ（APIキー→~/.secrets.zsh 分離必須） | 未着手 |
| 3 | git パッケージ（include 方式、http.sslverify=false 削除） | 未着手 |
| 4 | brew パッケージ（.Brewfile 手動記載） | 未着手 |
| 5 | アプリ設定（codex, ghostty, aerospace, sketchybar, tmux） | 未着手 |
| 5.8 | nvim パッケージ（独自 git リポから octopus merge） | 未着手 |
| 6 | ドキュメント + クリーンアップ（LICENSE, README） | 未着手 |

詳細は `.brain/dotfiles/prp/PRP-001-dotfiles-setup.md` 参照。

## PRP 管理

| ディレクトリ | 状態 |
|-------------|------|
| `.brain/dotfiles/prp/` | アクティブ（進行中） |
| `.brain/dotfiles/prp/done/` | 完了済み |
| `.brain/dotfiles/prp/cancel/` | キャンセル |
| `.brain/dotfiles/prp/tbd/` | 保留（要件不明確・意思決定待ち） |

### 現在の PRP

| PRP | 内容 | 状態 |
|-----|------|------|
| PRP-001 | dotfiles プロジェクト構築（マスタープラン） | アクティブ |
| PRP-002 | GitHub リモートリポジトリ登録 | done |
