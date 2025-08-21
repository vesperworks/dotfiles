---
name: s
description: 'Smart commit with auto-generated message: /s [optional context]'
---

# Smart Commit

現在のgit diffを分析し、変更内容を理解して適切なコミットメッセージを生成し、コミットを実行します。

## 使用方法
`/s [意図やコンテキスト]`

## 実行内容

事前定義されたスクリプトを呼び出してスマートコミットを実行します：

```bash
~/.claude/scripts/smart-commit.sh "$ARGUMENTS"
```

### 処理の流れ
1. **スクリプト実行**: `smart-commit.sh`を呼び出し（パーミッション確認なし）
2. **変更分析**: git statusとdiffでファイル変更を分析
3. **タイプ判定**: 変更内容から適切なコミットタイプを自動判定
4. **メッセージ生成**: タイムスタンプ付きメッセージファイルを作成
5. **コミット実行**: すべての変更をステージングしてコミット

### スクリプトの詳細
- **場所**: `~/.claude/scripts/smart-commit.sh`
- **実行権限**: 実行可能に設定済み
- **引数**: コンテキスト情報（オプション）

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
- コミットメッセージファイルは`./tmp/`ディレクトリに保存されます
- タイムスタンプ形式: `YYYYMMDD-HHMMSS`
- スクリプトは事前定義済みでパーミッション確認は不要です

## 生成される中間ファイル

| ファイル名 | 説明 |
|-----------|------|
| `./tmp/commit-msg-{timestamp}.txt` | 生成されたコミットメッセージ |

このファイルにより、生成されたメッセージのレビューと履歴追跡が可能になります。