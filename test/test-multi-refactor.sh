#!/bin/bash
# test-multi-refactor.sh - multi-refactor.mdのセッション分離修正をテスト

echo "Testing multi-refactor.md session separation fix..."

# 各フェーズが新しいセッションで環境変数とユーティリティ関数を使えることを確認

# 1. Step 1のテスト（環境変数の保存）
echo "=== Step 1: Testing environment variable persistence ==="
bash -c '
source .claude/scripts/worktree-utils.sh || exit 1
TASK_DESCRIPTION="test refactoring task"
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed "s/[^a-zA-Z0-9]/-/g" | tr "[:upper:]" "[:lower:]" | cut -c1-30)
ENV_FILE=".worktrees/.env-${TASK_ID}-test"
WORKTREE_PATH="/test/worktree"
REFACTOR_BRANCH="refactor/test"
FEATURE_NAME="test-feature"
PROJECT_TYPE="nodejs"

# 環境変数をファイルに保存
cat > "$ENV_FILE" << EOF
WORKTREE_PATH="$WORKTREE_PATH"
REFACTOR_BRANCH="$REFACTOR_BRANCH"
FEATURE_NAME="$FEATURE_NAME"
PROJECT_TYPE="$PROJECT_TYPE"
TASK_DESCRIPTION="$TASK_DESCRIPTION"
EOF

echo "Environment file created: $ENV_FILE"
cat "$ENV_FILE"
'

# 2. Phase 1 (Analysis) のテスト
echo -e "\n=== Phase 1: Testing Analysis phase in new session ==="
bash -c '
# 共通ユーティリティの再読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-*test 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    echo "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

# 変数と関数の確認
echo "WORKTREE_PATH=$WORKTREE_PATH"
echo "REFACTOR_BRANCH=$REFACTOR_BRANCH"
echo "FEATURE_NAME=$FEATURE_NAME"
echo "PROJECT_TYPE=$PROJECT_TYPE"

# 関数が使えることを確認
if type -t show_progress >/dev/null; then
    echo "✓ show_progress function available"
else
    echo "✗ show_progress function NOT available"
    exit 1
fi

if type -t create_phase_status >/dev/null; then
    echo "✓ create_phase_status function available"
else
    echo "✗ create_phase_status function NOT available"
    exit 1
fi
'

# 3. Phase 2 (Plan) のテスト
echo -e "\n=== Phase 2: Testing Plan phase in new session ==="
bash -c '
# 共通ユーティリティの再読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-*test 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    echo "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

# 変数確認
echo "TASK_DESCRIPTION=$TASK_DESCRIPTION"

# 関数が使えることを確認
if type -t check_phase_completed >/dev/null; then
    echo "✓ check_phase_completed function available"
else
    echo "✗ check_phase_completed function NOT available"
    exit 1
fi
'

# 4. Phase 3 (Refactor) のテスト
echo -e "\n=== Phase 3: Testing Refactor phase in new session ==="
bash -c '
# 共通ユーティリティの再読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-*test 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    echo "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

# 変数確認
echo "FEATURE_NAME=$FEATURE_NAME"

# 関数が使えることを確認
if type -t run_tests >/dev/null; then
    echo "✓ run_tests function available"
else
    echo "✗ run_tests function NOT available"
    exit 1
fi

if type -t rollback_on_error >/dev/null; then
    echo "✓ rollback_on_error function available"
else
    echo "✗ rollback_on_error function NOT available"
    exit 1
fi
'

# 5. Phase 4 (Verify) のテスト
echo -e "\n=== Phase 4: Testing Verify phase in new session ==="
bash -c '
# 共通ユーティリティの再読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-*test 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    echo "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

# 関数が使えることを確認
if type -t update_phase_status >/dev/null; then
    echo "✓ update_phase_status function available"
else
    echo "✗ update_phase_status function NOT available"
    exit 1
fi
'

# 6. Step 3 (Completion) のテスト
echo -e "\n=== Step 3: Testing Completion step in new session ==="
bash -c '
# 共通ユーティリティの再読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-*test 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    echo "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

# 変数確認
echo "REFACTOR_BRANCH=$REFACTOR_BRANCH"

# 関数が使えることを確認
if type -t merge_to_main >/dev/null; then
    echo "✓ merge_to_main function available"
else
    echo "✗ merge_to_main function NOT available"
    exit 1
fi

if type -t create_pull_request >/dev/null; then
    echo "✓ create_pull_request function available"
else
    echo "✗ create_pull_request function NOT available"
    exit 1
fi

if type -t cleanup_worktree >/dev/null; then
    echo "✓ cleanup_worktree function available"
else
    echo "✗ cleanup_worktree function NOT available"
    exit 1
fi
'

# クリーンアップ
echo -e "\n=== Cleanup ==="
rm -f .worktrees/.env-*test
echo "Test environment files cleaned up"

echo -e "\n=== Test Summary ==="
echo "If all functions and variables were available in each phase, the session separation fix is working correctly!"