---
description: 'Learn from mistakes and save rules: /learn (会話履歴から検出) or /learn "correction" (直接指定)'
argument-hint: [correction]
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Learn Command

会話中のミスや修正を分析し、再発防止のルールを生成・永続化する。

## モード判定

- `$ARGUMENTS` が**空**の場合 → **会話履歴分析モード**
- `$ARGUMENTS` が**ある**場合 → **直接指定モード**

---

## 直接指定モード（引数あり）

`/learn "コミットメッセージにCo-Authored-Byを含めない"` の形式で呼び出された場合:

1. **入力**: `$ARGUMENTS` をそのまま分析対象として使用
2. **処理**: self-learning スキルの Step 2（ミス分析）から開始
3. **出力**: ルール提案 → 承認 → 保存

---

## 会話履歴分析モード（引数なし）

`/learn` の形式で呼び出された場合:

1. **スキャン対象**: 直近の会話コンテキスト
2. **検出パターン**:
   - ユーザーからの修正指示（「〜じゃなくて〜」「〜してください」）
   - エラー発生とその修正
   - 繰り返し同じ指摘を受けた内容
   - 「今後は〜して」「いつも〜して」等の恒久的指示
3. **処理**: self-learning スキルの Step 1（入力解析）から開始
4. **出力**: 検出したミス → ルール提案 → 承認 → 保存

---

## ワークフロー概要

```
[入力]
   │
   ├─ 引数あり: "$ARGUMENTS"
   │
   └─ 引数なし: 会話履歴をスキャン
         │
         ▼
[ミス分析]
   │
   ├─ 何が起きたか（具体的事象）
   └─ なぜ起きたか（根本原因）
         │
         ▼
[汎用化]
   │
   └─ 具体 → 抽象ルールに変換
         │
         ▼
[既存ルールスキャン]
   │
   ├─ 重複検出
   └─ 矛盾検出
         │
         ▼
[提案 & 承認]
   │
   └─ AskUserQuestion で確認
         │
         ▼
[保存]
   │
   └─ 承認された保存先に Write/Edit
```

---

## 詳細は self-learning スキルを参照

このコマンドは `self-learning` スキルのワークフローを実行します。

**参照スキル**: self-learning
- [SKILL.md](~/.claude/skills/self-learning/SKILL.md)
- [Rule Patterns](~/.claude/skills/self-learning/references/rule-patterns.md)
- [Storage Guide](~/.claude/skills/self-learning/references/storage-guide.md)

---

## 使用例

### 直接指定（推奨）

```bash
/learn "コミットメッセージにCo-Authored-Byを含めない"
```

```bash
/learn "CLAUDE.mdの編集にはWriteではなくEditを使う"
```

```bash
/learn "テストファイルは*.test.tsではなく*.spec.tsで命名"
```

### 会話履歴から検出

```bash
/learn
# → 直近の会話からミス・修正パターンを自動検出
```

---

## 注意事項

- **承認必須**: ユーザー承認なしにファイルは変更されません
- **重複検出**: 既存ルールとの重複は自動的に検出・マージ提案されます
- **保存先自動判定**: AIがルールの性質に基づいて最適な保存先を提案します
- **ロールバック可能**: 保存後も `git checkout` で復元可能です
