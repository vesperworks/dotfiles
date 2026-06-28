# Verification Strategies Reference

検証ループ（Verification Loop）の設計パターン集。Inner Loop の出力品質を保証する。

---

## Strategy 1: テスト実行検証

最もシンプルで信頼性の高い検証。コードの正しさを客観的に確認できる。

### 適用条件
- テストスイートが存在する
- 変更がテスト可能（関数、API、コンポーネント等）

### 実装パターン

**In /loop or /goal prompt:**
```
検証:
- `nr test` を実行し、全テストが PASS すること
- 新しいテストを追加した場合、カバレッジが下がっていないこと
- 失敗したら変更を元に戻して次の対象へ
```

**In Workflow pipeline stage:**
```javascript
(result) => agent(
  `Run "nr test" and verify all tests pass. If any test fails, report the failure.`,
  { schema: TEST_RESULT_SCHEMA }
)
```

### TEST_RESULT_SCHEMA
```javascript
const TEST_RESULT_SCHEMA = {
  type: 'object',
  properties: {
    passed: { type: 'boolean' },
    totalTests: { type: 'number' },
    failedTests: { type: 'number' },
    failures: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          testName: { type: 'string' },
          error: { type: 'string' },
        },
        required: ['testName', 'error'],
      },
    },
  },
  required: ['passed', 'totalTests', 'failedTests'],
}
```

---

## Strategy 2: Adversarial Verify（反証検証）

発見型タスク（バグ検出、セキュリティ監査）で最も効果的。偽陽性を除去する。

### 適用条件
- 発見内容が「本物かどうか」の判定が必要
- 偽陽性のコストが高い（修正工数が無駄になる）

### 実装パターン

**Single vote（簡易）:**
```javascript
const verdict = await agent(
  `Adversarially verify this finding. Try to REFUTE it.
  Default to refuted=true if uncertain.
  
  Claim: ${finding.description}
  Evidence: ${finding.evidence}`,
  { schema: VERDICT_SCHEMA }
)
const isReal = verdict?.isReal === true
```

**Multi-vote（厳格）:**
```javascript
const votes = await parallel(
  Array.from({ length: 3 }, () => () =>
    agent(
      `Try to refute: ${claim}. Default to refuted=true if uncertain.`,
      { schema: VERDICT_SCHEMA }
    )
  )
)
const survives = votes.filter(Boolean).filter(v => !v.refuted).length >= 2
```

**Perspective-diverse（多角的）:**
```javascript
const LENSES = ['correctness', 'security', 'performance', 'reproducibility']
const votes = await parallel(
  LENSES.map(lens => () =>
    agent(
      `Judge "${finding.desc}" via the ${lens} lens — is this real?`,
      { schema: VERDICT_SCHEMA }
    )
  )
)
const survives = votes.filter(Boolean).filter(v => v.isReal).length >= 2
```

### VERDICT_SCHEMA
```javascript
const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    isReal: { type: 'boolean' },
    confidence: { type: 'number' },
    reasoning: { type: 'string' },
  },
  required: ['isReal', 'confidence', 'reasoning'],
}
```

### 投票数の目安

| タスク重要度 | 投票数 | 合格ライン |
|-------------|--------|-----------|
| 低（情報収集） | 1 | isReal === true |
| 中（コードレビュー） | 3 | 過半数が isReal |
| 高（セキュリティ監査） | 3-5 + perspective-diverse | 過半数 + confidence > 0.7 |

---

## Strategy 3: Lint/Format 検証

静的解析による機械的な品質チェック。コードスタイルと基本的な問題を検出。

### 適用条件
- コードの変更を含むタスク
- プロジェクトに lint/format ツールが設定済み

### 実装パターン

**In /loop or /goal prompt:**
```
検証:
- `nr check` を実行し、lint/format エラーが 0 であること
- エラーがあれば `nr check:fix` で自動修正を試みる
- 自動修正できないエラーは手動対応として報告
```

**In Workflow:**
```javascript
(result) => agent(
  `Run "nr check" to verify lint and format compliance. 
  If errors found, run "nr check:fix" and report remaining issues.`,
  { schema: LINT_RESULT_SCHEMA }
)
```

---

## Strategy 4: 人間レビュー検証

破壊的操作や重要な判断を含むループで使用。人間を Verification Loop に組み込む。

### 適用条件
- ループが git push / merge / deploy を含む
- 判断基準が定量化しにくい（UX、文章品質等）
- 信頼性を最大限に高めたい

### 実装パターン

**In /loop or /goal prompt:**
```
各イテレーション完了後:
- 変更内容のサマリーを表示
- 「続行しますか？」と確認
- NO の場合は変更を元に戻して停止
```

**In Workflow (AskUserQuestion is not available in Workflow agents):**
Human-review checkpoints cannot be embedded inside Workflow scripts.
Instead, design the Workflow to produce a report, then have the main loop
present it to the user for approval before taking action.

---

## 組み合わせガイド

複数の検証戦略を組み合わせることで、品質を段階的に高められる。

### 推奨の組み合わせ

| タスク種別 | 1st検証 | 2nd検証 | 3rd検証 |
|-----------|---------|---------|---------|
| バグ修正 | テスト実行 | lint/format | — |
| 新機能追加 | テスト実行 | lint/format | 人間レビュー |
| セキュリティ監査 | adversarial verify (3票) | — | 人間レビュー |
| リファクタリング | テスト実行 | lint/format | adversarial verify |
| コンテンツ生成 | LLM judge | — | 人間レビュー |

### パイプラインでの配置

```
Inner Loop → [1st検証: 高速フィルタ] → [2nd検証: 精密チェック] → [3rd検証: 最終承認]
```

早い段階で明らかな問題を弾き、後段ほど精密な検証を行う。コストの安い検証を先に配置する。
