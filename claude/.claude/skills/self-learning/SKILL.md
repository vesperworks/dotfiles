---
name: self-learning
description: 会話中のミスや修正を汎用ルールに変換し、CLAUDE.mdまたは.claude/rules/に永続化する。Use when the user corrects a mistake, asks to remember a rule, or wants to learn from errors. Specializes in rule generalization, duplicate detection, and optimal storage location selection. NOT for general notetaking (use notetaking skill) and NOT for code documentation (use codebase-exploration).
---

# Self-Learning Skill

## Core Purpose

会話中のミス・修正・フィードバックを分析し、再発防止のための汎用ルールを生成。ユーザー承認後に適切な保存先（CLAUDE.md / .claude/rules/）に永続化する。

## Quick Checklist (初期確認)

- [ ] 入力ソースの特定（引数 or 会話履歴）
- [ ] ミスの具体的事象と根本原因の特定
- [ ] 既存ルールとの重複チェック
- [ ] 保存先の自動判定

## Basic Workflow

### Step 1: 入力解析

**引数あり**の場合（`/learn "具体的な修正内容"`）:
- 引数をそのまま分析対象として使用

**引数なし**の場合（`/learn`）:
- 直近の会話コンテキストをスキャン
- 以下のパターンを検出:
  - ユーザーからの修正指示（「〜じゃなくて〜」「〜してください」）
  - エラー発生とその修正
  - 繰り返し同じ指摘を受けた内容
  - 「今後は〜して」「いつも〜して」等の恒久的指示

### Step 2: ミス分析

1. **何が起きたか**（具体的事象）を特定
   - 例: 「コミットメッセージにCo-Authored-Byを追加してしまった」

2. **なぜ起きたか**（根本原因）を特定
   - 例: 「Claude Codeのデフォルト動作として追加されている」

3. **影響範囲**を特定
   - このプロジェクト固有か？
   - 特定のファイルパターンに限定されるか？
   - チームで共有すべきか？

### Step 3: 汎用化

具体的なミスを抽象的なルールに変換する。

**参照**: [Rule Patterns](./references/rule-patterns.md) で詳細な変換パターンを確認

**基本形式**:
```markdown
## ルールタイトル

{WHY: なぜこのルールが必要か}

{RULE: 具体的な指示（NEVER/ALWAYS/Prefer形式）}

**例**:
- 良い例: {correct example}
- 悪い例: {incorrect example}

<!-- 経緯: {元のミスの要約} -->
```

### Step 4: 既存ルールスキャン

保存前に既存ルールとの重複・矛盾をチェック:

```bash
# グローバルルール
Glob("~/.claude/CLAUDE.md")
Glob("~/.claude/rules/*.md")

# プロジェクトルール
Glob("./CLAUDE.md")
Glob("./.claude/rules/*.md")
Glob("./CLAUDE.local.md")
```

**チェック項目**:
- セマンティック重複（同じ概念の別表現）
- 矛盾（既存ルールと相反する内容）
- 包含関係（既存ルールが新ルールを含む/逆）

### Step 5: 提案 & 承認

AskUserQuestion で以下を確認:

```yaml
AskUserQuestion:
  questions:
    - question: "以下のルールを保存しますか？"
      header: "ルール確認"
      multiSelect: false
      options:
        - label: "はい、保存する"
          description: "{保存先パス}"
        - label: "内容を修正したい"
          description: "ルールの文言を調整"
        - label: "保存先を変更したい"
          description: "別の保存先を選択"
        - label: "保存しない"
          description: "今回は保存せずに終了"
```

**重複検出時の追加選択肢**:
- 「既存ルールとマージ」
- 「既存ルールを置換」
- 「両方を保持」

### Step 6: 保存

承認後、選択された保存先にルールを追加:

- **CLAUDE.md への追記**: Edit ツールで適切なセクションに追加
- **.claude/rules/*.md への追記/新規作成**: Write/Edit ツールで保存
- **YAML frontmatter付きルール**: paths フィールドでスコープを指定

**保存先判定の詳細**: [Storage Guide](./references/storage-guide.md) を参照

## Output Deliverables

保存完了後に以下を表示:

```markdown
## ✅ ルールを保存しました

**保存先**: {file_path}
**ルールタイトル**: {rule_title}

### 保存内容
{saved_rule_content}

---
💡 このルールは今後のセッションで自動的に適用されます。
```

## Rollback / Recovery

**保存を間違えた場合**:

1. ファイルの変更を確認: `git diff {file_path}`
2. 必要に応じて復元: `git checkout {file_path}`
3. または Edit ツールで手動修正

## Advanced References

For detailed rule patterns and storage guidelines, see:
- [Rule Patterns](./references/rule-patterns.md) - ルール生成パターン、METAルール、変換テンプレート
- [Storage Guide](./references/storage-guide.md) - 保存先判定の決定木、各保存先の特徴
