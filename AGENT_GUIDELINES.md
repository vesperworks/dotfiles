# Claude Code エージェントファイル作成・修正ガイドライン

## 概要
このドキュメントは、Claude Codeのエージェントファイル（`.klaude/agents/`ディレクトリ内のファイル）を作成・修正するための包括的なガイドラインです。

## 必須要素

### 1. YAMLフロントマター
```yaml
---
name: [エージェント名]  # kebab-case形式、簡潔で説明的
description: [詳細説明]  # 以下の要素を含む：
  # - 使用目的の明確な説明
  # - 具体的な使用シナリオ
  # - Examples:セクションに2-3個の具体例
  # - <example>タグで囲んだ実例
  # - <commentary>タグで使用理由の説明
tools: [ツールリスト]  # カンマ区切り、必要最小限のツールを選択
model: [モデル名]  # sonnet（標準）/opus（高度な推論が必要な場合）
color: [色名]  # エージェントの性質を表す色
  # cyan: レビュー/品質管理
  # red: エラー/デバッグ
  # orange: テスト/QA
  # blue: 調査/分析
---
```

### 2. プロンプト本体構造

#### 開始部（ペルソナ定義）
```markdown
You are [役割], [専門性の説明]. [能力や経験の説明].
```

#### 責任セクション
```markdown
**Core Responsibilities:** または Your primary responsibilities:
1. **[責任1]**: 詳細説明
2. **[責任2]**: 詳細説明
...
```

#### メソドロジーセクション
```markdown
## [作業名] Methodology または **[作業名] Workflow:**
1. **[ステップ1]**: 具体的なアクション
2. **[ステップ2]**: 具体的なアクション
...
```

#### 出力フォーマットセクション
```markdown
## Output Structure または **Reporting Standards:**
- 具体的な出力形式の説明
- マークダウンやコードブロックの例
- ファイル保存場所の指定
```

#### ガイド原則セクション
```markdown
## Guiding Principles または **Quality Standards:**
- **原則名**: 説明
- **原則名**: 説明
...
```

## 作成・修正時のベストプラクティス

### 1. 言語と文体
- エージェント本体は英語で記述
- 専門的だが理解しやすい文章
- 命令形ではなく説明形（You are/You will）
- 日本語固有の要素は日本語併記可（例：セキュリティ要件）

### 2. descriptionの書き方
- 改行は`\n`でエスケープ
- Examples:セクションは必須
- 各例に`<example>`と`<commentary>`タグを使用
- コンテキスト、ユーザー入力、アシスタント応答、説明を含む

#### descriptionの例
```yaml
description: Use this agent when...\n\nExamples:\n<example>\nContext: [状況説明]\nuser: "[ユーザーの質問]"\nassistant: "[アシスタントの応答]"\n<commentary>\n[使用理由の説明]\n</commentary>\n</example>
```

### 3. ツール選択の基準

#### 基本ツール（ほぼ全エージェントで使用）
- Read, Write, Edit, MultiEdit
- Glob, Grep, LS
- TodoWrite

#### 特殊用途ツール
- **調査系**: Task, Bash, WebSearch, WebFetch, mcp__context7系
- **デバッグ系**: BashOutput, KillBash
- **テスト系**: mcp__playwright-server系
- **計画系**: ExitPlanMode

### 4. セクション構造
- `##`（H2）または`**太字**`でセクション分け
- 番号付きリストで手順を明確化
- 箇条書きで原則や基準を列挙
- コードブロックで出力例を提示

### 5. 色の選択基準
- **cyan**: コードレビュー、品質管理
- **red**: エラー処理、デバッグ
- **orange**: テスト、QA
- **blue**: 調査、分析、研究
- **green**: 実装、開発
- **purple**: 設計、アーキテクチャ

## 品質チェックリスト

- [ ] YAMLフロントマターが正しくフォーマットされている
- [ ] nameがkebab-case形式である
- [ ] descriptionに具体例が2つ以上含まれている
- [ ] 必要なツールが全て含まれている
- [ ] 不要なツールが含まれていない
- [ ] エージェントの役割が明確に定義されている
- [ ] 作業プロセスが段階的に説明されている
- [ ] 出力フォーマットが明示されている
- [ ] ガイド原則が含まれている
- [ ] 改行が`\n`でエスケープされている

## 具体的な修正手順

### 既存エージェントの修正時
1. YAMLフロントマターの形式を確認
2. descriptionに例が不足していれば追加
3. プロンプト本体のセクション構造を整理
4. 出力フォーマットを明確化
5. 不要なツールを削除、必要なツールを追加

### 新規エージェントの作成時
1. 既存エージェントをテンプレートとして参考にする
2. 専門領域を明確に定義
3. 具体的な使用シナリオを3つ以上考える
4. 段階的な作業プロセスを設計
5. 出力の形式と保存場所を決定
6. 適切な色とモデルを選択

### テスト方法
1. YAMLパーサーでフロントマターの妥当性確認
2. descriptionの改行が正しくエスケープされているか確認
3. ツールリストが実際に利用可能か確認
4. プロンプトの論理的一貫性を確認
5. 実際にエージェントを呼び出してテスト

## エージェントファイルのテンプレート

```yaml
---
name: example-agent
description: Use this agent when [使用目的].\n\nExamples:\n<example>\nContext: [コンテキスト]\nuser: "[ユーザー入力]"\nassistant: "[応答]"\n<commentary>\n[理由]\n</commentary>\n</example>
tools: Read, Write, Edit, MultiEdit, Glob, Grep, LS, TodoWrite
model: sonnet
color: cyan
---

You are [役割], specializing in [専門分野]. Your expertise includes [能力の詳細].

**Core Responsibilities:**
1. **[責任1]**: [詳細説明]
2. **[責任2]**: [詳細説明]
3. **[責任3]**: [詳細説明]

## Working Methodology

### Phase 1: [フェーズ名]
- [アクション1]
- [アクション2]
- [アクション3]

### Phase 2: [フェーズ名]
- [アクション1]
- [アクション2]
- [アクション3]

## Output Structure

Your output should follow this format:
```
## [セクション1]
[内容]

## [セクション2]
[内容]
```

## Guiding Principles

- **[原則1]**: [説明]
- **[原則2]**: [説明]
- **[原則3]**: [説明]

Remember: [重要な注意事項やリマインダー]
```

## 参考：既存エージェントの分析結果

### 共通パターン
1. **構造の一貫性**: 全エージェントが同じYAML+Markdownフォーマット
2. **役割の専門化**: 各エージェントは明確に定義された専門領域
3. **実例駆動**: descriptionに必ず具体的な使用例
4. **体系的アプローチ**: 段階的で再現可能なプロセス
5. **品質重視**: エラーハンドリング、検証、文書化

### エージェント別の特徴
- **code-reviewer-claude-md**: CLAUDE.md準拠のコードレビューに特化
- **error-debugger**: 体系的なデバッグプロセスと根本原因分析
- **qa-playwright-tester**: Playwright MCPを使用した包括的なQAテスト
- **tech-domain-researcher**: ultrathink手法による技術調査と文書化

## 更新履歴
- 2024-08-22: 初版作成
- エージェントファイル構造の分析に基づくガイドライン策定

## 関連ファイル
- `.klaude/agents/`: エージェント定義ファイル格納ディレクトリ
- `CLAUDE.md`: プロジェクト全体の設定と規約
- `.klaude/settings.json`: Claude Code設定ファイル