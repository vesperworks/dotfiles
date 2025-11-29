#!/bin/bash
# worktree-utils.sh - 基本的なユーティリティ関数（簡素化版）
#
# 役割進化型ワークフローのための最小限のユーティリティ関数を提供します。
# worktree関連の機能はすべて削除されました。

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

# エラーハンドリング
handle_error() {
    local exit_code=$1
    local error_msg=$2
    
    log_error "$error_msg (Exit code: $exit_code)"
    
    # テストモードの場合はexitしない
    if [[ "${TEST_MODE:-false}" != "true" ]]; then
        exit "$exit_code"
    fi
    return "$exit_code"
}

# 環境検証
verify_environment() {
    log_info "Verifying environment..."
    
    local missing_tools=()
    
    # 必須ツールのチェック
    for tool in git; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    # gitリポジトリの確認
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        log_error "Not inside a git repository"
        return 1
    fi
    
    log_success "Environment verification passed"
    return 0
}

# プロジェクトタイプの検出
detect_project_type() {
    local project_root="${1:-.}"
    
    if [[ -f "$project_root/package.json" ]]; then
        echo "node"
    elif [[ -f "$project_root/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$project_root/go.mod" ]]; then
        echo "go"
    elif [[ -f "$project_root/requirements.txt" ]] || [[ -f "$project_root/setup.py" ]]; then
        echo "python"
    elif [[ -f "$project_root/Makefile" ]]; then
        echo "make"
    else
        echo "unknown"
    fi
}

# テストコマンドの取得
get_test_command() {
    local project_type="${1:-}"
    
    case "$project_type" in
        node)
            if [[ -f "package.json" ]] && rg -q '"test"' package.json; then
                echo "nr test"
            else
                echo ""
            fi
            ;;
        rust)
            echo "cargo test"
            ;;
        python)
            echo "uv run pytest"
            ;;
        make)
            if rg -q '^test:' Makefile; then
                echo "make test"
            else
                echo ""
            fi
            ;;
        *)
            echo ""
            ;;
    esac
}

# テスト実行とチェック
run_tests() {
    local project_type="${1:-}"
    
    local test_cmd=$(get_test_command "$project_type")
    
    if [[ -z "$test_cmd" ]]; then
        log_warning "No test command found for project type: $project_type"
        return 0
    fi
    
    log_info "Running tests: $test_cmd"
    if ! eval "$test_cmd"; then
        log_error "Tests failed"
        return 1
    fi
    
    log_success "All tests passed"
    return 0
}

# Lintコマンドの取得
get_lint_command() {
    local project_type="${1:-}"
    
    case "$project_type" in
        node)
            if [[ -f "package.json" ]] && rg -q '"lint"' package.json; then
                echo "nr lint"
            else
                echo ""
            fi
            ;;
        rust)
            echo "cargo clippy"
            ;;
        python)
            echo "uv run ruff check"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Formatコマンドの取得
get_format_command() {
    local project_type="${1:-}"
    
    case "$project_type" in
        node)
            if [[ -f "package.json" ]] && rg -q '"format"' package.json; then
                echo "nr format"
            else
                echo ""
            fi
            ;;
        rust)
            echo "cargo fmt"
            ;;
        python)
            echo "uv run ruff format"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Buildコマンドの取得
get_build_command() {
    local project_type="${1:-}"
    
    case "$project_type" in
        node)
            if [[ -f "package.json" ]] && rg -q '"build"' package.json; then
                echo "nr build"
            else
                echo ""
            fi
            ;;
        rust)
            echo "cargo build"
            ;;
        python)
            # Pythonは通常ビルドステップなし
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# 品質チェック（Lint, Format, Test, Build）
run_quality_checks() {
    local project_type="${1:-}"
    
    log_info "Running quality checks for $project_type project..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local all_passed=true
    
    # 1. Lint
    local lint_cmd=$(get_lint_command "$project_type")
    if [[ -n "$lint_cmd" ]]; then
        log_info "Running lint: $lint_cmd"
        if ! eval "$lint_cmd"; then
            log_error "❌ Lint failed - code quality issues detected"
            all_passed=false
        else
            log_success "✅ Lint passed"
        fi
    fi
    
    # 2. Format
    local format_cmd=$(get_format_command "$project_type")
    if [[ -n "$format_cmd" ]]; then
        log_info "Running format check: $format_cmd --check 2>/dev/null || $format_cmd"
        if ! eval "$format_cmd --check 2>/dev/null || $format_cmd"; then
            log_error "❌ Format check failed - code formatting issues detected"
            all_passed=false
        else
            log_success "✅ Format check passed"
        fi
    fi
    
    # 3. Test
    local test_cmd=$(get_test_command "$project_type")
    if [[ -n "$test_cmd" ]]; then
        log_info "Running tests: $test_cmd"
        if ! eval "$test_cmd"; then
            log_error "❌ Tests failed"
            all_passed=false
        else
            log_success "✅ Tests passed"
        fi
    fi
    
    # 4. Build
    local build_cmd=$(get_build_command "$project_type")
    if [[ -n "$build_cmd" ]]; then
        log_info "Running build: $build_cmd"
        if ! eval "$build_cmd"; then
            log_error "❌ Build failed"
            all_passed=false
        else
            log_success "✅ Build succeeded"
        fi
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ "$all_passed" == "true" ]]; then
        log_success "All quality checks passed! ✨"
        return 0
    else
        log_error "Some quality checks failed. Implementation not accepted."
        return 1
    fi
}

# 安全なコマンド実行
safe_execute() {
    local command="$1"
    local error_msg="${2:-Command failed}"
    
    log_info "Executing: $command"
    if ! eval "$command"; then
        handle_error $? "$error_msg"
    fi
}

# git操作の標準化
git_commit() {
    local message="$1"
    local files="${2:-.}"
    
    git add $files || return 1
    git commit -m "$message" || return 1
    log_success "Committed: $message"
}

# 進捗表示
show_progress() {
    local current_phase="$1"
    local total_phases="${2:-5}"
    local phase_number="${3:-1}"
    
    local progress=$((phase_number * 100 / total_phases))
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Progress: ${progress}% - ${current_phase}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# コマンドラインオプションの解析（簡素化版）
parse_workflow_options() {
    local args=("$@")
    
    # デフォルト値
    TASK_DESCRIPTION=""
    CLEANUP_DAYS="7"
    AUTO_CLEANUP="false"
    
    # オプション解析
    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            --cleanup)
                AUTO_CLEANUP="true"
                ;;
            --cleanup-days)
                ((i++))
                if [[ $i -lt ${#args[@]} ]]; then
                    CLEANUP_DAYS="${args[$i]}"
                fi
                ;;
            *)
                # タスク説明として扱う
                if [[ -z "${TASK_DESCRIPTION:-}" ]]; then
                    TASK_DESCRIPTION="${args[$i]}"
                else
                    TASK_DESCRIPTION="$TASK_DESCRIPTION ${args[$i]}"
                fi
                ;;
        esac
        ((i++))
    done
    
    # エクスポート
    export TASK_DESCRIPTION CLEANUP_DAYS AUTO_CLEANUP
}

# プロンプトファイルの読み込み（デフォルト値付き）
load_prompt() {
    local prompt_file="$1"
    local default_prompt="$2"
    
    if [[ -f "$prompt_file" ]]; then
        bat --style=plain "$prompt_file"
    else
        log_warning "Prompt file not found: $prompt_file"
        echo "$default_prompt"
    fi
}

# GitHub PR作成機能（簡素化版）
create_pull_request() {
    local branch_name="$1"
    local task_description="$2"
    local pr_body="${3:-Task: $task_description}"
    
    # ghコマンドの存在確認
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        log_info "Install with: brew install gh"
        return 1
    fi
    
    # 認証確認
    if ! gh auth status &>/dev/null; then
        log_error "Not authenticated with GitHub"
        log_info "Run: gh auth login"
        return 1
    fi
    
    # ブランチをプッシュ
    log_info "Pushing branch to remote..."
    if ! git push -u origin "$branch_name"; then
        log_error "Failed to push branch"
        return 1
    fi
    
    # PR作成
    log_info "Creating pull request..."
    if gh pr create \
        --title "$task_description" \
        --body "$pr_body" \
        --base main \
        --head "$branch_name"; then
        
        log_success "Pull request created successfully"
        return 0
    else
        log_error "Failed to create pull request"
        return 1
    fi
}

# デフォルトプロンプト定義（役割進化型用に更新）
DEFAULT_EXPLORER_PROMPT="あなたはExplorerです。以下の観点で調査してください：
1. 既存コードの理解
2. 要件の明確化
3. 制約事項の特定
4. 関連ファイルの洗い出し
5. 結果を./tmp/に保存"

DEFAULT_ANALYST_PROMPT="あなたはAnalystです。Explorerの結果を基に分析してください：
1. 影響範囲の特定
2. リスク評価
3. 実装戦略の検討
4. 優先順位の決定
5. 結果を./tmp/に保存"

DEFAULT_DESIGNER_PROMPT="あなたはDesignerです。分析結果を基に設計してください：
1. アーキテクチャ設計
2. インターフェース定義
3. データ構造設計
4. テスト戦略
5. 結果を./tmp/に保存"

DEFAULT_DEVELOPER_PROMPT="あなたはDeveloperです。設計に基づいて実装してください：
1. コード実装
2. ユニットテスト作成
3. 段階的なコミット
4. ドキュメント更新
5. 結果を./tmp/に保存"

DEFAULT_REVIEWER_PROMPT="あなたはReviewerです。実装をレビューしてください：
1. コード品質確認
2. テスト実行
3. ドキュメント確認
4. 改善提案
5. 結果を./tmp/に保存"

# エクスポート
export -f log_info log_success log_warning log_error
export -f handle_error verify_environment detect_project_type
export -f get_test_command run_tests safe_execute git_commit
export -f show_progress parse_workflow_options load_prompt
export -f create_pull_request
export -f get_lint_command get_format_command get_build_command run_quality_checks

# デフォルトプロンプトのエクスポート
export DEFAULT_EXPLORER_PROMPT DEFAULT_ANALYST_PROMPT DEFAULT_DESIGNER_PROMPT
export DEFAULT_DEVELOPER_PROMPT DEFAULT_REVIEWER_PROMPT

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "worktree-utils.sh - Basic Utilities (Simplified)"
    echo ""
    echo "This is a simplified version without worktree support."
    echo "For role-based workflow, use role-utils.sh instead."
    echo ""
fi