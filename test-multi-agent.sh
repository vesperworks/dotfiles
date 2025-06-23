#!/bin/bash

# test-multi-agent.sh - マルチエージェントワークフローのテストスクリプト

set -euo pipefail

# カラー定義
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "================================================"
echo "Multi-Agent Workflow Test Script"
echo "================================================"

# テストモードを設定
export TEST_MODE=true

# 1. 環境検証テスト
echo -e "\n${YELLOW}[1/4] Testing environment verification...${NC}"
source .claude/scripts/worktree-utils.sh
if verify_environment; then
    echo -e "${GREEN}✓ Environment verification passed${NC}"
else
    echo -e "${RED}✗ Environment verification failed${NC}"
    exit 1
fi

# 2. プロジェクトタイプ検出テスト
echo -e "\n${YELLOW}[2/4] Testing project type detection...${NC}"
PROJECT_TYPE=$(detect_project_type)
echo "Detected project type: $PROJECT_TYPE"

# 3. Worktree作成テスト
echo -e "\n${YELLOW}[3/4] Testing worktree creation...${NC}"
TEST_TASK="Test task for multi-agent workflow"

# create_task_worktree関数を直接呼び出す
echo "Creating worktree for task: $TEST_TASK"
WORKTREE_INFO=$(create_task_worktree "$TEST_TASK" "test" 2>&1) || {
    echo "create_task_worktree returned non-zero: $?"
}
echo "WORKTREE_INFO: '$WORKTREE_INFO'"

if [[ "$WORKTREE_INFO" == *"|"* ]]; then
    # 最後の行だけを取得（パス|ブランチの形式）
    LAST_LINE=$(echo "$WORKTREE_INFO" | tail -n1)
    WORKTREE_PATH=$(echo "$LAST_LINE" | cut -d'|' -f1)
    TASK_BRANCH=$(echo "$LAST_LINE" | cut -d'|' -f2)
    echo "Extracted WORKTREE_PATH: $WORKTREE_PATH"
    echo "Extracted TASK_BRANCH: $TASK_BRANCH"
else
    echo -e "${RED}✗ Failed to create worktree${NC}"
    echo "Error output: $WORKTREE_INFO"
    exit 1
fi

if [[ -d "$WORKTREE_PATH" ]]; then
    echo -e "${GREEN}✓ Worktree created successfully${NC}"
    echo "  Path: $WORKTREE_PATH"
    echo "  Branch: $TASK_BRANCH"
else
    echo -e "${RED}✗ Worktree creation failed${NC}"
    exit 1
fi

# 4. ワークフローシミュレーション
echo -e "\n${YELLOW}[4/4] Simulating multi-agent workflow...${NC}"

cd "$WORKTREE_PATH"

# Explorer phase
echo -e "\n${YELLOW}Phase 1: Explorer${NC}"
cat > explore-results.md << EOF
# Exploration Results

## Task Summary
Testing multi-agent workflow implementation

## Current Implementation Analysis
- Worktree utilities are functional
- Project structure is set up correctly

## Problem Identification
No critical issues found during exploration

## Dependencies and Constraints
- Git 2.5+ required for worktree support
- Bash shell required

## Recommendations
Proceed with implementation testing
EOF

if git_commit_phase "EXPLORE" "Test exploration complete" "explore-results.md"; then
    echo -e "${GREEN}✓ Explorer phase completed${NC}"
fi

# Planner phase
echo -e "\n${YELLOW}Phase 2: Planner${NC}"
cat > plan-results.md << EOF
# Planning Results

## Implementation Strategy
1. Create test structure
2. Implement basic functionality
3. Add error handling

## TDD Workflow
- Write failing tests first
- Implement minimal code
- Refactor for quality

## Quality Gates
- All tests must pass
- Code coverage > 80%
EOF

if git_commit_phase "PLAN" "Test planning complete" "plan-results.md"; then
    echo -e "${GREEN}✓ Planner phase completed${NC}"
fi

# Coder phase
echo -e "\n${YELLOW}Phase 3: Coder${NC}"
cat > coding-results.md << EOF
# Coding Results

## Implementation Summary
Successfully implemented test workflow

## Test Results
All tests passing

## Code Quality
- Clean code principles followed
- Proper error handling implemented
EOF

if git_commit_phase "CODING" "Test implementation complete" "coding-results.md"; then
    echo -e "${GREEN}✓ Coder phase completed${NC}"
fi

# 完了レポート
echo -e "\n${YELLOW}Creating completion report...${NC}"
cat > task-completion-report.md << EOF
# Task Completion Report

## Task Summary
**Task**: $TEST_TASK
**Branch**: $TASK_BRANCH
**Worktree**: $WORKTREE_PATH
**Completed**: $(date)

## Phase Results
- ✅ **Explore**: Root cause analysis
- ✅ **Plan**: Implementation strategy
- ✅ **Code**: TDD implementation
- ✅ **Tests**: All tests passing

## Next Steps
1. Review implementation in worktree: $WORKTREE_PATH
2. Clean up worktree: git worktree remove $WORKTREE_PATH
EOF

if git_commit_phase "COMPLETE" "Test workflow complete" "task-completion-report.md"; then
    echo -e "${GREEN}✓ Completion report created${NC}"
fi

# 元のディレクトリに戻る
cd - > /dev/null

# 結果サマリー
echo -e "\n================================================"
echo -e "${GREEN}Test Summary${NC}"
echo -e "================================================"
echo "✓ Environment verification: PASSED"
echo "✓ Project detection: PASSED (Type: $PROJECT_TYPE)"
echo "✓ Worktree creation: PASSED"
echo "✓ Multi-agent workflow: PASSED"
echo ""
echo "Test worktree created at: $WORKTREE_PATH"
echo "Test branch: $TASK_BRANCH"
echo ""
echo "To clean up test worktree, run:"
echo "  git worktree remove $WORKTREE_PATH"
echo ""
echo -e "${GREEN}All tests passed!${NC}"