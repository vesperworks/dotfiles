#!/bin/bash
# worktree-utils.sh - マルチエージェントワークフロー用共通ユーティリティ

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
    local worktree_path=${3:-}
    
    log_error "$error_msg (Exit code: $exit_code)"
    
    # worktreeのクリーンアップ
    if [[ -n "$worktree_path" ]] && [[ -d "$worktree_path" ]]; then
        log_warning "Cleaning up worktree: $worktree_path"
        git worktree remove --force "$worktree_path" 2>/dev/null || true
    fi
    
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
            if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
                echo "npm test"
            else
                echo ""
            fi
            ;;
        rust)
            echo "cargo test"
            ;;
        go)
            echo "go test ./..."
            ;;
        python)
            if command -v pytest &> /dev/null; then
                echo "pytest"
            else
                echo "python -m unittest"
            fi
            ;;
        make)
            if grep -q '^test:' Makefile; then
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

# worktree作成
create_task_worktree() {
    local task_description="$1"
    local task_type="${2:-task}"  # tdd, feature, refactor
    
    # タスク識別子生成
    local project_root=$(basename "$(pwd)")
    local task_id=$(echo "$task_description" | sed 's/[^a-zA-Z0-9]/-/g' | cut -c1-20)
    local timestamp=$(date +%Y%m%d-%H%M%S)
    
    # ブランチ名決定
    local branch_prefix
    case "$task_type" in
        tdd|bugfix)
            branch_prefix="bugfix"
            ;;
        feature)
            branch_prefix="feature"
            ;;
        refactor)
            branch_prefix="refactor"
            ;;
        *)
            branch_prefix="task"
            ;;
    esac
    
    local task_branch="${branch_prefix}/${task_id}-${timestamp}"
    local worktree_path="../${project_root}-${task_id}"
    
    # 既存worktreeのチェック
    if git worktree list | grep -q "$worktree_path"; then
        log_warning "Worktree already exists: $worktree_path"
        # タイムスタンプを追加して別名にする
        worktree_path="${worktree_path}-${timestamp}"
    fi
    
    # worktree作成
    log_info "Creating worktree: $worktree_path"
    if ! git worktree add "$worktree_path" -b "$task_branch" 2>/dev/null; then
        handle_error $? "Failed to create worktree" "$worktree_path"
    fi
    
    # .claude設定をコピー
    if [[ -d ".claude" ]]; then
        cp -r .claude "$worktree_path/" || log_warning "Failed to copy .claude directory"
    fi
    
    # 結果を返す
    echo "$worktree_path|$task_branch"
}

# worktreeのクリーンアップ
cleanup_worktree() {
    local worktree_path="$1"
    
    if [[ -d "$worktree_path" ]]; then
        log_info "Cleaning up worktree: $worktree_path"
        git worktree remove --force "$worktree_path" 2>/dev/null || {
            log_warning "Failed to remove worktree, trying manual cleanup"
            rm -rf "$worktree_path"
        }
    fi
}

# プロンプトファイルの読み込み（デフォルト値付き）
load_prompt() {
    local prompt_file="$1"
    local default_prompt="$2"
    
    if [[ -f "$prompt_file" ]]; then
        cat "$prompt_file"
    else
        log_warning "Prompt file not found: $prompt_file"
        echo "$default_prompt"
    fi
}

# 安全なコマンド実行
safe_execute() {
    local command="$1"
    local error_msg="${2:-Command failed}"
    local worktree_path="${3:-}"
    
    log_info "Executing: $command"
    if ! eval "$command"; then
        handle_error $? "$error_msg" "$worktree_path"
    fi
}

# テスト実行とチェック
run_tests() {
    local project_type="${1:-}"
    local worktree_path="${2:-}"
    
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

# git操作の標準化
git_commit_phase() {
    local phase="$1"
    local message="$2"
    local files="${3:-.}"
    
    git add $files || return 1
    git commit -m "[$phase] $message" || return 1
    log_success "Committed: [$phase] $message"
}

# 進捗表示
show_progress() {
    local current_phase="$1"
    local total_phases="${2:-4}"
    local phase_number="${3:-1}"
    
    local progress=$((phase_number * 100 / total_phases))
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Progress: ${progress}% - ${current_phase}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# デフォルトプロンプト定義
DEFAULT_EXPLORER_PROMPT="あなたはExplorerエージェントです。以下のタスクについて調査・分析を行ってください：
1. 現在のコードベースを調査・分析
2. 問題の根本原因を特定
3. 影響範囲と依存関係を明確化
4. 要件と制約を整理
5. 結果をexplore-results.mdに保存"

DEFAULT_PLANNER_PROMPT="あなたはPlannerエージェントです。Explore結果を基に実装戦略を策定してください：
1. 実装戦略を策定
2. TDD手順での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果をplan-results.mdに保存"

DEFAULT_CODER_PROMPT="あなたはCoderエージェントです。計画に基づいてTDD実装を行ってください：
1. 失敗するテストを先に作成
2. テストを通すための最小実装
3. コード品質向上のリファクタリング
4. 結果をcoding-results.mdに保存"

# エクスポート
export -f log_info log_success log_warning log_error
export -f handle_error verify_environment detect_project_type
export -f get_test_command create_task_worktree cleanup_worktree
export -f load_prompt safe_execute run_tests git_commit_phase
export -f show_progress

# デフォルトプロンプトのエクスポート
export DEFAULT_EXPLORER_PROMPT DEFAULT_PLANNER_PROMPT DEFAULT_CODER_PROMPT