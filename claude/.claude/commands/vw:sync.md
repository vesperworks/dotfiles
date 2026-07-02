---
name: sync
description: boot（PRP・wip・会話履歴からTaskListを復元）+ harvest（作業ログ・教訓の刈り取り、MEMORY.mdポインタ更新）の2フェーズでセッションのコンテキストを管理する
argument-hint: [boot|harvest]
allowed-tools: Read, Edit, Write, Glob, Bash(jj log:*), Bash(git log:*), Bash(search-sessions:*), Bash(date:*), Bash(trash:*), TaskCreate, TaskList, TaskGet, TaskUpdate, AskUserQuestion
---

# Session Boot + Harvest

## Core Purpose

セッション開始時に PRP・wip・会話履歴から文脈を復元し（**boot**）、セッション区切りで今回の作業を該当先に刈り取る（**harvest**）。MEMORY.md は「1行ポインタのインデックス」に徹し、タスク台帳や完了 changelog にはしない。

## 記憶の3レーン

| レーン | 実体 | ライフサイクル |
|---|---|---|
| Lessons（教訓） | `memory/` 配下の個別ファイル（1ファイル1教訓、frontmatter の description = 1行サマリー） | 恒久。重複は既存更新、誤りは trash で削除 |
| 作業ログ | PRP がある作業 → PRP 内の進捗テーブルが正。PRP 外の浮遊作業 → `wip-<topic>.md`（先頭に現在地、下に時系列ログ） | 完了したら刈り取り（git log / PRP done/ に委譲して trash） |
| インデックス | MEMORY.md（1行ポインタのみ） | 常時最新。残タスク詳細・完了 changelog は持たない |

## Quick Checklist（初期応答で必ず確認）

- [ ] フェーズ判定（下記）に従い boot / harvest を確定する
- [ ] MEMORY.md / wip-*.md のパスを特定（`~/.claude/projects/{project-slug}/memory/`）
- [ ] PRP パス（`.brain/*/prp/`）を特定する
- [ ] 現在の TaskList 状態を取得する

## フェーズ判定

```text
1. 引数優先: `/vw:sync boot` / `/vw:sync harvest` と明示されたら常にそれに従い、以下は行わない
2. 無引数の場合はマーカーファイルで判定:
   マーカー: ~/.claude/projects/{project-slug}/memory/.sync-last（epoch 秒1行のみ）
   Read で読み、Bash: date +%s の現在時刻との差を計算
   マーカーが存在しない、または差が 21600 秒（6時間）超 → boot
   差が 21600 秒以内 → harvest
3. 矛盾時の確認: タイムスタンプ判定が会話の実態と明らかに矛盾する場合
   （例: harvest 判定だがこのセッションでまだ何も作業していない）は
   AskUserQuestion で1回確認する
4. マーカー更新: boot / harvest どちらのフェーズが完了した際にも、
   Bash: date +%s の値を Write で .sync-last に上書きする
   （.sync-last は内部状態のドットファイルであり、MEMORY.md のポインタには載せない）
```

---

## Phase 1: boot（セッション開始時のコンテキスト復元）

**boot では MEMORY.md への書き込みを一切行わない（読むだけ）。** 目的は外部ソースから TaskList を復元することに限定する。

### 1-A: PRP スキャン

```text
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

### 1-B: 会話履歴の読み取り（VCS ログ → search-sessions）

```text
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
```

### 1-C: wip-*.md スキャン（PRP 外の浮遊作業ログ）

```text
WIP パス: ~/.claude/projects/{project-slug}/memory/wip-*.md
→ Glob で検出し、各ファイルの概要（先頭の現在地）を把握
→ wip-*.md は PRP に紐付かない浮遊作業のためのログ。
  作成条件: PRP 化するほどではない単発作業が発生した時
  刈り取り条件: 作業が完了しコミット済みになった時（harvest で trash）
```

### TaskList 復元

PRP の未完了タスク・wip-*.md の現在地・会話履歴由来の候補から TaskList を復元する。方向は **外部ソース → TaskList の一方向**（TaskList → Memory への反映は boot では行わない）。

```text
1. TaskList / TaskGet で既存タスクを取得（重複生成を避けるため）
2. アクティブ PRP の未完了タスクで TaskList にないもの → TaskCreate（PRP リンク付き）
3. wip-*.md の現在地で TaskList にないもの → TaskCreate
4. 会話履歴（search-sessions）から拾った未完了指示 → 自動生成せず、
   AskUserQuestion で「タスク化しますか？」と確認してから TaskCreate
5. PRP の Phase 進捗と TaskList の状態に矛盾があれば、上書きせず
   AskUserQuestion で正を確認する（下記 yaml 参照）
```

```yaml
AskUserQuestion:
  questions:
    - question: "PRP の進捗と TaskList が一致しません。どちらを正としますか？"
      header: "Conflict"
      options:
        - label: "PRP を正とする"
          description: "PRP の進捗テーブルで TaskList を更新"
        - label: "TaskList を正とする"
          description: "TaskList の状態を優先し PRP 側は次の harvest で追記"
        - label: "個別に確認"
          description: "1件ずつ判断する"
```

### Boot Report

```markdown
## Boot Report

### PRP 状態サマリー
| PRP | タイトル | 状態 | 進捗 |
|-----|---------|------|------|
| PRP-NNN | {title} | アクティブ/完了/保留 | {Phase X/Y 完了} |

### 直近の会話
- **スレッド {uuid先頭8文字}**（{date}）: {summary}

### WIP メモ
- {filename}: {現在地の概要}

### TaskList 復元
- [TaskID] {subject} ← PRP-{NNN} / wip-{topic}.md / 会話履歴（要確認）

### Summary
- Tasks created: N
- Conversation insights (要確認): N
```

---

## Phase 2: harvest（セッション区切り/任意実行時の刈り取り）

### 2-A: 作業ログへの追記

```text
IF PRP に紐付く作業が進展/完了:
  → 該当 PRP の進捗テーブルを Edit で更新（MEMORY.md は更新しない）

IF PRP 外の浮遊作業が進展:
  → wip-<topic>.md の先頭「現在地」を更新し、下の時系列ログに追記
  → 新規の浮遊作業なら wip-<topic>.md を新規作成

IF 前回 harvest 以降に進捗テーブル/wip-*.md が既に最新（変化なし）:
  → 追記をスキップする
```

### 2-B: wip-*.md の刈り取り

```text
IF wip-<topic>.md の作業が完了しコミット済み:
  → 刈り取り（削除）を提案
  → AskUserQuestion で確認
  → 承認されたら Bash(trash) で削除（rm は使わない）
```

### 2-C: 教訓（lesson）の検出・保存

会話中のユーザーによる修正（corrections）や確認済みアプローチ（confirmed approaches）を検出したら、lesson ファイルの新規作成 or 既存更新を提案する。

#### 保存判定基準（必須）

- **1ファイル1教訓**、先頭（frontmatter の description）に1行サマリーを置く
- 修正（corrections）・確認済みアプローチ（confirmed approaches）の両方を対象とし、**「なぜ重要か」を必ず含めて**記録する
- repo（git log / コード / PRP done/）やチャット履歴に**既に記録済みの事実は保存しない**
- 新規作成より**既存ノートの更新を優先**する（重複を作らない）
- **誤りと判明したノートは trash で削除**する
- 前回 harvest 以降に**同一の教訓が既に保存済み**なら、新規作成・更新ともにスキップする

### 2-D: MEMORY.md ポインタ更新

MEMORY.md への操作は**ポインタ（1行）の追加・更新・削除のみ**。残タスクの詳細や完了 changelog は書き込まない。

```text
IF lesson ファイルを新規作成/更新した:
  → MEMORY.md に1行ポインタを追加・更新（例: "- [タイトル](file.md) — 1行要約"）

IF wip-*.md を刈り取った:
  → MEMORY.md 側の対応ポインタがあれば削除

IF 対応するポインタが既に最新（追加・更新・削除の対象がない）:
  → 何もしない
```

### 2-E: PRP done/ 移動提案

```text
IF アクティブ PRP の Success Criteria が 80% 以上チェック済み:
  → done/ への移動を提案（AskUserQuestion で確認）
```

### Harvest Report

```markdown
## Harvest Report

### 作業ログ更新
- PRP-{NNN} 進捗テーブル ← Phase {N} 完了反映
- wip-{topic}.md ← 現在地更新 / 新規作成

### wip 刈り取り
- wip-{topic}.md（完了・コミット済み）→ trash 提案

### 教訓（lesson）
- 新規: {file}.md — {1行サマリー}（why: {理由}）
- 更新: {file}.md
- 保存見送り: {理由}（repo/履歴に既に記録済み 等）

### MEMORY.md ポインタ
- 追加: {pointer}
- 削除: {pointer}

### Summary
- PRP updated: N / wip pruned: N / lessons saved: N / pointers changed: N
```

---

## Rollback / Recovery

- PRP・wip-*.md・MEMORY.md の更新は Edit ツールで行うため、`jj diff` で差分確認可能
- TaskList の変更は TaskUpdate で status を戻せる
- trash した wip-*.md / lesson ファイルは macOS ゴミ箱から復元可能
- 問題発生時: `jj diff` で変更を確認 → `jj restore` で復元

## Guidelines

### 冪等性
- 同じ状態で複数回 harvest を実行しても結果が変わらないこと
- 既に反映済みの進捗・ポインタは再処理しない
- 会話履歴からの提案は、既に TaskList / lesson に存在する場合はスキップ

### 最小変更
- 必要なセクションのみ更新（ファイル全体の書き換えを避ける）
- Edit ツールで差分のみ適用

### 透明性
- Boot Report / Harvest Report で全変更を可視化
- サイレント変更・サイレント削除はしない
- 会話履歴のスレッド UUID 先頭8文字を表示し、正しいスレッドか確認可能にする

### パフォーマンス
- PRP は Glob でファイル一覧 → アクティブ PRP のみ Read（done/cancel/tbd はファイル名のみ）
- 会話履歴は `search-sessions` CLI 経由（JSONL 直接読み取りは権限問題があるため避ける）
- `search-sessions` のインデックス検索は ~18ms、ディープ検索は ~280ms で十分高速
