#!/bin/bash
# Test 4: Refactoring Completion Test

set -euo pipefail

# Source utilities
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# Test configuration
TEST_NAME="Refactoring Completion"
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

# Test 4.1: Complete refactoring workflow
test_complete_refactoring_workflow() {
    print_test_header "Test 4.1: Complete Refactoring Workflow"
    
    # Create refactoring worktree
    local task_description="refactor-test-utils"
    local worktree_info=$(create_task_worktree "$task_description" "refactor")
    TEST_WORKTREE=$(echo "$worktree_info" | cut -d'|' -f1)
    local branch_name=$(echo "$worktree_info" | cut -d'|' -f2)
    local feature_name=$(echo "$worktree_info" | cut -d'|' -f3)
    
    # Verify branch name format
    if [[ "$branch_name" == refactor/* ]]; then
        print_test_result "Refactor branch created correctly" "true"
        echo "  Branch: $branch_name"
    else
        print_test_result "Refactor branch created correctly" "false"
        echo "  Expected: refactor/*, Got: $branch_name"
    fi
    
    # Execute full workflow
    local phases=("explore" "plan" "code" "test")
    for phase in "${phases[@]}"; do
        update_phase_status "$TEST_WORKTREE" "$phase" "started"
        
        # Create phase result file
        case $phase in
            explore)
                cat > "$TEST_WORKTREE/explore-results.md" << EOF
# Exploration Results
## Analysis
- Current code structure analyzed
- Refactoring opportunities identified
- Dependencies mapped
EOF
                ;;
            plan)
                cat > "$TEST_WORKTREE/plan-results.md" << EOF
# Refactoring Plan
## Strategy
1. Extract common functions
2. Improve error handling
3. Add comprehensive tests
EOF
                ;;
            code)
                # Simulate actual code changes
                mkdir -p "$TEST_WORKTREE/src/utils"
                cat > "$TEST_WORKTREE/src/utils/refactored.js" << 'EOF'
// Refactored utility functions
export function improvedFunction(param) {
    // Better implementation
    return param;
}
EOF
                cat > "$TEST_WORKTREE/coding-results.md" << EOF
# Coding Results
## Changes
- Extracted common utilities
- Improved error handling
- Enhanced performance
EOF
                ;;
            test)
                # Create test results
                mkdir -p "$TEST_WORKTREE/test/utils"
                cat > "$TEST_WORKTREE/test/utils/refactored.test.js" << 'EOF'
// Tests for refactored code
describe('improvedFunction', () => {
    test('handles basic case', () => {
        expect(improvedFunction('test')).toBe('test');
    });
});
EOF
                ;;
        esac
        
        # Commit phase results
        git -C "$TEST_WORKTREE" add -A
        git -C "$TEST_WORKTREE" commit -m "[$phase] Phase complete: $task_description" > /dev/null 2>&1
        
        update_phase_status "$TEST_WORKTREE" "$phase" "completed"
    done
    
    # Verify all phases completed
    local all_completed=true
    for phase in "${phases[@]}"; do
        if ! check_phase_completed "$TEST_WORKTREE" "$phase"; then
            all_completed=false
            break
        fi
    done
    
    if [[ "$all_completed" == "true" ]]; then
        print_test_result "All refactoring phases completed" "true"
    else
        print_test_result "All refactoring phases completed" "false"
    fi
}

# Test 4.2: Completion report generation
test_completion_report() {
    print_test_header "Test 4.2: Completion Report Generation"
    
    # Generate completion report
    cat > "$TEST_WORKTREE/task-completion-report.md" << EOF
# Task Completion Report

## Task Summary
**Task**: $TEST_NAME
**Branch**: $(git -C "$TEST_WORKTREE" branch --show-current)
**Worktree**: $TEST_WORKTREE
**Completed**: $(date)

## Phase Results
- ✅ **Explore**: Root cause analysis
- ✅ **Plan**: Implementation strategy  
- ✅ **Code**: Refactoring implementation
- ✅ **Test**: Quality verification

## Files Modified
$(git -C "$TEST_WORKTREE" diff --name-only HEAD~4 2>/dev/null || echo "Multiple files")

## Commits
$(git -C "$TEST_WORKTREE" log --oneline -n 5)

## Test Results
All tests passing

## Next Steps
1. Review implementation
2. Merge to main
3. Clean up worktree
EOF
    
    # Commit report
    git -C "$TEST_WORKTREE" add task-completion-report.md
    git -C "$TEST_WORKTREE" commit -m "[COMPLETE] Task finished: refactoring" > /dev/null 2>&1
    
    if [[ -f "$TEST_WORKTREE/task-completion-report.md" ]]; then
        print_test_result "Completion report generated" "true"
    else
        print_test_result "Completion report generated" "false"
    fi
}

# Test 4.3: Git history validation
test_git_history() {
    print_test_header "Test 4.3: Git History Validation"
    
    # Check commit count
    local commit_count=$(git -C "$TEST_WORKTREE" rev-list --count HEAD)
    if [[ $commit_count -ge 5 ]]; then
        print_test_result "Sufficient commits in history" "true"
        echo "  Total commits: $commit_count"
    else
        print_test_result "Sufficient commits in history" "false"
        echo "  Expected: >= 5, Got: $commit_count"
    fi
    
    # Verify commit message format
    local proper_format=true
    while IFS= read -r commit; do
        if ! [[ "$commit" =~ ^\[[A-Z\-]+\] ]]; then
            proper_format=false
            echo "  Invalid format: $commit"
        fi
    done < <(git -C "$TEST_WORKTREE" log --oneline --format="%s" -n 10)
    
    if [[ "$proper_format" == "true" ]]; then
        print_test_result "All commits follow proper format" "true"
    else
        print_test_result "All commits follow proper format" "false"
    fi
}

# Test 4.4: Code quality checks
test_code_quality() {
    print_test_header "Test 4.4: Code Quality Verification"
    
    # Check for structured directories
    local dirs_exist=true
    for dir in "src" "test" "report"; do
        if [[ ! -d "$TEST_WORKTREE/$dir" ]]; then
            dirs_exist=false
            echo "  Missing directory: $dir"
        fi
    done
    
    if [[ "$dirs_exist" == "true" ]]; then
        print_test_result "Project structure maintained" "true"
    else
        print_test_result "Project structure maintained" "false"
    fi
    
    # Verify no temp files left
    local temp_files=$(find "$TEST_WORKTREE" -name "*.tmp" -o -name "*.swp" -o -name "*~" 2>/dev/null | wc -l)
    if [[ $temp_files -eq 0 ]]; then
        print_test_result "No temporary files present" "true"
    else
        print_test_result "No temporary files present" "false"
        echo "  Found $temp_files temporary files"
    fi
}

# Test 4.5: Merge readiness
test_merge_readiness() {
    print_test_header "Test 4.5: Merge Readiness Check"
    
    # Check if branch can be merged cleanly
    local current_branch=$(git branch --show-current)
    local test_branch=$(git -C "$TEST_WORKTREE" branch --show-current)
    
    # Test merge (dry run)
    set +e
    git merge-tree $(git merge-base HEAD "$test_branch") HEAD "$test_branch" > /dev/null 2>&1
    local merge_status=$?
    set -e
    
    if [[ $merge_status -eq 0 ]]; then
        print_test_result "Branch ready for clean merge" "true"
    else
        print_test_result "Branch ready for clean merge" "false"
        echo "  Merge conflicts may exist"
    fi
    
    # Verify no untracked files
    local untracked=$(git -C "$TEST_WORKTREE" status --porcelain | grep "^??" | wc -l)
    if [[ $untracked -eq 0 ]]; then
        print_test_result "No untracked files" "true"
    else
        print_test_result "No untracked files" "false"
        echo "  Found $untracked untracked files"
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
    echo -e "${BLUE}Phase 3 Test 4: Refactoring Completion${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Set trap for cleanup
    trap cleanup_test EXIT
    
    test_complete_refactoring_workflow
    test_completion_report
    test_git_history
    test_code_quality
    test_merge_readiness
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $TEST_PASSED${NC} | ${RED}Failed: $TEST_FAILED${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Exit with failure if any test failed
    [[ $TEST_FAILED -eq 0 ]] || exit 1
}

# Run tests
main "$@"