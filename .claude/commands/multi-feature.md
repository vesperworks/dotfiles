# Multi-Agent Feature Development Workflow

あなたは現在、マルチエージェント機能開発ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1機能=1worktree）に基づき、以下の手順で**自動実行**してください。

## 開発する機能
$ARGUMENTS

## 実行方針
**1機能 = 1worktree** で全フローを自動実行。ユーザーは指示後、他の作業が可能。このタスクは独立したworktree内で**全フローを自動完了**します。

### Step 1: 機能用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 共通ユーティリティの読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境検証
verify_environment || exit 1

# プロジェクトタイプの検出
PROJECT_TYPE=$(detect_project_type)
log_info "Detected project type: $PROJECT_TYPE"

# worktree作成
WORKTREE_INFO=$(create_task_worktree "$ARGUMENTS" "feature")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
FEATURE_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)

log_success "Feature worktree created"
echo "📋 Feature: $ARGUMENTS"
echo "🌿 Branch: $FEATURE_BRANCH"
echo "📁 Worktree: $WORKTREE_PATH"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$FEATURE_BRANCH`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Explore（探索・要件分析）
```bash
# ClaudeCodeアクセス制限対応: cdを使用せず、worktree内で作業
log_info "Working in worktree: $WORKTREE_PATH"

show_progress "Explore" 5 1

# Explorerプロンプトの読み込み（メインディレクトリから）
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
```

**Explorer指示**:
$EXPLORER_PROMPT

**開発機能**: $ARGUMENTS

**作業ディレクトリ**: $WORKTREE_PATH
**注意**: ClaudeCodeのアクセス制限により、直接worktreeディレクトリに移動できません。以下の方法で作業してください：
- ファイル読み取り: `Read $WORKTREE_PATH/ファイル名`
- ファイル書き込み: `Write $WORKTREE_PATH/ファイル名`
- ファイル編集: `Edit $WORKTREE_PATH/ファイル名`

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
# Explore結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/explore-results.md" ]]; then
    # worktree内でコミット
    git -C "$WORKTREE_PATH" add explore-results.md
    git -C "$WORKTREE_PATH" commit -m "[EXPLORE] Feature analysis complete: $ARGUMENTS" || {
        log_error "Failed to commit explore results"
        handle_error 1 "Explore phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [EXPLORE] Feature analysis complete"
else
    log_warning "$WORKTREE_PATH/explore-results.md not found, skipping commit"
fi
```

#### Phase 2: Plan（実装戦略・アーキテクチャ設計）
```bash
show_progress "Plan" 5 2

# Plannerプロンプトの読み込み
PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
```

**Planner指示**:
$PLANNER_PROMPT

**前フェーズ結果**: `$WORKTREE_PATH/explore-results.md`
**開発機能**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

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
# Plan結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/plan-results.md" ]]; then
    git -C "$WORKTREE_PATH" add plan-results.md
    git -C "$WORKTREE_PATH" commit -m "[PLAN] Architecture design complete: $ARGUMENTS" || {
        log_error "Failed to commit plan results"
        handle_error 1 "Plan phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [PLAN] Architecture design complete"
else
    log_warning "$WORKTREE_PATH/plan-results.md not found, skipping commit"
fi
```

#### Phase 3: Prototype（プロトタイプ作成）
```bash
show_progress "Prototype" 5 3
```

**実行内容**:
1. 最小限の動作するプロトタイプ作成
2. 基本的なUI/UXスケルトン実装
3. モックデータでの動作確認
4. プロトタイプのスクリーンショット作成
5. `prototype-results.md` に実装詳細を保存

```bash
# プロトタイプ実装のコミット
if [[ -d "src/" ]] || [[ -d "components/" ]]; then
    git_commit_phase "PROTOTYPE" "Initial prototype: $ARGUMENTS" "src/ components/" || {
        log_warning "No prototype files to commit"
    }
fi

# プロトタイプ結果のコミット
if [[ -f "prototype-results.md" ]] || [[ -d "screenshots/" ]]; then
    git_commit_phase "PROTOTYPE" "Prototype documentation: $ARGUMENTS" "prototype-results.md screenshots/" || {
        log_warning "No prototype documentation to commit"
    }
fi
```

#### Phase 4: Coding（本格実装）
```bash
show_progress "Coding" 5 4

# Coderプロンプトの読み込み
CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
```

**Coder指示**:
$CODER_PROMPT

**前フェーズ結果**: 
- `$WORKTREE_PATH/explore-results.md`
- `$WORKTREE_PATH/plan-results.md`
- `$WORKTREE_PATH/prototype-results.md`

**開発機能**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

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
if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME" ]]; then
    git -C "$WORKTREE_PATH" add "test/$FEATURE_NAME"
    git -C "$WORKTREE_PATH" commit -m "[TEST] Interface and integration tests for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No test files to commit"
    }
fi

# 機能実装
if [[ -d "$WORKTREE_PATH/src/$FEATURE_NAME" ]]; then
    git -C "$WORKTREE_PATH" add "src/$FEATURE_NAME"
    git -C "$WORKTREE_PATH" commit -m "[IMPLEMENT] Core feature implementation for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No implementation files to commit"
    }
fi

# E2Eテスト
if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME/e2e" ]]; then
    git -C "$WORKTREE_PATH" add "test/$FEATURE_NAME/e2e"
    git -C "$WORKTREE_PATH" commit -m "[E2E] End-to-end tests for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No E2E test files to commit"
    }
fi

# 最適化とドキュメント
if [[ -d "$WORKTREE_PATH/report/$FEATURE_NAME/performance" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/performance"
    git -C "$WORKTREE_PATH" commit -m "[OPTIMIZE] Performance optimization for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No optimization files to commit"
    }
fi

# 最終結果保存
if [[ -f "coding-results.md" ]]; then
    git_commit_phase "CODING" "Feature implementation complete: $ARGUMENTS" "coding-results.md" || {
        log_warning "Failed to commit coding results"
    }
fi
```

### Step 3: 完了通知とPR準備

```bash
show_progress "Completion" 5 5

# 全テスト実行 - プロジェクトタイプに応じたテスト
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - feature may be incomplete"
fi

# E2Eテスト実行（存在する場合）
if [[ -f "package.json" ]] && grep -q '"e2e"' package.json; then
    npm run e2e || log_warning "E2E tests need review"
fi

# ビルド実行（存在する場合）
if [[ -f "package.json" ]] && grep -q '"build"' package.json; then
    npm run build || log_warning "Build process needs review"
fi

# 完了レポート生成（メインディレクトリに一時作成してからコピー）
cat > /tmp/feature-completion-report.md << EOF
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
- $(if [[ -f "$WORKTREE_PATH/explore-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Explore**: Requirements and constraints analyzed
- $(if [[ -f "$WORKTREE_PATH/plan-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Plan**: Architecture and implementation strategy defined
- $(if [[ -f "$WORKTREE_PATH/prototype-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Prototype**: Working prototype demonstrated
- $(if [[ -f "$WORKTREE_PATH/coding-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Code**: Full feature implementation completed
- $(if run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then echo "✅"; else echo "⚠️"; fi) **Test**: Comprehensive test coverage achieved
- ✅ **Ready**: Feature ready for review and integration

## Files Created/Modified
### New Components
$(find "$WORKTREE_PATH/src/$FEATURE_NAME" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules || echo "No new components")

### API Changes
$(find "$WORKTREE_PATH/src/$FEATURE_NAME" -name "*.ts" -o -name "*.js" 2>/dev/null | grep -v node_modules || echo "No API changes")

### Test Coverage
$(find "$WORKTREE_PATH/test/$FEATURE_NAME" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l || echo "0") test files

### Coverage Report
Detailed coverage report: $WORKTREE_PATH/report/$FEATURE_NAME/coverage/

### Quality Report
Code quality metrics: $WORKTREE_PATH/report/$FEATURE_NAME/quality/

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

# 完了レポートをworktreeにコピーしてコミット
cp /tmp/feature-completion-report.md "$WORKTREE_PATH/feature-completion-report.md"
rm /tmp/feature-completion-report.md

# worktree内でコミット
if [[ -f "$WORKTREE_PATH/feature-completion-report.md" ]]; then
    git -C "$WORKTREE_PATH" add feature-completion-report.md
    git -C "$WORKTREE_PATH" commit -m "[COMPLETE] Feature ready for integration: $ARGUMENTS" || {
        log_warning "Failed to commit completion report"
    }
    log_success "Committed: [COMPLETE] Feature ready for integration"
fi

log_success "Feature development completed independently!"
echo "📊 Report: $WORKTREE_PATH/feature-completion-report.md"
echo "🔀 Ready for PR: $FEATURE_BRANCH → main"
echo "🚀 Demo available in: $WORKTREE_PATH"
echo ""
echo "💡 User can now proceed with other tasks."
echo "🧹 Cleanup: git worktree remove $WORKTREE_PATH (after PR merge)"

# エラーが発生していた場合は非ゼロで終了
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then
    exit 1
fi
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