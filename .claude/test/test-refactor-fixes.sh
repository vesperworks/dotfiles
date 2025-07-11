#!/bin/bash
# test-refactor-fixes.sh - multi-refactorバグ修正のテストスクリプト

set -uo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ログ関数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# テスト結果カウンター
TESTS_PASSED=0
TESTS_FAILED=0

# ユーティリティの読み込み
# worktree-utils.shのset -eを無効化
OLD_E_FLAG=$-
set +e
source .claude/scripts/worktree-utils.sh
# 元の状態に戻す
if [[ $OLD_E_FLAG == *e* ]]; then
    set -e
fi

# テスト1: 日本語パラメータでのブランチ名生成
test_japanese_branch_name() {
    log_info "Testing Japanese parameter handling..."
    
    # 日本語タスク説明
    local task_desc="認証機能のJWT有効期限チェック不具合を修正"
    local feature_name=$(get_feature_name "$task_desc" "refactor")
    
    log_info "Task description: $task_desc"
    log_info "Generated feature name: $feature_name"
    
    # 空でないことを確認
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is empty!"
        ((TESTS_FAILED++))
        return 1
    fi
    
    # 特殊文字がないことを確認
    if [[ "$feature_name" =~ [^a-zA-Z0-9-] ]]; then
        log_error "Feature name contains invalid characters: $feature_name"
        ((TESTS_FAILED++))
        return 1
    fi
    
    log_success "Japanese parameter handling test passed"
    ((TESTS_PASSED++))
}

# テスト2: 変数名統一の確認
test_variable_consistency() {
    log_info "Testing variable name consistency..."
    
    # parse_workflow_optionsのテスト
    parse_workflow_options "テストタスク" "--keep-worktree" "--pr"
    
    # TASK_DESCRIPTIONが設定されているか確認
    if [[ -z "$TASK_DESCRIPTION" ]]; then
        log_error "TASK_DESCRIPTION not set by parse_workflow_options"
        ((TESTS_FAILED++))
        return 1
    fi
    
    if [[ "$TASK_DESCRIPTION" != "テストタスク" ]]; then
        log_error "TASK_DESCRIPTION has wrong value: $TASK_DESCRIPTION"
        ((TESTS_FAILED++))
        return 1
    fi
    
    # オプションが正しく解析されているか確認
    if [[ "$KEEP_WORKTREE" != "true" ]] || [[ "$CREATE_PR" != "true" ]]; then
        log_error "Options not parsed correctly"
        ((TESTS_FAILED++))
        return 1
    fi
    
    log_success "Variable consistency test passed"
    ((TESTS_PASSED++))
}

# テスト3: フェーズ管理システム
test_phase_management() {
    log_info "Testing phase management system..."
    
    # テスト用一時ディレクトリ
    local test_dir="/tmp/test-phase-$$"
    mkdir -p "$test_dir"
    
    # フェーズステータス作成
    create_phase_status "$test_dir" "analysis" "started"
    
    # ステータスファイルが作成されたか確認
    if [[ ! -f "$test_dir/.status/analysis.json" ]]; then
        log_error "Phase status file not created"
        ((TESTS_FAILED++))
        rm -rf "$test_dir"
        return 1
    fi
    
    # フェーズが完了していないことを確認
    if check_phase_completed "$test_dir" "analysis"; then
        log_error "Phase should not be completed yet"
        ((TESTS_FAILED++))
        rm -rf "$test_dir"
        return 1
    fi
    
    # フェーズを完了に更新
    update_phase_status "$test_dir" "analysis" "completed"
    
    # フェーズが完了したことを確認
    if ! check_phase_completed "$test_dir" "analysis"; then
        log_error "Phase should be completed"
        ((TESTS_FAILED++))
        rm -rf "$test_dir"
        return 1
    fi
    
    # クリーンアップ
    rm -rf "$test_dir"
    
    log_success "Phase management test passed"
    ((TESTS_PASSED++))
}

# テスト4: エラーハンドリング
test_error_handling() {
    log_info "Testing error handling with rollback..."
    
    # テスト用一時ディレクトリ（gitリポジトリとして初期化）
    local test_dir="/tmp/test-error-$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    git init >/dev/null 2>&1
    echo "test" > test.txt
    git add . && git commit -m "Initial commit" >/dev/null 2>&1
    
    # エラー時のロールバック
    rollback_on_error "$test_dir" "test-phase" "Test error message"
    
    # エラーレポートが作成されたか確認
    if [[ ! -f "$test_dir/error-report.md" ]]; then
        log_error "Error report not created"
        ((TESTS_FAILED++))
        cd - >/dev/null
        rm -rf "$test_dir"
        return 1
    fi
    
    # ステータスがfailedになったか確認
    if [[ -f "$test_dir/.status/test-phase.json" ]]; then
        local status=$(rg '"status"' "$test_dir/.status/test-phase.json" | cut -d'"' -f4)
        if [[ "$status" != "failed" ]]; then
            log_error "Phase status should be 'failed', got: $status"
            ((TESTS_FAILED++))
            cd - >/dev/null
            rm -rf "$test_dir"
            return 1
        fi
    fi
    
    # クリーンアップ
    cd - >/dev/null
    rm -rf "$test_dir"
    
    log_success "Error handling test passed"
    ((TESTS_PASSED++))
}

# メインテスト実行
main() {
    log_info "=== Starting multi-refactor bug fix tests ==="
    
    # 各テストを実行
    test_japanese_branch_name
    test_variable_consistency
    test_phase_management
    test_error_handling
    
    # 結果サマリー
    echo ""
    log_info "=== Test Summary ==="
    log_success "Tests passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests failed: $TESTS_FAILED"
        exit 1
    else
        log_success "All tests passed!"
    fi
}

# テストを実行
main "$@"