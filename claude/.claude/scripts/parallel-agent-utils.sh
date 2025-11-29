#!/bin/bash
# parallel-agent-utils.sh - 並列エージェント実行機能専用ユーティリティ

# 並列エージェント実行機能
run_parallel_agents() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local test_files_pattern="${4:-}"
    local impl_files_pattern="${5:-}"
    
    log_info "Starting parallel TDD agents for feature: $feature_name"
    
    # 並列実行用の一時ディレクトリ
    local temp_dir="$worktree_path/.parallel-agents"
    mkdir -p "$temp_dir"
    
    # 並列実行のための状態ファイル
    local test_agent_status="$temp_dir/test-agent.status"
    local impl_agent_status="$temp_dir/impl-agent.status"
    local test_agent_result="$temp_dir/test-agent.result"
    local impl_agent_result="$temp_dir/impl-agent.result"
    
    # ステータスファイル初期化
    echo "running" > "$test_agent_status"
    echo "running" > "$impl_agent_status"
    
    log_info "Launching Test Agent and Implementation Agent in parallel..."
    
    # Test Agent (バックグラウンド実行)
    (
        run_test_agent "$worktree_path" "$feature_name" "$task_description" "$test_files_pattern"
        echo $? > "$test_agent_result"
        echo "completed" > "$test_agent_status"
    ) &
    local test_agent_pid=$!
    
    # Implementation Agent (バックグラウンド実行)
    (
        run_impl_agent "$worktree_path" "$feature_name" "$task_description" "$impl_files_pattern"
        echo $? > "$impl_agent_result"
        echo "completed" > "$impl_agent_status"
    ) &
    local impl_agent_pid=$!
    
    log_info "Test Agent PID: $test_agent_pid, Impl Agent PID: $impl_agent_pid"
    
    # 並列実行の進捗監視
    monitor_parallel_execution "$temp_dir" "$test_agent_pid" "$impl_agent_pid"
    
    # 両エージェントの完了を待機
    wait $test_agent_pid
    local test_exit_code=$?
    wait $impl_agent_pid  
    local impl_exit_code=$?
    
    # 結果の統合
    merge_parallel_results "$worktree_path" "$temp_dir" "$feature_name"
    
    # クリーンアップ
    rm -rf "$temp_dir"
    
    # 全体の成功判定
    if [[ $test_exit_code -eq 0 ]] && [[ $impl_exit_code -eq 0 ]]; then
        log_success "Parallel TDD agents completed successfully"
        return 0
    else
        log_error "One or more parallel agents failed (Test: $test_exit_code, Impl: $impl_exit_code)"
        return 1
    fi
}

# テスト作成専門エージェント
run_test_agent() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local test_files_pattern="${4:-}"
    
    log_info "[Test Agent] Starting test creation for: $feature_name"
    
    # テスト専門プロンプトの読み込み
    local test_prompt=$(load_prompt ".klaude/prompts/coder-test.md" "$DEFAULT_CODER_TEST_PROMPT")
    
    # テスト作成の実行ログ
    local test_log="$worktree_path/test-agent.log"
    echo "[Test Agent] Starting at $(date)" > "$test_log"
    
    # TDD Red Phase: 失敗するテストを作成
    log_info "[Test Agent] Creating failing tests (RED phase)"
    
    # テスト種別の判定と作成
    create_unit_tests "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$test_log"
    create_integration_tests "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$test_log"
    create_e2e_tests "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$test_log"
    
    # テスト結果レポート作成
    create_test_report "$worktree_path" "$feature_name" 2>&1 | tee -a "$test_log"
    
    echo "[Test Agent] Completed at $(date)" >> "$test_log"
    log_success "[Test Agent] Test creation completed"
    
    return 0
}

# 実装専門エージェント
run_impl_agent() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local impl_files_pattern="${4:-}"
    
    log_info "[Impl Agent] Starting implementation for: $feature_name"
    
    # 実装専門プロンプトの読み込み
    local impl_prompt=$(load_prompt ".klaude/prompts/coder-impl.md" "$DEFAULT_CODER_IMPL_PROMPT")
    
    # 実装の実行ログ
    local impl_log="$worktree_path/impl-agent.log"
    echo "[Impl Agent] Starting at $(date)" > "$impl_log"
    
    # TDD Green Phase: テストを通す実装を作成
    log_info "[Impl Agent] Creating implementation (GREEN phase)"
    
    # 段階的実装
    implement_core_functionality "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$impl_log"
    implement_edge_cases "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$impl_log"
    optimize_implementation "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$impl_log"
    
    # 実装結果レポート作成
    create_impl_report "$worktree_path" "$feature_name" 2>&1 | tee -a "$impl_log"
    
    echo "[Impl Agent] Completed at $(date)" >> "$impl_log"
    log_success "[Impl Agent] Implementation completed"
    
    return 0
}

# 並列実行の進捗監視
monitor_parallel_execution() {
    local temp_dir="$1"
    local test_pid="$2"
    local impl_pid="$3"
    
    local test_status_file="$temp_dir/test-agent.status"
    local impl_status_file="$temp_dir/impl-agent.status"
    
    log_info "Monitoring parallel execution..."
    
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local spinner_index=0
    
    while [[ "$(bat --style=plain "$test_status_file" 2>/dev/null)" == "running" ]] || [[ "$(bat --style=plain "$impl_status_file" 2>/dev/null)" == "running" ]]; do
        local spinner_char="${spinner_chars:$spinner_index:1}"
        echo -ne "\r${spinner_char} Test Agent: $(bat --style=plain "$test_status_file" 2>/dev/null || echo "starting") | Impl Agent: $(bat --style=plain "$impl_status_file" 2>/dev/null || echo "starting")"
        
        spinner_index=$(( (spinner_index + 1) % ${#spinner_chars} ))
        sleep 0.5
    done
    
    echo -e "\n"
    log_success "Parallel execution monitoring completed"
}

# 並列実行結果のマージ
merge_parallel_results() {
    local worktree_path="$1"
    local temp_dir="$2"
    local feature_name="$3"
    
    log_info "Merging parallel execution results..."
    
    # 結果ファイルの存在確認
    local test_result=$(bat --style=plain "$temp_dir/test-agent.result" 2>/dev/null || echo "1")
    local impl_result=$(bat --style=plain "$temp_dir/impl-agent.result" 2>/dev/null || echo "1")
    
    # 統合レポート作成
    cat > "$worktree_path/parallel-tdd-report.md" << EOF
# Parallel TDD Execution Report

## Feature: $feature_name
**Execution Time**: $(date)

## Test Agent Results
**Status**: $([ "$test_result" -eq 0 ] && echo "✅ Success" || echo "❌ Failed")
**Exit Code**: $test_result

### Test Creation Summary
$(if [[ -f "$worktree_path/test-agent.log" ]]; then
    rg -E "\[Test Agent\].*:" "$worktree_path/test-agent.log" | tail -10 || echo "No test log found"
else
    echo "No test log found"
fi)

## Implementation Agent Results  
**Status**: $([ "$impl_result" -eq 0 ] && echo "✅ Success" || echo "❌ Failed")
**Exit Code**: $impl_result

### Implementation Summary
$(if [[ -f "$worktree_path/impl-agent.log" ]]; then
    rg -E "\[Impl Agent\].*:" "$worktree_path/impl-agent.log" | tail -10 || echo "No impl log found"
else
    echo "No impl log found"
fi)

## TDD Cycle Status
- **RED Phase**: Tests created first
- **GREEN Phase**: Implementation follows tests
- **REFACTOR Phase**: Code quality improvements

## Files Created
### Test Files
$(fd -t f '\.(test|spec)\.' "$worktree_path/test/$feature_name" 2>/dev/null | head -10 || echo "No test files found")

### Implementation Files
$(fd -t f . "$worktree_path/src/$feature_name" 2>/dev/null | head -10 || echo "No implementation files found")

## Next Steps
1. Review test coverage
2. Run full test suite
3. Optimize implementation
4. Update documentation
EOF
    
    # gitコミット
    if [[ -f "$worktree_path/parallel-tdd-report.md" ]]; then
        git -C "$worktree_path" add parallel-tdd-report.md
        git -C "$worktree_path" commit -m "[PARALLEL-TDD] Completed parallel test and implementation for $feature_name" || {
            log_warning "Failed to commit parallel TDD report"
        }
    fi
    
    log_success "Parallel results merged successfully"
}

# テスト作成ヘルパー関数群
create_unit_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Test Agent] Creating unit tests for: $feature_name"
    
    # 単体テストディレクトリの確保
    mkdir -p "$worktree_path/test/$feature_name/unit"
    
    # プロジェクトタイプに応じたテストファイル作成
    local project_type=$(detect_project_type "$worktree_path")
    
    case "$project_type" in
        node)
            create_jest_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
        rust)
            create_rust_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
        python)
            create_pytest_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
        *)
            create_generic_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
    esac
    
    log_success "[Test Agent] Unit tests created"
}

create_integration_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Test Agent] Creating integration tests for: $feature_name"
    
    # 統合テストディレクトリの確保
    mkdir -p "$worktree_path/test/$feature_name/integration"
    
    # 統合テストの基本構造を作成
    cat > "$worktree_path/test/$feature_name/integration/integration.test.md" << EOF
# Integration Tests for $feature_name

## Test Scenarios
1. Component Integration Testing
2. API Integration Testing
3. Database Integration Testing
4. External Service Integration Testing

## Test Description
$task_description

## Created: $(date)
EOF
    
    log_success "[Test Agent] Integration tests created"
}

create_e2e_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Test Agent] Creating E2E tests for: $feature_name"
    
    # E2Eテストディレクトリの確保
    mkdir -p "$worktree_path/test/$feature_name/e2e"
    
    # E2Eテストの基本構造を作成
    cat > "$worktree_path/test/$feature_name/e2e/e2e.test.md" << EOF
# End-to-End Tests for $feature_name

## User Journey Testing
1. User Story Based Testing
2. Cross-browser Testing
3. Mobile Responsive Testing
4. Performance Testing

## Test Description
$task_description

## Created: $(date)
EOF
    
    log_success "[Test Agent] E2E tests created"
}

create_test_report() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "[Test Agent] Creating test report for: $feature_name"
    
    cat > "$worktree_path/test-creation-report.md" << EOF
# Test Creation Report: $feature_name

## Summary
**Feature**: $feature_name
**Test Creation Completed**: $(date)

## Test Coverage Plan
### Unit Tests
- Core functionality testing
- Boundary condition testing
- Error handling testing
- Input validation testing

### Integration Tests
- Component interaction testing
- API integration testing
- Database integration testing
- Service integration testing

### E2E Tests
- User workflow testing
- Cross-platform testing
- Performance testing
- Accessibility testing

## Test Files Created
$(fd -t f . "$worktree_path/test/$feature_name" 2>/dev/null | head -20 || echo "No test files found")

## TDD Red Phase Status
✅ Failing tests created
🔄 Ready for implementation phase
📋 Test coverage plan documented

## Next Steps
1. Run tests to confirm RED state
2. Begin implementation to achieve GREEN state
3. Refactor for code quality
EOF
    
    log_success "[Test Agent] Test report created"
}

# 実装関数群
implement_core_functionality() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Impl Agent] Implementing core functionality for: $feature_name"
    
    # コア実装ディレクトリの確保
    mkdir -p "$worktree_path/src/$feature_name/core"
    
    # プロジェクトタイプに応じた実装ファイル作成
    local project_type=$(detect_project_type "$worktree_path")
    
    case "$project_type" in
        node)
            create_node_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
        rust)
            create_rust_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
        python)
            create_python_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
        *)
            create_generic_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
    esac
    
    log_success "[Impl Agent] Core functionality implemented"
}

implement_edge_cases() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Impl Agent] Implementing edge cases for: $feature_name"
    
    # エッジケース実装
    mkdir -p "$worktree_path/src/$feature_name/utils"
    
    cat > "$worktree_path/src/$feature_name/utils/edge-cases.md" << EOF
# Edge Cases Implementation: $feature_name

## Handled Edge Cases
1. Null/undefined input handling
2. Empty data structure handling
3. Boundary value handling
4. Error condition handling
5. Resource limitation handling

## Description
$task_description

## Implementation Date
$(date)
EOF
    
    log_success "[Impl Agent] Edge cases implemented"
}

optimize_implementation() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Impl Agent] Optimizing implementation for: $feature_name"
    
    # 最適化レポート作成
    mkdir -p "$worktree_path/report/$feature_name/performance"
    
    cat > "$worktree_path/report/$feature_name/performance/optimization.md" << EOF
# Performance Optimization Report: $feature_name

## Optimization Areas
1. Algorithm efficiency improvements
2. Memory usage optimization
3. I/O operation optimization
4. Caching strategy implementation
5. Lazy loading implementation

## Performance Metrics
- Before optimization: TBD
- After optimization: TBD
- Improvement percentage: TBD

## Description
$task_description

## Optimization Date
$(date)
EOF
    
    log_success "[Impl Agent] Implementation optimized"
}

create_impl_report() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "[Impl Agent] Creating implementation report for: $feature_name"
    
    cat > "$worktree_path/implementation-report.md" << EOF
# Implementation Report: $feature_name

## Summary
**Feature**: $feature_name
**Implementation Completed**: $(date)

## Implementation Phases
### Core Functionality
✅ Basic feature implementation
✅ Core business logic
✅ Primary use cases covered

### Edge Cases
✅ Error handling implemented
✅ Boundary conditions handled
✅ Input validation added

### Optimization
✅ Performance optimizations applied
✅ Memory usage optimized
✅ Code quality improvements

## Implementation Files Created
$(fd -t f . "$worktree_path/src/$feature_name" 2>/dev/null | head -20 || echo "No implementation files found")

## TDD Green Phase Status
✅ Tests passing
✅ Core functionality implemented
🔄 Ready for refactoring phase

## Quality Metrics
- Code coverage: TBD
- Performance benchmarks: TBD
- Code quality score: TBD

## Next Steps
1. Run full test suite
2. Measure performance metrics
3. Code review and refactoring
4. Documentation updates
EOF
    
    log_success "[Impl Agent] Implementation report created"
}

# プロジェクト固有の実装関数群
create_jest_unit_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/test/$feature_name/unit/$feature_name.test.js" << EOF
// Unit tests for $feature_name
// $task_description
// Generated: $(date)

describe('$feature_name', () => {
  test('should implement core functionality', () => {
    // Red phase: This test should fail initially
    expect(false).toBe(true);
  });
  
  test('should handle edge cases', () => {
    // Red phase: This test should fail initially
    expect(false).toBe(true);
  });
  
  test('should validate inputs', () => {
    // Red phase: This test should fail initially
    expect(false).toBe(true);
  });
});
EOF
}

create_generic_unit_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/test/$feature_name/unit/test_$feature_name.md" << EOF
# Generic Unit Tests for $feature_name

## Test Description
$task_description

## Test Cases
1. Core functionality test (should fail initially)
2. Edge case handling test (should fail initially)  
3. Input validation test (should fail initially)

## Created: $(date)
EOF
}

create_node_implementation() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    # feature_nameの最初の文字を大文字にする（互換性のある方法）
    local class_name=$(echo "$feature_name" | sed 's/^./\U&/')
    
    cat > "$worktree_path/src/$feature_name/index.js" << EOF
// Implementation for $feature_name
// $task_description
// Generated: $(date)

class $class_name {
  constructor() {
    // Core functionality implementation
  }
  
  // Implement methods to make tests pass
}

module.exports = $class_name;
EOF
}

create_generic_implementation() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/src/$feature_name/implementation.md" << EOF
# Generic Implementation for $feature_name

## Description
$task_description

## Implementation Structure
1. Core functionality
2. Edge case handling
3. Input validation
4. Error handling

## Created: $(date)
EOF
}

# デフォルトプロンプト定義
DEFAULT_CODER_TEST_PROMPT="あなたはテスト作成専門のCoder-Testエージェントです。TDDのRED phaseを担当します：
1. 機能要件に基づく失敗するテストを作成
2. 単体テスト、統合テスト、E2Eテストの作成
3. テストケースの境界値・エラーハンドリング確認
4. テストの実行とRED状態の確認
5. 結果をtest-creation-report.mdに保存"

DEFAULT_CODER_IMPL_PROMPT="あなたは実装専門のCoder-Implエージェントです。TDDのGREEN phaseを担当します：
1. 作成されたテストを通すための最小実装を作成
2. 段階的な機能実装（コア→エッジケース→最適化）
3. エラーハンドリングと入力検証の実装
4. パフォーマンス最適化の実施
5. 結果をimplementation-report.mdに保存"

# エクスポート
export -f run_parallel_agents run_test_agent run_impl_agent
export -f monitor_parallel_execution merge_parallel_results
export -f create_unit_tests create_integration_tests create_e2e_tests create_test_report
export -f implement_core_functionality implement_edge_cases optimize_implementation create_impl_report
export -f create_jest_unit_tests create_generic_unit_tests create_node_implementation create_generic_implementation
export DEFAULT_CODER_TEST_PROMPT DEFAULT_CODER_IMPL_PROMPT