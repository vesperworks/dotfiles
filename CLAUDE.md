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
| `tmux` | `~/.config/tmux/` | 完了 |
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

## .gitignore ルール

### .brain/

- ルートに1つだけ存在（`dotfiles/.brain/`）
- サブディレクトリでプロジェクト別管理: `.brain/dotfiles/`, `.brain/tmux/` 等
- パッケージ内に `.brain/` を作らない（ルートに集約）

### .claude/

- `claude/.claude/` = stow パッケージ本体 → **バージョン管理対象**
- 各パッケージ内に生まれる `.claude/` → **gitignore 対象**（`**/.claude/` + `!claude/.claude/`）
- `settings.local.json`, `projects/`, `todos/`, `plans/` → gitignore 対象

### plugins/

- TPM 等のプラグインマネージャが管理するディレクトリ → gitignore 対象
- 例: `tmux/.config/tmux/plugins/`

## セキュリティ（公開リポ前提）

- **機密情報は絶対にコミットしない**
- APIキー・トークン → 1Password Environments（`~/.secrets.env`）で管理
- `settings.local.json` → .gitignore 対象
- `.brain/` → .gitignore 対象

## octopus merge（独自 git リポの取り込み）

独自 git リポジトリを持つパッケージは `git subtree add` で履歴ごと取り込む。

```bash
git subtree add --prefix=<package>/.config/<app> <source-repo> <branch>
```

- 履歴が dotfiles の main に合流する
- subtree add 後、jj が自動検出（colocate モード）
- plugins/ 等の外部依存は gitignore で除外し、プラグインマネージャに任せる

## 進捗状況

| Phase | 内容 | 状態 |
|-------|------|------|
| 0 | jj 初期化 + claude 移植（226コミット履歴付き） | 完了 |
| 1 | .gitignore + install.sh + GitHub 登録 | 完了 |
| 1.5 | vw:commit の jj 対応（PRP-017 Part 1） | 完了 |
| 2 | zsh パッケージ（APIキー→1Password Environments 移行） | 完了 |
| 2.5 | ghostty / alacritty パッケージ | 完了 |
| 3 | tmux パッケージ（独自 git リポから subtree merge） | 完了 |
| 4 | git パッケージ（丸ごと stow） | 完了 |
| 5 | brew パッケージ（.Brewfile 手動記載） | 完了 |
| 6 | アプリ設定（aerospace, sketchybar） | 完了 |
| 6a | codex パッケージ | 後回し |
| 6.8 | nvim パッケージ（独自 git リポから subtree merge） | 未着手 |
| 5.9 | non-colocate 移行（PRP-017 Part 2） | 未着手 |
| 7 | ドキュメント + クリーンアップ（LICENSE, README） | 未着手 |

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
| PRP-017 | vw:commit git/jj 両対応 + non-colocate 移行 | Part 1 完了 / Part 2 待機 |
