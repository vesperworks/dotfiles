# Loop Patterns Reference

## Pattern A: /loop (繰り返し型)

単一タスクを定期的または連続的に繰り返す。明確な終了条件がないか、外部イベントを待つケース。

### テンプレート

```
/loop {interval} {task_description}
各イテレーションで:
1. {step_1: 現状を確認}
2. {step_2: 1つの単位を処理}
3. {step_3: 結果を検証}
4. {step_4: 成功なら次へ、失敗なら元に戻して別の対象へ}

停止条件: {condition} になるか、{N}回連続で失敗したら停止
```

### 具体例: TODO コメント消化

```
/loop このリポジトリの TODO コメントを1つずつ解消してください。
各イテレーションで:
1. grep -r "TODO" で未解決の TODO を1つ選ぶ
2. 修正を実装
3. テスト実行
4. 成功なら次の TODO へ、失敗なら元に戻して別の TODO へ

停止条件: TODO が0になるか、3回連続で失敗したら停止
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

---

## Pattern B: /goal (目標達成型)

測定可能なゴールに向かって自律的に進む。完了条件が明確なケース。

### テンプレート

```
/goal {measurable_goal}

Inner Loop:
- {step_1: 現状を測定}
- {step_2: 最も効果的な対象を特定}
- {step_3: 改善を実装}
- {step_4: テスト実行で成功確認}

Outer Loop:
- {success_condition} 達成で完了
- 同一対象で{N}回失敗 → スキップして次へ
- 合計{M}分経過で中間報告

検証: {verification_command} の結果が単調改善していること
```

### 具体例: テストカバレッジ向上

```
/goal このリポジトリのテストカバレッジを80%以上にする

Inner Loop:
- カバレッジレポートを生成
- カバレッジが最も低いファイルを特定
- テストを追加
- テスト実行で成功確認

Outer Loop:
- カバレッジ 80% 達成で完了
- 同一ファイルで3回テスト失敗 → スキップして次のファイルへ
- 合計30分経過で中間報告

検証: nr test --coverage の数値が単調増加していること
```

### 使い分けの判断基準

- 目標が数値化できる（カバレッジ %, エラー数, スコア等）
- 各イテレーションが目標に向かって単調に進む
- 完了条件を自動的に検証できる

### Outer Loop 設計のポイント

| 要素 | 推奨値 | 理由 |
|------|--------|------|
| 最大イテレーション | 20 | 無限ループ防止 |
| 同一対象の最大試行 | 3 | 詰まりからの脱出 |
| 中間報告間隔 | 30分 or 10イテレーション | 人間の認知を維持 |
| 進捗停滞検知 | 3回連続で改善なし | 戦略変更のトリガー |

---

## Pattern C: Workflow (多段検証型)

並列スキャン → 検証 → 統合。多角的な分析や大規模な変換が必要なケース。

### テンプレート

```javascript
export const meta = {
  name: '{task-name}',
  description: '{one-line description}',
  phases: [
    { title: '{phase_1_name}', detail: '{what_happens}' },
    { title: '{phase_2_name}', detail: '{what_happens}' },
    { title: '{phase_3_name}', detail: '{what_happens}' },
  ],
}

// --- Observation Cleaning: schemas ---
const {RESULT_SCHEMA} = {
  type: 'object',
  properties: {
    // define structured output for Inner Loop
  },
  required: [...],
}

const {VERDICT_SCHEMA} = {
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
  { key: '{dim_1}', prompt: '{specific_task_1}' },
  { key: '{dim_2}', prompt: '{specific_task_2}' },
  { key: '{dim_3}', prompt: '{specific_task_3}' },
]

// --- Outer Loop: budget-gated execution ---
phase('{phase_1_name}')
const results = await pipeline(
  DIMENSIONS,
  // Inner Loop: each dimension processed independently
  d => agent(d.prompt, {
    label: `{phase_1}:${d.key}`,
    phase: '{phase_1_name}',
    schema: {RESULT_SCHEMA},
  }),
  // Verification Loop: adversarial verify each finding
  (review, dim) => parallel(
    (review?.{items} || []).map(f => () =>
      agent(
        `Adversarially verify: ${f.description}. Try to REFUTE it.`,
        {
          label: `verify:${f.file}`,
          phase: '{phase_2_name}',
          schema: {VERDICT_SCHEMA},
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
phase('{phase_3_name}')
const report = await agent(
  `Synthesize ${confirmed.length} confirmed findings into a prioritized report.
  Findings: ${JSON.stringify(confirmed)}`,
  { label: 'report', phase: '{phase_3_name}' }
)

return { confirmed, report }
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

phase('Scan')
const results = await pipeline(
  DIMENSIONS,
  d => agent(d.prompt, {
    label: `scan:${d.key}`,
    phase: 'Scan',
    schema: FINDING_SCHEMA,
  }),
  (review, dim) => parallel(
    (review?.findings || []).map(f => () =>
      agent(
        `Adversarially verify this security finding. Try to REFUTE it. Default to refuted=true if uncertain.\n\nFile: ${f.file}:${f.line}\nClaim: ${f.description}\nEvidence: ${f.evidence}`,
        {
          label: `verify:${f.file}:${f.line}`,
          phase: 'Verify',
          schema: VERDICT_SCHEMA,
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
  { label: 'report', phase: 'Report' }
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
| loop-until-budget | トークン上限に応じた動的スケール | `while (budget.remaining() > 50_000)` |
