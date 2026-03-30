---
name: sync
description: Memory↔TaskList同期 + PRP・会話履歴からのコンテキスト把握
allowed-tools: Read, Edit, Write, Glob, Bash(ls -lt:*), Bash(tail:*), TaskCreate, TaskList, TaskGet, TaskUpdate, AskUserQuestion
---

# Memory ↔ TaskList Sync + Context Discovery

## Core Purpose

Claude の auto-memory（MEMORY.md）と TaskList 間の整合性を保ちつつ、PRP の進捗状況と直近の会話履歴から「プロジェクトの流れ」を把握する。セッション開始時に実行することで、前回の作業文脈を素早く復元する。

## Quick Checklist (初期応答で必ず確認)

- [ ] MEMORY.md のパスを特定（プロジェクト別 memory ディレクトリ）
- [ ] プロジェクトスラッグを特定（MEMORY.md パスから逆算）
- [ ] 現在の TaskList 状態を取得
- [ ] MEMORY.md の現在の内容を読み取り

## Basic Workflow

### Step 0: Context Discovery（並列実行）

同期の前に、プロジェクトの「流れ」を把握する。以下を**同時に**実行する：

#### 0-A: PRP スキャン

```
PRP パス: .brain/*/prp/

1. Glob(".brain/*/prp/*.md") → アクティブ PRP 一覧
2. Glob(".brain/*/prp/done/*.md") → 完了 PRP（ファイル名のみ）
3. Glob(".brain/*/prp/cancel/*.md") → キャンセル PRP（ファイル名のみ）
4. Glob(".brain/*/prp/tbd/*.md") → 保留 PRP（ファイル名のみ）
5. アクティブ PRP のみ Read で全文読み取り
   → メタデータ（PRP番号、更新日）を抽出
   → 進捗状況テーブルを抽出
   → Success Criteria のチェック状況を集計
```

#### 0-B: 会話履歴の読み取り（VCS ログ → search-sessions）

```
VCS コミットログからキーワードを抽出し、search-sessions で関連セッションを検索する。
（search-sessions はクエリ必須のため、コミットログから逆算する）

1. 直近コミットからキーワード抽出:
   jj の場合: jj log -r 'ancestors(main, 5)' --no-graph -T 'description ++ "\n"'
   git の場合: git log --oneline -5

2. コミットメッセージから scope / キーワードを抽出:
   例: "feat(tmux): add git status" → "tmux", "git status"
   例: "fix(zsh): suppress sheldon" → "zsh", "sheldon"

3. 各キーワードで search-sessions 実行（並列可）:
   Bash: search-sessions "<keyword>" --since "3 days ago" --limit 3
   ヒットしない場合: search-sessions "<keyword>" --deep --limit 3

4. 結果から以下を抽出:
   - セッション日時
   - サマリー / 最初のプロンプト
   - セッション ID（resume 用）

5. MEMORY.md の残タスクに関連するセッションがあれば紐付け
```

#### 0-C: wip-*.md スキャン

```
WIP パス: ~/.claude/projects/{project-slug}/memory/wip-*.md
→ Glob で検出し、各ファイルの概要を把握
```

### Step 1: 現状収集（並列実行）

以下を**同時に**実行する：

1. **TaskList を取得** → 全タスクの status/subject/owner を収集
2. **MEMORY.md を読み取り** → 現在のセクション構造と内容を把握

```
Memory パス: ~/.claude/projects/{project-slug}/memory/MEMORY.md
```

### Step 2: 差分検出

以下の5カテゴリで差分を分析：

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

#### D. PRP ↔ Memory/Task 照合

```
IF アクティブ PRP の Phase 進捗と MEMORY.md の Phase テーブルに差異:
  → Memory 更新候補として記録

IF アクティブ PRP 内の未完了タスクで TaskList にエントリがない:
  → Task 生成候補として記録

IF 完了候補の PRP（Success Criteria 80%以上チェック済み）:
  → done/ への移動を提案
```

#### E. 会話履歴からの洞察（search-sessions）

```
search-sessions の結果から以下を抽出:
- 直近セッションのサマリー: 何をしていたか
- MEMORY.md の残タスクに関連するセッション: 進捗の手がかり
- 必要に応じてキーワード検索で深掘り（--deep）

→ 残タスク候補として Memory/TaskList と照合
→ **提案のみ**（自動タスク生成はしない → AskUserQuestion で確認）
```

### Step 3: 自動同期の実行

差分に基づいて以下を**自動実行**（コンフリクト時・会話履歴由来はユーザー確認）：

1. **MEMORY.md 更新**: Edit ツールで該当セクションを更新
2. **TaskList 更新**: TaskCreate / TaskUpdate で反映
3. **wip-*.md の整理**: 完了した WIP メモがあれば MEMORY.md に統合提案

### Step 4: 同期レポート出力

```markdown
## Sync Report

### Context Overview

#### PRP 状態サマリー
| PRP | タイトル | 状態 | 進捗 |
|-----|---------|------|------|
| PRP-NNN | {title} | アクティブ/完了/保留 | {Phase X/Y 完了} |

#### 直近の会話
- **スレッド {uuid先頭8文字}**（{date}）:
  - User: 「{content-snippet}」
  - Assistant: {content-snippet}
- **スレッド {uuid先頭8文字}**（{date}）:
  - User: 「{content-snippet}」
  - Assistant: {content-snippet}

#### WIP メモ
- {filename}: {概要}

---

### Memory → Task（新規タスク生成）
- [TaskID] {subject} ← MEMORY.md#{section}

### Task → Memory（メモリー更新）
- MEMORY.md#進捗 ← [TaskID] {subject} (completed)

### PRP → Task/Memory（PRP 由来の同期）
- [TaskID] {subject} ← PRP-{NNN}#{task}
- MEMORY.md#Phase管理 ← PRP-{NNN} Phase {N} 完了反映

### 会話履歴 → 提案（未完了指示の検出）
- 「{content-snippet}」← スレッド {id}（要確認）

### Conflicts（要確認）
- {description of conflict}

### Summary
- Tasks created: N
- Memory sections updated: N
- PRP-derived actions: N
- Conversation insights: N
- Conflicts: N
```

## Sync Rules

### メモリー更新ルール

| MEMORY.md セクション | 更新トリガー |
|---------------------|-------------|
| プロジェクト進捗（Phase 管理） | Phase に関連するタスク完了時 / PRP Phase 照合時 |
| 残タスク | タスク完了/新規作成時 / 会話履歴から未完了指示検出時 |
| 直近の変更メモ | 任意のタスク完了時（最新5件を保持） |
| VCS 注意事項 | VCS 関連の学びがあった時 |
| 完了済みパッケージ | パッケージ関連タスク完了時 |

### タスク生成ルール

| 条件 | アクション |
|------|----------|
| MEMORY.md に `未着手` の Phase がある | Phase 開始用タスクを生成 |
| 残タスクに Issue 番号の記載あり | Issue リンク付きタスクを生成 |
| `次` マークのある項目 | 優先タスクとして生成 |
| PRP 内の未完了タスクが TaskList にない | PRP リンク付きタスクを生成 |
| 会話履歴に未完了指示がある | **提案のみ**（AskUserQuestion で確認後に生成） |

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
- 会話履歴からの提案は、既に TaskList に存在する場合はスキップ

### 最小変更
- 必要なセクションのみ更新（ファイル全体の書き換えを避ける）
- Edit ツールで差分のみ適用

### 透明性
- 同期レポートで全変更を可視化
- サイレント変更はしない
- 会話履歴のスレッド UUID 先頭8文字を表示し、正しいスレッドか確認可能にする

### パフォーマンス
- PRP は Glob でファイル一覧 → アクティブ PRP のみ Read（done/cancel/tbd はファイル名のみ）
- 会話履歴は `search-sessions` CLI 経由（JSONL 直接読み取りは権限問題があるため避ける）
- `search-sessions` のインデックス検索は ~18ms、ディープ検索は ~280ms で十分高速
