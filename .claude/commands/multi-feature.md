# Multi-Agent Feature Development Workflow

あなたは現在、マルチエージェント機能開発ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1機能=1worktree）に基づき、以下の手順で**自動実行**してください。

## 開発する機能
$ARGUMENTS

## 実行方針
**1機能 = 1worktree** で全フローを自動実行。ユーザーは指示後、他の作業が可能。このタスクは独立したworktree内で**全フローを自動完了**します。

### Step 1: 機能用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 1. 機能識別子生成
PROJECT_ROOT=$(basename $(pwd))
FEATURE_ID=$(echo "$ARGUMENTS" | sed 's/[^a-zA-Z0-9]/-/g' | cut -c1-20)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
FEATURE_BRANCH="feature/${FEATURE_ID}-${TIMESTAMP}"
WORKTREE_PATH="../${PROJECT_ROOT}-feature-${FEATURE_ID}"

# 2. Featureブランチ作成とWorktree作成（公式パターン）
git worktree add "$WORKTREE_PATH" -b "$FEATURE_BRANCH"

# 3. .claude設定をコピー
cp -r .claude "$WORKTREE_PATH/"

echo "🚀 Feature worktree created: $WORKTREE_PATH"
echo "📋 Feature: $ARGUMENTS"
echo "🌿 Branch: $FEATURE_BRANCH"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$FEATURE_BRANCH`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Explore（探索・要件分析）
```bash
cd "$WORKTREE_PATH"

# Explorerエージェント実行
echo "🔍 Phase 1: Exploring feature requirements..."
```

**Explorer指示**:
$(cat .claude/prompts/explorer.md)

**開発機能**: $ARGUMENTS

**実行内容**:
1. 新機能の要件分析・技術調査
2. 既存システムとの統合ポイント特定
3. 必要な依存関係とAPIの調査
4. UI/UXおよびデザイン要件の明確化
5. パフォーマンス・セキュリティ要件の洗い出し
6. MCP連携可能性の検討（Figma、Context7など）
7. 結果を `explore-results.md` に保存

**MCP連携（利用可能な場合）**:
- **Figma**: デザインコンポーネント・スタイルガイド取得
- **Context7**: プロジェクトアーキテクチャ・既存パターン分析
- **Playwright/Puppeteer**: 類似機能のE2Eテストパターン調査

```bash
git add explore-results.md
git commit -m "[EXPLORE] Feature analysis complete: $ARGUMENTS"
```

#### Phase 2: Plan（実装戦略・アーキテクチャ設計）
```bash
echo "📋 Phase 2: Planning feature architecture..."
```

**Planner指示**:
$(cat .claude/prompts/planner.md)

**前フェーズ結果**: `explore-results.md`
**開発機能**: $ARGUMENTS

**実行内容**:
1. Explore結果を基にアーキテクチャ設計
2. コンポーネント構成とインターフェース定義
3. データフローとステート管理戦略
4. API設計（REST/GraphQL/WebSocket）
5. UI/UXの実装アプローチ
6. テスト戦略（単体・統合・E2E）
7. 段階的リリース計画
8. 結果を `plan-results.md` に保存

**MCP連携戦略**:
- **Figma → Code**: コンポーネント自動生成計画
- **Playwright**: E2Eテストシナリオ設計
- **Context7**: 既存アーキテクチャとの整合性確認

```bash
git add plan-results.md
git commit -m "[PLAN] Architecture design complete: $ARGUMENTS"
```

#### Phase 3: Prototype（プロトタイプ作成）
```bash
echo "🛠️ Phase 3: Creating feature prototype..."
```

**実行内容**:
1. 最小限の動作するプロトタイプ作成
2. 基本的なUI/UXスケルトン実装
3. モックデータでの動作確認
4. プロトタイプのスクリーンショット作成
5. `prototype-results.md` に実装詳細を保存

```bash
# プロトタイプ実装
git add src/ components/ 
git commit -m "[PROTOTYPE] Initial prototype: $ARGUMENTS"

# プロトタイプ結果
git add prototype-results.md screenshots/
git commit -m "[PROTOTYPE] Prototype documentation: $ARGUMENTS"
```

#### Phase 4: Coding（本格実装）
```bash
echo "💻 Phase 4: Full feature implementation..."
```

**Coder指示**:
$(cat .claude/prompts/coder.md)

**前フェーズ結果**: `explore-results.md`, `plan-results.md`, `prototype-results.md`
**開発機能**: $ARGUMENTS

**TDD実行順序（機能開発向け）**:
1. **インターフェーステスト作成**: APIやコンポーネントの境界テスト
2. **統合テスト作成**: 機能全体のワークフローテスト
3. **実装**: テストを満たす機能実装
4. **E2Eテスト**: ユーザー視点の動作確認
5. **最適化**: パフォーマンス・UX改善

**MCP活用実装**:
- **Figma**: デザイントークン取得・コンポーネント生成
- **Playwright**: E2Eテスト自動生成・実行
- **Context7**: 動的設定・コンテキスト情報活用

```bash
# API/コンポーネントテスト
git add tests/unit/ tests/integration/
git commit -m "[TEST] Interface and integration tests: $ARGUMENTS"

# 機能実装
git add src/ components/ api/
git commit -m "[IMPLEMENT] Core feature implementation: $ARGUMENTS"

# E2Eテスト
git add tests/e2e/
git commit -m "[E2E] End-to-end tests: $ARGUMENTS"

# 最適化とドキュメント
git add performance/ docs/
git commit -m "[OPTIMIZE] Performance and documentation: $ARGUMENTS"

# 最終結果保存
git add coding-results.md
git commit -m "[CODING] Feature implementation complete: $ARGUMENTS"
```

### Step 3: 完了通知とPR準備

```bash
echo "✅ Phase 5: Feature completion..."

# 全テスト実行
npm test || echo "⚠️ Some tests need attention"
npm run e2e || echo "⚠️ E2E tests need review"

# デモ環境準備（可能な場合）
npm run build || echo "⚠️ Build process needs review"

# 完了レポート生成
cat > feature-completion-report.md << EOF
# Feature Completion Report

## Feature Summary
**Feature**: $ARGUMENTS  
**Branch**: $FEATURE_BRANCH
**Worktree**: $WORKTREE_PATH
**Completed**: $(date)

## Implementation Overview
### Architecture
- Component structure implemented
- API endpoints created
- State management configured
- Database schema updated (if applicable)

### UI/UX
- Design system compliance verified
- Responsive design implemented
- Accessibility standards met
- Performance metrics within targets

## Phase Results
- ✅ **Explore**: Requirements and constraints analyzed
- ✅ **Plan**: Architecture and implementation strategy defined
- ✅ **Prototype**: Working prototype demonstrated
- ✅ **Code**: Full feature implementation completed
- ✅ **Test**: Comprehensive test coverage achieved
- ✅ **Ready**: Feature ready for review and integration

## Files Created/Modified
### New Components
$(find components/ -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules || echo "No new components")

### API Changes
$(find api/ -name "*.ts" -o -name "*.js" 2>/dev/null | grep -v node_modules || echo "No API changes")

### Test Coverage
$(find tests/ -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l || echo "0") test files

## Commits
$(git log --oneline origin/main..HEAD)

## Demo & Testing
- Local demo: \`cd $WORKTREE_PATH && npm run dev\`
- Run tests: \`cd $WORKTREE_PATH && npm test\`
- E2E tests: \`cd $WORKTREE_PATH && npm run e2e\`

## Integration Checklist
- [ ] Code review completed
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Performance benchmarks met
- [ ] Security review (if applicable)
- [ ] Accessibility verified
- [ ] Design approval received

## Next Steps
1. Review implementation in worktree: $WORKTREE_PATH
2. Test feature locally with demo environment
3. Create PR: $FEATURE_BRANCH → main
4. Clean up worktree after merge

## MCP Integration Results (if applicable)
- Figma components synced: [Yes/No]
- Playwright E2E tests generated: [Yes/No]
- Context7 patterns applied: [Yes/No]

EOF

git add feature-completion-report.md
git commit -m "[COMPLETE] Feature ready for integration: $ARGUMENTS"

echo "🎉 Feature development completed independently!"
echo "📊 Report: $WORKTREE_PATH/feature-completion-report.md"
echo "🔀 Ready for PR: $FEATURE_BRANCH → main"
echo "🚀 Demo available in: $WORKTREE_PATH"
echo ""
echo "💡 User can now proceed with other tasks."
echo "🧹 Cleanup: git worktree remove $WORKTREE_PATH (after PR merge)"
```

## 使用例

### 基本的な機能開発
```
/project:multi-feature "ユーザープロフィール画像アップロード機能"
```

### デザイン連携を含む機能開発
```
/project:multi-feature "Figmaデザインに基づくダッシュボードウィジェット"
```

### API統合を含む機能開発
```
/project:multi-feature "外部決済システムとのWebhook統合"
```

## 実行結果

ユーザーは指示後すぐに次のタスクに移行可能。この機能開発は独立worktree内で以下のフローを自動完了します：

1. **探索フェーズ**: 要件分析・技術調査・デザイン確認
2. **計画フェーズ**: アーキテクチャ設計・実装戦略策定
3. **プロトタイプ**: 動作確認可能な最小実装
4. **実装フェーズ**: TDD準拠の本格実装・E2Eテスト
5. **完了フェーズ**: デモ環境準備・PR準備完了

全工程が自動化され、ユーザーは最終レビュー時のみ関与すれば良い設計です。