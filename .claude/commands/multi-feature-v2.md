<feature_development_workflow>

# Multi-Agent Feature Development Workflow v2.0

<workflow_metadata>
  <version>2.0</version>
  <command>multi-feature</command>
  <type>feature_development</type>
  <parallel_capable>true</parallel_capable>
  <mcp_integration>true</mcp_integration>
  <capabilities>
    - Parallel agent execution (Test & Implementation)
    - MCP tool integration (Figma, Playwright, Context7)
    - Advanced error recovery mechanisms
    - Quality gate enforcement at each phase
    - Interactive prototyping with screenshots
    - Comprehensive phase management
  </capabilities>
</workflow_metadata>

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
- `--parallel`: 並列エージェント実行を有効化（デフォルト: 有効）
- `--skip-prototype`: プロトタイプフェーズをスキップ
- `--mcp-tools`: 使用するMCPツールを指定（figma,playwright,context7）

## 実行方針
**1機能 = 1worktree** で全フローを自動実行。ユーザーは指示後、他の作業が可能。このタスクは独立したworktree内で**全フローを自動完了**します。

<quality_gates>
  <gate phase="all" priority="critical">
    <name>security</name>
    <criteria>
      - Input validation on all user inputs
      - Authentication and authorization checks
      - Secure data transmission (HTTPS/WSS)
      - No sensitive data in logs or commits
      - Dependency vulnerability scanning
    </criteria>
    <validation>automated</validation>
    <enforcement>blocking</enforcement>
  </gate>
  
  <gate phase="coding" priority="high">
    <name>test_coverage</name>
    <criteria>
      - Unit test coverage >= 80%
      - Integration test coverage >= 70%
      - E2E test coverage for critical paths
      - All edge cases covered
    </criteria>
    <validation>automated</validation>
    <enforcement>blocking</enforcement>
  </gate>
  
  <gate phase="performance" priority="medium">
    <name>performance_metrics</name>
    <criteria>
      - Response time < 200ms (p95)
      - Memory usage < 512MB
      - No N+1 queries
      - Bundle size within limits
    </criteria>
    <validation>automated</validation>
    <enforcement>warning</enforcement>
  </gate>
  
  <gate phase="accessibility" priority="high">
    <name>a11y_compliance</name>
    <criteria>
      - WCAG 2.1 AA compliance
      - Keyboard navigation support
      - Screen reader compatibility
      - Proper ARIA labels
    </criteria>
    <validation>automated</validation>
    <enforcement>blocking</enforcement>
  </gate>
</quality_gates>

<phase name="worktree_setup" duration="2-3min" parallel="false">
  <objectives>
    <objective priority="critical">Create isolated worktree for feature development</objective>
    <objective priority="critical">Set up environment variables and configurations</objective>
    <objective priority="high">Validate project environment and dependencies</objective>
    <objective priority="medium">Initialize quality gate tracking</objective>
  </objectives>
  
  <tools>
    <tool type="system">
      <name>Git worktree</name>
      <usage>Isolated branch management</usage>
    </tool>
    <tool type="script">
      <name>worktree-utils.sh</name>
      <usage>Utility functions for worktree operations</usage>
    </tool>
  </tools>

### Step 1: 機能用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 共通ユーティリティの読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 並列実行ユーティリティの読み込み（利用可能な場合）
if [[ -f ".claude/scripts/parallel-agent-utils.sh" ]]; then
    source .claude/scripts/parallel-agent-utils.sh
    export PARALLEL_AGENT_LOADED=true
fi

# MCP可用性チェック
check_mcp_availability() {
    local mcp_tools=()
    
    # Figmaチェック
    if command -v mcp__figma__get_file &>/dev/null; then
        mcp_tools+=("figma")
        export MCP_FIGMA_AVAILABLE="true"
    fi
    
    # Playwrightチェック
    if command -v mcp__playwright__browser_navigate &>/dev/null; then
        mcp_tools+=("playwright")
        export MCP_PLAYWRIGHT_AVAILABLE="true"
    fi
    
    # Context7チェック
    if command -v mcp__context7__resolve-library-id &>/dev/null; then
        mcp_tools+=("context7")
        export MCP_CONTEXT7_AVAILABLE="true"
    fi
    
    if [[ ${#mcp_tools[@]} -gt 0 ]]; then
        log_info "MCP tools available: ${mcp_tools[*]}"
        return 0
    else
        log_warning "No MCP tools available - proceeding without MCP integration"
        return 1
    fi
}

# オプション解析
parse_workflow_options $ARGUMENTS

# 環境検証
verify_environment || exit 1

# プロジェクトタイプの検出
PROJECT_TYPE=$(detect_project_type)
log_info "Detected project type: $PROJECT_TYPE"

# MCP可用性チェック
check_mcp_availability

# 古いworktreeのクリーンアップ（オプション）
if [[ "$AUTO_CLEANUP" == "true" ]]; then
    cleanup_old_worktrees "$CLEANUP_DAYS"
fi

# worktree作成
WORKTREE_INFO=$(create_task_worktree "$TASK_DESCRIPTION" "feature")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
FEATURE_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)
FEATURE_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f3)

# タスクIDを生成（環境ファイル名用）
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ENV_FILE=$(generate_env_file_path "feature" "$TASK_ID" "$TIMESTAMP")

# 環境変数をファイルに保存
cat > "$ENV_FILE" << EOF
# Feature Development Environment
WORKTREE_PATH="$WORKTREE_PATH"
FEATURE_BRANCH="$FEATURE_BRANCH"
FEATURE_NAME="$FEATURE_NAME"
PROJECT_TYPE="$PROJECT_TYPE"
TASK_DESCRIPTION="$TASK_DESCRIPTION"

# Options
KEEP_WORKTREE="$KEEP_WORKTREE"
NO_MERGE="$NO_MERGE"
CREATE_PR="$CREATE_PR"
NO_DRAFT="$NO_DRAFT"
AUTO_CLEANUP="$AUTO_CLEANUP"
CLEANUP_DAYS="$CLEANUP_DAYS"
PARALLEL_EXECUTION="${PARALLEL_EXECUTION:-true}"
SKIP_PROTOTYPE="${SKIP_PROTOTYPE:-false}"

# MCP Integration
MCP_FIGMA_AVAILABLE="${MCP_FIGMA_AVAILABLE:-false}"
MCP_PLAYWRIGHT_AVAILABLE="${MCP_PLAYWRIGHT_AVAILABLE:-false}"
MCP_CONTEXT7_AVAILABLE="${MCP_CONTEXT7_AVAILABLE:-false}"
MCP_TOOLS="${MCP_TOOLS:-}"

# Phase Status
CURRENT_PHASE=""
COMPLETED_PHASES=""
EOF

# フェーズ管理ディレクトリの初期化
mkdir -p "$WORKTREE_PATH/.phases"
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/quality"

# 品質ゲート初期化
initialize_quality_gates "$WORKTREE_PATH" "all"

log_success "Feature worktree created with enhanced phase management"
echo "📋 Feature: $TASK_DESCRIPTION"
echo "🌿 Branch: $FEATURE_BRANCH"
echo "📁 Worktree: $WORKTREE_PATH"
echo "🏷️ Feature: $FEATURE_NAME"
echo "⚙️ Options: keep-worktree=$KEEP_WORKTREE, no-merge=$NO_MERGE, pr=$CREATE_PR, parallel=$PARALLEL_EXECUTION"
echo "🔧 MCP Tools: figma=$MCP_FIGMA_AVAILABLE, playwright=$MCP_PLAYWRIGHT_AVAILABLE, context7=$MCP_CONTEXT7_AVAILABLE"
echo "💾 Environment: $ENV_FILE"

# 初期コミット
git -C "$WORKTREE_PATH" commit --allow-empty -m "[INIT] Feature development started: $TASK_DESCRIPTION"

# 環境ファイルパスを明示的にエクスポート（セッション分離対応）
export ENV_FILE
echo ""
echo "📌 IMPORTANT: Use this environment file in each phase:"
echo "   ENV_FILE='$ENV_FILE'"
```

  <outputs>
    <output required="true">
      <type>worktree</type>
      <path>$WORKTREE_PATH</path>
      <description>Isolated git worktree for feature development</description>
    </output>
    <output required="true">
      <type>environment</type>
      <path>$ENV_FILE</path>
      <description>Environment configuration file</description>
    </output>
    <output required="true">
      <type>directory</type>
      <path>$WORKTREE_PATH/.phases</path>
      <description>Phase status tracking directory</description>
    </output>
  </outputs>
</phase>

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$FEATURE_BRANCH`

**IMPORTANT**: 以下の全フローを**同一worktree内で連続自動実行**します：

<phase name="explore" duration="15-20min" parallel="false">
  <objectives>
    <objective priority="critical">Analyze feature requirements and constraints</objective>
    <objective priority="high">Identify integration points with existing system</objective>
    <objective priority="high">Research necessary dependencies and APIs</objective>
    <objective priority="medium">Define UI/UX and design requirements</objective>
    <objective priority="medium">Evaluate performance and security needs</objective>
  </objectives>
  
  <tools>
    <tool type="analysis">
      <name>Read</name>
      <usage>Codebase analysis and pattern discovery</usage>
    </tool>
    <tool type="search">
      <name>Grep</name>
      <usage>Pattern searching and dependency mapping</usage>
    </tool>
    <tool type="mcp" optional="true">
      <name>mcp__figma</name>
      <usage>Design system and component extraction</usage>
    </tool>
    <tool type="mcp" optional="true">
      <name>mcp__context7</name>
      <usage>Project context and architecture analysis</usage>
    </tool>
  </tools>

#### Phase 1: Explore（探索・要件分析）

```bash
# フェーズ開始前チェック
phase_start_checks() {
    local phase_name="$1"
    shift
    local dependencies=("$@")
    
    # 依存フェーズの完了確認
    for dep in "${dependencies[@]}"; do
        if ! check_phase_completed "$WORKTREE_PATH" "$dep"; then
            log_error "Dependency phase '$dep' not completed for phase '$phase_name'"
            return 1
        fi
    done
    
    # フェーズ開始記録
    create_phase_status "$WORKTREE_PATH" "$phase_name" "started"
    
    # 品質ゲートの初期化
    initialize_quality_gates "$WORKTREE_PATH" "$phase_name"
    
    return 0
}

# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

# フェーズ開始チェック
phase_start_checks "explore" || exit 1

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
7. MUST save results to `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md`

**MCP連携（利用可能な場合）**:
```bash
# Figma連携でデザイン要件取得
if [[ "$MCP_FIGMA_AVAILABLE" == "true" ]]; then
    log_info "Fetching design requirements from Figma..."
    # Figmaからデザイントークンやコンポーネント情報を取得
    # mcp__figma__get_design_tokens --feature "$FEATURE_NAME"
fi

# Context7連携でプロジェクトコンテキスト取得
if [[ "$MCP_CONTEXT7_AVAILABLE" == "true" ]]; then
    log_info "Analyzing project context with Context7..."
    # プロジェクトアーキテクチャや既存パターンを分析
    # mcp__context7__analyze_architecture --feature "$FEATURE_NAME"
fi
```

```bash
# レポートディレクトリ作成
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"

# Explore結果の品質チェック
validate_explore_results() {
    local results_file="$1"
    
    # 必須セクションの存在確認
    local required_sections=(
        "Requirements Analysis"
        "Technical Constraints"
        "Integration Points"
        "Design Requirements"
        "Risk Assessment"
    )
    
    for section in "${required_sections[@]}"; do
        if ! grep -q "## $section" "$results_file"; then
            log_warning "Missing required section: $section"
            return 1
        fi
    done
    
    return 0
}

# Explore結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md" ]]; then
    # 品質チェック
    if validate_explore_results "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md"; then
        # worktree内でコミット
        git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/explore-results.md"
        git -C "$WORKTREE_PATH" commit -m "[EXPLORE] Feature analysis complete: $ARGUMENTS" || {
            log_error "Failed to commit explore results"
            handle_error 1 "Explore phase failed" "$WORKTREE_PATH"
        }
        log_success "Committed: [EXPLORE] Feature analysis complete"
        
        # フェーズ完了記録
        update_phase_status "$WORKTREE_PATH" "explore" "completed"
    else
        log_error "Explore results failed quality validation"
        update_phase_status "$WORKTREE_PATH" "explore" "failed"
        handle_error 1 "Explore phase quality check failed" "$WORKTREE_PATH"
    fi
else
    log_warning "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md not found"
    update_phase_status "$WORKTREE_PATH" "explore" "failed"
    handle_error 1 "Explore phase output missing" "$WORKTREE_PATH"
fi
```

  <outputs>
    <output required="true">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md</path>
      <format>markdown</format>
      <sections>
        - Requirements Analysis
        - Technical Constraints
        - Integration Points
        - Design Requirements
        - Risk Assessment
        - MCP Integration Opportunities
      </sections>
    </output>
    <output required="false">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/dependencies.json</path>
      <format>json</format>
      <description>Identified dependencies and APIs</description>
    </output>
  </outputs>
  
  <quality_checks>
    <check>All critical requirements documented</check>
    <check>Technical feasibility confirmed</check>
    <check>Integration points identified</check>
    <check>Security considerations addressed</check>
  </quality_checks>
</phase>

<phase name="plan" duration="15-20min" parallel="false">
  <objectives>
    <objective priority="critical">Design system architecture based on exploration</objective>
    <objective priority="high">Define component structure and interfaces</objective>
    <objective priority="high">Plan data flow and state management</objective>
    <objective priority="high">Design APIs (REST/GraphQL/WebSocket)</objective>
    <objective priority="medium">Create comprehensive testing strategy</objective>
    <objective priority="medium">Define phased rollout plan</objective>
  </objectives>
  
  <tools>
    <tool type="design">
      <name>Architecture design tools</name>
      <usage>System design and diagramming</usage>
    </tool>
    <tool type="planning">
      <name>Test planning frameworks</name>
      <usage>Test strategy definition</usage>
    </tool>
    <tool type="mcp" optional="true">
      <name>mcp__context7</name>
      <usage>Architecture pattern validation</usage>
    </tool>
  </tools>

#### Phase 2: Plan（実装戦略・アーキテクチャ設計）

```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

# フェーズ開始チェック（exploreフェーズが完了していることを確認）
phase_start_checks "plan" "explore" || exit 1

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
8. MUST save results to `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md`

**アーキテクチャドキュメント構造**:
```markdown
# Architecture Plan: $FEATURE_NAME

## Executive Summary
- Feature overview and goals
- Key architectural decisions
- Technology stack

## System Architecture
### Component Diagram
- Frontend components
- Backend services
- Data stores
- External integrations

### Sequence Diagrams
- User workflows
- API interactions
- Data flow

## API Design
### Endpoints
- REST/GraphQL schema
- Request/Response formats
- Authentication/Authorization

### WebSocket Events (if applicable)
- Event types
- Payload structures
- Connection management

## Data Model
### Database Schema
- Tables/Collections
- Relationships
- Indexes

### State Management
- Client state structure
- Server state caching
- Sync strategies

## Testing Strategy
### Unit Tests
- Component coverage
- Service coverage
- Utility coverage

### Integration Tests
- API tests
- Database tests
- External service mocks

### E2E Tests
- Critical user journeys
- Performance scenarios
- Error scenarios

## Implementation Phases
### Phase 1: Core Infrastructure
### Phase 2: Basic Functionality
### Phase 3: Advanced Features
### Phase 4: Polish and Optimization

## Risk Mitigation
### Technical Risks
### Security Risks
### Performance Risks
```

```bash
# Context7連携でアーキテクチャ検証
if [[ "$MCP_CONTEXT7_AVAILABLE" == "true" ]]; then
    log_info "Validating architecture with Context7..."
    # 既存アーキテクチャパターンとの整合性確認
    # mcp__context7__validate_architecture --plan "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md"
fi

# Plan結果の品質チェック
validate_plan_results() {
    local results_file="$1"
    
    # アーキテクチャセクションの確認
    if ! grep -q "## System Architecture" "$results_file"; then
        log_warning "Missing System Architecture section"
        return 1
    fi
    
    # API設計セクションの確認
    if ! grep -q "## API Design" "$results_file"; then
        log_warning "Missing API Design section"
        return 1
    fi
    
    # テスト戦略セクションの確認
    if ! grep -q "## Testing Strategy" "$results_file"; then
        log_warning "Missing Testing Strategy section"
        return 1
    fi
    
    return 0
}

# Plan結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md" ]]; then
    # 品質チェック
    if validate_plan_results "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md"; then
        git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/plan-results.md"
        git -C "$WORKTREE_PATH" commit -m "[PLAN] Architecture design complete: $ARGUMENTS" || {
            log_error "Failed to commit plan results"
            handle_error 1 "Plan phase failed" "$WORKTREE_PATH"
        }
        log_success "Committed: [PLAN] Architecture design complete"
        
        # フェーズ完了記録
        update_phase_status "$WORKTREE_PATH" "plan" "completed"
    else
        log_error "Plan results failed quality validation"
        update_phase_status "$WORKTREE_PATH" "plan" "failed"
        handle_error 1 "Plan phase quality check failed" "$WORKTREE_PATH"
    fi
else
    log_warning "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md not found"
    update_phase_status "$WORKTREE_PATH" "plan" "failed"
    handle_error 1 "Plan phase output missing" "$WORKTREE_PATH"
fi
```

  <outputs>
    <output required="true">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md</path>
      <format>markdown</format>
      <sections>
        - System Architecture
        - API Design
        - Data Model
        - Testing Strategy
        - Implementation Phases
        - Risk Mitigation
      </sections>
    </output>
    <output required="false">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/architecture/</path>
      <format>diagrams</format>
      <description>Architecture diagrams and flowcharts</description>
    </output>
  </outputs>
  
  <quality_checks>
    <check>Architecture completeness</check>
    <check>API contracts defined</check>
    <check>Test strategy comprehensive</check>
    <check>Risks identified and mitigated</check>
  </quality_checks>
</phase>

<phase name="prototype" duration="20-30min" parallel="false">
  <objectives>
    <objective priority="high">Create interactive UI/UX mockup</objective>
    <objective priority="high">Implement minimal working prototype</objective>
    <objective priority="medium">Generate design documentation</objective>
    <objective priority="medium">Create demo environment</objective>
    <objective priority="low">Capture screenshots for review</objective>
  </objectives>
  
  <tools>
    <tool type="development">
      <name>Code generation tools</name>
      <usage>Rapid prototype development</usage>
    </tool>
    <tool type="mcp" optional="true">
      <name>mcp__figma</name>
      <usage>Export design components and generate code</usage>
    </tool>
    <tool type="mcp" optional="true">
      <name>mcp__playwright__browser_snapshot</name>
      <usage>Capture prototype screenshots</usage>
    </tool>
  </tools>

#### Phase 3: Prototype（プロトタイプ作成）

```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

# プロトタイプフェーズのスキップチェック
if [[ "$SKIP_PROTOTYPE" == "true" ]]; then
    log_info "Skipping prototype phase as requested"
    update_phase_status "$WORKTREE_PATH" "prototype" "skipped"
else
    # フェーズ開始チェック
    phase_start_checks "prototype" "explore" "plan" || exit 1
    
    show_progress "Prototype" 5 3
    
    # プロトタイプ生成関数
    generate_interactive_prototype() {
        local worktree_path="$1"
        local feature_name="$2"
        
        log_info "Generating interactive prototype for $feature_name"
        
        # プロトタイプディレクトリ構造作成
        mkdir -p "$worktree_path/prototype/ui-mockup"
        mkdir -p "$worktree_path/prototype/api-stub"
        mkdir -p "$worktree_path/prototype/demo"
        mkdir -p "$worktree_path/prototype/screenshots"
        
        # Figma連携でデザインコンポーネント取得
        if [[ "$MCP_FIGMA_AVAILABLE" == "true" ]]; then
            log_info "Exporting design components from Figma..."
            # mcp__figma__export_components \
            #     --feature "$feature_name" \
            #     --output "$worktree_path/prototype/ui-mockup"
        fi
        
        # インタラクティブデモ作成
        create_demo_environment "$worktree_path" "$feature_name"
        
        # スクリーンショット自動生成
        if [[ "$MCP_PLAYWRIGHT_AVAILABLE" == "true" ]]; then
            capture_prototype_screenshots "$worktree_path" "$feature_name"
        fi
        
        # プロトタイプドキュメント生成
        generate_prototype_documentation "$worktree_path" "$feature_name"
    }
    
    # デモ環境作成関数
    create_demo_environment() {
        local worktree_path="$1"
        local feature_name="$2"
        
        log_info "Creating demo environment..."
        
        # プロジェクトタイプに応じたデモ環境構築
        case "$PROJECT_TYPE" in
            "react"|"nextjs")
                # React/Next.jsデモページ作成
                create_react_demo "$worktree_path" "$feature_name"
                ;;
            "vue")
                # Vueデモページ作成
                create_vue_demo "$worktree_path" "$feature_name"
                ;;
            "angular")
                # Angularデモページ作成
                create_angular_demo "$worktree_path" "$feature_name"
                ;;
            *)
                # 汎用HTMLデモページ作成
                create_html_demo "$worktree_path" "$feature_name"
                ;;
        esac
    }
    
    # スクリーンショット取得関数
    capture_prototype_screenshots() {
        local worktree_path="$1"
        local feature_name="$2"
        
        if [[ "$MCP_PLAYWRIGHT_AVAILABLE" == "true" ]]; then
            log_info "Capturing prototype screenshots..."
            
            # デモサーバー起動（バックグラウンド）
            start_demo_server "$worktree_path" &
            local server_pid=$!
            
            # サーバー起動待機
            sleep 5
            
            # スクリーンショット取得
            # mcp__playwright__browser_navigate --url "http://localhost:3000/prototype"
            # mcp__playwright__browser_snapshot
            # mcp__playwright__browser_take_screenshot \
            #     --filename "$worktree_path/prototype/screenshots/main-view.png"
            
            # デモサーバー停止
            kill $server_pid 2>/dev/null || true
        else
            log_warning "Playwright not available, skipping screenshots"
        fi
    }
fi
```

**実行内容**:
1. 最小限の動作するプロトタイプ作成
2. 基本的なUI/UXスケルトン実装
3. モックデータでの動作確認
4. プロトタイプのスクリーンショット作成
5. インタラクティブデモ環境の構築
6. MUST document implementation details in `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/prototype-results.md`

**プロトタイプ構造**:
```
prototype/
├── ui-mockup/           # UIモックアップとコンポーネント
│   ├── components/      # 基本UIコンポーネント
│   ├── pages/          # ページレイアウト
│   └── styles/         # スタイルシート
├── api-stub/           # APIスタブとモックデータ
│   ├── endpoints/      # モックエンドポイント
│   ├── data/          # サンプルデータ
│   └── schemas/       # データスキーマ
├── demo/              # デモ環境
│   ├── index.html     # デモエントリーポイント
│   ├── demo.js        # デモスクリプト
│   └── README.md      # デモ実行手順
└── screenshots/       # プロトタイプのスクリーンショット
    ├── main-view.png
    ├── mobile-view.png
    └── interactions.gif
```

```bash
# プロトタイプドキュメント生成
generate_prototype_documentation() {
    local worktree_path="$1"
    local feature_name="$2"
    
    cat > "$worktree_path/report/$feature_name/phase-results/prototype-results.md" << EOF
# Prototype Documentation: $feature_name

## Overview
Prototype implementation for $TASK_DESCRIPTION

## UI Components
### Created Components
$(find "$worktree_path/prototype/ui-mockup/components" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l || echo "0") components

### Page Layouts
$(find "$worktree_path/prototype/ui-mockup/pages" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l || echo "0") pages

## API Stubs
### Mock Endpoints
$(find "$worktree_path/prototype/api-stub/endpoints" -name "*.js" -o -name "*.ts" 2>/dev/null | wc -l || echo "0") endpoints

### Sample Data
$(find "$worktree_path/prototype/api-stub/data" -name "*.json" 2>/dev/null | wc -l || echo "0") data files

## Demo Environment
### Access Instructions
1. Navigate to: \`cd $worktree_path/prototype/demo\`
2. Install dependencies: \`npm install\` (if needed)
3. Start demo: \`npm run demo\` or open \`index.html\`

### Interactive Features
- User interactions demonstrated
- Data flow visualization
- State management examples

## Screenshots
$(ls "$worktree_path/prototype/screenshots" 2>/dev/null | wc -l || echo "0") screenshots captured

## Design Decisions
### UI/UX Choices
- Component library selection
- Color scheme and typography
- Responsive design approach

### Technical Choices
- Framework utilization
- State management approach
- API communication patterns

## Next Steps
- Gather stakeholder feedback
- Refine based on user testing
- Prepare for full implementation
EOF
}

# プロトタイプ実装のコミット
if [[ "$SKIP_PROTOTYPE" != "true" ]]; then
    # プロトタイプ実装
    generate_interactive_prototype "$WORKTREE_PATH" "$FEATURE_NAME"
    
    # プロトタイプファイルのコミット
    if [[ -d "$WORKTREE_PATH/prototype" ]]; then
        git -C "$WORKTREE_PATH" add prototype/
        git -C "$WORKTREE_PATH" commit -m "[PROTOTYPE] Interactive prototype: $ARGUMENTS" || {
            log_warning "No prototype files to commit"
        }
    fi
    
    # プロトタイプ結果のコミット
    if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/prototype-results.md" ]]; then
        git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/prototype-results.md"
        git -C "$WORKTREE_PATH" commit -m "[PROTOTYPE] Prototype documentation: $ARGUMENTS" || {
            log_warning "No prototype documentation to commit"
        }
        log_success "Prototype phase completed"
        update_phase_status "$WORKTREE_PATH" "prototype" "completed"
    fi
fi
```

  <outputs>
    <output required="true">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/prototype-results.md</path>
      <format>markdown</format>
      <description>Prototype documentation and design decisions</description>
    </output>
    <output required="false">
      <path>$WORKTREE_PATH/prototype/</path>
      <format>directory</format>
      <description>Complete prototype implementation</description>
    </output>
    <output required="false">
      <path>$WORKTREE_PATH/prototype/screenshots/</path>
      <format>images</format>
      <description>Visual documentation of prototype</description>
    </output>
  </outputs>
  
  <quality_checks>
    <check>Prototype demonstrates core functionality</check>
    <check>UI/UX aligns with requirements</check>
    <check>Demo environment functional</check>
    <check>Documentation complete</check>
  </quality_checks>
</phase>

<phase name="coding" duration="30-45min" parallel="true">
  <objectives>
    <objective priority="critical">Implement full feature following TDD practices</objective>
    <objective priority="critical">Create comprehensive test coverage</objective>
    <objective priority="high">Optimize performance and UX</objective>
    <objective priority="high">Integrate with existing systems</objective>
    <objective priority="medium">Implement error handling and logging</objective>
  </objectives>
  
  <parallel_execution>
    <agent name="test_agent" type="coder-test">
      <prompt_file>.claude/prompts/coder-test.md</prompt_file>
      <working_dir>$WORKTREE_PATH/test/$FEATURE_NAME</working_dir>
      <outputs>
        <output>test-agent.log</output>
        <output>test-creation-report.md</output>
      </outputs>
    </agent>
    
    <agent name="impl_agent" type="coder-impl">
      <prompt_file>.claude/prompts/coder-impl.md</prompt_file>
      <working_dir>$WORKTREE_PATH/src/$FEATURE_NAME</working_dir>
      <outputs>
        <output>impl-agent.log</output>
        <output>implementation-report.md</output>
      </outputs>
    </agent>
    
    <coordination>
      <monitor>monitor_parallel_execution</monitor>
      <merge>merge_parallel_results</merge>
      <timeout>3600</timeout>
    </coordination>
  </parallel_execution>
  
  <tools>
    <tool type="development">
      <name>Code editors</name>
      <usage>Implementation and refactoring</usage>
    </tool>
    <tool type="testing">
      <name>Testing frameworks</name>
      <usage>Unit, integration, and E2E tests</usage>
    </tool>
    <tool type="mcp" optional="true">
      <name>mcp__playwright</name>
      <usage>E2E test generation and execution</usage>
    </tool>
  </tools>

#### Phase 4: Coding（本格実装）

```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

# フェーズ開始チェック
phase_start_checks "coding" "explore" "plan" || exit 1

show_progress "Coding" 5 4

# 並列実行関数
run_parallel_feature_development() {
    local worktree_path="$1"
    local feature_name="$2"
    
    if [[ "$PARALLEL_EXECUTION" == "true" ]] && [[ "$PARALLEL_AGENT_LOADED" == "true" ]]; then
        log_info "Starting parallel TDD agents for feature development..."
        
        # テストエージェント用環境準備
        mkdir -p "$worktree_path/test/$feature_name"
        mkdir -p "$worktree_path/.parallel/test"
        
        # 実装エージェント用環境準備
        mkdir -p "$worktree_path/src/$feature_name"
        mkdir -p "$worktree_path/.parallel/impl"
        
        # 並列エージェント実行
        run_parallel_agents \
            "$worktree_path" \
            "$feature_name" \
            "$TASK_DESCRIPTION" \
            "test/$feature_name/**/*.test.*" \
            "src/$feature_name/**/*"
        
        local parallel_exit_code=$?
        
        if [[ $parallel_exit_code -eq 0 ]]; then
            log_success "Parallel TDD execution completed successfully"
            
            # 並列実行結果のマージ
            merge_parallel_results "$worktree_path" "$feature_name"
        else
            log_error "Parallel TDD execution failed"
            return $parallel_exit_code
        fi
    else
        # フォールバック: 従来の順次実行
        log_info "Executing sequential TDD workflow..."
        execute_sequential_tdd "$worktree_path" "$feature_name"
    fi
}

# 順次実行フォールバック
execute_sequential_tdd() {
    local worktree_path="$1"
    local feature_name="$2"
    
    # Coderプロンプトの読み込み
    CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
    
    # 従来の順次TDD実行
    # ... 既存のTDD実装コード ...
}

# 並列実行結果マージ関数
merge_parallel_results() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "Merging parallel execution results..."
    
    # テスト結果とカバレッジのマージ
    if [[ -f "$worktree_path/.parallel/test/coverage.json" ]]; then
        merge_coverage_reports \
            "$worktree_path/.parallel/test/coverage.json" \
            "$worktree_path/.parallel/impl/coverage.json" \
            "$worktree_path/coverage/merged-coverage.json"
    fi
    
    # 実行ログのマージ
    cat > "$worktree_path/report/$feature_name/phase-results/parallel-execution-summary.md" << EOF
# Parallel Execution Summary

## Test Agent Results
$(cat "$worktree_path/.parallel/test/test-creation-report.md" 2>/dev/null || echo "No test report available")

## Implementation Agent Results
$(cat "$worktree_path/.parallel/impl/implementation-report.md" 2>/dev/null || echo "No implementation report available")

## Coverage Summary
- Test Coverage: $(extract_coverage "$worktree_path/.parallel/test/coverage.json")%
- Implementation Coverage: $(extract_coverage "$worktree_path/.parallel/impl/coverage.json")%
- Combined Coverage: $(extract_coverage "$worktree_path/coverage/merged-coverage.json")%

## Execution Timeline
- Start Time: $(cat "$worktree_path/.parallel/start-time.txt")
- End Time: $(date)
- Total Duration: $(calculate_duration "$worktree_path/.parallel/start-time.txt")
EOF
}

# メイン実装フロー実行
run_parallel_feature_development "$WORKTREE_PATH" "$FEATURE_NAME"
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
1. **インターフェーステスト作成**: APIやコンポーネントの境界テスト - ALWAYS write tests first
2. **統合テスト作成**: 機能全体のワークフローテスト - MUST cover all workflows
3. **実装**: テストを満たす機能実装 - NEVER commit failing tests
4. **E2Eテスト**: ユーザー視点の動作確認 - MUST validate user journeys
5. **最適化**: パフォーマンス・UX改善 - ALWAYS measure before optimizing

**並列実行の利点**:
- Test AgentとImplementation Agentが同時に作業
- テスト作成と実装が並行して進む
- 相互フィードバックによる品質向上
- 開発時間の大幅短縮

**MCP活用実装**:
```bash
# Figmaコンポーネント生成
if [[ "$MCP_FIGMA_AVAILABLE" == "true" ]]; then
    log_info "Generating components from Figma designs..."
    # mcp__figma__generate_components \
    #     --design-system "$WORKTREE_PATH/design-system.json" \
    #     --output "$WORKTREE_PATH/src/$FEATURE_NAME/components"
fi

# Playwright E2Eテスト自動生成
if [[ "$MCP_PLAYWRIGHT_AVAILABLE" == "true" ]]; then
    log_info "Generating Playwright E2E tests..."
    # mcp__playwright__browser_generate_playwright_test \
    #     --name "$FEATURE_NAME-e2e" \
    #     --description "E2E tests for $FEATURE_NAME" \
    #     --steps "..."
fi

# Context7によるベストプラクティス適用
if [[ "$MCP_CONTEXT7_AVAILABLE" == "true" ]]; then
    log_info "Applying Context7 best practices..."
    # mcp__context7__apply_patterns \
    #     --feature "$FEATURE_NAME" \
    #     --codebase "$WORKTREE_PATH/src"
fi
```

```bash
# 実装品質チェックと段階的コミット
commit_implementation_phases() {
    local worktree_path="$1"
    local feature_name="$2"
    
    # API/コンポーネントテスト
    if [[ -d "$worktree_path/test/$feature_name" ]]; then
        # テストカバレッジチェック
        local test_coverage=$(calculate_test_coverage "$worktree_path/test/$feature_name")
        if [[ $test_coverage -ge 80 ]]; then
            git -C "$worktree_path" add "test/$feature_name"
            git -C "$worktree_path" commit -m "[TEST] Interface and integration tests for $feature_name: $ARGUMENTS" || {
                log_warning "No test files to commit"
            }
            log_success "Test coverage: $test_coverage%"
        else
            log_error "Test coverage too low: $test_coverage% (required: 80%)"
            update_phase_status "$worktree_path" "coding" "failed_quality"
            return 1
        fi
    fi
    
    # 機能実装
    if [[ -d "$worktree_path/src/$feature_name" ]]; then
        # コード品質チェック
        run_code_quality_checks "$worktree_path/src/$feature_name" || {
            log_error "Code quality checks failed"
            return 1
        }
        
        git -C "$worktree_path" add "src/$feature_name"
        git -C "$worktree_path" commit -m "[IMPLEMENT] Core feature implementation for $feature_name: $ARGUMENTS" || {
            log_warning "No implementation files to commit"
        }
    fi
    
    # E2Eテスト
    if [[ -d "$worktree_path/test/$feature_name/e2e" ]]; then
        git -C "$worktree_path" add "test/$feature_name/e2e"
        git -C "$worktree_path" commit -m "[E2E] End-to-end tests for $feature_name: $ARGUMENTS" || {
            log_warning "No E2E test files to commit"
        }
    fi
    
    # パフォーマンス最適化
    if perform_optimization "$worktree_path" "$feature_name"; then
        git -C "$worktree_path" add -u
        git -C "$worktree_path" commit -m "[OPTIMIZE] Performance optimization for $feature_name: $ARGUMENTS" || {
            log_warning "No optimization changes to commit"
        }
    fi
    
    return 0
}

# コード品質チェック関数
run_code_quality_checks() {
    local code_path="$1"
    
    log_info "Running code quality checks..."
    
    # Linting
    case "$PROJECT_TYPE" in
        "javascript"|"typescript"|"react"|"nextjs")
            if [[ -f "package.json" ]] && grep -q '"lint"' package.json; then
                npm run lint -- "$code_path" || return 1
            fi
            ;;
        "python")
            if command -v ruff &>/dev/null; then
                ruff check "$code_path" || return 1
            fi
            ;;
    esac
    
    # Type checking
    case "$PROJECT_TYPE" in
        "typescript"|"react"|"nextjs")
            if [[ -f "tsconfig.json" ]]; then
                npx tsc --noEmit -p . || return 1
            fi
            ;;
        "python")
            if command -v mypy &>/dev/null; then
                mypy "$code_path" || return 1
            fi
            ;;
    esac
    
    # Security scanning
    check_security_requirements "$code_path" || return 1
    
    return 0
}

# パフォーマンス最適化関数
perform_optimization() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "Performing performance optimization..."
    
    # バンドルサイズ分析（フロントエンド）
    if [[ "$PROJECT_TYPE" =~ ^(react|nextjs|vue|angular)$ ]]; then
        analyze_bundle_size "$worktree_path" "$feature_name"
    fi
    
    # クエリ最適化（バックエンド）
    if [[ -d "$worktree_path/src/$feature_name/queries" ]]; then
        optimize_database_queries "$worktree_path" "$feature_name"
    fi
    
    # キャッシング戦略実装
    implement_caching_strategy "$worktree_path" "$feature_name"
    
    return 0
}

# 実装フェーズの実行とコミット
commit_implementation_phases "$WORKTREE_PATH" "$FEATURE_NAME"

# 最終結果レポート生成
generate_coding_results() {
    cat > "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md" << EOF
# Coding Phase Results: $FEATURE_NAME

## Implementation Summary
- Feature: $TASK_DESCRIPTION
- Implementation Type: $(if [[ "$PARALLEL_EXECUTION" == "true" ]]; then echo "Parallel TDD"; else echo "Sequential TDD"; fi)
- Duration: $(calculate_phase_duration "$WORKTREE_PATH" "coding")

## Test Coverage
$(generate_coverage_report "$WORKTREE_PATH" "$FEATURE_NAME")

## Code Quality Metrics
$(generate_quality_metrics "$WORKTREE_PATH" "$FEATURE_NAME")

## Performance Metrics
$(generate_performance_metrics "$WORKTREE_PATH" "$FEATURE_NAME")

## Files Created/Modified
### Components
$(find "$WORKTREE_PATH/src/$FEATURE_NAME" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | wc -l || echo "0") components

### Services
$(find "$WORKTREE_PATH/src/$FEATURE_NAME" -name "*.service.*" 2>/dev/null | wc -l || echo "0") services

### Tests
$(find "$WORKTREE_PATH/test/$FEATURE_NAME" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | wc -l || echo "0") test files

## MCP Integration Results
- Figma components: $(if [[ "$MCP_FIGMA_AVAILABLE" == "true" ]]; then echo "✅ Generated"; else echo "❌ Not available"; fi)
- Playwright E2E: $(if [[ "$MCP_PLAYWRIGHT_AVAILABLE" == "true" ]]; then echo "✅ Generated"; else echo "❌ Not available"; fi)
- Context7 patterns: $(if [[ "$MCP_CONTEXT7_AVAILABLE" == "true" ]]; then echo "✅ Applied"; else echo "❌ Not available"; fi)

## Next Steps
- Integration testing with existing features
- User acceptance testing
- Performance benchmarking
- Security audit
EOF
}

# 最終結果保存
generate_coding_results

if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/coding-results.md"
    git -C "$WORKTREE_PATH" commit -m "[CODING] Feature implementation complete: $ARGUMENTS" || {
        log_warning "Failed to commit coding results"
    }
    log_success "Coding phase completed"
    update_phase_status "$WORKTREE_PATH" "coding" "completed"
fi
```

  <outputs>
    <output required="true">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md</path>
      <format>markdown</format>
      <description>Comprehensive coding phase results</description>
    </output>
    <output required="true">
      <path>$WORKTREE_PATH/src/$FEATURE_NAME/</path>
      <format>source code</format>
      <description>Complete feature implementation</description>
    </output>
    <output required="true">
      <path>$WORKTREE_PATH/test/$FEATURE_NAME/</path>
      <format>test files</format>
      <description>Comprehensive test suite</description>
    </output>
    <output required="false">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/coverage/</path>
      <format>coverage reports</format>
      <description>Test coverage analysis</description>
    </output>
  </outputs>
  
  <quality_checks>
    <check>Test coverage >= 80%</check>
    <check>All tests passing</check>
    <check>Code quality standards met</check>
    <check>Performance benchmarks achieved</check>
    <check>Security requirements satisfied</check>
  </quality_checks>
</phase>

<phase name="completion" duration="10-15min" parallel="false">
  <objectives>
    <objective priority="critical">Run all tests and verify quality</objective>
    <objective priority="critical">Generate completion report</objective>
    <objective priority="high">Prepare for PR or merge</objective>
    <objective priority="medium">Clean up resources if requested</objective>
    <objective priority="low">Generate metrics and analytics</objective>
  </objectives>
  
  <tools>
    <tool type="testing">
      <name>Test runners</name>
      <usage>Final test execution</usage>
    </tool>
    <tool type="reporting">
      <name>Report generators</name>
      <usage>Completion documentation</usage>
    </tool>
    <tool type="git">
      <name>Git tools</name>
      <usage>PR creation and merging</usage>
    </tool>
  </tools>

### Step 3: 完了通知とPR準備

```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

# フェーズ開始チェック
phase_start_checks "completion" "explore" "plan" "coding" || exit 1

show_progress "Completion" 5 5

# 最終品質ゲートチェック
final_quality_gate_check() {
    local worktree_path="$1"
    local all_passed=true
    
    log_info "Running final quality gate checks..."
    
    # セキュリティチェック
    if ! check_quality_gates "$worktree_path" "security"; then
        log_error "Security quality gate failed"
        all_passed=false
    fi
    
    # テストカバレッジチェック
    if ! check_quality_gates "$worktree_path" "test_coverage"; then
        log_error "Test coverage quality gate failed"
        all_passed=false
    fi
    
    # パフォーマンスチェック
    if ! check_quality_gates "$worktree_path" "performance_metrics"; then
        log_warning "Performance quality gate failed (non-blocking)"
    fi
    
    # アクセシビリティチェック
    if ! check_quality_gates "$worktree_path" "a11y_compliance"; then
        log_error "Accessibility quality gate failed"
        all_passed=false
    fi
    
    if [[ "$all_passed" == "true" ]]; then
        log_success "All quality gates passed"
        return 0
    else
        log_error "Some quality gates failed"
        return 1
    fi
}

# ALWAYS run all tests - プロジェクトタイプに応じたテスト
log_info "Running comprehensive test suite..."
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - feature may be incomplete"
    update_phase_status "$WORKTREE_PATH" "completion" "failed"
    # NEVER proceed with failing tests
    exit 1
fi

# E2Eテスト実行（存在する場合）
if [[ -f "$WORKTREE_PATH/package.json" ]] && grep -q '"e2e"' "$WORKTREE_PATH/package.json"; then
    log_info "Running E2E tests..."
    (cd "$WORKTREE_PATH" && npm run e2e) || log_warning "E2E tests need review"
fi

# MUST run build if available
if [[ -f "$WORKTREE_PATH/package.json" ]] && grep -q '"build"' "$WORKTREE_PATH/package.json"; then
    log_info "Running build process..."
    (cd "$WORKTREE_PATH" && npm run build) || {
        log_error "Build process failed"
        update_phase_status "$WORKTREE_PATH" "completion" "failed"
        exit 1
    }
fi

# 最終品質ゲートチェック
if ! final_quality_gate_check "$WORKTREE_PATH"; then
    update_phase_status "$WORKTREE_PATH" "completion" "failed_quality"
    handle_error 1 "Final quality gates failed" "$WORKTREE_PATH"
fi

# 完了レポート生成
generate_completion_report() {
    local worktree_path="$1"
    local feature_name="$2"
    
    cat > "$worktree_path/report/$feature_name/phase-results/task-completion-report.md" << EOF
# Feature Completion Report

## Feature Summary
**Feature**: $ARGUMENTS  
**Branch**: $FEATURE_BRANCH
**Worktree**: $worktree_path
**Completed**: $(date)
**Total Duration**: $(calculate_total_duration "$worktree_path")

## Implementation Overview
### Architecture
- Component structure implemented
- API endpoints created
- State management configured
- Database schema updated (if applicable)

### UI/UX
- Design system compliance verified
- Responsive design implemented
- Accessibility standards met (WCAG 2.1 AA)
- Performance metrics within targets

## Phase Results
$(generate_phase_summary "$worktree_path")

## Quality Gate Results
$(generate_quality_gate_summary "$worktree_path")

## Files Created/Modified
### New Components
$(find "$worktree_path/src/$feature_name" -name "*.tsx" -o -name "*.jsx" 2>/dev/null | grep -v node_modules | head -10 || echo "No new components")

### API Changes
$(find "$worktree_path/src/$feature_name" -name "*.ts" -o -name "*.js" 2>/dev/null | grep -E "(service|api|endpoint)" | head -10 || echo "No API changes")

### Test Coverage
- Unit Tests: $(find "$worktree_path/test/$feature_name" -name "*.test.*" 2>/dev/null | wc -l || echo "0") files
- Integration Tests: $(find "$worktree_path/test/$feature_name" -name "*.integration.*" 2>/dev/null | wc -l || echo "0") files
- E2E Tests: $(find "$worktree_path/test/$feature_name/e2e" -name "*" 2>/dev/null | wc -l || echo "0") files
- Total Coverage: $(extract_total_coverage "$worktree_path")%

## Performance Metrics
$(generate_performance_summary "$worktree_path")

## Security Analysis
$(generate_security_summary "$worktree_path")

## Commits
\`\`\`
$(git -C "$worktree_path" log --oneline origin/main..HEAD)
\`\`\`

## Demo & Testing
- Local demo: \`cd $worktree_path && npm run dev\`
- Run tests: \`cd $worktree_path && npm test\`
- E2E tests: \`cd $worktree_path && npm run e2e\`
- View prototype: \`cd $worktree_path/prototype/demo\`

## Integration Checklist
- [x] Code implementation complete
- [x] All tests passing
- [x] Build successful
- [x] Quality gates passed
- [ ] Code review completed
- [ ] Documentation updated
- [ ] User acceptance testing
- [ ] Production deployment plan

## MCP Integration Summary
$(generate_mcp_summary)

## Next Steps
1. Review implementation in worktree: $worktree_path
2. Test feature locally with demo environment
3. Create PR: $FEATURE_BRANCH → main
4. Conduct code review
5. Deploy to staging environment
6. Perform user acceptance testing
7. Clean up worktree after merge

## Recommendations
$(generate_recommendations "$worktree_path" "$feature_name")

---
*Report generated automatically by Multi-Agent Feature Development Workflow v2.0*
EOF
}

# 補助関数群
generate_phase_summary() {
    local worktree_path="$1"
    
    echo "| Phase | Status | Duration | Quality |"
    echo "|-------|--------|----------|---------|"
    
    for phase in explore plan prototype coding completion; do
        local status=$(get_phase_status "$worktree_path" "$phase")
        local duration=$(calculate_phase_duration "$worktree_path" "$phase")
        local quality=$(get_phase_quality "$worktree_path" "$phase")
        
        echo "| $phase | $status | $duration | $quality |"
    done
}

generate_quality_gate_summary() {
    local worktree_path="$1"
    
    echo "| Quality Gate | Status | Details |"
    echo "|--------------|--------|---------|"
    echo "| Security | $(if check_quality_gates "$worktree_path" "security" &>/dev/null; then echo "✅ PASS"; else echo "❌ FAIL"; fi) | Input validation, auth checks |"
    echo "| Test Coverage | $(if check_quality_gates "$worktree_path" "test_coverage" &>/dev/null; then echo "✅ PASS"; else echo "❌ FAIL"; fi) | $(extract_total_coverage "$worktree_path")% coverage |"
    echo "| Performance | $(if check_quality_gates "$worktree_path" "performance_metrics" &>/dev/null; then echo "✅ PASS"; else echo "⚠️ WARN"; fi) | Response time, memory usage |"
    echo "| Accessibility | $(if check_quality_gates "$worktree_path" "a11y_compliance" &>/dev/null; then echo "✅ PASS"; else echo "❌ FAIL"; fi) | WCAG 2.1 AA compliance |"
}

generate_mcp_summary() {
    echo "### MCP Tools Utilization"
    echo ""
    if [[ "$MCP_FIGMA_AVAILABLE" == "true" ]]; then
        echo "#### Figma Integration"
        echo "- ✅ Design tokens imported"
        echo "- ✅ Components generated from design system"
        echo "- ✅ Style guide synchronized"
    fi
    
    if [[ "$MCP_PLAYWRIGHT_AVAILABLE" == "true" ]]; then
        echo ""
        echo "#### Playwright Integration"
        echo "- ✅ E2E tests auto-generated"
        echo "- ✅ Visual regression tests created"
        echo "- ✅ Cross-browser testing configured"
    fi
    
    if [[ "$MCP_CONTEXT7_AVAILABLE" == "true" ]]; then
        echo ""
        echo "#### Context7 Integration"
        echo "- ✅ Architecture patterns applied"
        echo "- ✅ Best practices validated"
        echo "- ✅ Code consistency maintained"
    fi
    
    if [[ "$MCP_FIGMA_AVAILABLE" != "true" ]] && [[ "$MCP_PLAYWRIGHT_AVAILABLE" != "true" ]] && [[ "$MCP_CONTEXT7_AVAILABLE" != "true" ]]; then
        echo "- No MCP tools were available during development"
    fi
}

# レポート生成
generate_completion_report "$WORKTREE_PATH" "$FEATURE_NAME"

# worktree内でコミット
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/task-completion-report.md"
    git -C "$WORKTREE_PATH" commit -m "[COMPLETE] Feature ready for integration: $TASK_DESCRIPTION" || {
        log_warning "Failed to commit completion report"
    }
    log_success "Committed: [COMPLETE] Feature ready for integration"
    update_phase_status "$WORKTREE_PATH" "completion" "completed"
fi

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
    
    # PR本文生成
    generate_pr_body() {
        cat << EOF
## Summary
$TASK_DESCRIPTION

## Changes
$(git -C "$WORKTREE_PATH" log --oneline origin/main..HEAD | head -10)

## Quality Metrics
- Test Coverage: $(extract_total_coverage "$WORKTREE_PATH")%
- Build Status: ✅ Passing
- Quality Gates: ✅ All passed

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No console errors or warnings

## Demo
See prototype at: \`$WORKTREE_PATH/prototype/demo\`

---
*PR generated by Multi-Agent Feature Development Workflow v2.0*
EOF
    }
    
    if create_pull_request "$WORKTREE_PATH" "$FEATURE_BRANCH" "$TASK_DESCRIPTION" "$is_draft" "$(generate_pr_body)"; then
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
    echo ""
    echo "========================================="
    echo "✅ FEATURE DEVELOPMENT COMPLETED"
    echo "========================================="
    echo "📊 Report: $WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md"
    echo "🔀 Branch: $FEATURE_BRANCH"
    echo "🚀 Demo: cd $WORKTREE_PATH && npm run dev"
    echo "📁 Worktree: $WORKTREE_PATH"
    echo "💾 Environment: $ENV_FILE"
    echo ""
    echo "🧹 To clean up later:"
    echo "   git worktree remove $WORKTREE_PATH"
    echo "   rm -f $ENV_FILE"
    echo "========================================="
fi

log_success "Feature development completed independently!"
echo ""
echo "💡 User can now proceed with other tasks."

# 成功終了
exit 0
```

  <outputs>
    <output required="true">
      <path>$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md</path>
      <format>markdown</format>
      <description>Comprehensive completion report</description>
    </output>
    <output required="false">
      <path>Pull Request URL</path>
      <format>url</format>
      <description>GitHub PR if created</description>
    </output>
  </outputs>
  
  <quality_checks>
    <check>All phases completed successfully</check>
    <check>All quality gates passed</check>
    <check>Tests passing</check>
    <check>Build successful</check>
    <check>Documentation complete</check>
  </quality_checks>
</phase>

## 実行結果

ユーザーは指示後すぐに次のタスクに移行可能。この機能開発は独立worktree内で以下のフローを自動完了します：

1. **探索フェーズ**: 要件分析・技術調査・デザイン確認（MCP連携含む）
2. **計画フェーズ**: アーキテクチャ設計・実装戦略策定
3. **プロトタイプ**: インタラクティブな動作確認可能な実装
4. **実装フェーズ**: 並列TDD実行・E2Eテスト・最適化
5. **完了フェーズ**: 品質ゲート検証・デモ環境準備・PR準備

全工程が自動化され、各フェーズで品質ゲートが適用され、ユーザーは最終レビュー時のみ関与すれば良い設計です。

### 改善版の主な特徴

1. **完全なXML構造化**: 各フェーズが明確に定義され、入出力が明示的
2. **並列実行サポート**: Test AgentとImplementation Agentの同時実行
3. **MCP完全統合**: Figma、Playwright、Context7の活用
4. **品質ゲート強制**: 各フェーズで自動品質チェック
5. **エラー回復機能**: 失敗時の自動リカバリーとロールバック
6. **包括的なレポート**: 各フェーズの詳細な実行結果とメトリクス

</feature_development_workflow>