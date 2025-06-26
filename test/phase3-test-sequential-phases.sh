#!/bin/bash
# Test 2: Sequential Phase Execution Test

set -euo pipefail

# Source utilities
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# Test configuration
TEST_NAME="Sequential Phase Execution"
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

# Test 2.1: Phase status management
test_phase_status() {
    print_test_header "Test 2.1: Phase Status Management"
    
    # Create test worktree
    local task_description="sequential-phase-test"
    local worktree_info=$(create_task_worktree "$task_description" "test")
    TEST_WORKTREE=$(echo "$worktree_info" | cut -d'|' -f1)
    
    # Test phase status creation
    create_phase_status "$TEST_WORKTREE" "explore" "started"
    if [[ -f "$TEST_WORKTREE/.status/explore.json" ]]; then
        print_test_result "Phase status file created" "true"
    else
        print_test_result "Phase status file created" "false"
        return
    fi
    
    # Test phase completion check
    update_phase_status "$TEST_WORKTREE" "explore" "completed"
    if check_phase_completed "$TEST_WORKTREE" "explore"; then
        print_test_result "Phase completion check works" "true"
    else
        print_test_result "Phase completion check works" "false"
    fi
    
    # Test incomplete phase check
    update_phase_status "$TEST_WORKTREE" "plan" "in_progress"
    if ! check_phase_completed "$TEST_WORKTREE" "plan"; then
        print_test_result "Incomplete phase detected correctly" "true"
    else
        print_test_result "Incomplete phase detected correctly" "false"
    fi
}

# Test 2.2: Simulated Explorer phase
test_explorer_phase() {
    print_test_header "Test 2.2: Explorer Phase Simulation"
    
    # Simulate explorer phase
    update_phase_status "$TEST_WORKTREE" "explore" "started"
    
    # Create explore results
    cat > "$TEST_WORKTREE/explore-results.md" << EOF
# Exploration Results
Task: Sequential phase test
Status: Analysis complete
Date: $(date)
EOF
    
    # Commit results
    git -C "$TEST_WORKTREE" add explore-results.md
    git -C "$TEST_WORKTREE" commit -m "[EXPLORE] Analysis complete: sequential test" > /dev/null 2>&1
    
    update_phase_status "$TEST_WORKTREE" "explore" "completed"
    
    if [[ -f "$TEST_WORKTREE/explore-results.md" ]] && check_phase_completed "$TEST_WORKTREE" "explore"; then
        print_test_result "Explorer phase completed successfully" "true"
    else
        print_test_result "Explorer phase completed successfully" "false"
    fi
}

# Test 2.3: Simulated Planner phase
test_planner_phase() {
    print_test_header "Test 2.3: Planner Phase Simulation"
    
    # Check prerequisite
    if ! check_phase_completed "$TEST_WORKTREE" "explore"; then
        print_test_result "Planner phase prerequisite check" "false"
        return
    fi
    
    update_phase_status "$TEST_WORKTREE" "plan" "started"
    
    # Create plan results
    cat > "$TEST_WORKTREE/plan-results.md" << EOF
# Planning Results
Task: Sequential phase test
Strategy: TDD approach
Date: $(date)
EOF
    
    # Commit results
    git -C "$TEST_WORKTREE" add plan-results.md
    git -C "$TEST_WORKTREE" commit -m "[PLAN] Strategy complete: sequential test" > /dev/null 2>&1
    
    update_phase_status "$TEST_WORKTREE" "plan" "completed"
    
    if [[ -f "$TEST_WORKTREE/plan-results.md" ]] && check_phase_completed "$TEST_WORKTREE" "plan"; then
        print_test_result "Planner phase completed successfully" "true"
    else
        print_test_result "Planner phase completed successfully" "false"
    fi
}

# Test 2.4: Simulated Coder phase
test_coder_phase() {
    print_test_header "Test 2.4: Coder Phase Simulation"
    
    # Check prerequisites
    if ! check_phase_completed "$TEST_WORKTREE" "plan"; then
        print_test_result "Coder phase prerequisite check" "false"
        return
    fi
    
    update_phase_status "$TEST_WORKTREE" "code" "started"
    
    # Simulate TDD cycle
    local feature_name="sequential-test"
    
    # RED phase
    mkdir -p "$TEST_WORKTREE/test/$feature_name"
    echo "// Failing test" > "$TEST_WORKTREE/test/$feature_name/test.js"
    git -C "$TEST_WORKTREE" add "test/$feature_name"
    git -C "$TEST_WORKTREE" commit -m "[TDD-RED] Failing tests for sequential test" > /dev/null 2>&1
    
    # GREEN phase
    mkdir -p "$TEST_WORKTREE/src/$feature_name"
    echo "// Implementation" > "$TEST_WORKTREE/src/$feature_name/index.js"
    git -C "$TEST_WORKTREE" add "src/$feature_name"
    git -C "$TEST_WORKTREE" commit -m "[TDD-GREEN] Implementation for sequential test" > /dev/null 2>&1
    
    # REFACTOR phase
    echo "// Refactored code" >> "$TEST_WORKTREE/src/$feature_name/index.js"
    git -C "$TEST_WORKTREE" add -A
    git -C "$TEST_WORKTREE" commit -m "[TDD-REFACTOR] Code improvements" > /dev/null 2>&1
    
    # Create coding results
    cat > "$TEST_WORKTREE/coding-results.md" << EOF
# Coding Results
Task: Sequential phase test
TDD Cycle: Complete
Date: $(date)
EOF
    
    git -C "$TEST_WORKTREE" add coding-results.md
    git -C "$TEST_WORKTREE" commit -m "[CODING] Implementation complete: sequential test" > /dev/null 2>&1
    
    update_phase_status "$TEST_WORKTREE" "code" "completed"
    
    if [[ -f "$TEST_WORKTREE/coding-results.md" ]] && check_phase_completed "$TEST_WORKTREE" "code"; then
        print_test_result "Coder phase completed successfully" "true"
    else
        print_test_result "Coder phase completed successfully" "false"
    fi
}

# Test 2.5: Phase transition validation
test_phase_transitions() {
    print_test_header "Test 2.5: Phase Transition Validation"
    
    # Check all phases completed in order
    local all_phases_completed=true
    for phase in explore plan code; do
        if ! check_phase_completed "$TEST_WORKTREE" "$phase"; then
            all_phases_completed=false
            echo "  Phase $phase not completed"
        fi
    done
    
    if [[ "$all_phases_completed" == "true" ]]; then
        print_test_result "All phases completed in sequence" "true"
    else
        print_test_result "All phases completed in sequence" "false"
    fi
    
    # Verify commit history
    local commit_count=$(git -C "$TEST_WORKTREE" rev-list --count HEAD)
    if [[ $commit_count -ge 6 ]]; then  # At least 6 commits expected
        print_test_result "Commit history shows sequential execution" "true"
        echo "  Total commits: $commit_count"
    else
        print_test_result "Commit history shows sequential execution" "false"
        echo "  Expected: >= 6 commits, Got: $commit_count"
    fi
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
    echo -e "${BLUE}Phase 3 Test 2: Sequential Phase Execution${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Set trap for cleanup
    trap cleanup_test EXIT
    
    test_phase_status
    test_explorer_phase
    test_planner_phase
    test_coder_phase
    test_phase_transitions
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $TEST_PASSED${NC} | ${RED}Failed: $TEST_FAILED${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Exit with failure if any test failed
    [[ $TEST_FAILED -eq 0 ]] || exit 1
}

# Run tests
main "$@"