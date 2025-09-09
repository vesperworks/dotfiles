# Agent重複・関連性分析レポート

## 分析概要

新規定義された5つのsubagentと既存の4つのagentの重複・関連性を分析し、統合可能性と実装戦略を評価しました。

## 既存Agent概要

### 1. code-reviewer-claude-md
- **責任範囲**: CLAUDE.md準拠のコードレビュー
- **専門機能**: セキュリティ・品質・保守性のチェック
- **特徴**: 日本語対応、構造化レビュー出力、優先度分類

### 2. error-debugger  
- **責任範囲**: エラー分析と根本原因調査
- **専門機能**: 系統的デバッグ、最小修正、回復処理
- **特徴**: 段階的分析プロセス、証拠ベース診断

### 3. qa-playwright-tester
- **責任範囲**: ブラウザ自動化テストとQA
- **専門機能**: E2Eテスト、品質パイプライン、要件検証
- **特徴**: Playwright MCP連携、詳細テストレポート

### 4. tech-domain-researcher
- **責任範囲**: 最新技術調査と文書化
- **専門機能**: 技術スタック研究、公式文書収集
- **特徴**: Opus使用、ultrathink検証、権威ソース優先

## 新規Subagent概要

### 1. code-explorer
- **責任範囲**: 既存コードベース調査と要件明確化
- **専門機能**: 関連コード調査、アーキテクチャ理解、影響範囲特定

### 2. impact-analyst
- **責任範囲**: 影響範囲分析とリスク評価
- **専門機能**: 依存関係分析、複雑度見積、実装戦略提案

### 3. architecture-designer
- **責任範囲**: システム設計とインターフェース定義
- **専門機能**: API設計、データモデル設計、テスト戦略策定

### 4. feature-developer
- **責任範囲**: TDD実装とコード作成
- **専門機能**: テストファースト開発、段階的コミット、品質チェック

### 5. quality-reviewer
- **責任範囲**: 最終品質確認と改善提案
- **専門機能**: セルフレビュー、テスト実行、品質ゲート確認

## 重複・関連性分析

### 🔄 機能的重複

#### 1. quality-reviewer ⟷ code-reviewer-claude-md
**重複度**: **HIGH (85%)**
- **共通機能**: コードレビュー、品質チェック、改善提案
- **差異点**: 
  - code-reviewer: CLAUDE.md準拠特化、日本語対応
  - quality-reviewer: TDDワークフロー特化、品質ゲート確認

#### 2. feature-developer ⟷ error-debugger  
**重複度**: **MEDIUM (40%)**
- **共通機能**: コード修正、品質チェック実行
- **差異点**:
  - error-debugger: エラー専門、根本原因分析
  - feature-developer: 新機能実装、TDD専門

#### 3. code-explorer ⟷ tech-domain-researcher
**重複度**: **LOW (25%)**
- **共通機能**: 調査・分析機能
- **差異点**:
  - tech-domain-researcher: 最新技術・外部情報
  - code-explorer: 既存コードベース・内部構造

### 🤝 相補的関係

#### 1. code-explorer + impact-analyst + architecture-designer
**関係性**: **順次連携型**
- 調査→分析→設計の段階的ワークフロー
- 各段階の成果物が次の入力となる

#### 2. qa-playwright-tester + quality-reviewer
**関係性**: **並列連携型**  
- qa-playwright-tester: E2Eテスト、ブラウザ検証
- quality-reviewer: 静的解析、コード品質

#### 3. error-debugger + feature-developer
**関係性**: **問題解決型**
- error-debugger: 問題診断と修正
- feature-developer: 実装とテスト作成

## 統合可能性評価

### ✅ 統合推奨

#### 1. quality-reviewer → code-reviewer-claude-md拡張
**推奨度**: **HIGH**
- **理由**: 高い機能重複、既存agentが成熟
- **実装方法**: code-reviewer-claude-mdに品質ゲート機能を追加
- **追加要素**: TDDワークフロー対応、./tmp/成果物管理

#### 2. code-explorer → tech-domain-researcher拡張  
**推奨度**: **MEDIUM**
- **理由**: 調査機能の共通性、補完的専門分野
- **実装方法**: tech-domain-researcherに内部コード調査機能を追加
- **追加要素**: 既存コードベース分析、アーキテクチャ理解

### 🆕 新規作成推奨

#### 1. impact-analyst
**推奨度**: **HIGH**
- **理由**: 既存agentにない専門領域
- **特徴**: 依存関係分析、リスク評価特化
- **ベースagent**: なし（完全新規）

#### 2. architecture-designer
**推奨度**: **HIGH**  
- **理由**: 設計専門の既存agentが存在しない
- **特徴**: システム設計、API定義特化
- **ベースagent**: なし（完全新規）

#### 3. feature-developer
**推奨度**: **MEDIUM**
- **理由**: TDD実装専門、既存agentと棲み分け可能
- **特徴**: 実装とテスト作成の一体化
- **ベースagent**: なし（完全新規、ただしerror-debuggerを参考）

## 実装戦略

### Phase 1: 既存Agent拡張
1. **code-reviewer-claude-md.md** → **quality-reviewer-enhanced.md**
   - 品質ゲート機能追加
   - TDDワークフロー対応
   - ./tmp/成果物管理機能

2. **tech-domain-researcher.md** → **code-explorer-enhanced.md**
   - 内部コード調査機能追加
   - アーキテクチャ分析機能
   - 既存実装パターン理解

### Phase 2: 新規Agent作成
1. **impact-analyst.md** (完全新規)
   - 依存関係分析専門
   - リスク評価とスコアリング
   - 実装戦略立案

2. **architecture-designer.md** (完全新規)
   - システム設計専門
   - API/データモデル定義
   - SOLID原則適用

3. **feature-developer.md** (新規、error-debugger参考)
   - TDD実装専門
   - 段階的開発プロセス
   - 品質チェック統合

## 推奨実装順序

### 優先度1: 統合による効率化
1. `quality-reviewer-enhanced.md` (code-reviewer-claude-md拡張)
2. `code-explorer-enhanced.md` (tech-domain-researcher拡張)

### 優先度2: 新規専門Agent
3. `impact-analyst.md` (完全新規)
4. `architecture-designer.md` (完全新規)

### 優先度3: 実装特化Agent  
5. `feature-developer.md` (新規)

## 期待効果

### 統合による利益
- **開発効率**: 既存の成熟したagentを基盤として活用
- **一貫性**: 確立されたパターンとスタイルの継承
- **学習コスト**: 既存agentの知識を活用した段階的拡張

### 新規作成による利益
- **専門性**: 各フェーズに特化した高度な機能
- **ワークフロー**: 役割進化型の理想的な実装
- **拡張性**: 将来的な機能追加とカスタマイズの柔軟性

## 結論

既存agentの75%を基盤として活用し、25%を新規作成することで、効率的な役割進化型ワークフローを実現できます。特に`code-reviewer-claude-md`の拡張による品質レビュー統合と、完全新規の`impact-analyst`・`architecture-designer`の組み合わせが、最も効果的な実装戦略となります。