#!/bin/bash
# Unit test for parse_workflow_options function
# Task: multiコマンドの総合テストを実行

source .claude/scripts/worktree-utils.sh

# Test setup
setup() {
    # Reset environment
    unset KEEP_WORKTREE NO_MERGE CREATE_PR NO_DRAFT AUTO_CLEANUP CLEANUP_DAYS TASK_DESCRIPTION
}

# Test teardown
teardown() {
    unset KEEP_WORKTREE NO_MERGE CREATE_PR NO_DRAFT AUTO_CLEANUP CLEANUP_DAYS TASK_DESCRIPTION
}

# Test 1: Empty arguments
test_empty_arguments() {
    setup
    parse_workflow_options
    
    [[ "$KEEP_WORKTREE" == "false" ]] || return 1
    [[ "$NO_MERGE" == "false" ]] || return 1
    [[ "$CREATE_PR" == "false" ]] || return 1
    [[ "$NO_DRAFT" == "false" ]] || return 1
    [[ "$AUTO_CLEANUP" == "true" ]] || return 1
    [[ "$CLEANUP_DAYS" == "7" ]] || return 1
    [[ -z "$TASK_DESCRIPTION" ]] || return 1
    
    echo "✅ Empty arguments test passed"
    teardown
}

# Test 2: Simple task description
test_simple_task() {
    setup
    parse_workflow_options "テストタスク"
    
    [[ "$TASK_DESCRIPTION" == "テストタスク" ]] || return 1
    [[ "$KEEP_WORKTREE" == "false" ]] || return 1
    
    echo "✅ Simple task test passed"
    teardown
}

# Test 3: Multiple arguments with options
test_multiple_options() {
    setup
    parse_workflow_options "テストタスク" "--keep-worktree" "--pr" "--no-draft"
    
    [[ "$TASK_DESCRIPTION" == "テストタスク" ]] || return 1
    [[ "$KEEP_WORKTREE" == "true" ]] || return 1
    [[ "$CREATE_PR" == "true" ]] || return 1
    [[ "$NO_DRAFT" == "true" ]] || return 1
    [[ "$AUTO_CLEANUP" == "false" ]] || return 1
    
    echo "✅ Multiple options test passed"
    teardown
}

# Test 4: Cleanup days option
test_cleanup_days() {
    setup
    parse_workflow_options "--cleanup-days" "14" "テストタスク"
    
    [[ "$CLEANUP_DAYS" == "14" ]] || return 1
    [[ "$TASK_DESCRIPTION" == "テストタスク" ]] || return 1
    
    echo "✅ Cleanup days test passed"
    teardown
}

# Test 5: Complex task description
test_complex_task() {
    setup
    parse_workflow_options "multiコマンドの" "総合テストを" "実行"
    
    [[ "$TASK_DESCRIPTION" == "multiコマンドの 総合テストを 実行" ]] || return 1
    
    echo "✅ Complex task test passed"
    teardown
}

# Run all tests
echo "Running parse_workflow_options tests..."
test_empty_arguments || echo "❌ Empty arguments test failed"
test_simple_task || echo "❌ Simple task test failed"
test_multiple_options || echo "❌ Multiple options test failed"
test_cleanup_days || echo "❌ Cleanup days test failed"
test_complex_task || echo "❌ Complex task test failed"

echo "\nAll tests completed!"