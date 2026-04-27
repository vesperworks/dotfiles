# フェーズ 5: Sprint Planning & Review

スプリントレビュー（先週の Done 整理）と次スプリント計画（今週の枠組み）を担う対話モード。
コミット/PR 履歴から「Done 未マークだが完了済みの Issue」を推測してサジェストし、ユーザー別 tree で表示してから一括反映する。

## 重要な前提

| 項目 | 必須 |
|------|------|
| Project V2 に **Sprint**（Iteration Field）が存在 | ✅ |
| Project V2 に **Status**（SingleSelect: Backlog/Todo/In Progress/Done など）が存在 | ✅ |
| 対象 Issue が Project に追加されている | ✅ |
| `gh auth status` 成功 + project スコープあり | ✅ |

不足している場合は **SETUP.md フェーズに戻る**ことを案内する。

## モード分岐

ユーザー入力から判定:

| 入力例 | モード |
|--------|--------|
| 「先週のレビュー」「Sprint Review」「Done つけてないやつ」 | **A: Review（先週分のクローズ）** |
| 「次のスプリント計画」「今週何やる」「Sprint Planning」 | **B: Plan（今週分の割当）** |
| 「スプリントプランニング」のみ | **両方**（A → B の順で実行） |

判別が曖昧な場合は AskUserQuestion で確認する。

---

## モード A: Sprint Review — 先週分のクローズ整理

### A.1: データ収集

`pm-sprint-review.sh` を実行して JSON を取得。

```bash
${CLAUDE_SKILL_DIR}/scripts/pm-sprint-review.sh \
  --project <N> --owner <login> [--sprint "<title>"]
```

**Sprint 未指定なら直前の完了 Sprint が自動選択される。** 出力 JSON は以下を含む:

- `sprint`: 対象 Sprint のメタデータ（title/startDate/duration/id）
- `period.since` / `period.until`: コミット/PR 検索期間
- `commits`: 期間内の git log（`%h %an %ad %f` JSON 配列）
- `prs`: 期間内のマージ済 PR（`closes` 配列に Issue 参照番号を抽出済み）
- `projectItems`: Sprint に紐づく Project Item 一覧（status/state/assignees/issueType）
- `doneCandidates`: 自動検出した Done 候補（reason: `close-ref` / `commit-ref`）

### A.2: 担当者別 tree レンダリング

LLM が JSON を読み、**担当者ごとに tree** を組み立てて表示する。テンプレート:

```
## 📅 Sprint Review: <title>（<since>〜<until>）

### 👤 <author>（<git-author>）— <N> commits / <M> PR merged

🌳 <Feature 名 or 推定カテゴリ>
│
├─ ✅ #<num> [<type>] <title>  [Status / state]
│   ├─ ✅ <commit/PR ref>
│   └─ ...
│
├─ 🟡 #<num> [<type>] <title>  ← Done 候補（理由: close-ref PR #M）
│
└─ ⏸ #<num> [<type>] <title>  ← 動かなかった（コミット参照なし）
```

**マークの使い分け:**

| 記号 | 意味 |
|------|------|
| ✅ | 既に Done/Closed 済み（または明確に完了） |
| 🟡 | Done 候補（doneCandidates にあり、ユーザー確認待ち） |
| ⏸ | 進捗なし（次スプリント繰越し or Done で整理する候補） |
| 🚫 | 中止 / スコープ外（メモリ参照で判定） |

### A.3: ユーザー確認

AskUserQuestion で2点確認する:

1. Done 候補（🟡）を一括で Status=Done + Issue Close するか、個別選択するか
2. 進捗なし（⏸）をどう扱うか（次スプリント繰越し / Done 整理 / そのまま放置）

### A.4: 一括反映

- **Issue Close + Status=Done**: 各 Issue の Project Item ID を取得して以下を実行
  - `pm-project-fields.sh <num> --project <N> --owner <login> --status Done`
  - `gh issue close <num> --reason completed -c "<comment>"`
- **Sprint 紐付け**: Iteration Field を当該 Sprint に揃える
  - `pm-project-fields.sh <num> --project <N> --owner <login> --iteration "<sprint title>"`

複数件は **インライン直書きせず**、Write ツールで `/tmp/claude/run_*.sh` を作成して `bash` 実行する。

### A.5: 結果サマリー

```
## ✅ Sprint Review 完了

| カテゴリ | 件数 |
|---------|------|
| Done 候補 → Closed | N件 |
| 繰越し → 次 Sprint | M件 |
| 整理（Done 化） | K件 |
```

---

## モード B: Sprint Planning — 今週分の割当

### B.1: データ収集

`pm-sprint-plan.sh` を実行:

```bash
${CLAUDE_SKILL_DIR}/scripts/pm-sprint-plan.sh \
  --project <N> --owner <login> [--sprint "<title>"]
```

**Sprint 未指定なら現在の Iteration が自動選択される。** 出力 JSON:

- `currentSprint` / `previousSprint`: 対象/直前 Sprint メタ
- `sprintFieldId`: Sprint Field の GraphQL ID
- `carryover`: In Progress 状態のもの（前 Sprint からの継続候補）
- `backlog`: Status=Todo/Backlog/null かつ現 Sprint 未割当
- `byAssignee`: 担当者別グルーピング

### B.2: 担当者別の枠表示

```
## 📅 Sprint Plan: <title>（<startDate>〜+<duration>日）

### 👤 <login>
**繰越し In Progress**: N件
- ⏳ #<num> [<type>] <title>

**Backlog 候補**: M件
- 🆕 #<num> [<type>] <title>  Priority=<value>
- 🆕 ...
```

未割当（`_unassigned`）の Issue は別カテゴリで表示。

### B.3: 割当案を提示・確認

5日 Sprint に詰めすぎない粒度（**Task 5〜8件 / 担当者** が目安）で割当案を出し、AskUserQuestion で確認:

1. 提案通り Sprint 割当
2. スコープを絞る（Task を半分に）
3. 個別調整したい

### B.4: 一括反映

`pm-project-fields.sh --bulk` 用の JSON を作成して実行。

```json
[
  {"issue": 535, "iteration": "Sprint 17", "status": "Todo"},
  {"issue": 536, "iteration": "Sprint 17", "status": "Todo"}
]
```

```bash
${CLAUDE_SKILL_DIR}/scripts/pm-project-fields.sh --bulk /tmp/claude/sprint17_plan.json \
  --project <N> --owner <login>
```

### B.5: 結果サマリー

```
## ✅ Sprint Plan 完了

Sprint <title> に **N件** 割当（繰越し X件 + 新規 Y件）

担当者別:
- <user1>: N件
- <user2>: M件
```

---

## ヒントと注意

### 推測の質を上げるためのフォールバック

- PR/コミットに `closes #N` が無い場合は、**LLM 側でファイル名/branch 名/タイトルから類推**してユーザーに確認する（自動 Done 化はしない）
- メモリ（`feedback_*.md` / `project_*.md`）に「凍結」「中止」記録があれば 🚫 でマーク
- PRP（`.brain/PRPs/active/*.md`）が動いている場合、Issue 化されていない作業を「PRP 内タスク」として別枠表示

### 破壊的アクションの確認

| アクション | 事前確認 |
|-----------|---------|
| Issue Close（複数件） | ✅ 必ず AskUserQuestion |
| Status=Done への一括変更 | ✅ 必ず AskUserQuestion |
| Sprint 紐付け変更 | 1〜2件なら省略可、5件以上は確認 |

### スクリプト失敗時のフォールバック

- `gh project item-list` の `--limit` は最大 100。それ以上は GraphQL でページング（pm-sprint-plan.sh で実装済）
- `gh project item-add` で既に追加済みのアイテムを足しても 200 OK で重複追加されない（item-id は同じ）
- 認証エラー時は `gh auth refresh -s project` を案内

### 言い換え/タイトルポリシー

ユーザーが「○○って言わなくていい」「△△に言い換えて」と指示した場合は、提示中の Issue タイトルや本文をその語彙に揃えてから起票する。提示後の小修正は対話で受け付ける。
