# multi-feature-ccm コマンドガイド

## 概要

`multi-feature-ccm`は、ccmanagerを統合したマルチエージェント機能開発コマンドです。複数の機能開発を並列で効率的に管理できます。

## 主な特徴

- **ccmanagerによるセッション管理**: 各worktreeの作業状態を一元管理
- **プリセット駆動開発**: フェーズごとに最適化された起動設定
- **並列開発サポート**: 複数機能の同時開発と切り替えが容易
- **進捗可視化**: 各フェーズの完了状態をリアルタイムで確認

## 使用方法

### 基本的な使用

```bash
/multi-feature-ccm "ユーザープロフィール画像アップロード機能"
```

### オプション

- `--keep-worktree`: 作業用worktreeを削除せずに保持
- `--no-merge`: mainブランチへの自動マージをスキップ
- `--pr`: GitHub Pull Requestを作成
- `--no-draft`: 通常のPR作成（デフォルトはドラフト）
- `--no-ccm`: ccmanager統合を無効化（従来モード）
- `--preset-base`: ccmanagerプリセットのベース名（デフォルト: feature）

### 複数機能の並列開発

```bash
# ターミナル1
/multi-feature-ccm "決済システム統合" --keep-worktree

# ターミナル2
/multi-feature-ccm "通知システム実装" --keep-worktree

# ccmコマンドで管理
$ ccm
  ● payment-integration (feature-coder)
❯ ◐ notification-system (feature-explorer)
```

## ccmanagerプリセット設定

`~/.config/ccmanager/config.json`に以下のプリセットを追加することを推奨：

```json
{
  "commandPresets": {
    "presets": [
      {
        "id": "feature-explorer",
        "name": "Feature Explorer",
        "command": "claude",
        "args": ["--prompt", "@~/.claude/prompts/explorer.md", "--dangerously-skip-permissions"]
      },
      {
        "id": "feature-planner",
        "name": "Feature Planner",
        "command": "claude",
        "args": ["--prompt", "@~/.claude/prompts/planner.md", "--resume"]
      },
      {
        "id": "feature-coder",
        "name": "Feature Coder (TDD)",
        "command": "claude",
        "args": ["--prompt", "@~/.claude/prompts/coder.md", "--resume"]
      }
    ]
  }
}
```

## ワークフロー

1. **Worktree Setup**: ccmanager統合環境の準備
2. **Explorer Phase**: 要件分析とコンテキスト調査
3. **Planner Phase**: アーキテクチャ設計と実装戦略
4. **Prototype Phase**: 最小限の動作確認
5. **Coder Phase**: TDDによる本格実装
6. **Completion Phase**: 品質確認とレポート生成

## 従来版との違い

| 機能 | multi-feature | multi-feature-ccm |
|------|--------------|-------------------|
| セッション管理 | 手動 | ccmanagerで自動化 |
| フェーズ切り替え | コマンド実行 | ccmanager UI |
| 並列開発 | 可能だが管理が困難 | 簡単に切り替え可能 |
| 進捗確認 | ログを確認 | ccmanagerで一覧表示 |

## トラブルシューティング

### ccmanagerが見つからない場合

```bash
npm install -g ccmanager
```

### jqが見つからない場合

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### ccmanager統合を無効化したい場合

```bash
/multi-feature-ccm "機能名" --no-ccm
```

## 関連ドキュメント

- [ccmanager公式ドキュメント](https://github.com/khulnasoft/ccmanager)
- [multi-feature.md](../.claude/commands/multi-feature.md) - 従来版のコマンド
- [worktree-utils.sh](../.claude/scripts/worktree-utils.sh) - 共通ユーティリティ関数