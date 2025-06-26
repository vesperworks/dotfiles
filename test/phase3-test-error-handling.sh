#!/bin/bash
# Test 3: Error Handling and Rollback Test

set -euo pipefail

# Source utilities
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# Test configuration
TEST_NAME="Error Handling and Rollback"
TEST_PASSED=0
TEST_FAILED=0
TEST_WORKTREE=""

# Test result tracking
print_test_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_test_result() {
    local test_name="$1"
    local passed="$2"
    if [[ "$passed" == "true" ]]; then
        echo -e "${GREEN}✓${NC} $test_name"
        ((TEST_PASSED++))
    else
        echo -e "${RED}✗${NC} $test_name"
        ((TEST_FAILED++))
    fi
}

# Test 3.1: Worktree creation failure handling
test_worktree_creation_failure() {
    print_test_header "Test 3.1: Worktree Creation Failure"
    
    # Try to create worktree with invalid branch name
    local task_description="test/invalid/branch/name"
    
    # This should fail but be handled gracefully
    set +e
    local worktree_info=$(create_task_worktree "$task_description" "test" 2>&1)
    local exit_code=$?
    set -e
    
    # The function should handle the error and return non-zero
    if [[ $exit_code -ne 0 ]]; then
        print_test_result "Invalid branch name handled correctly" "true"
    else
        print_test_result "Invalid branch name handled correctly" "false"
        echo "  Expected failure, but got success"
    fi
}

# Test 3.2: Phase failure rollback
test_phase_failure_rollback() {
    print_test_header "Test 3.2: Phase Failure Rollback"
    
    # Create test worktree
    local task_description="error-handling-test"
    local worktree_info=$(create_task_worktree "$task_description" "test")
    TEST_WORKTREE=$(echo "$worktree_info" | cut -d'|' -f1)
    
    # Simulate phase failure
    update_phase_status "$TEST_WORKTREE" "explore" "started"
    
    # Call rollback function
    rollback_on_error "$TEST_WORKTREE" "explore" "Simulated failure for testing"
    
    # Check error report was created
    if [[ -f "$TEST_WORKTREE/error-report.md" ]]; then
        print_test_result "Error report created on rollback" "true"
        
        # Verify error report content
        if grep -q "Simulated failure for testing" "$TEST_WORKTREE/error-report.md"; then
            print_test_result "Error message recorded correctly" "true"
        else
            print_test_result "Error message recorded correctly" "false"
        fi
    else
        print_test_result "Error report created on rollback" "false"
    fi
    
    # Check phase status is 'failed'
    local status_file="$TEST_WORKTREE/.status/explore.json"
    if [[ -f "$status_file" ]] && grep -q '"status": "failed"' "$status_file"; then
        print_test_result "Phase status set to failed" "true"
    else
        print_test_result "Phase status set to failed" "false"
    fi
}

# Test 3.3: Cleanup after error
test_cleanup_after_error() {
    print_test_header "Test 3.3: Cleanup After Error"
    
    # Create another test worktree
    local task_description="cleanup-test-$(date +%s)"
    local worktree_info=$(create_task_worktree "$task_description" "test")
    local worktree_path=$(echo "$worktree_info" | cut -d'|' -f1)
    
    # Simulate some work
    echo "test data" > "$worktree_path/test-file.txt"
    
    # Force cleanup with error handling
    cleanup_worktree "$worktree_path"
    
    # Verify cleanup
    if [[ ! -d "$worktree_path" ]]; then
        print_test_result "Worktree cleaned up after error" "true"
    else
        print_test_result "Worktree cleaned up after error" "false"
        # Try force cleanup
        git worktree remove --force "$worktree_path" 2>/dev/null || true
    fi
}

# Test 3.4: Concurrent worktree handling
test_concurrent_worktree_handling() {
    print_test_header "Test 3.4: Concurrent Worktree Handling"
    
    # Create multiple worktrees
    local worktrees=()
    for i in {1..3}; do
        local task="concurrent-test-$i"
        local info=$(create_task_worktree "$task" "test")
        local path=$(echo "$info" | cut -d'|' -f1)
        worktrees+=("$path")
    done
    
    # Verify all created
    local all_created=true
    for wt in "${worktrees[@]}"; do
        if [[ ! -d "$wt" ]]; then
            all_created=false
            break
        fi
    done
    
    if [[ "$all_created" == "true" ]]; then
        print_test_result "Multiple worktrees created successfully" "true"
    else
        print_test_result "Multiple worktrees created successfully" "false"
    fi
    
    # Cleanup all
    for wt in "${worktrees[@]}"; do
        cleanup_worktree "$wt"
    done
    
    # Verify all cleaned
    local all_cleaned=true
    for wt in "${worktrees[@]}"; do
        if [[ -d "$wt" ]]; then
            all_cleaned=false
            break
        fi
    done
    
    if [[ "$all_cleaned" == "true" ]]; then
        print_test_result "All worktrees cleaned up properly" "true"
    else
        print_test_result "All worktrees cleaned up properly" "false"
    fi
}

# Test 3.5: Recovery from interrupted workflow
test_workflow_recovery() {
    print_test_header "Test 3.5: Workflow Recovery"
    
    # Create test worktree
    local task_description="recovery-test"
    local worktree_info=$(create_task_worktree "$task_description" "test")
    local worktree_path=$(echo "$worktree_info" | cut -d'|' -f1)
    
    # Simulate interrupted workflow (only explore phase done)
    update_phase_status "$worktree_path" "explore" "completed"
    echo "# Explore Results" > "$worktree_path/explore-results.md"
    git -C "$worktree_path" add explore-results.md
    git -C "$worktree_path" commit -m "[EXPLORE] Partial completion" > /dev/null 2>&1
    
    # Now simulate recovery - check what phases need to be done
    local phases_to_complete=()
    for phase in plan code test; do
        if ! check_phase_completed "$worktree_path" "$phase"; then
            phases_to_complete+=("$phase")
        fi
    done
    
    if [[ ${#phases_to_complete[@]} -eq 3 ]]; then
        print_test_result "Incomplete phases detected correctly" "true"
        echo "  Phases to complete: ${phases_to_complete[*]}"
    else
        print_test_result "Incomplete phases detected correctly" "false"
    fi
    
    # Cleanup
    cleanup_worktree "$worktree_path"
}

# Cleanup function
cleanup_test() {
    if [[ -n "$TEST_WORKTREE" ]] && [[ -d "$TEST_WORKTREE" ]]; then
        cleanup_worktree "$TEST_WORKTREE"
        log_info "Test worktree cleaned up"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Phase 3 Test 3: Error Handling & Rollback${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Set trap for cleanup
    trap cleanup_test EXIT
    
    test_worktree_creation_failure
    test_phase_failure_rollback
    test_cleanup_after_error
    test_concurrent_worktree_handling
    test_workflow_recovery
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $TEST_PASSED${NC} | ${RED}Failed: $TEST_FAILED${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Exit with failure if any test failed
    [[ $TEST_FAILED -eq 0 ]] || exit 1
}

# Run tests
main "$@"