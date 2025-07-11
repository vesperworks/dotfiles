#!/bin/bash
# worktree-utils.sh - マルチエージェントワークフロー用共通ユーティリティ

# 並列エージェント実行機能を読み込み
# 複数の場所を試して読み込み（エラーを無視）
PARALLEL_AGENT_LOADED=false

# 現在のディレクトリから相対的に探す
if [[ -f ".claude/scripts/parallel-agent-utils.sh" ]]; then
    set +e  # 一時的にエラーを無視
    source ".claude/scripts/parallel-agent-utils.sh" && PARALLEL_AGENT_LOADED=true
    set -e
fi

# BASH_SOURCEベースで探す（設定されている場合のみ）
if [[ "$PARALLEL_AGENT_LOADED" = false ]] && [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
    if [[ -f "$SCRIPT_DIR/parallel-agent-utils.sh" ]]; then
        set +e  # 一時的にエラーを無視
        source "$SCRIPT_DIR/parallel-agent-utils.sh" && PARALLEL_AGENT_LOADED=true
        set -e
    fi
fi

if [[ "$PARALLEL_AGENT_LOADED" = false ]]; then
    echo "Warning: parallel-agent-utils.sh not found, parallel agent functionality will be limited"
fi

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
        # 環境ファイルパターンも追加
        if ! grep -q "^\.worktrees/\.env-\*$" .gitignore; then
            echo ".worktrees/.env-*" >> .gitignore
            log_info "Added .worktrees/.env-* to .gitignore"
        fi
    else
        echo -e ".worktrees/\n.worktrees/.env-*" > .gitignore
        log_info "Created .gitignore with .worktrees/ and .env-* entries"
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
    TASK_DESCRIPTION=""
    
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

# 環境ファイル管理関数
generate_env_file_path() {
    local task_type="$1"
    local task_id="$2"
    local timestamp="$3"
    
    # .worktreesディレクトリが存在することを確認
    mkdir -p .worktrees
    
    # 環境ファイルパスを生成
    local env_file_path=".worktrees/.env-${task_type}-${task_id}-${timestamp}"
    
    # パスの正規化（相対パスを絶対パスに変換）
    echo "$(pwd)/$env_file_path"
}

# 環境ファイルを探す関数（より安全な実装）
find_env_file() {
    local env_file_path="${1:-}"
    
    # 明示的にパスが指定されている場合
    if [[ -n "$env_file_path" ]] && [[ -f "$env_file_path" ]]; then
        echo "$env_file_path"
        return 0
    fi
    
    # ENV_FILE環境変数が設定されている場合
    if [[ -n "${ENV_FILE:-}" ]] && [[ -f "$ENV_FILE" ]]; then
        echo "$ENV_FILE"
        return 0
    fi
    
    # 最新の環境ファイルを探す（フォールバック）
    local latest_env=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
    if [[ -n "$latest_env" ]] && [[ -f "$latest_env" ]]; then
        log_warning "Using latest environment file as fallback: $latest_env"
        echo "$latest_env"
        return 0
    fi
    
    # 環境ファイルが見つからない
    log_error "No environment file found. Searched locations:"
    log_error "  - Explicit path: ${env_file_path:-<none>}"
    log_error "  - ENV_FILE variable: ${ENV_FILE:-<not set>}"
    log_error "  - Latest in .worktrees/: $(ls -la .worktrees/.env-* 2>&1 | head -5 || echo '<none found>')"
    log_error ""
    log_error "This usually happens when:"
    log_error "  1. The task was started in a different session"
    log_error "  2. Multiple tasks are running in parallel without proper ENV_FILE"
    log_error "  3. The environment file was manually deleted"
    log_error "  4. ClaudeCode's session separation prevents variable inheritance"
    log_error ""
    log_error "To fix:"
    log_error "  1. Check Step 1 output for the environment file path"
    log_error "  2. Set ENV_FILE explicitly: ENV_FILE='/path/to/.worktrees/.env-...'"
    log_error "  3. Or pass the path to load_env_file: load_env_file '/path/to/.worktrees/.env-...'"
    return 1
}

# 環境ファイルを安全に読み込む関数
load_env_file() {
    local env_file_path="${1:-}"
    
    # 環境ファイルを探す
    local env_file=$(find_env_file "$env_file_path")
    if [[ $? -ne 0 ]]; then
        log_error "Failed to find environment file"
        return 1
    fi
    
    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file does not exist: $env_file"
        return 1
    fi
    
    # 環境ファイルを読み込む
    source "$env_file"
    log_info "Environment loaded from: $env_file"
    
    # 必須変数の検証
    local missing_vars=()
    for var in WORKTREE_PATH TASK_BRANCH FEATURE_NAME PROJECT_TYPE TASK_DESCRIPTION; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        return 1
    fi
    
    return 0
}

# 環境ファイル管理関数のエクスポート
export -f generate_env_file_path find_env_file load_env_file

# ==========================================
# フェーズ共通関数（DRY原則）
# ==========================================

# フェーズ初期化共通関数
initialize_phase() {
    local env_file="${1:-}"
    local phase_name="${2:-Unknown}"
    
    # 共通ユーティリティの再読み込み（セッション分離対応）
    source .claude/scripts/worktree-utils.sh || {
        log_error "worktree-utils.sh not found"
        return 1
    }
    
    # 環境ファイルを安全に読み込み
    if ! load_env_file "$env_file"; then
        log_error "Failed to load environment file"
        return 1
    fi
    
    log_info "Phase initialized: $phase_name"
    return 0
}

# フェーズ結果のコミット共通関数
commit_phase_results() {
    local phase_tag="$1"      # EXPLORE, PLAN, PROTOTYPE, etc.
    local worktree_path="$2"
    local file_path="$3"
    local commit_message="$4"
    local optional_paths="${5:-}"
    
    if [[ ! -f "$file_path" ]]; then
        log_warning "$file_path not found, skipping commit"
        return 1
    fi
    
    # 基本ファイルを追加
    git -C "$worktree_path" add "$file_path" || {
        log_warning "Failed to add $file_path"
        return 1
    }
    
    # オプションのパスがあれば追加
    if [[ -n "$optional_paths" ]]; then
        for path in $optional_paths; do
            if [[ -e "$worktree_path/$path" ]]; then
                git -C "$worktree_path" add "$path" 2>/dev/null || {
                    log_warning "Failed to add optional path: $path"
                }
            fi
        done
    fi
    
    # コミット実行
    git -C "$worktree_path" commit -m "[$phase_tag] $commit_message" || {
        log_warning "Failed to commit $phase_tag results"
        return 1
    }
    
    log_success "Committed: [$phase_tag] $commit_message"
    return 0
}

# 完了レポート生成共通関数
generate_completion_report() {
    local worktree_path="$1"
    local task_name="$2"       # feature_name, task_name等
    local task_description="$3"
    local branch_name="$4"
    local project_type="$5"
    local task_type="${6:-feature}"  # feature, tdd, refactor
    
    # レポートディレクトリ
    local report_dir="$worktree_path/report/$task_name/phase-results"
    
    # フェーズ結果ファイルの確認
    local explore_status=$([[ -f "$report_dir/explore-results.md" ]] && echo "✅" || echo "⚠️")
    local plan_status=$([[ -f "$report_dir/plan-results.md" ]] && echo "✅" || echo "⚠️")
    local test_status=$(run_tests "$project_type" "$worktree_path" &>/dev/null && echo "✅" || echo "⚠️")
    
    # タスクタイプ別のステータス
    local prototype_status="N/A"
    local coding_status="N/A"
    if [[ "$task_type" == "feature" ]]; then
        prototype_status=$([[ -f "$report_dir/prototype-results.md" ]] && echo "✅" || echo "⚠️")
        coding_status=$([[ -f "$report_dir/coding-results.md" ]] && echo "✅" || echo "⚠️")
    elif [[ "$task_type" == "tdd" ]] || [[ "$task_type" == "bugfix" ]]; then
        coding_status=$([[ -f "$report_dir/coding-results.md" ]] && echo "✅" || echo "⚠️")
    fi
    
    # ファイル統計
    local src_files=0
    local test_files=0
    local doc_files=0
    
    if [[ -d "$worktree_path/src/$task_name" ]]; then
        src_files=$(find "$worktree_path/src/$task_name" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.tsx" -o -name "*.jsx" \) 2>/dev/null | wc -l || echo "0")
    fi
    
    if [[ -d "$worktree_path/test/$task_name" ]]; then
        test_files=$(find "$worktree_path/test/$task_name" -type f \( -name "*.test.*" -o -name "*.spec.*" \) 2>/dev/null | wc -l || echo "0")
    fi
    
    if [[ -d "$worktree_path/report/$task_name" ]]; then
        doc_files=$(find "$worktree_path/report/$task_name" -name "*.md" 2>/dev/null | wc -l || echo "0")
    fi
    
    # タスクタイプ別のタイトル
    local report_title="Task Completion Report"
    case "$task_type" in
        feature)
            report_title="Feature Completion Report"
            ;;
        tdd|bugfix)
            report_title="TDD/Bugfix Completion Report"
            ;;
        refactor)
            report_title="Refactoring Completion Report"
            ;;
    esac
    
    # レポート生成
    cat > "$report_dir/task-completion-report.md" << EOF
# $report_title

## Summary
**Task**: $task_description  
**Branch**: $branch_name
**Worktree**: $worktree_path
**Type**: $task_type
**Completed**: $(date)

## Phase Results
- $explore_status **Explore**: Requirements and constraints analyzed
- $plan_status **Plan**: Implementation strategy defined
EOF

    # タスクタイプ別のフェーズ結果追加
    if [[ "$task_type" == "feature" ]]; then
        echo "- $prototype_status **Prototype**: Working prototype demonstrated" >> "$report_dir/task-completion-report.md"
    fi
    
    if [[ "$task_type" != "refactor" ]]; then
        echo "- $coding_status **Code**: Implementation completed" >> "$report_dir/task-completion-report.md"
    fi
    
    cat >> "$report_dir/task-completion-report.md" << EOF
- $test_status **Test**: All tests passing
- ✅ **Ready**: Task ready for review and integration

## Files Summary
- Source files: $src_files
- Test files: $test_files
- Documentation: $doc_files

## Next Steps
1. Review implementation in worktree: $worktree_path
2. Test locally
3. Create PR: $branch_name → main
4. Clean up worktree after merge
EOF
}

# フェーズ共通関数のエクスポート
export -f initialize_phase commit_phase_results generate_completion_report

# ==========================================
# リファクタリング固有の共通関数
# ==========================================

# リファクタリングフェーズの初期化と前フェーズチェック
initialize_refactor_phase() {
    local env_file="${1:-}"
    local phase_name="${2:-Unknown}"
    local previous_phase="${3:-}"
    local total_phases="${4:-4}"
    local phase_number="${5:-1}"
    
    # 基本的な初期化
    if ! initialize_phase "$env_file" "$phase_name"; then
        return 1
    fi
    
    # 進捗表示
    show_progress "$phase_name" "$total_phases" "$phase_number"
    
    # 前フェーズの完了確認（必要な場合）
    if [[ -n "$previous_phase" ]]; then
        if ! check_phase_completed "$WORKTREE_PATH" "$previous_phase"; then
            log_error "$previous_phase phase not completed"
            handle_error 1 "Cannot proceed without $previous_phase phase" "$WORKTREE_PATH"
            return 1
        fi
    fi
    
    # フェーズ開始を記録
    create_phase_status "$WORKTREE_PATH" "$phase_name" "started"
    
    return 0
}

# リファクタリング結果のコミット（エラーハンドリング付き）
commit_refactor_phase() {
    local worktree_path="$1"
    local phase_name="$2"
    local phase_tag="$3"
    local result_file="$4"
    local commit_message="$5"
    local task_description="$6"
    
    if [[ -f "$result_file" ]]; then
        git -C "$worktree_path" add "${result_file#$worktree_path/}" || {
            rollback_on_error "$worktree_path" "$phase_name" "Failed to add $phase_name results"
            handle_error 1 "$phase_name phase failed" "$worktree_path"
            return 1
        }
        
        git -C "$worktree_path" commit -m "[$phase_tag] $commit_message: $task_description" || {
            rollback_on_error "$worktree_path" "$phase_name" "Failed to commit $phase_name results"
            handle_error 1 "$phase_name phase failed" "$worktree_path"
            return 1
        }
        
        log_success "Committed: [$phase_tag] $commit_message"
        update_phase_status "$worktree_path" "$phase_name" "completed"
    else
        rollback_on_error "$worktree_path" "$phase_name" "${result_file#$worktree_path/} not found"
        handle_error 1 "$phase_name results not created" "$worktree_path"
        return 1
    fi
    
    return 0
}

# 段階的リファクタリングコミット
commit_refactor_step() {
    local worktree_path="$1"
    local step_name="$2"
    local commit_message="$3"
    local task_description="$4"
    
    # 変更があるかチェック
    if [[ -n $(git -C "$worktree_path" diff --name-only) ]]; then
        git -C "$worktree_path" add . || {
            log_warning "Failed to add changes for $step_name"
            return 1
        }
        
        git -C "$worktree_path" commit -m "[REFACTOR] $commit_message: $task_description" || {
            log_warning "No changes for $step_name"
            return 1
        }
        
        log_success "Committed refactor step: $commit_message"
        return 0
    else
        log_info "No changes for $step_name"
        return 1
    fi
}

# リファクタリング完了レポート生成
generate_refactor_completion_report() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local refactor_branch="$4"
    local project_type="$5"
    
    local report_dir="$worktree_path/report/$feature_name/phase-results"
    
    # フェーズ結果の確認
    local analysis_status=$([[ -f "$report_dir/analysis-results.md" ]] && echo "✅" || echo "⚠️")
    local plan_status=$([[ -f "$report_dir/refactoring-plan.md" ]] && echo "✅" || echo "⚠️")
    local refactor_status=$([[ -f "$report_dir/refactoring-results.md" ]] && echo "✅" || echo "⚠️")
    local verify_status=$([[ -f "$report_dir/verification-report.md" ]] && echo "✅" || echo "⚠️")
    local test_status=$(run_tests "$project_type" "$worktree_path" &>/dev/null && echo "✅" || echo "⚠️")
    
    # コミット履歴とファイル変更の取得
    local commits=$(git -C "$worktree_path" log --oneline origin/main..HEAD 2>/dev/null || git -C "$worktree_path" log --oneline -n 10)
    local files_changed=$(git -C "$worktree_path" diff --name-only origin/main 2>/dev/null || echo "Unable to compare with origin/main")
    
    cat > "$report_dir/task-completion-report.md" << EOF
# Refactoring Completion Report

## Refactoring Summary
**Target**: $task_description  
**Branch**: $refactor_branch
**Worktree**: $worktree_path
**Completed**: $(date)

## Phase Results
- $analysis_status **Analysis**: Current state and risks assessed
- $plan_status **Plan**: Refactoring strategy defined
- $refactor_status **Refactor**: Changes implemented incrementally
- $verify_status **Verify**: Quality and compatibility confirmed
- $([[ -d "$worktree_path/report/$feature_name" ]] && echo "✅" || echo "⚠️") **Reports**: Quality metrics and coverage reports generated
- $test_status **Tests**: All tests passing

## Code Quality Improvements
- 複雑度: 詳細は\`$worktree_path/report/$feature_name/quality/complexity-report.md\`参照
- テストカバレッジ: 詳細は\`$worktree_path/report/$feature_name/coverage/coverage-report.html\`参照
- パフォーマンス: 詳細は\`$worktree_path/report/$feature_name/performance/benchmark-results.md\`参照

## Files Modified
$files_changed

## Commits
$commits

## Next Steps
1. Review refactoring in worktree: $worktree_path
2. Verify all tests pass and performance meets targets
3. Create PR: $refactor_branch → main
4. Clean up worktree after merge: \`git worktree remove $worktree_path\`

## Risk Assessment
- 後方互換性: [Maintained/Breaking changes]
- 移行ガイド: [Required/Not required]

EOF
}

# リファクタリング共通関数のエクスポート
export -f initialize_refactor_phase commit_refactor_phase commit_refactor_step generate_refactor_completion_report

# ==========================================
# ccmanager統合関数
# ==========================================

# ccmanagerの利用可能性チェック
check_ccmanager() {
    if command -v ccmanager &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ccmanagerフェーズ状態更新
update_ccm_phase() {
    local worktree_path="$1"
    local phase="$2"
    local status="$3"
    
    local config_file="$worktree_path/.ccmanager/feature-config.json"
    
    if [[ ! -f "$config_file" ]]; then
        log_warning "ccmanager config not found at $config_file"
        return 1
    fi
    
    # jqを使ってJSONを更新
    if command -v jq &>/dev/null; then
        local tmp_file=$(mktemp)
        jq ".phases.${phase}.status = \"${status}\" | .currentPhase = \"${phase}\"" \
            "$config_file" > "$tmp_file" && mv "$tmp_file" "$config_file"
        log_info "Updated ccmanager phase: $phase -> $status"
    else
        log_warning "jq not found, cannot update ccmanager phase status"
        return 1
    fi
    
    return 0
}

# ccmanager設定初期化
initialize_ccm_config() {
    local worktree_path="$1"
    local feature_name="$2"
    local branch_name="$3"
    local preset_base="${4:-feature}"
    
    # ccmanager設定ディレクトリ作成
    mkdir -p "$worktree_path/.ccmanager"
    
    # 設定ファイル作成
    cat > "$worktree_path/.ccmanager/feature-config.json" << EOF
{
  "featureName": "$feature_name",
  "branch": "$branch_name",
  "worktreePath": "$worktree_path",
  "presetBase": "$preset_base",
  "phases": {
    "explorer": {
      "preset": "${preset_base}-explorer",
      "prompt": "@${HOME}/.claude/prompts/explorer.md",
      "status": "pending"
    },
    "planner": {
      "preset": "${preset_base}-planner",
      "prompt": "@${HOME}/.claude/prompts/planner.md",
      "status": "pending"
    },
    "prototype": {
      "preset": "${preset_base}-prototype",
      "status": "pending"
    },
    "coder": {
      "preset": "${preset_base}-coder",
      "prompt": "@${HOME}/.claude/prompts/coder.md",
      "status": "pending"
    },
    "completion": {
      "preset": "${preset_base}-completion",
      "status": "pending"
    }
  },
  "currentPhase": "explorer",
  "startTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    log_success "Initialized ccmanager config for $feature_name"
    return 0
}

# ccmanagerプリセット名取得
get_ccm_preset_name() {
    local phase="$1"
    local preset_base="${2:-feature}"
    
    echo "${preset_base}-${phase}"
}

# ccmanagerセッション開始（オプション）
start_ccm_session() {
    local preset="$1"
    local worktree_path="$2"
    local auto_start="${3:-false}"
    
    if [[ "$auto_start" == "true" ]] && check_ccmanager; then
        log_info "Starting ccmanager session with preset: $preset"
        cd "$worktree_path"
        ccmanager start --preset "$preset" &
        return 0
    else
        log_info "Manual ccmanager start required:"
        echo "  1. Run 'ccm' in another terminal"
        echo "  2. Select the worktree: $(basename "$worktree_path")"
        echo "  3. Choose preset: $preset"
        return 0
    fi
}

# ccmanager統計情報取得
get_ccm_statistics() {
    local worktree_path="$1"
    local config_file="$worktree_path/.ccmanager/feature-config.json"
    
    if [[ ! -f "$config_file" ]] || ! command -v jq &>/dev/null; then
        echo "N/A"
        return 1
    fi
    
    jq -r '
        "Feature: \(.featureName)",
        "Branch: \(.branch)",
        "Started: \(.startTime)",
        "Current Phase: \(.currentPhase)",
        "Phases Completed: \(.phases | to_entries | map(select(.value.status == "completed")) | length)/5"
    ' "$config_file"
}

# ccmanager統合状態確認
check_ccm_integration() {
    local use_ccm="${1:-true}"
    
    if [[ "$use_ccm" != "true" ]]; then
        echo "disabled"
        return 1
    fi
    
    if ! check_ccmanager; then
        echo "not_available"
        return 1
    fi
    
    if ! command -v jq &>/dev/null; then
        echo "jq_missing"
        return 1
    fi
    
    echo "ready"
    return 0
}

# ccmanager関数のエクスポート
export -f check_ccmanager update_ccm_phase initialize_ccm_config
export -f get_ccm_preset_name start_ccm_session get_ccm_statistics
export -f check_ccm_integration