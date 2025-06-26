#!/bin/bash
# Master test runner for Phase 3 tests

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Results storage
declare -A TEST_RESULTS

# Print header
print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}         PHASE 3 VERIFICATION TEST SUITE${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "Date: $(date)"
    echo -e "Working Directory: $(pwd)"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"
}

# Run individual test
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo -e "${YELLOW}▶ Running: $test_name${NC}"
    echo -e "${YELLOW}────────────────────────────────────────${NC}"
    
    ((TOTAL_TESTS++))
    
    # Make script executable
    chmod +x "$test_script"
    
    # Run test and capture result
    set +e
    "$test_script"
    local exit_code=$?
    set -e
    
    if [[ $exit_code -eq 0 ]]; then
        ((PASSED_TESTS++))
        TEST_RESULTS["$test_name"]="PASSED"
        echo -e "\n${GREEN}✓ $test_name: PASSED${NC}\n"
    else
        ((FAILED_TESTS++))
        TEST_RESULTS["$test_name"]="FAILED"
        echo -e "\n${RED}✗ $test_name: FAILED (exit code: $exit_code)${NC}\n"
    fi
    
    return $exit_code
}

# Generate summary report
generate_summary() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                    TEST SUMMARY${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    
    echo -e "\nTotal Tests: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    
    echo -e "\n${BLUE}Individual Test Results:${NC}"
    echo -e "${BLUE}────────────────────────${NC}"
    
    for test_name in "${!TEST_RESULTS[@]}"; do
        local result="${TEST_RESULTS[$test_name]}"
        if [[ "$result" == "PASSED" ]]; then
            echo -e "${GREEN}✓${NC} $test_name"
        else
            echo -e "${RED}✗${NC} $test_name"
        fi
    done
    
    # Generate detailed report file
    cat > ".worktrees/bugfix-3/phase3-test-report.md" << EOF
# Phase 3 Test Execution Report

**Date**: $(date)  
**Total Tests**: $TOTAL_TESTS  
**Passed**: $PASSED_TESTS  
**Failed**: $FAILED_TESTS  
**Success Rate**: $(( TOTAL_TESTS > 0 ? PASSED_TESTS * 100 / TOTAL_TESTS : 0 ))%

## Test Results

### Test 1: Japanese Parameter Worktree Creation
**Status**: ${TEST_RESULTS["Test 1: Japanese Parameters"]:-NOT RUN}
- Tests Japanese text handling in branch names
- Validates proper encoding and sanitization
- Ensures worktree creation with non-ASCII input

### Test 2: Sequential Phase Execution  
**Status**: ${TEST_RESULTS["Test 2: Sequential Phases"]:-NOT RUN}
- Validates phase ordering (Explore→Plan→Code→Test)
- Tests phase status management
- Ensures proper state transitions

### Test 3: Error Handling and Rollback
**Status**: ${TEST_RESULTS["Test 3: Error Handling"]:-NOT RUN}
- Tests failure scenarios
- Validates rollback mechanisms
- Ensures cleanup after errors

### Test 4: Refactoring Completion
**Status**: ${TEST_RESULTS["Test 4: Refactoring Complete"]:-NOT RUN}
- Tests complete workflow execution
- Validates git history
- Ensures merge readiness

## Recommendations

$(if [[ $FAILED_TESTS -gt 0 ]]; then
    echo "1. Review failed tests and fix identified issues"
    echo "2. Re-run failed tests individually for debugging"
    echo "3. Check test logs for detailed error messages"
else
    echo "1. All tests passed - system ready for production use"
    echo "2. Consider adding more edge case tests"
    echo "3. Monitor performance in real-world usage"
fi)

## Next Steps

$(if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "- Phase 3 verification complete ✅"
    echo "- Ready to merge to main branch"
    echo "- Update documentation with test results"
else
    echo "- Fix failing tests before proceeding"
    echo "- Review error logs for root causes"
    echo "- Re-run test suite after fixes"
fi)
EOF
    
    echo -e "\n${BLUE}Report saved to: .worktrees/bugfix-3/phase3-test-report.md${NC}"
}

# Main execution
main() {
    print_header
    
    # Define tests
    declare -A TESTS=(
        ["Test 1: Japanese Parameters"]=".worktrees/bugfix-3/test/phase3-test-japanese-worktree.sh"
        ["Test 2: Sequential Phases"]=".worktrees/bugfix-3/test/phase3-test-sequential-phases.sh"
        ["Test 3: Error Handling"]=".worktrees/bugfix-3/test/phase3-test-error-handling.sh"
        ["Test 4: Refactoring Complete"]=".worktrees/bugfix-3/test/phase3-test-refactoring-complete.sh"
    )
    
    # Check if test scripts exist
    echo "Checking test scripts..."
    for test_name in "${!TESTS[@]}"; do
        local test_script="${TESTS[$test_name]}"
        if [[ ! -f "$test_script" ]]; then
            echo -e "${RED}Error: Test script not found: $test_script${NC}"
            exit 1
        fi
    done
    echo -e "${GREEN}All test scripts found ✓${NC}\n"
    
    # Run all tests (continue even if some fail)
    for test_name in "Test 1: Japanese Parameters" "Test 2: Sequential Phases" "Test 3: Error Handling" "Test 4: Refactoring Complete"; do
        set +e
        run_test "$test_name" "${TESTS[$test_name]}"
        set -e
    done
    
    # Generate summary
    generate_summary
    
    # Set exit code based on results
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo -e "\n${RED}════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}        PHASE 3 TESTS FAILED${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════${NC}"
        exit 1
    else
        echo -e "\n${GREEN}════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     ALL PHASE 3 TESTS PASSED! 🎉${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
        exit 0
    fi
}

# Run main
main "$@"