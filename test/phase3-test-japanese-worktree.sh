#!/bin/bash
# Test 1: Japanese Parameter Worktree Creation Test

set -euo pipefail

# Source utilities from main repo
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# Test configuration
TEST_NAME="Japanese Parameter Worktree Creation"
TEST_PASSED=0
TEST_FAILED=0

# Color output
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

# Test 1.1: Basic Japanese task description
test_basic_japanese() {
    print_test_header "Test 1.1: Basic Japanese Task Description"
    
    local task_description="認証機能のバグ修正"
    local feature_name=$(get_feature_name "$task_description" "bugfix")
    
    # Feature name should be safe ASCII
    if [[ "$feature_name" =~ ^[a-z0-9-]+$ ]]; then
        print_test_result "Feature name is safe ASCII" "true"
    else
        print_test_result "Feature name is safe ASCII" "false"
        echo "  Expected: ASCII characters only"
        echo "  Got: $feature_name"
    fi
    
    # Feature name should contain meaningful parts
    if [[ "$feature_name" == *"auth"* ]] || [[ "$feature_name" == *"bug"* ]] || [[ "$feature_name" == *"fix"* ]]; then
        print_test_result "Feature name contains meaningful parts" "true"
    else
        print_test_result "Feature name contains meaningful parts" "false"
        echo "  Expected: Contains auth/bug/fix"
        echo "  Got: $feature_name"
    fi
}

# Test 1.2: Complex Japanese with special characters
test_complex_japanese() {
    print_test_header "Test 1.2: Complex Japanese with Special Characters"
    
    local task_description="ユーザー認証機能の修正（JWT有効期限チェック）"
    local feature_name=$(get_feature_name "$task_description" "bugfix")
    
    # Should handle parentheses and special characters
    if [[ "$feature_name" =~ ^[a-z0-9-]+$ ]] && [[ ${#feature_name} -le 30 ]]; then
        print_test_result "Complex Japanese handled correctly" "true"
    else
        print_test_result "Complex Japanese handled correctly" "false"
        echo "  Got: $feature_name"
    fi
}

# Test 1.3: Empty/Invalid Japanese input
test_invalid_japanese() {
    print_test_header "Test 1.3: Invalid Japanese Input"
    
    # Test empty string
    local feature_name=$(get_feature_name "" "bugfix")
    if [[ "$feature_name" =~ ^bugfix-[0-9]{8}-[0-9]{6}$ ]]; then
        print_test_result "Empty string handled with timestamp" "true"
    else
        print_test_result "Empty string handled with timestamp" "false"
        echo "  Expected: bugfix-YYYYMMDD-HHMMSS"
        echo "  Got: $feature_name"
    fi
    
    # Test only particles
    feature_name=$(get_feature_name "のをが" "bugfix")
    if [[ "$feature_name" =~ ^bugfix-[0-9]{8}-[0-9]{6}$ ]]; then
        print_test_result "Particles-only string handled" "true"
    else
        print_test_result "Particles-only string handled" "false"
        echo "  Got: $feature_name"
    fi
}

# Test 1.4: Actual worktree creation with Japanese
test_worktree_creation() {
    print_test_header "Test 1.4: Actual Worktree Creation"
    
    local task_description="テスト用認証機能修正"
    local worktree_info
    
    # Try to create worktree
    set +e  # Temporarily disable exit on error
    worktree_info=$(create_task_worktree "$task_description" "test")
    local exit_code=$?
    set -e
    
    if [[ $exit_code -eq 0 ]] && [[ -n "$worktree_info" ]]; then
        local worktree_path=$(echo "$worktree_info" | cut -d'|' -f1)
        local branch_name=$(echo "$worktree_info" | cut -d'|' -f2)
        local feature_name=$(echo "$worktree_info" | cut -d'|' -f3)
        
        print_test_result "Worktree created successfully" "true"
        echo "  Path: $worktree_path"
        echo "  Branch: $branch_name"
        echo "  Feature: $feature_name"
        
        # Verify worktree exists
        if [[ -d "$worktree_path" ]]; then
            print_test_result "Worktree directory exists" "true"
            
            # Cleanup
            cleanup_worktree "$worktree_path"
            print_test_result "Worktree cleaned up" "true"
        else
            print_test_result "Worktree directory exists" "false"
        fi
    else
        print_test_result "Worktree created successfully" "false"
        echo "  Exit code: $exit_code"
    fi
}

# Main test execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Phase 3 Test 1: Japanese Parameter Handling${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    test_basic_japanese
    test_complex_japanese
    test_invalid_japanese
    test_worktree_creation
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}Passed: $TEST_PASSED${NC} | ${RED}Failed: $TEST_FAILED${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Exit with failure if any test failed
    [[ $TEST_FAILED -eq 0 ]] || exit 1
}

# Run tests
main "$@"