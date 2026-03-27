---
name: prp-generation
description: "Generate Project Requirement Prompts (PRPs) with multi-approach design evaluation. Use when the user needs to define requirements, plan features, or create implementation specifications. Supports single-mode (fast) and multi-mode (4 parallel approaches comparison)."
disable-model-invocation: true
---

# PRP Generation Skill

## Overview

This skill helps generate comprehensive Project Requirement Prompts (PRPs) with:
- Automatic detection when PRP is needed
- Single-mode: Fast PRP generation
- Multi-mode: 4 parallel approaches (Minimalist/Architect/Pragmatist/Conformist)
- Structured evaluation and recommendation

## When to Use

- User describes a feature to implement
- User asks "how should I implement..."
- User needs requirements clarification
- Complex features requiring design decisions

## Invocation

This skill automatically calls the `vw-prp-orchestrator` agent to handle:
1. Mode detection (single vs multi)
2. Parallel sub-agent execution
3. Evaluation and recommendation
4. User selection and PRP generation

For evaluation criteria, see [EVALUATION.md](./EVALUATION.md).

## Output

### Naming Convention

**CRITICAL: All PRPs must follow `PRP-XXX-{feature-name}.md` format**

1. **Check existing PRPs**: `Glob .brain/PRPs/**/PRP-*.md`
2. **Determine next number**: highest existing number + 1
3. **Format**: `PRP-XXX` (zero-padded to 3 digits)

### File Location

`.brain/PRPs/PRP-XXX-{feature-name}.md`

---

## 4 Approaches

4つの異なる設計思想でPRPを生成し、比較検討する。

### Minimalist Approach

**設計思想**: YAGNI + KISS
**モデル**: haiku（コスト効率重視）
**参照元**: vw-prp-plan-minimal

#### 核心原則
- **YAGNI**: 今必要じゃない機能は作らない
- **KISS**: シンプルに保つ
- 常に「本当に必要か？」を問う。MVP志向

#### PRP生成方針
- 必須機能のみに絞る（"nice-to-have"は含めない）
- タスク数を最小化（最大5-7タスク）
- 抽象化・汎用化を避ける
- 将来の拡張性より、今動くことを優先
- テストは最重要パスのみ

#### 適用例
プロトタイプ開発、小規模機能、時間制約が厳しいプロジェクト

---

### Architect Approach

**設計思想**: SOLID + DRY
**モデル**: sonnet（品質重視）
**参照元**: vw-prp-plan-architect

#### 核心原則
- **SOLID** principles compliance
- **DRY**: コードの重複を避ける
- 適切な抽象化と設計パターンの活用
- 拡張性・保守性重視

#### PRP生成方針
- インターフェース・抽象クラスの適切な定義
- 将来の機能追加を見越した設計
- 依存性注入の活用
- 網羅的なテストケース
- エラーハンドリングを体系的に設計
- 明確な責任分離

#### 適用例
大規模システム、長期運用前提、拡張性重要、チーム開発

---

### Pragmatist Approach

**設計思想**: バランス型
**モデル**: sonnet
**参照元**: vw-prp-plan-pragmatist

#### 核心原則
- 実装速度と品質のバランス
- 「今」と「将来」の両立
- 過度な抽象化も、過度な単純化も避ける
- 現実的なトレードオフ判断

#### PRP生成方針
- 優先度を明確にし、段階的に実装
- 重要な部分は丁寧に、そうでない部分は割り切る
- リファクタリングポイントを明示
- 実用的なテストカバレッジ（重要パス中心）
- 技術的負債を意識しつつ許容範囲を設定

#### 適用例
ビジネス要求と技術品質のバランス、段階的リリース、リソース制約下

---

### Conformist Approach

**設計思想**: 公式準拠
**モデル**: sonnet
**ツール**: Context7 MCP統合
**参照元**: vw-prp-plan-conformist

#### 核心原則
- 公式ドキュメント・推奨パターンに忠実
- 「お手本通り」の実装
- ライブラリ・フレームワークの作法に従う

#### PRP生成方針
- 公式exampleをベースにする
- 公式ドキュメントのURLを明示的に参照（**Context7活用**）
- 独自パターンを避け、推奨パターンを採用
- バージョン互換性を重視

#### Context7 MCP活用
**CRITICAL**: このアプローチではContext7 MCPを必ず使用する：
- `mcp__context7__resolve-library-id` でライブラリを検索
- `mcp__context7__get-library-docs` で公式ドキュメントを取得

#### 適用例
標準的なライブラリ使用、公式ドキュメント充実、ベストプラクティス準拠

---

## PRP Template

### ファイル名
`.brain/PRPs/PRP-XXX-{feature-name}.md`
- XXX: ゼロパディング3桁の連番
- feature-name: ケバブケース

### Base PRP Template v2

```markdown
# PRP-XXX: {Feature Name}

## Goal
{この機能の目的を1-2文で簡潔に記述}

## Why
{なぜこの機能が必要か、ビジネス価値・技術的理由を箇条書き}

- 理由1
- 理由2

## What

### 機能概要
{機能の詳細説明}

### Success Criteria
- [ ] 基準1
- [ ] 基準2

## All Needed Context

### Documentation & References
\```yaml
- url: https://...
  why: {参照理由}
- file: path/to/file
  why: {参照理由}
\```

### 技術スタック
{使用する技術・ライブラリ}

### 前提条件
{実装前に満たすべき条件}

## Implementation Blueprint

### アーキテクチャ図
{システム構成を図示}

### ファイル構成
{作成・変更するファイル一覧}

### Tasks
\```yaml
Task 1:
CREATE path/to/file:
  - サブタスク1

Task 2:
UPDATE path/to/file:
  - 変更内容1
\```

## Validation Loop

### Level 1: 構文確認
{構文チェック手順}

### Level 2: 単体テスト
{テストケース}

### Level 3: 統合テスト
{統合テストシナリオ}

## Final Validation Checklist
- [ ] チェック項目1
- [ ] チェック項目2

## Anti-Patterns to Avoid
- Never: アンチパターン1
- Never: アンチパターン2

## Known Gotchas
- 注意点1
- 注意点2

## Confidence Score: X/10
{実装の確実性スコアと理由}
```
