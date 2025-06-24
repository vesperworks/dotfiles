# ワークフロー改善機能の使用方法

このドキュメントでは、マルチエージェントワークフローの新機能について説明します。

## 新機能概要

1. **ブランチ切り替え確認**: worktree作成時に正しいブランチが設定されているか自動確認
2. **自動クリーンアップ**: 古いworktreeを定期的に削除
3. **ローカルマージ**: PRを作らずにローカルでmainにマージ
4. **PR作成**: GitHub CLIを使った自動PR作成
5. **柔軟なオプション**: 各種動作をカスタマイズ可能

## 利用可能なオプション

### `--keep-worktree`
worktreeを作業後も保持します（デフォルト: 削除）

```bash
/project:multi-tdd "バグ修正" --keep-worktree
```

### `--no-merge`
mainブランチへの自動マージをスキップします（デフォルト: マージ）

```bash
/project:multi-feature "新機能" --no-merge
```

### `--pr`
GitHub PRを自動作成します（デフォルト: 作成しない）

```bash
/project:multi-refactor "リファクタリング" --pr
```

### `--no-draft`
通常のPRを作成します（デフォルト: ドラフトPR）

```bash
/project:multi-feature "本番機能" --pr --no-draft
```

### `--no-cleanup`
古いworktreeの自動クリーンアップを無効化

```bash
/project:multi-tdd "長期作業" --no-cleanup
```

### `--cleanup-days N`
N日以上前のworktreeを削除（デフォルト: 7日）

```bash
/project:multi-feature "機能開発" --cleanup-days 14
```

## 使用例

### 1. 通常のローカル開発（デフォルト動作）
```bash
/project:multi-tdd "認証バグの修正"
```
- worktreeで開発
- テスト実行
- mainにマージ
- worktree削除

### 2. レビュー用にworktreeを保持
```bash
/project:multi-feature "ダッシュボード機能" --keep-worktree --no-merge
```
- worktreeで開発
- テスト実行
- マージせずに保持
- 手動でレビュー後にマージ

### 3. GitHub PR作成フロー
```bash
/project:multi-refactor "TypeScript移行" --pr
```
- worktreeで開発
- テスト実行
- ブランチをプッシュ
- ドラフトPR作成
- worktree保持（PRマージ後に削除）

### 4. 本番リリース用PR
```bash
/project:multi-feature "決済機能" --pr --no-draft
```
- worktreeで開発
- テスト実行
- ブランチをプッシュ
- 通常のPR作成（レビュー準備完了）

### 5. 長期開発プロジェクト
```bash
/project:multi-feature "大規模機能" --keep-worktree --no-merge --no-cleanup
```
- worktreeで開発
- マージしない
- worktree保持
- 自動クリーンアップ無効

## ワークフロー例

### シナリオ1: 素早いバグ修正
```bash
# バグ修正を実行
/project:multi-tdd "ログイン時のセッションエラー修正"

# 自動的に以下が実行される：
# 1. worktree作成（bugfix/login-session-error-...）
# 2. TDDサイクル実行
# 3. mainにマージ
# 4. worktree削除
```

### シナリオ2: チーム開発でのPR作成
```bash
# 新機能をPRで開発
/project:multi-feature "ユーザー通知システム" --pr

# 自動的に以下が実行される：
# 1. worktree作成（feature/user-notification-...）
# 2. 機能開発
# 3. GitHubにプッシュ
# 4. ドラフトPR作成
# 5. worktree保持（レビュー用）

# レビュー後、手動でマージしてからクリーンアップ
git worktree remove .worktrees/feature-user-notification-...
```

### シナリオ3: 段階的リファクタリング
```bash
# 第1段階
/project:multi-refactor "認証モジュールのasync/await化" --keep-worktree --no-merge

# レビューと動作確認

# 問題なければマージ
cd .
git merge refactor/auth-module-async-...

# worktreeクリーンアップ
git worktree remove .worktrees/refactor-auth-module-async-...
```

## 古いworktreeの管理

### 自動クリーンアップ
デフォルトでは、新しいワークフロー実行時に7日以上前のworktreeが自動削除されます。

### 手動クリーンアップ
```bash
# worktree-utils.shを読み込んで実行
source .claude/scripts/worktree-utils.sh
cleanup_old_worktrees 3  # 3日以上前のworktreeを削除
```

### 全worktreeの確認
```bash
git worktree list
```

## トラブルシューティング

### PR作成でエラーが出る場合
```bash
# GitHub CLIのインストール
brew install gh

# 認証
gh auth login
```

### マージでコンフリクトが発生した場合
自動マージが失敗した場合は、手動で解決してください：
```bash
git checkout main
git merge --no-ff branch-name
# コンフリクトを解決
git commit
```

### worktreeが削除できない場合
```bash
# 強制削除
git worktree remove --force .worktrees/feature-name
```

## ベストプラクティス

1. **短期タスク**: デフォルト設定（自動マージ・自動削除）を使用
2. **レビューが必要**: `--pr`オプションでPR作成
3. **実験的な変更**: `--keep-worktree --no-merge`で保持
4. **本番リリース**: `--pr --no-draft`で通常PR作成
5. **定期的なクリーンアップ**: 古いworktreeは自動削除される

## まとめ

新しいワークフロー改善により、以下が可能になりました：

- ✅ より安全なブランチ管理（自動確認）
- ✅ 柔軟な完了オプション（ローカルマージ or PR）
- ✅ worktreeの効率的な管理（自動クリーンアップ）
- ✅ チーム開発への対応（PR作成機能）
- ✅ 開発スタイルに合わせたカスタマイズ

これらの機能により、マルチエージェントワークフローがより実用的で柔軟になりました。