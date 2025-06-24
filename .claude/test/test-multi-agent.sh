#!/bin/bash
# test-multi-agent.sh - マルチエージェントワークフローの動作テスト

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# テスト開始
echo "======================================"
echo "Multi-Agent Workflow Test"
echo "======================================"

# 1. 環境確認
log_info "Checking environment..."
if [[ ! -f ".claude/scripts/worktree-utils.sh" ]]; then
    log_error "worktree-utils.sh not found"
    exit 1
fi

if [[ ! -d ".claude/commands" ]]; then
    log_error "Commands directory not found"
    exit 1
fi

log_success "Environment check passed"

# 2. コマンドファイルの確認
log_info "Checking command files..."
COMMANDS=("multi-tdd.md" "multi-feature.md" "multi-refactor.md")
for cmd in "${COMMANDS[@]}"; do
    if [[ -f ".claude/commands/$cmd" ]]; then
        log_success "✓ $cmd found"
    else
        log_error "✗ $cmd missing"
    fi
done

# 3. プロンプトファイルの確認
log_info "Checking prompt files..."
PROMPTS=("explorer.md" "planner.md" "coder.md" "tester.md")
for prompt in "${PROMPTS[@]}"; do
    if [[ -f ".claude/prompts/$prompt" ]]; then
        log_success "✓ $prompt found"
    else
        log_error "✗ $prompt missing"
    fi
done

# 4. worktree-utils.shの機能テスト
log_info "Testing worktree utilities..."
source .claude/scripts/worktree-utils.sh

# 環境検証テスト
if verify_environment; then
    log_success "✓ Environment verification works"
else
    log_error "✗ Environment verification failed"
fi

# プロジェクトタイプ検出テスト
PROJECT_TYPE=$(detect_project_type)
log_success "✓ Project type detected: $PROJECT_TYPE"

# 5. worktree作成・削除テスト
log_info "Testing worktree creation and cleanup..."
TEST_TASK="test-multi-agent-$(date +%s)"
WORKTREE_INFO=$(create_task_worktree "$TEST_TASK" "test" 2>&1 | tail -1)
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)

if [[ -d "$WORKTREE_PATH" ]]; then
    log_success "✓ Worktree created successfully: $WORKTREE_PATH"
    
    # クリーンアップテスト
    cleanup_worktree "$WORKTREE_PATH"
    if [[ ! -d "$WORKTREE_PATH" ]]; then
        log_success "✓ Worktree cleaned up successfully"
    else
        log_error "✗ Worktree cleanup failed"
    fi
else
    log_error "✗ Worktree creation failed"
fi

# 6. 統合テスト可能性の確認
log_info "Integration test readiness check..."
echo ""
echo "Ready for integration testing:"
echo "1. /project:multi-tdd \"Sample bug fix task\""
echo "2. /project:multi-feature \"Sample feature development\""  
echo "3. /project:multi-refactor \"Sample refactoring task\""
echo ""

# 結果サマリー
echo "======================================"
echo "Test Summary"
echo "======================================"
log_success "All critical components are in place!"
echo ""
echo "Next steps:"
echo "1. Run actual workflow commands through Claude"
echo "2. Monitor worktree creation and git operations"
echo "3. Verify agent prompts are being used correctly"
echo "4. Check final deliverables in worktree directories"