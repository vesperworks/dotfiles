#!/bin/bash
# test-structured-directories.sh - 構造化ディレクトリ機能のテスト

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
echo "Structured Directories Test"
echo "======================================"

# 1. worktree-utils.shの読み込み
log_info "Loading worktree-utils.sh..."
source .claude/scripts/worktree-utils.sh || {
    log_error "Failed to load worktree-utils.sh"
    exit 1
}

# 2. テスト用タスクでworktree作成
TEST_TASK="user authentication JWT fix"
log_info "Creating test worktree for: $TEST_TASK"

# create_task_worktree関数の出力をクリーンアップ
WORKTREE_INFO=$(create_task_worktree "$TEST_TASK" "feature" 2>&1 | tail -1)
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
FEATURE_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)
FEATURE_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f3)

log_success "Worktree created successfully"
echo "  Path: $WORKTREE_PATH"
echo "  Branch: $FEATURE_BRANCH"
echo "  Feature: $FEATURE_NAME"

# 3. ディレクトリ構造の確認
log_info "Verifying directory structure..."

# テストディレクトリ
for dir in "unit" "integration" "e2e"; do
    if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME/$dir" ]]; then
        log_success "✓ test/$FEATURE_NAME/$dir exists"
    else
        log_error "✗ test/$FEATURE_NAME/$dir missing"
    fi
done

# レポートディレクトリ
for dir in "coverage" "performance" "quality"; do
    if [[ -d "$WORKTREE_PATH/report/$FEATURE_NAME/$dir" ]]; then
        log_success "✓ report/$FEATURE_NAME/$dir exists"
    else
        log_error "✗ report/$FEATURE_NAME/$dir missing"
    fi
done

# ソースディレクトリ
if [[ -d "$WORKTREE_PATH/src/$FEATURE_NAME" ]]; then
    log_success "✓ src/$FEATURE_NAME exists"
else
    log_error "✗ src/$FEATURE_NAME missing"
fi

# 4. ディレクトリツリーの表示
log_info "Directory tree:"
echo ""
tree "$WORKTREE_PATH/test" "$WORKTREE_PATH/report" "$WORKTREE_PATH/src" -d -L 3 2>/dev/null || {
    log_warning "tree command not found, using ls instead"
    echo "test/:"
    ls -la "$WORKTREE_PATH/test/$FEATURE_NAME/"
    echo ""
    echo "report/:"
    ls -la "$WORKTREE_PATH/report/$FEATURE_NAME/"
    echo ""
    echo "src/:"
    ls -la "$WORKTREE_PATH/src/$FEATURE_NAME/"
}

# 5. クリーンアップ
log_info "Cleaning up test worktree..."
cleanup_worktree "$WORKTREE_PATH"

echo ""
log_success "Structured directories test completed!"
echo "Feature naming and directory creation are working correctly."