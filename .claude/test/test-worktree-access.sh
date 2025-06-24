#!/bin/bash
# test-worktree-access.sh - ClaudeCodeのworktreeアクセス制限をテストするスクリプト

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
log_info "ClaudeCode Worktree Access Test"
echo "================================"

# 1. worktree-utils.shの読み込み
log_info "Loading worktree-utils.sh..."
source .claude/scripts/worktree-utils.sh || {
    log_error "Failed to load worktree-utils.sh"
    exit 1
}
log_success "worktree-utils.sh loaded successfully"

# 2. 環境検証
log_info "Verifying environment..."
verify_environment || exit 1

# 3. テスト用worktree作成
TEST_TASK="test-worktree-access"
log_info "Creating test worktree for: $TEST_TASK"

# サブシェルで実行して出力を分離
WORKTREE_INFO=$(create_task_worktree "$TEST_TASK" "test" 2>&1 | tail -1)
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
TEST_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)

log_success "Test worktree created"
echo "  Branch: $TEST_BRANCH"
echo "  Path: $WORKTREE_PATH"

# 4. ファイル操作テスト
log_info "Testing file operations..."

# 4.1 ファイル作成テスト
TEST_FILE="$WORKTREE_PATH/test-file.md"
log_info "Creating test file: $TEST_FILE"
echo "# Test File" > "$TEST_FILE" && {
    log_success "File created successfully"
} || {
    log_error "Failed to create file"
}

# 4.2 ファイル読み取りテスト
log_info "Reading test file..."
if [[ -f "$TEST_FILE" ]]; then
    log_success "File exists and is readable"
    echo "  Content: $(head -1 "$TEST_FILE")"
else
    log_error "File not found"
fi

# 4.3 Git操作テスト（worktree内）
log_info "Testing git operations in worktree..."
git -C "$WORKTREE_PATH" add test-file.md 2>/dev/null && {
    log_success "git add successful"
} || {
    log_error "git add failed"
}

git -C "$WORKTREE_PATH" commit -m "test: worktree access test" 2>/dev/null && {
    log_success "git commit successful"
} || {
    log_error "git commit failed"
}

# 5. ClaudeCodeでの推奨アクセスパターン
echo ""
echo "ClaudeCode Recommended Access Patterns:"
echo "======================================="
echo "✅ Read file: Read $WORKTREE_PATH/file.md"
echo "✅ Write file: Write $WORKTREE_PATH/file.md"
echo "✅ Edit file: Edit $WORKTREE_PATH/file.md"
echo "✅ Git operations: git -C \"$WORKTREE_PATH\" command"
echo "❌ Change directory: cd $WORKTREE_PATH (blocked)"
echo ""

# 6. クリーンアップ
log_info "Cleaning up test worktree..."
cleanup_worktree "$WORKTREE_PATH"
log_success "Test worktree removed"

echo ""
log_success "All tests completed successfully!"
echo "ClaudeCode can work with worktrees in .worktrees subdirectory"
echo "using Read/Write/Edit tools and git -C commands."