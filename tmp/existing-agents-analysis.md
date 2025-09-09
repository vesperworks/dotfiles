# 既存Agentファイル分析レポート

## 概要

.claude/agents/内の4つのagentファイルを分析し、新しいagent作成のベースとなる構造とパターンを整理しました。

## 分析対象

1. `code-reviewer-claude-md.md` - コードレビュー専門agent
2. `error-debugger.md` - エラー・デバッグ専門agent  
3. `qa-playwright-tester.md` - QA・テスト専門agent
4. `tech-domain-researcher.md` - 技術調査専門agent

---

## 1. YAMLフロントマター構造

### 共通フィールド
すべてのagentで以下のフィールドが必須：

```yaml
---
name: [agent名]
description: [詳細な説明とexample]
tools: [利用可能ツール一覧]
model: [使用モデル]
color: [UI表示色]
---
```

### フィールド詳細分析

#### name
- **パターン**: ハイフン区切りの英語名
- **例**: `code-reviewer-claude-md`, `error-debugger`, `qa-playwright-tester`, `tech-domain-researcher`

#### description
- **構造**: "Use this agent when..." + 具体例
- **長さ**: 3-8行の詳細説明
- **必須要素**:
  - 使用タイミングの明確な説明
  - 具体的な使用例（examples）
  - contextとcommentaryを含む構造化example

#### tools
- **共通ツール**: Task, Bash, Glob, Grep, LS, ExitPlanMode, Read, Edit, MultiEdit, Write, NotebookEdit, WebFetch, TodoWrite, WebSearch, BashOutput, KillBash
- **MCP関連ツール**: 
  - playwright-server系（ブラウザ操作）
  - context7系（ドキュメント取得）
- **agent特化ツール**: 役割に応じて選択

#### model
- **パターン**: `sonnet` (3つ) / `opus` (1つ)
- **使い分け**: 一般的な作業はsonnet、高度な調査はopus

#### color
- **パターン**: `cyan`, `red`, `orange`, `blue`
- **役割との関連**: 視覚的な識別のため

---

## 2. 各Agentの専門機能と責任範囲

### code-reviewer-claude-md
- **専門領域**: CLAUDE.mdベースのコードレビュー
- **責任範囲**: 
  - セキュリティ・パフォーマンス・保守性チェック
  - プロジェクト固有ガイドライン遵守確認
  - 優先度別フィードバック提供
- **特徴**: 日本語でのレビュー結果出力

### error-debugger
- **専門領域**: エラー解析・デバッグ
- **責任範囲**:
  - 根本原因分析
  - 体系的なデバッグプロセス
  - 最小限の修正実装
- **特徴**: 段階的な分析手法（Assessment → Analysis → Investigation → Resolution）

### qa-playwright-tester
- **専門領域**: Web アプリケーションのQA
- **責任範囲**:
  - Playwright自動テスト実行
  - コード品質検証
  - 要件適合性確認
- **特徴**: ./test_report/ディレクトリへの詳細レポート出力

### tech-domain-researcher
- **専門領域**: 技術スタック調査
- **責任範囲**:
  - 最新技術情報収集
  - 公式ドキュメント参照
  - ./docsディレクトリへの文書化
- **特徴**: ultrathink手法による検証プロセス

---

## 3. 使用ツールパターン

### 基本ツールセット（全agent共通）
```
Task, Bash, Glob, Grep, LS, ExitPlanMode, Read, Edit, MultiEdit, Write, NotebookEdit, WebFetch, TodoWrite, WebSearch, BashOutput, KillBash
```

### 特化ツール

#### ブラウザ操作系（QA agent）
```
mcp__playwright-server__browser_*
```

#### ドキュメント取得系（研究 agent）  
```
mcp__context7__resolve-library-id, mcp__context7__get-library-docs
```

### ツール選択基準
- **汎用agent**: 基本ツールセット + 必要最小限の特化ツール
- **専門agent**: 基本ツールセット + 領域特化ツール一式

---

## 4. Descriptionの書き方パターン

### 基本構造
```
Use this agent when [使用条件]. This includes [具体的シナリオ]. The agent specializes in [専門領域].

Examples:
<example>
Context: [状況説明]
user: "[ユーザー発言例]"
assistant: "[適切な応答例]"
<commentary>
[agent使用の理由説明]
</commentary>
</example>
```

### 重要要素
1. **明確な使用条件**: "when encountering errors", "when you need comprehensive testing"
2. **具体的なシナリオ列挙**: エラー種別、テスト対象、調査項目など
3. **構造化example**: Context → user → assistant → commentary
4. **専門性の強調**: "specializes in", "expertise in"

---

## 5. プロンプト本体のセクション構成

### 共通セクション構造

#### 1. 役割定義
```
You are an expert [専門分野] specializing in [具体的領域].
```

#### 2. 主要責任（Primary Responsibilities）
- 番号付きリストで明確に列挙
- 各責任の具体的な作業内容

#### 3. 作業プロセス（Workflow/Methodology）  
- 段階的なプロセス定義
- フェーズ別の作業内容

#### 4. 出力形式（Output Format/Structure）
- 期待される成果物の具体的フォーマット
- マークダウン例やテンプレート提示

#### 5. 品質基準（Quality Standards/Guiding Principles）
- 作業品質の基準
- 判断指針

#### 6. 特殊考慮事項（Special Considerations）
- 例外的ケースの処理方法
- エスカレーション手順

### セクション構成のバリエーション

#### code-reviewer-claude-md
1. 役割定義 → 2. 主要責任 → 3. 構造化レビュープロセス → 4. レビュー基準 → 5. プロジェクト固有考慮事項 → 6. レビュー出力形式 → 7. コミュニケーションスタイル → 8. 対象範囲

#### error-debugger  
1. 役割定義 → 2. デバッグプロトコル → 3. デバッグ手法 → 4. 出力構造 → 5. 指導原則 → 6. 特殊考慮事項

#### qa-playwright-tester
1. 役割定義 → 2. 中核責任 → 3. テストワークフロー → 4. レポート基準 → 5. エラー処理プロトコル → 6. 品質基準 → 7. コミュニケーションスタイル

#### tech-domain-researcher
1. 役割定義 → 2. 中核責任 → 3. 調査方法論 → 4. 品質保証 → 5. 出力形式 → 6. エスカレーションプロトコル

---

## 新Agent作成のベステンプレート

### YAMLフロントマター
```yaml
---
name: [agent-name]
description: Use this agent when [使用条件]. This includes [具体的シナリオ]. The agent specializes in [専門領域].

Examples:
<example>
Context: [状況説明]
user: "[ユーザー発言例]"
assistant: "[適切な応答例]"
<commentary>
[agent使用の理由説明]
</commentary>
</example>
tools: Task, Bash, Glob, Grep, LS, ExitPlanMode, Read, Edit, MultiEdit, Write, NotebookEdit, WebFetch, TodoWrite, WebSearch, BashOutput, KillBash[, 特化ツール...]
model: sonnet
color: [色選択]
---
```

### プロンプト本体
```markdown
You are an expert [専門分野] specializing in [具体的領域]. Your expertise spans [関連技術・手法].

## Primary Responsibilities
1. **[責任1]**: [具体的な作業内容]
2. **[責任2]**: [具体的な作業内容]
...

## [Workflow/Methodology]
### [Phase1] Phase
- [具体的作業項目]
- [作業の詳細]

### [Phase2] Phase  
- [具体的作業項目]
- [作業の詳細]

## Output Structure
### [成果物タイプ1]
- [必要な要素]
- [フォーマット要件]

### [成果物タイプ2]
- [必要な要素] 
- [フォーマット要件]

## Quality Standards
- [品質基準1]
- [品質基準2]
- [判断指針]

## Special Considerations
- [例外ケース処理]
- [エスカレーション条件]
- [制約事項]

[最終的な目標や哲学の明示]
```

---

## 推奨事項

### 1. 命名規則
- ハイフン区切りの英語名
- 機能が分かりやすい名前
- 既存agentとの重複回避

### 2. ツール選択
- 基本ツールセットは全て含める
- 専門領域に必要な特化ツールのみ追加
- 不要なツールは含めない

### 3. プロンプト設計
- 明確な責任範囲の定義
- 段階的な作業プロセス
- 具体的な出力フォーマット
- 品質基準の明示

### 4. 品質確保
- 具体的なexampleの提供
- エラーケースの考慮
- エスカレーション手順の明示

このテンプレートと分析結果を基に、目的に特化した高品質なagentを作成することができます。