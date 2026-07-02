# Loop Patterns Reference

実行形式（/loop / Workflow）のテンプレート集。
**上位の判定は pattern-catalog.md（6協調パターン）で行い、選択後の落とし込みでこのファイルを使う。**

| 協調パターン | 実行形式の目安 |
|-------------|---------------|
| Retry Loop | Pattern A |
| Plan-Execute-Verify | Pattern B（目標型）or A + interval（定期型） |
| Explore-Narrow | Pattern C（並列探索）or A（小規模逐次） |
| Human-in-the-Loop | Pattern A/B + 承認ステップ（Workflow 内では AskUserQuestion 不可） |
| Orchestrator-Workers | Pattern C |
| Evaluator-Optimiser | Pattern C（generate → judge → 再生成） |

## Pattern A: /loop (繰り返し型)

単一タスクを定期的または連続的に繰り返す。明確な終了条件がないか、外部イベントを待つケース。

### テンプレート

```
/loop [interval] <task_description>
各イテレーションで:
1. <現状を確認するコマンド>
2. <1つの単位を処理>
3. <結果を検証>
4. 成功なら次へ、失敗なら元に戻して別の対象へ

停止条件: <condition> になるか、N回連続で失敗したら停止
出力制限: <大量出力コマンド> は先頭 N 件に限定
同一対象の再選択禁止: 直前に処理した対象を連続で選ばない
```

**interval の省略**: self-paced（連続処理）の場合は interval を書かない。`/loop <prompt>` のみ。

### 具体例: TODO コメント消化

```
/loop このリポジトリの TODO コメントを1つずつ解消してください。
各イテレーションで:
1. grep -r "TODO" --include="*.ts" --include="*.tsx" | head -20 で未解決の TODO を1つ選ぶ
2. 修正を実装
3. テスト実行
4. 成功なら次の TODO へ、失敗なら元に戻して別の TODO へ

停止条件: TODO が0になるか、3回連続で失敗したら停止
出力制限: grep 結果は先頭 20 件に限定
同一対象の再選択禁止: 直前に処理した TODO を連続で選ばない
```

### 使い分けの判断基準

- 処理対象が同質（TODO、lint warning、deprecation 等）
- 1イテレーションが独立している（前のイテレーションの結果に依存しない）
- 完了条件が「全部なくなる」か「時間切れ」

### interval の選び方

| ケース | interval | 理由 |
|--------|----------|------|
| 連続処理（TODO消化等） | なし（self-paced） | 各イテレーションを即座に次へ |
| 外部状態監視（CI, deploy） | 3m-5m | 状態変化の頻度に合わせる |
| 定期チェック（PR監視等） | 10m-30m | 低頻度で十分な監視 |
| 日次・定時（毎朝等） | **/loop 不向き** | セッション常駐が前提のため。cron 系（schedule skill の Cloud Routines / launchd）を使う |

---

## Pattern B: /loop 目標達成型

測定可能なゴールに向かって自律的に進む。完了条件が明確なケース。
Claude Code に `/goal` コマンドは存在しないため、`/loop` に完了条件を組み込む。

### テンプレート

```
/loop <measurable_goal> を達成するまで繰り返す。

各イテレーションで:
1. <測定コマンド> で現状を測定
2. 最も効果的な対象を特定
3. 改善を実装
4. テスト実行で成功確認

完了条件: <success_condition> を達成したら「完了」と宣言して停止
スキップ条件: 同一対象でN回失敗 → スキップして次へ
中間報告: M イテレーションごとに進捗を報告
最大イテレーション: 20回で停止（無限ループ防止）
出力制限: <大量出力コマンド> は先頭 N 件に限定
```

### 具体例: テストカバレッジ向上

```
/loop このリポジトリのテストカバレッジを80%以上にするまで繰り返す。

各イテレーションで:
1. nr test --coverage でカバレッジレポートを生成
2. カバレッジが最も低いファイルを特定
3. テストを追加
4. nr test で成功確認

完了条件: カバレッジ 80% 達成で停止
スキップ条件: 同一ファイルで3回テスト失敗 → スキップして次のファイルへ
中間報告: 5イテレーションごとにカバレッジ推移を表示
最大イテレーション: 20回で停止
```

### 使い分けの判断基準

- 目標が数値化できる（カバレッジ %, エラー数, スコア等）
- 各イテレーションが目標に向かって進む（必ずしも単調でなくてよい）
- 完了条件を自動的に検証できる

### 進捗が非単調な場合の対処

エラー修正で別のエラーが顕在化するケース（shellcheck 等）への対策:
- 「単調改善」ではなく「最終的に目標達成」を完了条件にする
- 一時的な悪化（エラー数増加）を許容する旨をプロンプトに明記
- 進捗停滞の判断は「N回連続で同じエラー数」にする（「改善なし」ではなく）

### Outer Loop 設計のポイント

| 要素 | 推奨値 | 理由 |
|------|--------|------|
| 最大イテレーション | 20 | 無限ループ防止 |
| 同一対象の最大試行 | 3 | 詰まりからの脱出 |
| 中間報告間隔 | 5-10 イテレーション | 人間の認知を維持 |
| 進捗停滞検知 | 3回連続で同じ測定値 | 戦略変更のトリガー |

---

## Pattern C: Workflow (多段検証型)

並列スキャン → 検証 → 統合。多角的な分析や大規模な変換が必要なケース。

**Sonnet 連携の原則**: 全 `agent()` 呼び出しに `model: 'sonnet'` を付ける。Generator（scan/execute）と Evaluator（verify/judge）は別の agent 呼び出しに分離する（maker–checker）。ファイル変更を伴う並列 worker には `isolation: 'worktree'` を付ける。

**実行ランタイム注記**: Workflow スクリプトは Claude Code の Workflow ツールが async コンテキストで実行するため、トップレベルの `await` / `return` が有効。素の Node/ESM として実行・`node --check` すると `Illegal return statement` になるが、それが正常。構文検証したい場合は `export const meta` を `const meta` に変え、全体を `async function wf() { ... }` でラップしてからチェックする。

### テンプレート

テンプレート内には2種類の ALL CAPS がある:
- **文字列リテラル置換** (`'TASK_NAME'`, `'PHASE_1_NAME'` 等): クォート内の文字列をお題に合わせて書き換える
- **JS 変数名** (`RESULT_SCHEMA`, `VERDICT_SCHEMA`, `DIMENSIONS`): そのまま使う（変数定義を書き換える）

生成する JS は有効な構文であること。

```javascript
export const meta = {
  name: 'TASK_NAME',
  description: 'ONE_LINE_DESCRIPTION',
  phases: [
    { title: 'PHASE_1_NAME', detail: 'WHAT_HAPPENS' },
    { title: 'PHASE_2_NAME', detail: 'WHAT_HAPPENS' },
    { title: 'Report', detail: 'Synthesize confirmed findings' },
  ],
}

// --- Observation Cleaning: schemas ---
const RESULT_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          // define per-finding fields here
        },
        required: [],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean' },
    confidence: { type: 'number' },
    reasoning: { type: 'string' },
  },
  required: ['isReal', 'confidence', 'reasoning'],
}

// --- Inner Loop: dimensions ---
const DIMENSIONS = [
  { key: 'dim1', prompt: 'SPECIFIC_TASK_1' },
  { key: 'dim2', prompt: 'SPECIFIC_TASK_2' },
  { key: 'dim3', prompt: 'SPECIFIC_TASK_3' },
]

// --- budget guard（安全弁: 必須。予算設定時、残量不足なら開始しない） ---
if (budget.total && budget.remaining() < 50_000) {
  return { error: 'insufficient token budget', remaining: budget.remaining() }
}

// --- Outer Loop ---
phase('PHASE_1_NAME')
const results = await pipeline(
  DIMENSIONS,
  d => agent(d.prompt, {
    label: `scan:${d.key}`,
    phase: 'PHASE_1_NAME',
    schema: RESULT_SCHEMA,
    model: 'sonnet',
  }),
  (review, dim) => parallel(
    (review?.findings || []).map(f => () =>
      agent(
        `Adversarially verify: ${f.description}. Try to REFUTE it.`,
        {
          label: `verify:${f.file}`,
          phase: 'PHASE_2_NAME',
          schema: VERDICT_SCHEMA,
          model: 'sonnet',
        }
      ).then(v => ({ ...f, verdict: v }))
    )
  ),
)

// --- Hallucination Loop detection: filter nulls ---
const confirmed = results
  .flat()
  .filter(Boolean)
  .filter(f => f.verdict?.isReal && f.verdict?.confidence > 0.7)

// --- Report ---
phase('Report')
const report = await agent(
  `Synthesize ${confirmed.length} confirmed findings into a prioritized report.
  Findings: ${JSON.stringify(confirmed)}`,
  { label: 'report', phase: 'Report', model: 'sonnet' }
)

return { confirmed, report }
```

### budget-gated loop テンプレート（動的スケール）

発見数が未知の場合や、トークン予算に応じてスケールしたい場合:

```javascript
const all = []
let dry = 0
while (budget.total && budget.remaining() > 50_000 && dry < 2) {
  const result = await agent('Find issues not yet in the list...', {
    schema: RESULT_SCHEMA,
    model: 'sonnet',
  })
  const fresh = (result?.findings || []).filter(f => !seen.has(key(f)))
  if (!fresh.length) { dry++; continue }
  dry = 0
  fresh.forEach(f => seen.add(key(f)))
  all.push(...fresh)
  log(`${all.length} found, ${Math.round(budget.remaining() / 1000)}k remaining`)
}
```

### 具体例: セキュリティ監査

```javascript
export const meta = {
  name: 'security-audit',
  description: 'Multi-dimensional security audit with adversarial verification',
  phases: [
    { title: 'Scan', detail: 'Parallel scanners across dimensions' },
    { title: 'Verify', detail: 'Adversarial verification of findings' },
    { title: 'Report', detail: 'Synthesize confirmed findings' },
  ],
}

const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          severity: { enum: ['critical', 'high', 'medium', 'low'] },
          description: { type: 'string' },
          evidence: { type: 'string' },
        },
        required: ['file', 'line', 'severity', 'description', 'evidence'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean' },
    confidence: { type: 'number' },
    reasoning: { type: 'string' },
  },
  required: ['isReal', 'confidence', 'reasoning'],
}

const DIMENSIONS = [
  { key: 'injection', prompt: 'Find SQL injection, command injection, XSS vulnerabilities' },
  { key: 'auth', prompt: 'Find authentication and authorization flaws' },
  { key: 'secrets', prompt: 'Find hardcoded secrets, API keys, tokens' },
]

// budget guard（安全弁: 必須）
if (budget.total && budget.remaining() < 50_000) {
  return { error: 'insufficient token budget', remaining: budget.remaining() }
}

phase('Scan')
const results = await pipeline(
  DIMENSIONS,
  d => agent(d.prompt, {
    label: `scan:${d.key}`,
    phase: 'Scan',
    schema: FINDING_SCHEMA,
    model: 'sonnet',
  }),
  (review, dim) => parallel(
    (review?.findings || []).map(f => () =>
      agent(
        `Adversarially verify this security finding. Try to REFUTE it. Default to refuted=true if uncertain.\n\nFile: ${f.file}:${f.line}\nClaim: ${f.description}\nEvidence: ${f.evidence}`,
        {
          label: `verify:${f.file}:${f.line}`,
          phase: 'Verify',
          schema: VERDICT_SCHEMA,
          model: 'sonnet',
        }
      ).then(v => ({ ...f, verdict: v }))
    )
  ),
)

const confirmed = results
  .flat()
  .filter(Boolean)
  .filter(f => f.verdict?.isReal && f.verdict?.confidence > 0.7)

phase('Report')
const report = await agent(
  `Synthesize ${confirmed.length} confirmed security findings into a prioritized report.
  Findings: ${JSON.stringify(confirmed)}`,
  { label: 'report', phase: 'Report', model: 'sonnet' }
)

return { confirmed, report }
```

### 使い分けの判断基準

- 作業を複数の独立した軸（dimension）に分解できる
- 各軸の結果を検証・統合する必要がある
- 並列実行で大幅に時間短縮できる
- 品質が重要で adversarial verify が必要

### Workflow 構造の選択

| パターン | 使いどころ | 構造 |
|----------|-----------|------|
| pipeline | 各アイテムが独立して全ステージを通過 | `pipeline(items, stage1, stage2)` |
| parallel + barrier | 全結果を集めてから次へ（dedup 等） | `parallel([...]).then(all => ...)` |
| loop-until-dry | 発見数が未知、網羅性重視 | `while (dry < 2) { ... }` |
| loop-until-budget | トークン上限に応じた動的スケール | `while (budget.total && budget.remaining() > 50_000)` |
