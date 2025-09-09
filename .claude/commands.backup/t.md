---
name: t
description: 'Archive completed tasks to done.md: /t'
---

# TODO管理コマンド

修正済みになった項目のtodo.mdでのステータス更新と、done.mdへのアーカイブを行います。

## 実行手順

1. **tmp/ディレクトリの準備**
   - `./tmp/`ディレクトリを作成（存在しない場合）
   - バックアップファイルの保存場所として使用

2. **バックアップの作成**
   - todo.mdとdone.mdのバックアップを`./tmp/`に保存
   - タイムスタンプ付きでバックアップ

3. **todo.mdを読み込み**
   - 完了済み項目（[x]マーク付き）を特定

4. **done.mdへのアーカイブ**
   - 完了日時を記録
   - 適切なセクションに分類して追加
   - 実施内容の詳細を保存

5. **todo.mdの更新**
   - 完了済みセクションを削除
   - 残タスクの優先順位を再整理
   - 次のアクションを明確化

6. **アーカイブレポートの生成**
   - `./tmp/`にアーカイブレポートを保存
   - 何が移動されたかを記録

## 使用例

```bash
/t
```

このコマンドは以下の処理を自動実行します：
- 完了項目をdone.mdへ移動
- todo.mdから完了済みセクションを削除
- 優先順位と次のアクションを更新

## 実行内容

### Step 1: tmpディレクトリの準備とバックアップ
```bash
# tmpディレクトリを作成
mkdir -p ./tmp

# タイムスタンプを生成
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# バックアップファイルを作成
if [ -f todo.md ]; then
    cp todo.md "./tmp/todo-backup-${TIMESTAMP}.md"
fi
if [ -f done.md ]; then
    cp done.md "./tmp/done-backup-${TIMESTAMP}.md"
fi
```

### Step 2: 完了項目の特定
```bash
# todo.mdから[x]マークの項目を検索
grep -n "^\s*- \[x\]" todo.md || echo "No completed items found"
```

### Step 3: done.mdへの追加
完了項目を適切にフォーマットしてdone.mdに追加：
- 完了日時の記録
- カテゴリ別の整理
- 実施内容の要約

### Step 4: todo.mdのクリーンアップ
- 完了済みセクションの削除
- 残タスクの再整理
- 優先順位の更新

### Step 5: アーカイブレポートの生成
```bash
# アーカイブレポートを生成
ARCHIVE_REPORT="./tmp/archive-report-${TIMESTAMP}.md"
echo "# Archive Report - ${TIMESTAMP}" > "$ARCHIVE_REPORT"
echo "" >> "$ARCHIVE_REPORT"
echo "## Archived Tasks" >> "$ARCHIVE_REPORT"
# アーカイブされたタスクの詳細を記録
```

### Step 6: コミット
```bash
git add todo.md done.md
git commit -m "chore: アーカイブ完了タスクをdone.mdへ移動"
```

## 注意事項
- 完了マーク（[x]）が付いているセクション全体を移動
- セクションの階層構造を保持
- 日付と実施内容を記録
- すべての中間ファイル（バックアップ、レポート）は`./tmp/`ディレクトリに保存
- タイムスタンプ形式: `YYYYMMDD-HHMMSS`

## 詳細な動作

### todo.mdの形式
```markdown
## 高優先度タスク
- [x] 完了したタスク1
  - 詳細な説明
  - 関連ファイル: src/auth.js
- [ ] 未完了のタスク2

## 中優先度タスク
- [x] 完了したタスク3
```

### done.mdへの移動形式
```markdown
## 2025-01-11
### 高優先度タスク
- [x] 完了したタスク1
  - 詳細な説明
  - 関連ファイル: src/auth.js
  - 完了時刻: 14:30

### 中優先度タスク
- [x] 完了したタスク3
  - 完了時刻: 15:45
```

## 実行後の確認

- todo.mdから完了項目が削除されているか
- done.mdに適切に追加されているか
- コミットが正しく作成されているか
- `./tmp/`ディレクトリに以下のファイルが作成されているか：
  - `todo-backup-{timestamp}.md`
  - `done-backup-{timestamp}.md`
  - `archive-report-{timestamp}.md`

## 生成される中間ファイル

| ファイル名 | 説明 |
|-----------|------|
| `./tmp/todo-backup-{timestamp}.md` | todo.mdのバックアップ |
| `./tmp/done-backup-{timestamp}.md` | done.mdのバックアップ |
| `./tmp/archive-report-{timestamp}.md` | アーカイブ作業のレポート |