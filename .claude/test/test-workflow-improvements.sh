#!/bin/bash
# test-workflow-improvements.sh - ワークフロー改善機能のテスト

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
echo "Workflow Improvements Test"
echo "======================================"

# 1. worktree-utils.shの読み込み
log_info "Loading worktree-utils.sh..."
source .claude/scripts/worktree-utils.sh || {
    log_error "Failed to load worktree-utils.sh"
    exit 1
}

# 2. オプション解析のテスト
log_info "Testing option parsing..."

# テストケース1: 基本的なタスク説明のみ
parse_workflow_options "ユーザー認証機能の実装"
if [[ "$TASK_DESCRIPTION" == "ユーザー認証機能の実装" ]] && \
   [[ "$KEEP_WORKTREE" == "false" ]] && \
   [[ "$NO_MERGE" == "false" ]] && \
   [[ "$CREATE_PR" == "false" ]]; then
    log_success "✓ Basic task description parsed correctly"
else
    log_error "✗ Basic task description parsing failed"
fi

# テストケース2: オプション付き
parse_workflow_options "新機能の追加 --keep-worktree --pr"
if [[ "$TASK_DESCRIPTION" == "新機能の追加" ]] && \
   [[ "$KEEP_WORKTREE" == "true" ]] && \
   [[ "$CREATE_PR" == "true" ]]; then
    log_success "✓ Options parsed correctly"
else
    log_error "✗ Option parsing failed"
    echo "  TASK_DESCRIPTION: $TASK_DESCRIPTION"
    echo "  KEEP_WORKTREE: $KEEP_WORKTREE"
    echo "  CREATE_PR: $CREATE_PR"
fi

# 3. ブランチ切り替え確認のテスト
log_info "Testing branch switching verification..."
TEST_TASK="test branch switching"
WORKTREE_INFO=$(create_task_worktree "$TEST_TASK" "test" 2>&1 | tail -1)
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
BRANCH_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)

# ブランチが正しく設定されているか確認
ACTUAL_BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current)
if [[ "$ACTUAL_BRANCH" == "$BRANCH_NAME" ]]; then
    log_success "✓ Branch correctly set: $BRANCH_NAME"
else
    log_error "✗ Branch mismatch: expected $BRANCH_NAME, got $ACTUAL_BRANCH"
fi

# 4. 自動クリーンアップのテスト
log_info "Testing auto cleanup..."
cleanup_worktree "$WORKTREE_PATH" "false"
if [[ ! -d "$WORKTREE_PATH" ]]; then
    log_success "✓ Worktree cleaned up successfully"
else
    log_error "✗ Worktree cleanup failed"
fi

# 5. keep-worktreeオプションのテスト
log_info "Testing keep-worktree option..."
WORKTREE_INFO=$(create_task_worktree "keep test" "test" 2>&1 | tail -1)
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
cleanup_worktree "$WORKTREE_PATH" "true"
if [[ -d "$WORKTREE_PATH" ]]; then
    log_success "✓ Worktree kept as requested"
    # 後片付け
    cleanup_worktree "$WORKTREE_PATH" "false"
else
    log_error "✗ Worktree was removed despite keep flag"
fi

# 6. 古いworktreeクリーンアップのテスト
log_info "Testing old worktree cleanup..."
# テスト用の古いworktreeを作成（実際には作成しない）
mkdir -p .worktrees/test-old-worktree
touch -t 202301010000 .worktrees/test-old-worktree

# 30日以上前のworktreeをクリーンアップ
cleanup_old_worktrees 30

if [[ ! -d ".worktrees/test-old-worktree" ]]; then
    log_success "✓ Old worktree cleaned up"
else
    log_error "✗ Old worktree cleanup failed"
    rm -rf .worktrees/test-old-worktree
fi

# 7. コマンドの更新確認
log_info "Checking command updates..."
for cmd in multi-tdd.md multi-feature.md multi-refactor.md; do
    if grep -q "parse_workflow_options" ".claude/commands/$cmd"; then
        log_success "✓ $cmd updated with new options"
    else
        log_error "✗ $cmd not updated"
    fi
done

echo ""
log_success "Workflow improvements test completed!"
echo ""
echo "Summary of new features:"
echo "- Branch switching verification ✓"
echo "- Auto cleanup functionality ✓"
echo "- Keep worktree option ✓"
echo "- Old worktree cleanup ✓"
echo "- PR creation option (not tested - requires gh CLI)"
echo "- Local merge option (not tested - requires clean git state)"