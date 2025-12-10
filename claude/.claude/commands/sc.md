---
name: sc
description: 'Smart commit: /sc (段階コミット) or /sc "message" (クイックコミット)'
---

# Smart Commit

## モード判定

- `$ARGUMENTS` が**空**の場合 → **段階コミットモード**（変更をグループ化して順次コミット）
- `$ARGUMENTS` が**ある**場合 → **クイックコミットモード**（従来の一括コミット）

---

## クイックコミットモード（引数あり）

`/sc "message"` の形式で呼び出された場合、従来のスクリプトを実行：

```bash
~/.claude/scripts/smart-commit.sh "$ARGUMENTS"
```

全変更を一括でステージング・コミットします。

---

## 段階コミットモード（引数なし）

`/sc` の形式で呼び出された場合、以下のステップで段階的にコミット：

### Step 1: 変更分析

1. `git status --porcelain` で変更ファイル一覧を取得
2. `git diff --name-only` でステージングされていない変更を確認
3. `git diff --cached --name-only` でステージング済みの変更を確認
4. 変更内容を分析し、論理的なグループに分類提案

**グループ化の基準**:
- 同じディレクトリ内のファイル
- 同じ機能・目的に関連するファイル
- 同じコミットタイプ（feat/fix/docs等）に該当するファイル

### Step 2: グループ確認

ユーザーに提案したグループを表示し、確認を求める：

```
変更を以下のグループでコミットしますか？

Commit 1: [feat] 新機能追加
  - src/feature.ts
  - src/feature.test.ts

Commit 2: [docs] ドキュメント更新
  - README.md
  - CLAUDE.md

Commit 3: [chore] 設定変更
  - .klaude/settings.json
```

承認されたらStep 3へ、調整が必要なら再グループ化。

### Step 3: TodoWrite でタスク化

各コミットをTodoアイテムとして登録：

```
TodoWrite([
  { content: "Commit 1: [feat] 新機能追加", status: "pending" },
  { content: "Commit 2: [docs] ドキュメント更新", status: "pending" },
  { content: "Commit 3: [chore] 設定変更", status: "pending" }
])
```

### Step 4: 順次コミット

各グループを順番に処理：

1. **ステージング**: `git add <specific-files>` （グループ内のファイルのみ）
2. **メッセージ生成**: 変更内容から適切なコミットメッセージを生成
3. **コミット実行**: `git commit -m "<type>(<scope>): <subject>\n\n<body>"`
4. **進捗更新**: TodoWrite で該当タスクを `completed` にマーク
5. 次のグループへ進む

### Step 5: 完了サマリー

全コミット完了後、結果を表示：

```bash
git log --oneline -N  # N = 作成したコミット数
```

---

## コミットメッセージ形式

```
<type>(<scope>): <subject>

<body>
```

### Type
- **feat**: 新機能
- **fix**: バグ修正
- **docs**: ドキュメントのみの変更
- **style**: コードの意味に影響しない変更（空白、フォーマット等）
- **refactor**: バグ修正でも機能追加でもないコード変更
- **test**: テストの追加や修正
- **chore**: ビルドプロセスやツールの変更

---

## 使用例

### 段階コミット（推奨）
```bash
/sc
# → 変更を分析 → グループ提案 → 順次コミット
```

### クイックコミット（従来動作）
```bash
/sc ダークモード対応
# → 全変更を一括コミット（feat: implement dark mode theme support）
```

---

## 注意事項

- 段階コミットモードでは、各グループごとに個別のコミットが作成されます
- クイックコミットモードでは、ステージングされていない変更も自動的にステージングされます
- コミット前に変更内容を確認することを推奨します
