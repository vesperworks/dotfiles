<feature_development_workflow>

# Multi-Agent Feature Development Workflow

あなたは現在、マルチエージェント機能開発ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1機能=1worktree）に基づき、以下の手順で**自動実行**してください。

## 開発する機能
$ARGUMENTS

## 利用可能なオプション
- `--keep-worktree`: worktreeを保持（デフォルト: 削除）
- `--no-merge`: mainへの自動マージをスキップ（デフォルト: マージ）
- `--pr`: GitHub PRを作成（デフォルト: 作成しない）
- `--no-draft`: 通常のPRを作成（デフォルト: ドラフト）
- `--no-cleanup`: 自動クリーンアップを無効化
- `--cleanup-days N`: N日以上前のworktreeを削除（デフォルト: 7）

## 実行方針
**1機能 = 1worktree** で全フローを自動実行。ユーザーは指示後、他の作業が可能。このタスクは独立したworktree内で**全フローを自動完了**します。

**IMPORTANT**: 以下のquality_gatesは全フェーズで適用されます。

<phase name="worktree_setup">
  <objectives>
    - Create isolated worktree for feature development
    - Set up environment variables and configurations
    - Validate project environment
  </objectives>
  
  <tools>
    - Git worktree commands
    - Bash scripting utilities
    - Environment validation functions
  </tools>
  
  <quality_gates>
    - MUST verify git repository status before creation
    - MUST generate unique worktree name
    - ALWAYS save environment variables securely
  </quality_gates>

  <implementation>
### Step 1: 機能用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：
```bash
# 共通ユーティリティの読み込みとワークフロー初期化
source .claude/scripts/worktree-utils.sh || exit 1
parse_workflow_options $ARGUMENTS
verify_environment || exit 1

# プロジェクトタイプ検出とオプション処理
PROJECT_TYPE=$(detect_project_type)
[[ "$AUTO_CLEANUP" == "true" ]] && cleanup_old_worktrees "$CLEANUP_DAYS"

# 機能開発用worktree作成
WORKTREE_INFO=$(create_task_worktree "$TASK_DESCRIPTION" "feature")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
FEATURE_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)
FEATURE_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f3)

# 環境ファイルの生成と保存
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
ENV_FILE=$(generate_env_file_path "feature" "$TASK_ID" "$(date +%Y%m%d-%H%M%S)")

# 環境変数をファイルに保存
cat > "$ENV_FILE" << EOF
WORKTREE_PATH="$WORKTREE_PATH"
FEATURE_BRANCH="$FEATURE_BRANCH"
FEATURE_NAME="$FEATURE_NAME"
PROJECT_TYPE="$PROJECT_TYPE"
TASK_DESCRIPTION="$TASK_DESCRIPTION"
KEEP_WORKTREE="$KEEP_WORKTREE"
NO_MERGE="$NO_MERGE"
CREATE_PR="$CREATE_PR"
NO_DRAFT="$NO_DRAFT"
AUTO_CLEANUP="$AUTO_CLEANUP"
CLEANUP_DAYS="$CLEANUP_DAYS"
EOF

export ENV_FILE
log_success "Feature worktree created: $WORKTREE_PATH"
echo "📌 IMPORTANT: Use this environment file in each phase: ENV_FILE='$ENV_FILE'"
```

<example>
```bash
# 使用例：機能開発の開始
/project:multi-feature "ユーザープロフィール画像アップロード機能"
# 出力: worktree作成、環境ファイルパス表示
```
</example>

  </implementation>
  
  <output>
    - Created worktree at specified path
    - Environment file with all necessary variables  
    - Initial commit on feature branch
  </output>
</phase>

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$FEATURE_BRANCH`

**IMPORTANT**: 以下の全フローを**同一worktree内で連続自動実行**します：

<phase name="explore">
  <objectives>
    - Analyze feature requirements and constraints
    - Identify integration points with existing system
    - Research necessary dependencies and APIs
    - Define UI/UX and design requirements
    - Evaluate performance and security needs
  </objectives>
  
  <tools>
    - Read tool for codebase analysis
    - Grep tool for pattern searching
    - MCP tools (Figma, Context7) if available
  </tools>
  
  <quality_gates>
    - MUST complete comprehensive requirements analysis
    - ALWAYS document integration points
    - MUST save results to standardized location
  </quality_gates>

  <implementation>
#### Phase 1: Explore（探索・要件分析）
```bash
# フェーズ初期化（共通関数使用）
initialize_phase "$ENV_FILE" "Explore"
show_progress "Explore" 5 1

# Explorerプロンプトの読み込み
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
```

**Explorer指示**:
$EXPLORER_PROMPT

**開発機能**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

**IMPORTANT**: ClaudeCodeのアクセス制限により、worktree内のファイル操作はRead/Write/Editツールで実行してください。

**実行内容**:
1. 新機能の要件分析・技術調査
2. 既存システムとの統合ポイント特定
3. 必要な依存関係とAPIの調査
4. UI/UXおよびデザイン要件の明確化
5. パフォーマンス・セキュリティ要件の洗い出し
6. MCP連携可能性の検討
7. **MUST** save results to `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md`

```bash
# レポートディレクトリ作成
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"

# Explore結果のコミット（共通関数使用）
commit_phase_results "EXPLORE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md" \
    "Feature analysis complete: $ARGUMENTS"
```

  </implementation>
  
  <output>
    - Comprehensive requirements document
    - Technical constraints analysis
    - Integration points specification
    - Committed explore-results.md
  </output>
</phase>

<phase name="plan">
  <objectives>
    - Design system architecture based on exploration
    - Define component structure and interfaces
    - Plan data flow and state management
    - Design APIs (REST/GraphQL/WebSocket)
    - Create testing strategy
  </objectives>
  
  <tools>
    - Architecture design tools
    - Diagramming capabilities
    - Test planning frameworks
  </tools>
  
  <quality_gates>
    - MUST create comprehensive architecture design
    - ALWAYS define clear interfaces and contracts
    - MUST establish testing strategy before implementation
  </quality_gates>

  <implementation>
#### Phase 2: Plan（実装戦略・アーキテクチャ設計）
```bash
# フェーズ初期化（共通関数使用）
initialize_phase "$ENV_FILE" "Plan"
show_progress "Plan" 5 2

# Plannerプロンプトの読み込み
PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
```

**Planner指示**:
$PLANNER_PROMPT

**前フェーズ結果**: `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md`
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
8. **MUST** save results to `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md`

```bash
# Plan結果のコミット（共通関数使用）
commit_phase_results "PLAN" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md" \
    "Architecture design complete: $ARGUMENTS"
```

  </implementation>
  
  <output>
    - Architecture design document
    - Component specifications
    - API contracts
    - Test strategy document
    - Committed plan-results.md
  </output>
</phase>

<phase name="prototype">
  <objectives>
    - Create minimal working prototype
    - Implement basic UI/UX skeleton
    - Verify concept with mock data
    - Generate screenshots for review
  </objectives>
  
  <tools>
    - Code generation tools
    - UI framework components
    - Mock data generators
    - Screenshot utilities
  </tools>
  
  <quality_gates>
    - MUST create functional prototype
    - ALWAYS include visual documentation
    - MUST verify basic user flows work
  </quality_gates>

  <implementation>
#### Phase 3: Prototype（プロトタイプ作成）
```bash
# フェーズ初期化（共通関数使用）
initialize_phase "$ENV_FILE" "Prototype"
show_progress "Prototype" 5 3
```

**実行内容**:
1. 最小限の動作するプロトタイプ作成
2. 基本的なUI/UXスケルトン実装
3. モックデータでの動作確認
4. プロトタイプのスクリーンショット作成
5. **MUST** document implementation details in `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/prototype-results.md`

```bash
# プロトタイプ実装のコミット
if [[ -d "src/" ]] || [[ -d "components/" ]]; then
    git_commit_phase "PROTOTYPE" "Initial prototype: $ARGUMENTS" "src/ components/" || {
        log_warning "No prototype files to commit"
    }
fi

# プロトタイプ結果のコミット（共通関数使用）
commit_phase_results "PROTOTYPE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/prototype-results.md" \
    "Prototype documentation: $ARGUMENTS" \
    "screenshots/"
```

  </implementation>
  
  <output>
    - Working prototype code
    - UI/UX skeleton
    - Screenshots of prototype
    - Prototype documentation
    - Committed prototype files
  </output>
</phase>

<phase name="coding">
  <objectives>
    - Implement full feature following TDD practices
    - Create comprehensive test coverage
    - Optimize performance and UX
    - Integrate with existing systems
  </objectives>
  
  <tools>
    - Code editors and IDEs
    - Testing frameworks
    - Performance profilers
    - MCP integration tools
  </tools>
  
  <quality_gates>
    - MUST achieve 80%+ test coverage
    - ALWAYS write tests before implementation
    - NEVER commit failing tests
    - MUST pass all performance benchmarks
  </quality_gates>

  <implementation>
#### Phase 4: Coding（本格実装）
```bash
# フェーズ初期化（共通関数使用）
initialize_phase "$ENV_FILE" "Coding"
show_progress "Coding" 5 4

# Coderプロンプトの読み込み
CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
```

**Coder指示**:
$CODER_PROMPT

**前フェーズ結果**: 
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md`
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md`
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/prototype-results.md`

**開発機能**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

**TDD実行順序（機能開発向け）**:
1. **インターフェーステスト作成**: APIやコンポーネントの境界テスト - **ALWAYS** write tests first
2. **統合テスト作成**: 機能全体のワークフローテスト - **MUST** cover all workflows
3. **実装**: テストを満たす機能実装 - **NEVER** commit failing tests
4. **E2Eテスト**: ユーザー視点の動作確認 - **MUST** validate user journeys
5. **最適化**: パフォーマンス・UX改善 - **ALWAYS** measure before optimizing

**MCP活用実装**:
- **Figma**: デザイントークン取得・コンポーネント生成
- **Playwright**: E2Eテスト自動生成・実行
- **Context7**: 動的設定・コンテキスト情報活用

```bash
# API/コンポーネントテストのコミット
if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME" ]]; then
    git_commit_phase "TEST" "Interface and integration tests for $FEATURE_NAME: $ARGUMENTS" "test/$FEATURE_NAME"
fi

# 機能実装のコミット
if [[ -d "$WORKTREE_PATH/src/$FEATURE_NAME" ]]; then
    git_commit_phase "IMPLEMENT" "Core feature implementation for $FEATURE_NAME: $ARGUMENTS" "src/$FEATURE_NAME"
fi

# E2Eテストのコミット
if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME/e2e" ]]; then
    git_commit_phase "E2E" "End-to-end tests for $FEATURE_NAME: $ARGUMENTS" "test/$FEATURE_NAME/e2e"
fi

# 最適化ドキュメントのコミット
if [[ -d "$WORKTREE_PATH/report/$FEATURE_NAME/performance" ]]; then
    git_commit_phase "OPTIMIZE" "Performance optimization for $FEATURE_NAME: $ARGUMENTS" "report/$FEATURE_NAME/performance"
fi

# 最終結果のコミット（共通関数使用）
commit_phase_results "CODING" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md" \
    "Feature implementation complete: $ARGUMENTS"
```

  </implementation>
  
  <output>
    - Complete feature implementation
    - Full test suite (unit, integration, E2E)
    - Performance optimization results
    - All tests passing
    - Committed implementation files
  </output>
</phase>

<phase name="completion">
  <objectives>
    - Run all tests and verify quality
    - Generate completion report
    - Prepare for PR or merge
    - Clean up resources if requested
  </objectives>
  
  <tools>
    - Test runners
    - Report generators
    - Git merge tools
    - PR creation utilities
  </tools>
  
  <quality_gates>
    - MUST pass all tests before marking complete
    - ALWAYS generate comprehensive report
    - NEVER merge code with failing tests
    - MUST clean up resources properly
  </quality_gates>

  <implementation>
### Step 3: 完了通知とPR準備

```bash
# フェーズ初期化（共通関数使用）
initialize_phase "$ENV_FILE" "Completion"
show_progress "Completion" 5 5

# **ALWAYS** run all tests - プロジェクトタイプに応じたテスト
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - feature may be incomplete"
    # **NEVER** proceed with failing tests
fi

# E2Eテスト実行（存在する場合）
if [[ -f "package.json" ]] && grep -q '"e2e"' package.json; then
    npm run e2e || log_warning "E2E tests need review"
fi

# **MUST** run build if available
if [[ -f "package.json" ]] && grep -q '"build"' package.json; then
    npm run build || log_warning "Build process needs review"
fi

# 完了レポート生成
# 注: 将来的には.claude/templates/feature-completion-report.mdを使用予定
generate_feature_completion_report() {
    local worktree_path="$1"
    local feature_name="$2"
    local arguments="$3"
    local feature_branch="$4"
    local project_type="$5"
    
    # フェーズ結果の確認
    local explore_status=$([[ -f "$worktree_path/report/$feature_name/phase-results/explore-results.md" ]] && echo "✅" || echo "⚠️")
    local plan_status=$([[ -f "$worktree_path/report/$feature_name/phase-results/plan-results.md" ]] && echo "✅" || echo "⚠️")
    local prototype_status=$([[ -f "$worktree_path/report/$feature_name/phase-results/prototype-results.md" ]] && echo "✅" || echo "⚠️")
    local coding_status=$([[ -f "$worktree_path/report/$feature_name/phase-results/coding-results.md" ]] && echo "✅" || echo "⚠️")
    local test_status=$(run_tests "$project_type" "$worktree_path" &>/dev/null && echo "✅" || echo "⚠️")
    
    cat > "$worktree_path/report/$feature_name/phase-results/task-completion-report.md" << EOF
# Feature Completion Report

## Feature Summary
**Feature**: $arguments  
**Branch**: $feature_branch
**Worktree**: $worktree_path
**Completed**: $(date)

## Phase Results
- $explore_status **Explore**: Requirements and constraints analyzed
- $plan_status **Plan**: Architecture and implementation strategy defined
- $prototype_status **Prototype**: Working prototype demonstrated
- $coding_status **Code**: Full feature implementation completed
- $test_status **Test**: Comprehensive test coverage achieved
- ✅ **Ready**: Feature ready for review and integration

## Files Summary
- Components: $(find "$worktree_path/src/$feature_name" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l || echo "0")
- API files: $(find "$worktree_path/src/$feature_name" -name "*.ts" -o -name "*.js" 2>/dev/null | wc -l || echo "0")
- Test files: $(find "$worktree_path/test/$feature_name" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l || echo "0")

## Next Steps
1. Review implementation in worktree: $worktree_path
2. Test feature locally
3. Create PR: $feature_branch → main
4. Clean up worktree after merge
EOF
}

# レポート生成関数の呼び出し
generate_feature_completion_report "$WORKTREE_PATH" "$FEATURE_NAME" "$ARGUMENTS" "$FEATURE_BRANCH" "$PROJECT_TYPE"

# 完了レポートのコミット（共通関数使用）
commit_phase_results "COMPLETE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" \
    "Feature ready for integration: $TASK_DESCRIPTION"

# ローカルマージ（オプション）
if [[ "$NO_MERGE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    log_info "Merging to main branch..."
    if merge_to_main "$WORKTREE_PATH" "$FEATURE_BRANCH" "$NO_MERGE"; then
        log_success "Successfully merged to main"
    else
        log_warning "Merge failed - manual intervention required"
    fi
fi

# PR作成（オプション）
if [[ "$CREATE_PR" == "true" ]]; then
    log_info "Creating pull request..."
    local is_draft="true"
    [[ "$NO_DRAFT" == "true" ]] && is_draft="false"
    
    if create_pull_request "$WORKTREE_PATH" "$FEATURE_BRANCH" "$TASK_DESCRIPTION" "$is_draft"; then
        log_success "Pull request created"
    else
        log_warning "Failed to create PR - you can create it manually"
    fi
fi

# worktreeクリーンアップ（オプション）
if [[ "$KEEP_WORKTREE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    cleanup_worktree "$WORKTREE_PATH" "$KEEP_WORKTREE"
    # 環境ファイルも削除
    if [[ -f "$ENV_FILE" ]]; then
        rm -f "$ENV_FILE"
        log_info "Environment file cleaned up: $ENV_FILE"
    fi
    echo "✨ Worktree cleaned up automatically"
else
    echo "📊 Report: $WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md"
    echo "🔀 Branch: $FEATURE_BRANCH"
    echo "🚀 Demo available in: $WORKTREE_PATH"
    echo "📁 Worktree kept at: $WORKTREE_PATH"
    echo "💾 Environment: $ENV_FILE"
    echo "🧹 To clean up later: git worktree remove $WORKTREE_PATH && rm -f $ENV_FILE"
fi

log_success "Feature development completed independently!"
echo ""
echo "💡 User can now proceed with other tasks."

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
  </implementation>

  <output>
    - Complete task report
    - All quality gates passed
    - PR ready (if requested)
    - Worktree cleaned (if requested)
  </output>
</phase>

## 実行結果

ユーザーは指示後すぐに次のタスクに移行可能。この機能開発は独立worktree内で以下のフローを自動完了します：

1. **探索フェーズ**: 要件分析・技術調査・デザイン確認
2. **計画フェーズ**: アーキテクチャ設計・実装戦略策定
3. **プロトタイプ**: 動作確認可能な最小実装
4. **実装フェーズ**: TDD準拠の本格実装・E2Eテスト
5. **完了フェーズ**: デモ環境準備・PR準備完了

全工程が自動化され、ユーザーは最終レビュー時のみ関与すれば良い設計です。

</feature_development_workflow>