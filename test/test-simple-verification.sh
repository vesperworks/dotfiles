#!/bin/bash
# simple verification test

echo "=== Phase 3 Verification Test ==="

# Test 1: Basic worktree-utils.sh functionality
echo "Test 1: Testing worktree-utils.sh basic functions"
source .claude/scripts/worktree-utils.sh 2>/dev/null || echo "Warning: Some functions may not be available"

# Test 2: Japanese parameter processing
echo "Test 2: Testing Japanese parameter processing"
task_desc="修正フェーズ3を実行"
echo "Input: $task_desc"

# Test get_feature_name function if available
if declare -f get_feature_name >/dev/null; then
    feature_name=$(get_feature_name "$task_desc" "refactor")
    echo "Generated feature name: $feature_name"
else
    echo "get_feature_name function not available, simulating..."
    # Simulate the function logic
    feature_name=$(echo "$task_desc" | \
        sed -e 's/修正/fix/g' \
            -e 's/フェーズ/phase/g' \
            -e 's/実行/execute/g' \
            -e 's/を/ /g' | \
        sed 's/[^a-zA-Z0-9 ]//g' | \
        tr '[:upper:]' '[:lower:]' | \
        awk '{for(i=1;i<=NF&&i<=3;i++) printf "%s-", $i}' | \
        sed 's/-$//')
    echo "Simulated feature name: $feature_name"
fi

# Test 3: File system verification
echo "Test 3: Checking file system structure"
if [[ -f ".claude/scripts/parallel-agent-utils.sh" ]]; then
    echo "✅ parallel-agent-utils.sh exists"
else
    echo "❌ parallel-agent-utils.sh missing"
fi

if [[ -f ".claude/scripts/worktree-utils.sh" ]]; then
    echo "✅ worktree-utils.sh exists"
else
    echo "❌ worktree-utils.sh missing"
fi

# Test 4: Git worktree basic functionality
echo "Test 4: Testing git worktree basic functionality"
git worktree list | head -3

echo "=== Verification Test Complete ==="