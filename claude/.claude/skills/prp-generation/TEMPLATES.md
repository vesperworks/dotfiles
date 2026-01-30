# PRP Templates

## Naming Convention

**ファイル名**: `.brain/PRPs/PRP-XXX-{feature-name}.md`
- XXX: ゼロパディング3桁の連番（既存の最大番号 + 1）
- feature-name: ケバブケース（小文字、ハイフン区切り）
- 例: `.brain/PRPs/PRP-009-user-authentication.md`

## Base PRP Template v2

各サブエージェントはこのテンプレートに沿ってPRPを生成する。

```markdown
# PRP-XXX: {Feature Name}

## Goal
{この機能の目的を1-2文で簡潔に記述}

## Why
{なぜこの機能が必要か、ビジネス価値・技術的理由を箇条書き}

- 理由1
- 理由2
- 理由3

## What

### 機能概要
{機能の詳細説明}

### Success Criteria
{完了条件をチェックリスト形式で記載}

- [ ] 基準1
- [ ] 基準2
- [ ] 基準3

## All Needed Context

### Documentation & References
{必要なドキュメント・参照URLをYAML形式でリスト}

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
{実装タスクをYAML形式でリスト}

\```yaml
Task 1:
CREATE path/to/file:
  - サブタスク1
  - サブタスク2

Task 2:
UPDATE path/to/file:
  - 変更内容1
  - 変更内容2
\```

## Validation Loop

### Level 1: 構文確認
{構文チェック手順}

### Level 2: 単体テスト
{テストケース}

### Level 3: 統合テスト
{統合テストシナリオ}

## Final Validation Checklist
{最終確認項目}

- [ ] チェック項目1
- [ ] チェック項目2

## Anti-Patterns to Avoid
{避けるべきアンチパターン}

- ❌ アンチパターン1
- ❌ アンチパターン2

## Known Gotchas
{既知の落とし穴}

- ⚠️ 注意点1
- ⚠️ 注意点2

## Confidence Score: X/10
{実装の確実性スコアと理由}
```
