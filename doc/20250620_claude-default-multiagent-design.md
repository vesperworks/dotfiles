# ClaudeCodeデフォルト機能によるマルチエージェント設計

## 概要

ClaudeCodeの公式`/`コマンド機能を活用し、現在会話中のClaudeがオーケストレーターとなってマルチエージェントシステムを実現する設計案。git worktreeでタスクを物理分離し、Anthropic公式のTDDフローに基づいた自動協業パターンを実装。

## 🎯 設計思想

### コアコンセプト
- **公式/コマンド**: ClaudeCodeの`.claude/commands/`機能のみを使用  
- **オーケストレーター**: 現在会話中のClaudeが全フロー統括
- **タスク分離**: git worktreeで1タスク=1worktreeの独立実行
- **自動化**: ユーザーは指示後、次のタスクに移行可能

### Anthropic公式フロー準拠
- **Explore > Plan > Confirm > Coding > Commit**
- **Write code › Screenshot result › Iterate**  
- **Write tests › Commit › Code › Iterate › Commit**

## 📋 実装パターン

### 1. 公式カスタムコマンド構造

```
.claude/
├── commands/
│   ├── multi-tdd.md           # /project:multi-tdd
│   ├── multi-feature.md       # /project:multi-feature
│   └── multi-refactor.md      # /project:multi-refactor
├── prompts/
│   ├── explorer.md            # Explore フェーズ用
│   ├── planner.md             # Plan フェーズ用
│   ├── coder.md               # Coding フェーズ用
│   └── tester.md              # Test フェーズ用
└── templates/
    └── task-completion.md     # タスク完了レポート
```

### 2. 核心の設計

#### **ユーザーの操作**：
```
> /project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"
```

#### **Anthropic公式フロー**：
```
Explore > Plan > Confirm > Coding > Commit
```

#### **git worktreeでの物理分離**：
```
../project-bugfix-jwt-123  （1タスク = 1worktree）
└── Explore → Plan → Code → Commit （全フローを1つのworktree内で実行）
```

#### **オーケストレーション**：
現在のClaudeCodeが**feature branchを切り**、**git worktreeを作成**し、**そのworktree内でサブエージェントを統括**して全フローを自動実行。**ユーザーは次の指示に移行可能**。

## 🚀 カスタムコマンド実装（正しいワークフロー）

### .claude/commands/multi-tdd.md

```markdown
# Multi-Agent TDD Workflow

あなたは現在、マルチエージェント TDD ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1タスク=1worktree）に基づき、以下の手順で**自動実行**してください。

## 実行タスク
$ARGUMENTS

## 実行方針
**ユーザーは指示後、次のタスクに移行可能**。このタスクは独立したworktree内で**全フローを自動完了**します。

### Step 1: タスク用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 1. タスク識別子生成
PROJECT_ROOT=$(basename $(pwd))
TASK_ID=$(echo "$ARGUMENTS" | sed 's/[^a-zA-Z0-9]/-/g' | cut -c1-20)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TASK_BRANCH="bugfix/jwt-${TIMESTAMP}"
WORKTREE_PATH="../${PROJECT_ROOT}-${TASK_ID}"

# 2. Featureブランチ作成とWorktree作成（公式パターン）
git worktree add "$WORKTREE_PATH" -b "$TASK_BRANCH"

# 3. .claude設定をコピー
cp -r .claude "$WORKTREE_PATH/"

echo "🚀 Task worktree created: $WORKTREE_PATH"
echo "📋 Task: $ARGUMENTS"
echo "🌿 Branch: $TASK_BRANCH"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$TASK_BRANCH`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Explore（探索・調査）
```bash
cd "$WORKTREE_PATH"

# Explorerエージェント実行
echo "🔍 Phase 1: Exploring..."
```

**Explorer指示**:
$(cat .claude/prompts/explorer.md)

**タスク**: $ARGUMENTS

**実行内容**:
1. 現在のコードベースを調査・分析
2. 問題の根本原因を特定
3. 影響範囲と依存関係を明確化
4. 要件と制約を整理
5. 結果を `explore-results.md` に保存

```bash
git add explore-results.md
git commit -m "[EXPLORE] Analysis complete: $ARGUMENTS"
```

#### Phase 2: Plan（計画策定）
```bash
echo "📋 Phase 2: Planning..."
```

**Planner指示**:
$(cat .claude/prompts/planner.md)

**前フェーズ結果**: `explore-results.md`
**タスク**: $ARGUMENTS

**実行内容**:
1. Explore結果を基に実装戦略を策定
2. TDD手順（Test First）での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果を `plan-results.md` に保存

```bash
git add plan-results.md
git commit -m "[PLAN] Strategy complete: $ARGUMENTS"
```

#### Phase 3: Coding（TDD実装）
```bash
echo "💻 Phase 3: Coding with TDD..."
```

**Coder指示**:
$(cat .claude/prompts/coder.md)

**前フェーズ結果**: `explore-results.md`, `plan-results.md`
**タスク**: $ARGUMENTS

**TDD実行順序**:
1. **Write tests › Commit** - 失敗するテストを先に作成
2. **Code › Iterate** - テストを通すための最小実装
3. **Refactor › Commit** - コード品質向上

```bash
# TDD Cycle
git add tests/
git commit -m "[TDD-RED] Failing tests: $ARGUMENTS"

git add src/
git commit -m "[TDD-GREEN] Implementation: $ARGUMENTS"

git add .
git commit -m "[TDD-REFACTOR] Code quality improvements: $ARGUMENTS"

# 最終結果保存
git add coding-results.md
git commit -m "[CODING] Implementation complete: $ARGUMENTS"
```

### Step 3: 完了通知とPR準備

```bash
echo "✅ Phase 4: Task completion..."

# 最終検証
npm test || echo "⚠️ Tests need attention"

# 完了レポート生成
cat > task-completion-report.md << EOF
# Task Completion Report

## Task Summary
**Task**: $ARGUMENTS  
**Branch**: $TASK_BRANCH
**Worktree**: $WORKTREE_PATH
**Completed**: $(date)

## Phase Results
- ✅ **Explore**: Root cause analysis complete
- ✅ **Plan**: Implementation strategy defined  
- ✅ **Code**: TDD implementation finished
- ✅ **Ready**: PR ready for review

## Files Modified
$(git diff --name-only origin/main)

## Commits
$(git log --oneline origin/main..HEAD)

## Next Steps
1. Review implementation in worktree: $WORKTREE_PATH
2. Create PR: $TASK_BRANCH → main
3. Clean up worktree after merge

EOF

git add task-completion-report.md
git commit -m "[COMPLETE] Task finished: $ARGUMENTS"

echo "🎉 Task completed independently!"
echo "📊 Report: $WORKTREE_PATH/task-completion-report.md"
echo "🔀 Ready for PR: $TASK_BRANCH → main"
echo ""
echo "💡 User can now proceed with next tasks."
echo "🧹 Cleanup: git worktree remove $WORKTREE_PATH (after PR merge)"
```

**使用例**: `/project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"`

**結果**: ユーザーは指示後すぐに次のタスクに移行可能。このタスクは独立worktree内で自動完了し、PR準備まで完了。
```

### .claude/commands/multi-feature.md

```markdown
# Multi-Agent Feature Development

新機能開発を独立worktreeで自動実行します。

## 開発する機能
$ARGUMENTS

## 実行方針
**1機能 = 1worktree** で全フローを自動実行。ユーザーは指示後、他の作業が可能。

### 実行フロー（自動化）
1. **Worktree作成**: `../project-feature-{name}`
2. **自動実行**: Explore → Plan → Code → Commit
3. **PR準備**: 完了後、自動でPR準備完了
4. **ユーザー復帰**: レビュー・マージのタイミングでのみ

**使用例**: `/project:multi-feature "ユーザープロフィール画像アップロード機能"`
```

### .claude/commands/multi-refactor.md

```markdown
# Multi-Agent Refactoring Workflow

リファクタリングを独立worktreeで自動実行します。

## リファクタリング対象
$ARGUMENTS

## 実行方針
**1リファクタリング = 1worktree** で全フローを自動実行。既存テストを保持しながら段階的に実行。

### 実行フロー（自動化）
1. **Worktree作成**: `../project-refactor-{target}`
2. **自動実行**: Analysis → Plan → Refactor → Verify
3. **PR準備**: テスト通過確認後、PR準備完了

**使用例**: `/project:multi-refactor "auth/*.js を TypeScript + async/await に移行"`
```

## 🔧 サブエージェントプロンプト

### .claude/prompts/explorer.md

```markdown
# Explorer Agent - 探索・調査専門

あなたは問題調査と要件整理の専門家です。**このworktree内で**与えられたタスクを深く分析し、実装に必要な情報を整理してください。

## 調査方針
- **根本原因**: 表面的な症状ではなく本質的な問題を特定
- **影響範囲**: 変更による影響をシステム全体で分析
- **制約条件**: 技術的・業務的制約を明確化
- **要件整理**: 機能・非機能要件を具体化

## 作業フロー
1. **現状分析**: 既存コード・設定・ドキュメントの調査
2. **問題特定**: 根本原因と影響範囲の特定
3. **要件抽出**: 解決すべき要件の明確化
4. **制約整理**: 技術的・業務的制約の洗い出し
5. **結果保存**: `explore-results.md` に調査結果を保存

## 出力形式
<current_state>
現在の状況とコードベースの分析
</current_state>

<root_cause>
問題の根本原因と発生メカニズム
</root_cause>

<impact_analysis>
変更による影響範囲とリスク
</impact_analysis>

<requirements>
機能要件・非機能要件の詳細
</requirements>

<constraints>
技術的・業務的制約事項
</constraints>

<next_phase_guidance>
Plan フェーズへの推奨事項
</next_phase_guidance>

**重要**: 調査完了後、必ず `explore-results.md` ファイルを作成して結果を保存し、gitコミットしてください。
```

### .claude/prompts/planner.md

```markdown
# Planner Agent - 戦略策定専門

あなたは実装戦略の策定とプロジェクト計画の専門家です。**同一worktree内の** `explore-results.md` を基に、具体的な実装計画を作成してください。

## 計画方針  
- **TDD優先**: Test-Driven Development を基本とする
- **段階的実装**: リスクを最小化する段階的アプローチ
- **品質重視**: 保守性・拡張性を考慮した設計
- **自動化対応**: 次のCoderエージェントが実行しやすい具体的な手順

## 作業フロー
1. **前フェーズ確認**: `explore-results.md` の内容を理解
2. **戦略策定**: 全体的な実装アプローチの決定
3. **TDD設計**: テストファーストの開発手順設計
4. **実装順序**: 依存関係を考慮した実装順序
5. **結果保存**: `plan-results.md` に戦略を保存

## 出力形式
<implementation_strategy>
全体的な実装戦略とアプローチ
</implementation_strategy>

<tdd_workflow>
具体的なTDD実行手順（Coderエージェント向け）
</tdd_workflow>

<development_phases>
段階的な実装計画と優先順位
</development_phases>

<testing_strategy>
テスト戦略とカバレッジ計画
</testing_strategy>

<quality_gates>
品質チェックポイントと基準
</quality_gates>

<coder_instructions>
Coderエージェントへの具体的実行指示
</coder_instructions>

**重要**: 計画完了後、必ず `plan-results.md` ファイルを作成して戦略を保存し、gitコミットしてください。
```

### .claude/prompts/coder.md

```markdown
# Coder Agent - TDD実装専門

あなたは TDD による高品質な実装の専門家です。**同一worktree内の** `plan-results.md` の戦略に基づき、テストファーストで実装を進めてください。

## 実装方針
- **Test First**: 必ず失敗するテストから開始
- **最小実装**: テストを通す最小限の実装
- **リファクタリング**: 実装後の品質向上
- **継続的検証**: 各段階での動作確認

## TDD サイクル
1. **Red**: 失敗するテストを作成 → Commit
2. **Green**: テストを通す最小実装 → Commit
3. **Refactor**: コード品質の向上 → Commit

## 作業フロー
1. **前フェーズ確認**: `plan-results.md` の戦略を理解
2. **テスト設計**: 失敗するテストケースの作成
3. **最小実装**: テストを通すための基本実装
4. **機能拡張**: 段階的な機能追加
5. **リファクタリング**: コード品質の向上
6. **結果保存**: `coding-results.md` に実装結果を保存

## 出力形式
<test_cases>
作成したテストケース（Red → Green の順）
</test_cases>

<implementation>
段階的に実装したコード
</implementation>

<refactoring>
リファクタリングによる改善内容
</refactoring>

<verification>
各段階での検証結果
</verification>

<final_status>
最終的な実装状況と品質評価
</final_status>

**重要**: 実装完了後、必ず `coding-results.md` ファイルを作成して結果を保存し、gitコミットしてください。各TDDサイクルでもこまめにコミットしてください。
```

## 📊 使用方法と実行例

### 基本的な使用フロー

#### 1. ユーザーの操作（瞬時完了）
```
# ClaudeCodeで指示
> /project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"

# ユーザーはすぐに次のタスクへ
> /project:multi-feature "ダッシュボードにグラフ機能追加"
```

#### 2. オーケストレーター（現在のClaude）の自動実行
```
🚀 Multi-Agent TDD Workflow Started (Independent Execution)
📋 Task: 認証機能のJWT有効期限チェック不具合を修正

🌳 Worktree Setup:
✓ Branch created: bugfix/jwt-20250620-143022
✓ Worktree created: ../project-jwt-fix
✓ User can proceed with next tasks

🔍 Auto-Executing in ../project-jwt-fix:

Phase 1: Explorer Agent (RUNNING)
├─ 🔍 Analyzing JWT authentication middleware...
├─ 🔍 Root cause: Token expiration logic bug
├─ 🔍 Impact: All authenticated endpoints affected
├─ ✅ explore-results.md saved & committed

Phase 2: Planner Agent (RUNNING)  
├─ 📋 Strategy: Fix middleware + add clock tolerance
├─ 📋 TDD Plan: Test edge cases → Fix logic → Refactor
├─ 📋 Quality Gates: 90%+ coverage, security scan
├─ ✅ plan-results.md saved & committed

Phase 3: Coder Agent (RUNNING)
├─ 🔴 [TDD-RED] Created failing tests for expiration
├─ ✅ Tests committed
├─ 🟢 [TDD-GREEN] Fixed JWT verification logic  
├─ ✅ Implementation committed
├─ 🔄 [TDD-REFACTOR] Improved error handling
├─ ✅ Refactor committed
├─ 📊 Final verification: All tests pass (18/18)
├─ ✅ coding-results.md saved & committed

🎉 Task Completed Independently!
📊 Report: ../project-jwt-fix/task-completion-report.md
🔀 PR Ready: bugfix/jwt-20250620-143022 → main
🧹 Cleanup: git worktree remove ../project-jwt-fix (after merge)

💡 User notification: JWT fix task completed, ready for review
```

### 並列実行例

```
# ユーザーが連続で指示（即座に次に移行可能）
> /project:multi-tdd "認証バグ修正"
> /project:multi-feature "新しいダッシュボード"  
> /project:multi-refactor "TypeScript移行"

# 3つのタスクが独立worktreeで並行自動実行
../project-jwt-fix/      ← 認証バグ修正（自動実行中）
../project-dashboard/    ← ダッシュボード開発（自動実行中）
../project-typescript/   ← TypeScript移行（自動実行中）
```

## 🎯 メリット

### 1. **真の非同期実行**
- ユーザーは指示後すぐに次のタスクへ移行
- 複数タスクが独立して並行実行
- 待ち時間ゼロの開発体験

### 2. **Anthropic公式準拠**
- **1タスク = 1worktree** の正しいパターン
- **独立ブランチ戦略**で完全分離
- **公式ベストプラクティス**を忠実に実装

### 3. **完全自動化**
- Explore → Plan → Code → Commit の全フロー自動実行
- 人間の介入は最終レビューのみ
- PR準備まで自動完了

### 4. **トレーサビリティ**
- 各タスクが独立したブランチ・worktreeで追跡可能
- 完全なgit履歴とコミット記録
- 段階的な品質保証プロセス

## 🚦 実装ステップ

### Phase 1: 基本自動化
1. **正しいworktree管理**: 1タスク=1worktreeパターン実装
2. **自動フロー実行**: Explore→Plan→Code の連続実行
3. **完了通知システム**: PR準備完了の自動通知

### Phase 2: 並列実行最適化
1. **複数タスク管理**: 独立worktreeでの並列実行
2. **リソース管理**: CPU・メモリ使用量の最適化
3. **競合回避**: 同時実行時の競合防止

### Phase 3: 高度な自動化
1. **動的品質チェック**: 自動テスト・静的解析
2. **インテリジェントPR**: 自動PR作成・レビュー依頼
3. **エラー回復**: 失敗時の自動リトライ・エラー通知

この設計により、**ユーザーが指示するだけで、ClaudeCodeが自動的にタスクを完了まで実行**する、真の自動化マルチエージェント環境が実現できます。🚀

## 🔌 MCP連携による外部ツール統合

### MCP対応ツールスタック
この設計では、MCP（Model Context Protocol）を通じて以下の外部ツールとシームレスに連携します：

#### 🎭 **Playwright** - E2Eテスト・ブラウザ自動化
- **Explorer**: 既存のE2Eテストケース分析・ブラウザ動作調査
- **Planner**: テスト戦略策定・シナリオ設計
- **Coder**: 自動化テストコード生成・デバッグ実行

#### 🎪 **Puppeteer** - ブラウザ操作・スクレイピング
- **Explorer**: Webサイト構造分析・動作パターン調査
- **Planner**: スクレイピング戦略・パフォーマンス最適化
- **Coder**: ブラウザ自動化スクリプト実装

#### 🧠 **Context7** - コンテキスト管理
- **Explorer**: プロジェクト全体のコンテキスト分析
- **Planner**: コンテキスト駆動の実装戦略
- **Coder**: コンテキスト情報を活用した適応的実装

#### 🎨 **Figma** - デザイン連携・プロトタイピング
- **Explorer**: デザインシステム分析・コンポーネント調査
- **Planner**: デザイン実装戦略・コンポーネント化計画
- **Coder**: Figma → Code の自動実装

### MCP統合パターン

#### .claude/prompts/explorer.md への追加
```markdown
## MCP連携ツール活用

### 利用可能な外部ツール
- **Playwright**: E2Eテスト分析・ブラウザ動作確認
- **Puppeteer**: Webサイト構造調査・動作パターン分析
- **Context7**: プロジェクトコンテキスト情報取得
- **Figma**: デザインシステム・コンポーネント情報取得

### 調査強化フロー
1. **Context7でプロジェクト全体把握**
2. **Figmaでデザイン要件確認**（UI関連タスクの場合）
3. **Playwright/Puppeteerで既存動作分析**（Web関連タスクの場合）
4. **従来の調査 + MCP情報の統合分析**

<mcp_integration>
利用したMCPツールと取得した情報
</mcp_integration>
```

#### .claude/prompts/planner.md への追加
```markdown
## MCP連携戦略

### 戦略策定での外部ツール活用
- **Figma**: デザイントークン・コンポーネント仕様の実装計画
- **Context7**: 既存アーキテクチャとの整合性確認
- **Playwright**: E2Eテスト戦略・カバレッジ計画
- **Puppeteer**: ブラウザ自動化・パフォーマンス戦略

### MCP統合実装計画
<mcp_strategy>
各フェーズでのMCPツール活用計画
</mcp_strategy>
```

#### .claude/prompts/coder.md への追加
```markdown
## MCP連携実装

### 実装での外部ツール活用
- **Figma**: デザイントークン取得・コンポーネント自動生成
- **Playwright**: E2Eテスト自動生成・実行・デバッグ
- **Puppeteer**: ブラウザ自動化スクリプト実装
- **Context7**: 動的コンテキスト情報の活用実装

### MCP統合TDDサイクル
1. **Red**: MCP情報を活用した失敗テスト作成
2. **Green**: MCPツールと連携した最小実装
3. **Refactor**: MCP連携の最適化とパフォーマンス改善

<mcp_implementation>
MCPツールとの連携実装詳細
</mcp_implementation>
```

### 実行例：MCP連携での開発フロー

#### メニューバータイマーアプリの場合
```
# ClaudeCodeで指示
> /project:multi-feature "Macのメニューバーにタイマーアプリ作成"

🔍 Explorer with MCP:
├─ 🧠 Context7: 既存Electron/Tauri経験とパターン分析
├─ 🎨 Figma: タイマーUIデザインパターン取得（もしあれば）
├─ 🎭 Playwright: 類似アプリのE2Eテストパターン調査
├─ ✅ MCP統合調査結果 → explore-results.md

📋 Planner with MCP:
├─ 🧠 Context7: プロジェクト全体との技術スタック整合性
├─ 🎨 Figma: デザイントークン・コンポーネント実装戦略
├─ 🎭 Playwright: メニューバーアプリ用E2Eテスト戦略
├─ ✅ MCP統合戦略 → plan-results.md

💻 Coder with MCP:
├─ 🎨 Figma: UIコンポーネント自動生成（Design → Code）
├─ 🎭 Playwright: メニューバーアプリ用E2Eテスト自動作成
├─ 🧠 Context7: 動的設定・コンテキスト情報活用
├─ ✅ MCP統合実装 → coding-results.md
```

### MCP活用メリット

#### 🎯 **設計品質向上**
- **Context7**: プロジェクト全体との整合性確保
- **Figma**: デザインシステムとの完全連携
- **実装前の網羅的情報収集**

#### 🚀 **開発速度向上**
- **Figma → Code**: デザインからの自動実装
- **Playwright**: E2Eテストの自動生成
- **繰り返し作業の大幅削減**

#### 🛡️ **品質保証強化**
- **Playwright**: 自動E2Eテスト・継続的品質チェック
- **Puppeteer**: ブラウザ互換性・パフォーマンス検証
- **デザイン・実装の乖離防止**

この統合により、**MCP連携を前提とした真の自動化マルチエージェント環境**が実現できます！🔌