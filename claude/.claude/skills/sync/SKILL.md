---
name: sync
description: Sync Claude Memory and TaskList. Completed tasks are reflected into MEMORY.md, and memory state generates new tasks. Use when synchronizing project progress between auto-memory and task tracking, or when /sync is invoked. NOT for project-wide PRP analysis (use vw:task) and NOT for session continuity (use continuity-ledger).
---

# Memory ↔ TaskList Sync

## Core Purpose

Claude の auto-memory（MEMORY.md）と TaskList（TaskCreate/TaskList/TaskUpdate）間の整合性を保つ。完了タスクをメモリーに反映し、メモリーの残項目から新規タスクを生成する自動同期スキル。

## Quick Checklist (初期応答で必ず確認)

- [ ] MEMORY.md のパスを特定（プロジェクト別 memory ディレクトリ）
- [ ] 現在の TaskList 状態を取得
- [ ] MEMORY.md の現在の内容を読み取り

## Basic Workflow

### Step 1: 現状収集（並列実行）

以下を**同時に**実行する：

1. **TaskList を取得** → 全タスクの status/subject/owner を収集
2. **MEMORY.md を読み取り** → 現在のセクション構造と内容を把握
3. **wip-*.md ファイルを確認** → WIP メモの有無

```
Memory パス: ~/.claude/projects/{project-slug}/memory/MEMORY.md
WIP パス:    ~/.claude/projects/{project-slug}/memory/wip-*.md
```

### Step 2: 差分検出

以下の3カテゴリで差分を分析：

#### A. Task → Memory 反映（完了タスク）

```
IF task.status == "completed":
  → MEMORY.md の該当セクションに反映
  → Phase 進捗テーブルの更新
  → 「直近の変更メモ」セクションへ追記
```

#### B. Memory → Task 生成（未タスク化の残項目）

```
IF memory に残タスクが記載されているが TaskList に対応タスクがない:
  → TaskCreate で新規タスク生成
  → description に MEMORY.md の該当項目をリンク
```

#### C. 不整合の検出

```
IF memory の状態と task の状態が矛盾:
  → コンフリクトとしてユーザーに報告
  例: Memory では「完了」だが Task は「pending」
```

### Step 3: 自動同期の実行

差分に基づいて以下を**自動実行**（コンフリクト時のみユーザー確認）：

1. **MEMORY.md 更新**: Edit ツールで該当セクションを更新
2. **TaskList 更新**: TaskCreate / TaskUpdate で反映
3. **wip-*.md の整理**: 完了した WIP メモがあれば MEMORY.md に統合提案

### Step 4: 同期レポート出力

```markdown
## 🔄 Sync Report

### Memory → Task（新規タスク生成）
- [TaskID] {subject} ← MEMORY.md#{section}

### Task → Memory（メモリー更新）
- MEMORY.md#進捗 ← [TaskID] {subject} (completed)

### Conflicts（要確認）
- ⚠️ {description of conflict}

### Summary
- Tasks created: N
- Memory sections updated: N
- Conflicts: N
```

## Sync Rules

### メモリー更新ルール

| MEMORY.md セクション | 更新トリガー |
|---------------------|-------------|
| プロジェクト進捗（Phase 管理） | Phase に関連するタスク完了時 |
| 残タスク | タスク完了/新規作成時 |
| 直近の変更メモ | 任意のタスク完了時（最新5件を保持） |
| VCS 注意事項 | VCS 関連の学びがあった時 |
| 完了済みパッケージ | パッケージ関連タスク完了時 |

### タスク生成ルール

| 条件 | アクション |
|------|----------|
| MEMORY.md に `未着手` の Phase がある | Phase 開始用タスクを生成 |
| 残タスクに Issue 番号の記載あり | Issue リンク付きタスクを生成 |
| `次` マークのある項目 | 優先タスクとして生成 |

### コンフリクト解決

コンフリクト検出時は AskUserQuestion で確認：

```yaml
AskUserQuestion:
  questions:
    - question: "Memory と TaskList で不整合があります。どちらを正としますか？"
      header: "Conflict"
      options:
        - label: "TaskList を正とする"
          description: "TaskList の状態で Memory を上書き"
        - label: "Memory を正とする"
          description: "Memory の状態で TaskList を更新"
        - label: "個別に確認"
          description: "1件ずつ判断する"
```

## Rollback / Recovery

- MEMORY.md の更新は Edit ツールで行うため、git diff で差分確認可能
- TaskList の変更は TaskUpdate で status を戻せる
- 問題発生時: `jj diff` で MEMORY.md の変更を確認 → `jj restore` で復元

## Guidelines

### 冪等性
- 同じ状態で複数回実行しても結果が変わらないこと
- 既に同期済みの項目は再処理しない

### 最小変更
- 必要なセクションのみ更新（ファイル全体の書き換えを避ける）
- Edit ツールで差分のみ適用

### 透明性
- 同期レポートで全変更を可視化
- サイレント変更はしない
