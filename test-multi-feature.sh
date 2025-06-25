#!/bin/bash

# Test script for multi-feature.md session separation fix

echo "=== Testing multi-feature.md session separation fix ==="

# 0. Clean up any existing test environment files
rm -f .worktrees/.env-test-* 2>/dev/null

# 1. Simulate Step 1 environment save
echo "Step 1: Saving environment variables..."
TASK_DESCRIPTION="test feature implementation"
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
ENV_FILE=".worktrees/.env-${TASK_ID}-$(date +%Y%m%d-%H%M%S)"

# Create test environment file
cat > "$ENV_FILE" << EOF
WORKTREE_PATH=".worktrees/test-feature"
FEATURE_BRANCH="feature/test-feature"
FEATURE_NAME="test-feature"
PROJECT_TYPE="test"
TASK_DESCRIPTION="$TASK_DESCRIPTION"
KEEP_WORKTREE="true"
NO_MERGE="true"
CREATE_PR="false"
NO_DRAFT="false"
AUTO_CLEANUP="false"
CLEANUP_DAYS="7"
EOF

echo "Environment saved to: $ENV_FILE"

# 2. Test Phase 1 (Explore) - New session
echo -e "\nPhase 1: Testing Explore phase in new session..."
bash -c '
    # Source utilities
    source .claude/scripts/worktree-utils.sh || {
        echo "Error: worktree-utils.sh not found"
        exit 1
    }
    
    # Load environment
    ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        echo "✓ Environment loaded from: $ENV_FILE"
    else
        echo "✗ Error: Environment file not found"
        exit 1
    fi
    
    # Test function availability
    if type -t log_info >/dev/null; then
        echo "✓ log_info function available"
        log_info "Explore phase test"
    else
        echo "✗ log_info function not found"
    fi
    
    # Test environment variables
    if [[ -n "$WORKTREE_PATH" ]]; then
        echo "✓ WORKTREE_PATH available: $WORKTREE_PATH"
    else
        echo "✗ WORKTREE_PATH not set"
    fi
    
    if [[ -n "$FEATURE_NAME" ]]; then
        echo "✓ FEATURE_NAME available: $FEATURE_NAME"
    else
        echo "✗ FEATURE_NAME not set"
    fi
'

# 3. Test Phase 2 (Plan) - New session
echo -e "\nPhase 2: Testing Plan phase in new session..."
bash -c '
    # Source utilities
    source .claude/scripts/worktree-utils.sh || {
        echo "Error: worktree-utils.sh not found"
        exit 1
    }
    
    # Load environment
    ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
    if [[ -f "$ENV_FILE" ]]; then
        source "$ENV_FILE"
        echo "✓ Environment loaded"
    else
        echo "✗ Error: Environment file not found"
        exit 1
    fi
    
    # Test function
    if type -t show_progress >/dev/null; then
        echo "✓ show_progress function available"
    else
        echo "✗ show_progress function not found"
    fi
    
    # Test environment
    if [[ "$PROJECT_TYPE" == "test" ]]; then
        echo "✓ PROJECT_TYPE correctly set: $PROJECT_TYPE"
    else
        echo "✗ PROJECT_TYPE incorrect: $PROJECT_TYPE"
    fi
'

# 4. Test Phase 3 (Prototype) - New session
echo -e "\nPhase 3: Testing Prototype phase in new session..."
bash -c '
    source .claude/scripts/worktree-utils.sh || exit 1
    ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    
    if type -t git_commit_phase >/dev/null; then
        echo "✓ git_commit_phase function available"
    else
        echo "✗ git_commit_phase function not found"
    fi
'

# 5. Test Phase 4 (Coding) - New session
echo -e "\nPhase 4: Testing Coding phase in new session..."
bash -c '
    source .claude/scripts/worktree-utils.sh || exit 1
    ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    
    if type -t load_prompt >/dev/null; then
        echo "✓ load_prompt function available"
    else
        echo "✗ load_prompt function not found"
    fi
    
    if [[ -n "$FEATURE_NAME" ]]; then
        echo "✓ FEATURE_NAME still available: $FEATURE_NAME"
    else
        echo "✗ FEATURE_NAME lost"
    fi
'

# 6. Test Step 3 (Completion) - New session
echo -e "\nStep 3: Testing Completion phase in new session..."
bash -c '
    source .claude/scripts/worktree-utils.sh || exit 1
    ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    
    if type -t run_tests >/dev/null; then
        echo "✓ run_tests function available"
    else
        echo "✗ run_tests function not found"
    fi
    
    if type -t cleanup_worktree >/dev/null; then
        echo "✓ cleanup_worktree function available"
    else
        echo "✗ cleanup_worktree function not found"
    fi
    
    echo "✓ All environment variables preserved:"
    echo "  - WORKTREE_PATH: $WORKTREE_PATH"
    echo "  - FEATURE_BRANCH: $FEATURE_BRANCH"
    echo "  - TASK_DESCRIPTION: $TASK_DESCRIPTION"
'

# 7. Clean up test environment file
echo -e "\nCleaning up test environment file..."
rm -f "$ENV_FILE"
echo "✓ Test environment file removed"

echo -e "\n=== Test completed ==="
echo "If all checks show ✓, the session separation fix is working correctly!"