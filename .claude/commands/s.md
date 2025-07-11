---
name: s
description: 'Smart commit with auto-generated message: /s [optional context]'
---

# Smart Commit

現在のgit diffを分析し、変更内容を理解して適切なコミットメッセージを生成し、コミットを実行します。

## 使用方法
`/s [意図やコンテキスト]`

## 実行内容

以下の手順で自動的にコミットを作成します：

1. **tmpディレクトリの準備**
   - `./tmp/`ディレクトリを作成（存在しない場合）
   - 中間ファイルの保存場所として使用

2. **変更内容の確認**
   - `git status`で変更ファイルを確認
   - `git diff --cached`でステージング済みの変更を確認
   - `git diff`でステージングされていない変更を確認

3. **差分の保存**
   - 現在の差分を`./tmp/commit-diff-{timestamp}.diff`に保存
   - コミット時点の変更内容を記録

4. **コミットメッセージの生成**
   - 変更内容を分析し、以下の形式でメッセージを生成：
     - 変更の種類を判定（feat/fix/docs/style/refactor/test/chore）
     - 影響範囲を特定（どのモジュール/機能か）
     - 変更の要約を作成（50文字以内）
     - 必要に応じて詳細説明を追加
   - 生成したメッセージを`./tmp/commit-msg-{timestamp}.txt`に保存

5. **ユーザーの意図の反映**
   - `$ARGUMENTS`で提供された意図やコンテキストを考慮
   - 意図が明確な場合は、それを優先してメッセージに反映

6. **コミットの実行**
   - 全ての変更をステージング（`git add -A`）
   - 生成したメッセージでコミット実行
   - **注意**: Co-Authored-Byは追加しません（settings.local.jsonの設定に従う）

## コミットメッセージ形式

```
<type>(<scope>): <subject>

<body>

$ARGUMENTSの内容: <ユーザーの意図>
```

### Type
- **feat**: 新機能
- **fix**: バグ修正
- **docs**: ドキュメントのみの変更
- **style**: コードの意味に影響しない変更（空白、フォーマット等）
- **refactor**: バグ修正でも機能追加でもないコード変更
- **test**: テストの追加や修正
- **chore**: ビルドプロセスやツールの変更

## 実行例

```bash
# 使用例1: 意図なし
/s

# 使用例2: 意図あり
/s 初期設定の追加

# 使用例3: 詳細な意図
/s CLAUDE.mdの改善とカスタムコマンドの追加
```

## 詳細な使用例

### ドキュメント更新
```bash
/s READMEにインストール手順を追加
# → docs: add installation instructions to README
```

### バグ修正
```bash
/s null参照エラーの修正
# → fix: handle null reference in user validation
```

### 機能追加
```bash
/s ダークモード対応
# → feat: implement dark mode theme support
```

### リファクタリング
```bash
/s 重複コードの削除
# → refactor: remove duplicate code in auth module
```

### テスト追加
```bash
/s ユーザー認証のユニットテスト
# → test: add unit tests for user authentication
```

## 注意事項

- ステージングされていない変更も自動的にステージングされます
- コミット前に変更内容を確認することを推奨します
- 大きな変更の場合は、複数のコミットに分割することを検討してください
- すべての中間ファイル（差分、コミットメッセージ）は`./tmp/`ディレクトリに保存されます
- タイムスタンプ形式: `YYYYMMDD-HHMMSS`

## 生成される中間ファイル

| ファイル名 | 説明 |
|-----------|------|
| `./tmp/commit-diff-{timestamp}.diff` | コミット時点のgit diff全体 |
| `./tmp/commit-msg-{timestamp}.txt` | 生成されたコミットメッセージ |

これらのファイルにより、以下が可能になります：
- コミット履歴の追跡
- 生成されたメッセージのレビュー
- 差分のアーカイブ