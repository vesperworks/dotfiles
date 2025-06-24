#!/bin/bash
# worktree-utils.sh - マルチエージェントワークフロー用共通ユーティリティ

set -euo pipefail

# 並列エージェント実行機能を読み込み
source "$(dirname "${BASH_SOURCE[0]}")/parallel-agent-utils.sh"

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

# プロジェクトの初回セットアップチェック
check_and_setup_project_structure() {
    # .worktreesディレクトリが存在しない場合は作成
    if [[ ! -d ".worktrees" ]]; then
        log_info "Creating .worktrees directory for worktree management..."
        mkdir -p .worktrees
    fi
    
    # .gitignoreに.worktrees/を追加（まだ追加されていない場合）
    if [[ -f ".gitignore" ]]; then
        if ! grep -q "^\.worktrees/$" .gitignore && ! grep -q "^\.worktrees$" .gitignore; then
            echo ".worktrees/" >> .gitignore
            log_info "Added .worktrees/ to .gitignore"
        fi
    else
        echo ".worktrees/" > .gitignore
        log_info "Created .gitignore with .worktrees/ entry"
    fi
    
    return 0
}

# worktree作成
create_task_worktree() {
    local task_description="$1"
    local task_type="${2:-task}"  # tdd, feature, refactor
    
    # 初回セットアップチェック
    check_and_setup_project_structure
    
    # タスク識別子生成
    local project_root=$(basename "$(pwd)")
    # 日本語を含む場合でも安全にブランチ名を生成
    local task_id=$(echo "$task_description" | \
        iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || echo "$task_description")
    
    # 英数字とハイフンのみに変換
    task_id=$(echo "$task_id" | \
        sed 's/[^a-zA-Z0-9]/-/g' | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/--*/-/g' | \
        sed 's/^-//' | \
        sed 's/-$//' | \
        cut -c1-30)
    
    # 空の場合はデフォルト値を設定
    if [[ -z "$task_id" ]]; then
        task_id="task"
    fi
    
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
    
    # ブランチ名（タイムスタンプなし - 1 feature = 1 branch）
    local task_branch="${branch_prefix}/${task_id}"
    # .worktreesサブディレクトリ内にworktreeを作成
    local worktree_path=".worktrees/${branch_prefix}-${task_id}"
    
    # 既存worktreeのチェック
    if [[ -d "$worktree_path" ]]; then
        # 既存worktreeが同じブランチを使用しているか確認
        local existing_branch=$(git -C "$worktree_path" branch --show-current 2>/dev/null || echo "")
        if [[ "$existing_branch" == "$task_branch" ]]; then
            log_info "Reusing existing worktree for branch: $task_branch"
            echo "$worktree_path|$task_branch|$(get_feature_name "$task_description" "$task_type")"
            return 0
        else
            # 異なるブランチの場合は別のworktreeを作成
            log_warning "Worktree exists with different branch: $existing_branch"
            worktree_path=".worktrees/${branch_prefix}-${task_id}-${timestamp}"
        fi
    fi
    
    # worktree作成（既存ブランチがあれば再利用）
    log_info "Creating worktree: $worktree_path"
    if git show-ref --verify --quiet "refs/heads/${task_branch}"; then
        log_info "Using existing branch: $task_branch"
        git worktree add "$worktree_path" "$task_branch" >/dev/null 2>&1
        local exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            handle_error $exit_code "Failed to create worktree with existing branch" "$worktree_path"
        fi
    else
        log_info "Creating new branch: $task_branch"
        git worktree add "$worktree_path" -b "$task_branch" >/dev/null 2>&1
        local exit_code=$?
        if [[ $exit_code -ne 0 ]]; then
            handle_error $exit_code "Failed to create worktree with new branch" "$worktree_path"
        fi
    fi
    
    # ブランチが正しく作成されたか確認
    local actual_branch=$(git -C "$worktree_path" branch --show-current)
    if [[ "$actual_branch" != "$task_branch" ]]; then
        log_error "Branch mismatch! Expected: $task_branch, Actual: $actual_branch"
        cleanup_worktree "$worktree_path"
        return 1
    fi
    log_success "Branch correctly set to: $task_branch"
    
    # .claude設定をコピー
    if [[ -d ".claude" ]]; then
        cp -r .claude "$worktree_path/" || log_warning "Failed to copy .claude directory"
    fi
    
    # feature名を生成
    local feature_name=$(get_feature_name "$task_description" "$task_type")
    
    # 構造化されたディレクトリを作成
    create_structured_directories "$worktree_path" "$feature_name"
    
    # 結果を返す（feature名も含める）
    echo "$worktree_path|$task_branch|$feature_name"
}

# worktreeのクリーンアップ
cleanup_worktree() {
    local worktree_path="$1"
    local keep_worktree="${2:-false}"
    
    if [[ "$keep_worktree" == "true" ]]; then
        log_info "Keeping worktree as requested: $worktree_path"
        return 0
    fi
    
    if [[ -d "$worktree_path" ]]; then
        log_info "Cleaning up worktree: $worktree_path"
        git worktree remove --force "$worktree_path" 2>/dev/null || {
            log_warning "Failed to remove worktree, trying manual cleanup"
            rm -rf "$worktree_path"
        }
        log_success "Worktree cleaned up: $worktree_path"
    fi
}

# 古いworktreeのクリーンアップ
cleanup_old_worktrees() {
    local days_old="${1:-7}"  # デフォルトは7日以上前
    
    log_info "Cleaning up worktrees older than $days_old days..."
    
    local count=0
    for worktree_dir in .worktrees/*; do
        if [[ -d "$worktree_dir" ]]; then
            # ディレクトリの最終更新日を確認
            if [[ $(find "$worktree_dir" -maxdepth 0 -mtime +$days_old 2>/dev/null) ]]; then
                log_info "Removing old worktree: $worktree_dir"
                cleanup_worktree "$worktree_dir"
                ((count++))
            fi
        fi
    done
    
    if [[ $count -eq 0 ]]; then
        log_info "No old worktrees found"
    else
        log_success "Cleaned up $count old worktrees"
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

# フェーズ管理システム
create_phase_status() {
    local worktree_path="$1"
    local phase_name="$2"
    local status="${3:-started}"
    
    local status_dir="$worktree_path/.status"
    mkdir -p "$status_dir"
    
    echo "{
  \"phase\": \"$phase_name\",
  \"status\": \"$status\",
  \"timestamp\": \"$(date -Iseconds)\",
  \"pid\": $$
}" > "$status_dir/${phase_name}.json"
}

check_phase_completed() {
    local worktree_path="$1"
    local phase_name="$2"
    
    local status_file="$worktree_path/.status/${phase_name}.json"
    if [[ -f "$status_file" ]]; then
        local status=$(grep '"status"' "$status_file" | cut -d'"' -f4)
        if [[ "$status" == "completed" ]]; then
            return 0
        fi
    fi
    return 1
}

update_phase_status() {
    local worktree_path="$1"
    local phase_name="$2"
    local status="$3"
    
    create_phase_status "$worktree_path" "$phase_name" "$status"
}

rollback_on_error() {
    local worktree_path="$1"
    local phase_name="$2"
    local error_msg="$3"
    
    log_error "Phase '$phase_name' failed: $error_msg"
    update_phase_status "$worktree_path" "$phase_name" "failed"
    
    # 失敗した状態をレポートに記録
    local error_report="$worktree_path/error-report.md"
    echo "# Error Report

## Phase: $phase_name
## Time: $(date)
## Error: $error_msg

### Worktree State
$(git -C "$worktree_path" status --short)

### Last Commit
$(git -C "$worktree_path" log -1 --oneline)

### Rollback Instructions
1. Review the error above
2. Fix the issue manually or restart the workflow
3. Clean up with: git worktree remove $worktree_path
" > "$error_report"
    
    git -C "$worktree_path" add "$error_report" 2>/dev/null
    git -C "$worktree_path" commit -m "[ERROR] $phase_name failed: $error_msg" 2>/dev/null
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

# コマンドラインオプションの解析
parse_workflow_options() {
    local args=("$@")
    
    # デフォルト値
    KEEP_WORKTREE="false"
    NO_MERGE="false"
    CREATE_PR="false"
    NO_DRAFT="false"
    AUTO_CLEANUP="true"
    CLEANUP_DAYS="7"
    
    # オプション解析
    local i=0
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            --keep-worktree)
                KEEP_WORKTREE="true"
                AUTO_CLEANUP="false"
                ;;
            --no-merge)
                NO_MERGE="true"
                ;;
            --pr)
                CREATE_PR="true"
                ;;
            --no-draft)
                NO_DRAFT="true"
                ;;
            --no-cleanup)
                AUTO_CLEANUP="false"
                ;;
            --cleanup-days)
                ((i++))
                CLEANUP_DAYS="${args[$i]}"
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
    export KEEP_WORKTREE NO_MERGE CREATE_PR NO_DRAFT AUTO_CLEANUP CLEANUP_DAYS TASK_DESCRIPTION
}

# 構造化されたディレクトリを作成
create_structured_directories() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "Creating structured directories for feature: $feature_name"
    
    # テストディレクトリ構造
    mkdir -p "$worktree_path/test/$feature_name/unit"
    mkdir -p "$worktree_path/test/$feature_name/integration"
    mkdir -p "$worktree_path/test/$feature_name/e2e"
    
    # レポートディレクトリ構造
    mkdir -p "$worktree_path/report/$feature_name/coverage"
    mkdir -p "$worktree_path/report/$feature_name/performance"
    mkdir -p "$worktree_path/report/$feature_name/quality"
    
    # ソースコードディレクトリ（必要に応じて）
    mkdir -p "$worktree_path/src/$feature_name"
    
    log_success "Structured directories created"
}

# タスクタイプからfeature名を生成
get_feature_name() {
    local task_description="$1"
    local task_type="$2"
    
    # タスク説明から意味のあるfeature名を抽出
    # 日本語文字を英語に変換してから処理
    local feature_name=""
    
    # 一般的なキーワードを英語に変換
    local translated=$(echo "$task_description" | \
        sed -e 's/認証機能/auth/g' \
            -e 's/認証/auth/g' \
            -e 's/ログイン/login/g' \
            -e 's/ユーザー/user/g' \
            -e 's/データベース/database/g' \
            -e 's/修正/fix/g' \
            -e 's/追加/add/g' \
            -e 's/削除/delete/g' \
            -e 's/更新/update/g' \
            -e 's/機能/feature/g' \
            -e 's/リファクタリング/refactor/g' \
            -e 's/テスト/test/g' \
            -e 's/バグ/bug/g' \
            -e 's/有効期限/expiry/g' \
            -e 's/チェック/check/g' \
            -e 's/不具合/issue/g' \
            -e 's/を/ /g' \
            -e 's/の/ /g')
    
    # 英数字とスペースのみ抽出して処理
    feature_name=$(echo "$translated" | \
        sed 's/[^a-zA-Z0-9 ]//g' | \
        tr '[:upper:]' '[:lower:]' | \
        awk '{for(i=1;i<=NF&&i<=3;i++) printf "%s-", $i}' | \
        sed 's/-$//' | \
        sed 's/--*/-/g' | \
        cut -c1-30)  # 最大30文字に制限
    
    # それでも空の場合はタスクタイプ + タイムスタンプ
    if [[ -z "$feature_name" ]] || [[ "$feature_name" == "-" ]]; then
        feature_name="${task_type}-$(date +%Y%m%d-%H%M%S)"
    fi
    
    echo "$feature_name"
}

# ローカルマージ機能
merge_to_main() {
    local worktree_path="$1"
    local branch_name="$2"
    local no_merge="${3:-false}"
    
    if [[ "$no_merge" == "true" ]]; then
        log_info "Skipping merge as requested"
        return 0
    fi
    
    # 現在のブランチを保存
    local current_branch=$(git branch --show-current)
    
    log_info "Merging $branch_name to main..."
    
    # mainブランチに切り替え
    if ! git checkout main; then
        log_error "Failed to checkout main branch"
        return 1
    fi
    
    # 最新の状態に更新
    if ! git pull origin main --rebase 2>/dev/null; then
        log_warning "Could not pull latest main (maybe offline)"
    fi
    
    # マージ実行
    if ! git merge "$branch_name" --no-ff -m "Merge branch '$branch_name'"; then
        log_error "Merge failed - conflicts may need to be resolved"
        git checkout "$current_branch"
        return 1
    fi
    
    log_success "Successfully merged $branch_name to main"
    
    # 元のブランチに戻る
    git checkout "$current_branch" 2>/dev/null || true
    
    return 0
}

# GitHub PR作成機能
create_pull_request() {
    local worktree_path="$1"
    local branch_name="$2"
    local task_description="$3"
    local is_draft="${4:-true}"
    
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
    if ! git -C "$worktree_path" push -u origin "$branch_name"; then
        log_error "Failed to push branch"
        return 1
    fi
    
    # PR作成
    local pr_flags=""
    if [[ "$is_draft" == "true" ]]; then
        pr_flags="--draft"
    fi
    
    # 完了レポートがあれば使用
    local pr_body=""
    if [[ -f "$worktree_path/task-completion-report.md" ]]; then
        pr_body=$(cat "$worktree_path/task-completion-report.md")
    elif [[ -f "$worktree_path/feature-completion-report.md" ]]; then
        pr_body=$(cat "$worktree_path/feature-completion-report.md")
    elif [[ -f "$worktree_path/refactoring-completion-report.md" ]]; then
        pr_body=$(cat "$worktree_path/refactoring-completion-report.md")
    else
        pr_body="## Summary
Task: $task_description
Branch: $branch_name
Worktree: $worktree_path

Please review the changes."
    fi
    
    log_info "Creating pull request..."
    if gh pr create \
        --title "$task_description" \
        --body "$pr_body" \
        --base main \
        --head "$branch_name" \
        $pr_flags; then
        
        log_success "Pull request created successfully"
        
        # PR URLを表示
        local pr_url=$(gh pr view "$branch_name" --json url -q .url)
        echo "PR URL: $pr_url"
        
        return 0
    else
        log_error "Failed to create pull request"
        return 1
    fi
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
export -f parse_workflow_options
export -f get_test_command create_task_worktree cleanup_worktree
export -f load_prompt safe_execute run_tests git_commit_phase
export -f show_progress create_structured_directories get_feature_name
export -f cleanup_old_worktrees merge_to_main create_pull_request
export -f create_phase_status check_phase_completed update_phase_status rollback_on_error

# デフォルトプロンプトのエクスポート
export DEFAULT_EXPLORER_PROMPT DEFAULT_PLANNER_PROMPT DEFAULT_CODER_PROMPT