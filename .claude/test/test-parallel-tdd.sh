#!/bin/bash
# test-parallel-tdd.sh - 並列TDD機能のテストスクリプト

set -euo pipefail

# テストディレクトリを設定
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"
CLAUDE_SCRIPTS_DIR="$PROJECT_ROOT/.claude/scripts"

# テスト用一時ディレクトリ
TEST_TEMP_DIR="/tmp/parallel-tdd-test-$(date +%Y%m%d-%H%M%S)"

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}[TEST-INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[TEST-SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[TEST-WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[TEST-ERROR]${NC} $1" >&2; }

# テスト結果カウンタ
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# テスト実行関数
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    ((TESTS_TOTAL++))
    log_info "Running test: $test_name"
    
    if $test_function; then
        ((TESTS_PASSED++))
        log_success "✅ $test_name"
    else
        ((TESTS_FAILED++))
        log_error "❌ $test_name"
    fi
    echo ""
}

# セットアップ
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # テスト環境の作成
    mkdir -p "$TEST_TEMP_DIR"
    cd "$TEST_TEMP_DIR"
    
    # Gitリポジトリ初期化
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # 基本的なプロジェクト構造を作成
    echo '{"name": "test-project", "version": "1.0.0"}' > package.json
    mkdir -p src test
    
    # 初期コミット
    git add .
    git commit -m "Initial commit"
    
    # .claude設定をコピー
    mkdir -p .claude/scripts .claude/prompts
    cp "$CLAUDE_SCRIPTS_DIR/worktree-utils.sh" .claude/scripts/
    if [[ -f "$PROJECT_ROOT/.claude/prompts/coder-test.md" ]]; then
        cp "$PROJECT_ROOT/.claude/prompts/coder-test.md" .claude/prompts/
    fi
    if [[ -f "$PROJECT_ROOT/.claude/prompts/coder-impl.md" ]]; then
        cp "$PROJECT_ROOT/.claude/prompts/coder-impl.md" .claude/prompts/
    fi
    
    # テストモードを有効化
    export TEST_MODE="true"
    
    log_success "Test environment setup complete"
}

# クリーンアップ
cleanup_test_environment() {
    log_info "Cleaning up test environment..."
    cd "$PROJECT_ROOT"
    rm -rf "$TEST_TEMP_DIR"
    unset TEST_MODE
    log_success "Test environment cleaned up"
}

# worktree-utils.shの読み込みテスト
test_load_worktree_utils() {
    if source "$CLAUDE_SCRIPTS_DIR/worktree-utils.sh"; then
        log_info "worktree-utils.sh loaded successfully"
        return 0
    else
        log_error "Failed to load worktree-utils.sh"
        return 1
    fi
}

# 並列エージェント関数の存在確認テスト
test_parallel_functions_exist() {
    local functions=(
        "run_parallel_agents"
        "run_test_agent" 
        "run_impl_agent"
        "monitor_parallel_execution"
        "merge_parallel_results"
        "create_unit_tests"
        "create_integration_tests"
        "create_e2e_tests"
        "implement_core_functionality"
        "implement_edge_cases"
        "optimize_implementation"
    )
    
    for func in "${functions[@]}"; do
        if ! declare -f "$func" > /dev/null; then
            log_error "Function $func not found"
            return 1
        fi
    done
    
    log_info "All parallel TDD functions found"
    return 0
}

# worktree作成テスト
test_worktree_creation() {
    local task_desc="test-parallel-tdd-feature"
    local worktree_info
    
    if worktree_info=$(create_task_worktree "$task_desc" "feature"); then
        local worktree_path=$(echo "$worktree_info" | cut -d'|' -f1)
        local branch_name=$(echo "$worktree_info" | cut -d'|' -f2)
        local feature_name=$(echo "$worktree_info" | cut -d'|' -f3)
        
        # worktreeの存在確認
        if [[ -d "$worktree_path" ]]; then
            log_info "Worktree created: $worktree_path"
            log_info "Branch: $branch_name"
            log_info "Feature: $feature_name"
            
            # 構造化ディレクトリの確認
            if [[ -d "$worktree_path/test/$feature_name" ]] && 
               [[ -d "$worktree_path/src/$feature_name" ]] &&
               [[ -d "$worktree_path/report/$feature_name" ]]; then
                log_info "Structured directories created successfully"
                
                # クリーンアップ
                cleanup_worktree "$worktree_path"
                return 0
            else
                log_error "Structured directories not created"
                return 1
            fi
        else
            log_error "Worktree directory not found: $worktree_path"
            return 1
        fi
    else
        log_error "Failed to create worktree"
        return 1
    fi
}

# テストエージェント関数テスト
test_test_agent_functions() {
    local test_worktree_path="$TEST_TEMP_DIR/.worktrees/test-feature"
    local feature_name="test-feature"
    local task_desc="Test feature for unit testing"
    
    # テスト用worktreeディレクトリ作成
    mkdir -p "$test_worktree_path/test/$feature_name"
    mkdir -p "$test_worktree_path/src/$feature_name"
    mkdir -p "$test_worktree_path/report/$feature_name"
    
    # テスト作成関数の実行
    if create_unit_tests "$test_worktree_path" "$feature_name" "$task_desc" &&
       create_integration_tests "$test_worktree_path" "$feature_name" "$task_desc" &&
       create_e2e_tests "$test_worktree_path" "$feature_name" "$task_desc" &&
       create_test_report "$test_worktree_path" "$feature_name"; then
        
        # 作成されたファイルの確認
        if [[ -f "$test_worktree_path/test/$feature_name/unit/test-feature.test.js" ]] &&
           [[ -f "$test_worktree_path/test/$feature_name/integration/integration.test.md" ]] &&
           [[ -f "$test_worktree_path/test/$feature_name/e2e/e2e.test.md" ]] &&
           [[ -f "$test_worktree_path/test-creation-report.md" ]]; then
            log_info "Test agent functions executed successfully"
            return 0
        else
            log_error "Expected test files not created"
            return 1
        fi
    else
        log_error "Test agent functions failed"
        return 1
    fi
}

# 実装エージェント関数テスト
test_impl_agent_functions() {
    local test_worktree_path="$TEST_TEMP_DIR/.worktrees/impl-feature"
    local feature_name="impl-feature"
    local task_desc="Implementation feature for testing"
    
    # 実装用worktreeディレクトリ作成
    mkdir -p "$test_worktree_path/test/$feature_name"
    mkdir -p "$test_worktree_path/src/$feature_name"
    mkdir -p "$test_worktree_path/report/$feature_name"
    
    # 実装関数の実行
    if implement_core_functionality "$test_worktree_path" "$feature_name" "$task_desc" &&
       implement_edge_cases "$test_worktree_path" "$feature_name" "$task_desc" &&
       optimize_implementation "$test_worktree_path" "$feature_name" "$task_desc" &&
       create_impl_report "$test_worktree_path" "$feature_name"; then
        
        # 作成されたファイルの確認
        if [[ -f "$test_worktree_path/src/$feature_name/index.js" ]] &&
           [[ -f "$test_worktree_path/src/$feature_name/utils/edge-cases.md" ]] &&
           [[ -f "$test_worktree_path/report/$feature_name/performance/optimization.md" ]] &&
           [[ -f "$test_worktree_path/implementation-report.md" ]]; then
            log_info "Implementation agent functions executed successfully"
            return 0
        else
            log_error "Expected implementation files not created"
            return 1
        fi
    else
        log_error "Implementation agent functions failed"
        return 1
    fi
}

# 並列実行監視テスト
test_parallel_monitoring() {
    local temp_dir="$TEST_TEMP_DIR/parallel-test"
    mkdir -p "$temp_dir"
    
    # 疑似的な並列実行状況を作成
    echo "running" > "$temp_dir/test-agent.status"
    echo "running" > "$temp_dir/impl-agent.status"
    
    # バックグラウンドでステータス更新
    (
        sleep 2
        echo "completed" > "$temp_dir/test-agent.status"
        sleep 1
        echo "completed" > "$temp_dir/impl-agent.status"
    ) &
    local update_pid=$!
    
    # 監視機能のテスト（タイムアウト付き）
    if timeout 10s monitor_parallel_execution "$temp_dir" $$ $$; then
        log_info "Parallel monitoring completed successfully"
        wait $update_pid
        return 0
    else
        log_error "Parallel monitoring failed or timed out"
        kill $update_pid 2>/dev/null || true
        return 1
    fi
}

# 結果マージテスト
test_results_merge() {
    local temp_dir="$TEST_TEMP_DIR/merge-test"
    local worktree_path="$temp_dir/worktree"
    local feature_name="merge-feature"
    
    mkdir -p "$worktree_path/test/$feature_name"
    mkdir -p "$worktree_path/src/$feature_name"
    mkdir -p "$temp_dir"
    
    # 疑似的な結果ファイルを作成
    echo "0" > "$temp_dir/test-agent.result"
    echo "0" > "$temp_dir/impl-agent.result"
    echo "[Test Agent] Test creation completed" > "$worktree_path/test-agent.log"
    echo "[Impl Agent] Implementation completed" > "$worktree_path/impl-agent.log"
    
    # Git初期化（マージ機能用）
    cd "$worktree_path"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # 結果マージの実行
    if merge_parallel_results "$worktree_path" "$temp_dir" "$feature_name"; then
        if [[ -f "$worktree_path/parallel-tdd-report.md" ]]; then
            log_info "Results merge completed successfully"
            return 0
        else
            log_error "Parallel TDD report not created"
            return 1
        fi
    else
        log_error "Results merge failed"
        return 1
    fi
}

# プロンプトファイル確認テスト
test_prompt_files() {
    local prompts_dir="$PROJECT_ROOT/.claude/prompts"
    
    if [[ -f "$prompts_dir/coder-test.md" ]] && [[ -f "$prompts_dir/coder-impl.md" ]]; then
        log_info "Specialized agent prompt files exist"
        
        # プロンプトファイルの内容確認
        if grep -q "Coder-Test Agent" "$prompts_dir/coder-test.md" &&
           grep -q "Coder-Impl Agent" "$prompts_dir/coder-impl.md"; then
            log_info "Prompt files contain expected content"
            return 0
        else
            log_error "Prompt files missing expected content"
            return 1
        fi
    else
        log_error "Specialized agent prompt files not found"
        return 1
    fi
}

# メイン実行
main() {
    log_info "Starting Parallel TDD Feature Tests"
    echo "=========================================="
    
    # セットアップ
    setup_test_environment
    
    # テスト実行
    run_test "Load worktree-utils.sh" test_load_worktree_utils
    run_test "Parallel functions exist" test_parallel_functions_exist
    run_test "Worktree creation" test_worktree_creation
    run_test "Test agent functions" test_test_agent_functions  
    run_test "Implementation agent functions" test_impl_agent_functions
    run_test "Parallel monitoring" test_parallel_monitoring
    run_test "Results merge" test_results_merge
    run_test "Prompt files" test_prompt_files
    
    # クリーンアップ
    cleanup_test_environment
    
    # 結果表示
    echo "=========================================="
    log_info "Test Results Summary:"
    log_success "Passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Failed: $TESTS_FAILED"
    else
        log_success "Failed: $TESTS_FAILED"
    fi
    log_info "Total: $TESTS_TOTAL"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "🎉 All tests passed! Parallel TDD feature is ready."
        exit 0
    else
        log_error "❌ Some tests failed. Please review the implementation."
        exit 1
    fi
}

# トラップでクリーンアップを確実に実行
trap cleanup_test_environment EXIT

# メイン実行
main "$@"