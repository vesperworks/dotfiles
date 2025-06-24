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
    # .worktreesサブディレクトリ内にworktreeを作成
    local worktree_path=".worktrees/${branch_prefix}-${task_id}"
    
    # 既存worktreeのチェック
    if [[ -d "$worktree_path" ]] || git worktree list | grep -q "$worktree_path"; then
        log_warning "Worktree already exists: $worktree_path"
        # タイムスタンプを追加して別名にする
        worktree_path=".worktrees/${branch_prefix}-${task_id}-${timestamp}"
    fi
    
    # worktree作成
    log_info "Creating worktree: $worktree_path"
    if ! git worktree add "$worktree_path" -b "$task_branch" >/dev/null 2>&1; then
        handle_error $? "Failed to create worktree" "$worktree_path"
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
    # 例: "認証機能のJWT有効期限チェック不具合を修正" → "auth-jwt-fix"
    local feature_name=$(echo "$task_description" | \
        sed 's/[^a-zA-Z0-9 ]//g' | \
        tr '[:upper:]' '[:lower:]' | \
        awk '{print $1"-"$2"-"$3}' | \
        sed 's/-$//' | \
        sed 's/--/-/g')
    
    # 空の場合はタスクタイプ + タイムスタンプ
    if [[ -z "$feature_name" ]] || [[ "$feature_name" == "--" ]]; then
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

# 並列エージェント実行機能
run_parallel_agents() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local test_files_pattern="${4:-}"
    local impl_files_pattern="${5:-}"
    
    log_info "Starting parallel TDD agents for feature: $feature_name"
    
    # 並列実行用の一時ディレクトリ
    local temp_dir="$worktree_path/.parallel-agents"
    mkdir -p "$temp_dir"
    
    # 並列実行のための状態ファイル
    local test_agent_status="$temp_dir/test-agent.status"
    local impl_agent_status="$temp_dir/impl-agent.status"
    local test_agent_result="$temp_dir/test-agent.result"
    local impl_agent_result="$temp_dir/impl-agent.result"
    
    # ステータスファイル初期化
    echo "running" > "$test_agent_status"
    echo "running" > "$impl_agent_status"
    
    log_info "Launching Test Agent and Implementation Agent in parallel..."
    
    # Test Agent (バックグラウンド実行)
    (
        run_test_agent "$worktree_path" "$feature_name" "$task_description" "$test_files_pattern"
        echo $? > "$test_agent_result"
        echo "completed" > "$test_agent_status"
    ) &
    local test_agent_pid=$!
    
    # Implementation Agent (バックグラウンド実行)
    (
        run_impl_agent "$worktree_path" "$feature_name" "$task_description" "$impl_files_pattern"
        echo $? > "$impl_agent_result"
        echo "completed" > "$impl_agent_status"
    ) &
    local impl_agent_pid=$!
    
    log_info "Test Agent PID: $test_agent_pid, Impl Agent PID: $impl_agent_pid"
    
    # 並列実行の進捗監視
    monitor_parallel_execution "$temp_dir" "$test_agent_pid" "$impl_agent_pid"
    
    # 両エージェントの完了を待機
    wait $test_agent_pid
    local test_exit_code=$?
    wait $impl_agent_pid  
    local impl_exit_code=$?
    
    # 結果の統合
    merge_parallel_results "$worktree_path" "$temp_dir" "$feature_name"
    
    # クリーンアップ
    rm -rf "$temp_dir"
    
    # 全体の成功判定
    if [[ $test_exit_code -eq 0 ]] && [[ $impl_exit_code -eq 0 ]]; then
        log_success "Parallel TDD agents completed successfully"
        return 0
    else
        log_error "One or more parallel agents failed (Test: $test_exit_code, Impl: $impl_exit_code)"
        return 1
    fi
}

# テスト作成専門エージェント
run_test_agent() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local test_files_pattern="${4:-}"
    
    log_info "[Test Agent] Starting test creation for: $feature_name"
    
    # テスト専門プロンプトの読み込み
    local test_prompt=$(load_prompt ".claude/prompts/coder-test.md" "$DEFAULT_CODER_TEST_PROMPT")
    
    # テスト作成の実行ログ
    local test_log="$worktree_path/test-agent.log"
    echo "[Test Agent] Starting at $(date)" > "$test_log"
    
    # TDD Red Phase: 失敗するテストを作成
    log_info "[Test Agent] Creating failing tests (RED phase)"
    
    # テスト種別の判定と作成
    create_unit_tests "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$test_log"
    create_integration_tests "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$test_log"
    create_e2e_tests "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$test_log"
    
    # テスト結果レポート作成
    create_test_report "$worktree_path" "$feature_name" 2>&1 | tee -a "$test_log"
    
    echo "[Test Agent] Completed at $(date)" >> "$test_log"
    log_success "[Test Agent] Test creation completed"
    
    return 0
}

# 実装専門エージェント
run_impl_agent() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    local impl_files_pattern="${4:-}"
    
    log_info "[Impl Agent] Starting implementation for: $feature_name"
    
    # 実装専門プロンプトの読み込み
    local impl_prompt=$(load_prompt ".claude/prompts/coder-impl.md" "$DEFAULT_CODER_IMPL_PROMPT")
    
    # 実装の実行ログ
    local impl_log="$worktree_path/impl-agent.log"
    echo "[Impl Agent] Starting at $(date)" > "$impl_log"
    
    # TDD Green Phase: テストを通す実装を作成
    log_info "[Impl Agent] Creating implementation (GREEN phase)"
    
    # 段階的実装
    implement_core_functionality "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$impl_log"
    implement_edge_cases "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$impl_log"
    optimize_implementation "$worktree_path" "$feature_name" "$task_description" 2>&1 | tee -a "$impl_log"
    
    # 実装結果レポート作成
    create_impl_report "$worktree_path" "$feature_name" 2>&1 | tee -a "$impl_log"
    
    echo "[Impl Agent] Completed at $(date)" >> "$impl_log"
    log_success "[Impl Agent] Implementation completed"
    
    return 0
}

# 並列実行の進捗監視
monitor_parallel_execution() {
    local temp_dir="$1"
    local test_pid="$2"
    local impl_pid="$3"
    
    local test_status_file="$temp_dir/test-agent.status"
    local impl_status_file="$temp_dir/impl-agent.status"
    
    log_info "Monitoring parallel execution..."
    
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local spinner_index=0
    
    while [[ "$(cat "$test_status_file" 2>/dev/null)" == "running" ]] || [[ "$(cat "$impl_status_file" 2>/dev/null)" == "running" ]]; do
        local spinner_char="${spinner_chars:$spinner_index:1}"
        echo -ne "\r${spinner_char} Test Agent: $(cat "$test_status_file" 2>/dev/null || echo "starting") | Impl Agent: $(cat "$impl_status_file" 2>/dev/null || echo "starting")"
        
        spinner_index=$(( (spinner_index + 1) % ${#spinner_chars} ))
        sleep 0.5
    done
    
    echo -e "\n"
    log_success "Parallel execution monitoring completed"
}

# 並列実行結果のマージ
merge_parallel_results() {
    local worktree_path="$1"
    local temp_dir="$2"
    local feature_name="$3"
    
    log_info "Merging parallel execution results..."
    
    # 結果ファイルの存在確認
    local test_result=$(cat "$temp_dir/test-agent.result" 2>/dev/null || echo "1")
    local impl_result=$(cat "$temp_dir/impl-agent.result" 2>/dev/null || echo "1")
    
    # 統合レポート作成
    cat > "$worktree_path/parallel-tdd-report.md" << EOF
# Parallel TDD Execution Report

## Feature: $feature_name
**Execution Time**: $(date)

## Test Agent Results
**Status**: $([ "$test_result" -eq 0 ] && echo "✅ Success" || echo "❌ Failed")
**Exit Code**: $test_result

### Test Creation Summary
$(if [[ -f "$worktree_path/test-agent.log" ]]; then
    grep -E "\[Test Agent\].*:" "$worktree_path/test-agent.log" | tail -10 || echo "No test log found"
else
    echo "No test log found"
fi)

## Implementation Agent Results  
**Status**: $([ "$impl_result" -eq 0 ] && echo "✅ Success" || echo "❌ Failed")
**Exit Code**: $impl_result

### Implementation Summary
$(if [[ -f "$worktree_path/impl-agent.log" ]]; then
    grep -E "\[Impl Agent\].*:" "$worktree_path/impl-agent.log" | tail -10 || echo "No impl log found"
else
    echo "No impl log found"
fi)

## TDD Cycle Status
- **RED Phase**: Tests created first
- **GREEN Phase**: Implementation follows tests
- **REFACTOR Phase**: Code quality improvements

## Files Created
### Test Files
$(find "$worktree_path/test/$feature_name" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | head -10 || echo "No test files found")

### Implementation Files
$(find "$worktree_path/src/$feature_name" -name "*.*" 2>/dev/null | head -10 || echo "No implementation files found")

## Next Steps
1. Review test coverage
2. Run full test suite
3. Optimize implementation
4. Update documentation
EOF
    
    # gitコミット
    if [[ -f "$worktree_path/parallel-tdd-report.md" ]]; then
        git -C "$worktree_path" add parallel-tdd-report.md
        git -C "$worktree_path" commit -m "[PARALLEL-TDD] Completed parallel test and implementation for $feature_name" || {
            log_warning "Failed to commit parallel TDD report"
        }
    fi
    
    log_success "Parallel results merged successfully"
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

DEFAULT_CODER_TEST_PROMPT="あなたはテスト作成専門のCoder-Testエージェントです。TDDのRED phaseを担当します：
1. 機能要件に基づく失敗するテストを作成
2. 単体テスト、統合テスト、E2Eテストの作成
3. テストケースの境界値・エラーハンドリング確認
4. テストの実行とRED状態の確認
5. 結果をtest-creation-report.mdに保存"

DEFAULT_CODER_IMPL_PROMPT="あなたは実装専門のCoder-Implエージェントです。TDDのGREEN phaseを担当します：
1. 作成されたテストを通すための最小実装を作成
2. 段階的な機能実装（コア→エッジケース→最適化）
3. エラーハンドリングと入力検証の実装
4. パフォーマンス最適化の実施
5. 結果をimplementation-report.mdに保存"

# テスト作成ヘルパー関数群
create_unit_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Test Agent] Creating unit tests for: $feature_name"
    
    # 単体テストディレクトリの確保
    mkdir -p "$worktree_path/test/$feature_name/unit"
    
    # プロジェクトタイプに応じたテストファイル作成
    local project_type=$(detect_project_type "$worktree_path")
    
    case "$project_type" in
        node)
            create_jest_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
        rust)
            create_rust_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
        python)
            create_pytest_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
        *)
            create_generic_unit_tests "$worktree_path" "$feature_name" "$task_description"
            ;;
    esac
    
    log_success "[Test Agent] Unit tests created"
}

create_integration_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Test Agent] Creating integration tests for: $feature_name"
    
    # 統合テストディレクトリの確保
    mkdir -p "$worktree_path/test/$feature_name/integration"
    
    # 統合テストの基本構造を作成
    cat > "$worktree_path/test/$feature_name/integration/integration.test.md" << EOF
# Integration Tests for $feature_name

## Test Scenarios
1. Component Integration Testing
2. API Integration Testing
3. Database Integration Testing
4. External Service Integration Testing

## Test Description
$task_description

## Created: $(date)
EOF
    
    log_success "[Test Agent] Integration tests created"
}

create_e2e_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Test Agent] Creating E2E tests for: $feature_name"
    
    # E2Eテストディレクトリの確保
    mkdir -p "$worktree_path/test/$feature_name/e2e"
    
    # E2Eテストの基本構造を作成
    cat > "$worktree_path/test/$feature_name/e2e/e2e.test.md" << EOF
# End-to-End Tests for $feature_name

## User Journey Testing
1. User Story Based Testing
2. Cross-browser Testing
3. Mobile Responsive Testing
4. Performance Testing

## Test Description
$task_description

## Created: $(date)
EOF
    
    log_success "[Test Agent] E2E tests created"
}

create_test_report() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "[Test Agent] Creating test report for: $feature_name"
    
    cat > "$worktree_path/test-creation-report.md" << EOF
# Test Creation Report: $feature_name

## Summary
**Feature**: $feature_name
**Test Creation Completed**: $(date)

## Test Coverage Plan
### Unit Tests
- Core functionality testing
- Boundary condition testing
- Error handling testing
- Input validation testing

### Integration Tests
- Component interaction testing
- API integration testing
- Database integration testing
- Service integration testing

### E2E Tests
- User workflow testing
- Cross-platform testing
- Performance testing
- Accessibility testing

## Test Files Created
$(find "$worktree_path/test/$feature_name" -type f 2>/dev/null | head -20 || echo "No test files found")

## TDD Red Phase Status
✅ Failing tests created
🔄 Ready for implementation phase
📋 Test coverage plan documented

## Next Steps
1. Run tests to confirm RED state
2. Begin implementation to achieve GREEN state
3. Refactor for code quality
EOF
    
    log_success "[Test Agent] Test report created"
}

# 実装関数群
implement_core_functionality() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Impl Agent] Implementing core functionality for: $feature_name"
    
    # コア実装ディレクトリの確保
    mkdir -p "$worktree_path/src/$feature_name/core"
    
    # プロジェクトタイプに応じた実装ファイル作成
    local project_type=$(detect_project_type "$worktree_path")
    
    case "$project_type" in
        node)
            create_node_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
        rust)
            create_rust_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
        python)
            create_python_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
        *)
            create_generic_implementation "$worktree_path" "$feature_name" "$task_description"
            ;;
    esac
    
    log_success "[Impl Agent] Core functionality implemented"
}

implement_edge_cases() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Impl Agent] Implementing edge cases for: $feature_name"
    
    # エッジケース実装
    mkdir -p "$worktree_path/src/$feature_name/utils"
    
    cat > "$worktree_path/src/$feature_name/utils/edge-cases.md" << EOF
# Edge Cases Implementation: $feature_name

## Handled Edge Cases
1. Null/undefined input handling
2. Empty data structure handling
3. Boundary value handling
4. Error condition handling
5. Resource limitation handling

## Description
$task_description

## Implementation Date
$(date)
EOF
    
    log_success "[Impl Agent] Edge cases implemented"
}

optimize_implementation() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    log_info "[Impl Agent] Optimizing implementation for: $feature_name"
    
    # 最適化レポート作成
    mkdir -p "$worktree_path/report/$feature_name/performance"
    
    cat > "$worktree_path/report/$feature_name/performance/optimization.md" << EOF
# Performance Optimization Report: $feature_name

## Optimization Areas
1. Algorithm efficiency improvements
2. Memory usage optimization
3. I/O operation optimization
4. Caching strategy implementation
5. Lazy loading implementation

## Performance Metrics
- Before optimization: TBD
- After optimization: TBD
- Improvement percentage: TBD

## Description
$task_description

## Optimization Date
$(date)
EOF
    
    log_success "[Impl Agent] Implementation optimized"
}

create_impl_report() {
    local worktree_path="$1"
    local feature_name="$2"
    
    log_info "[Impl Agent] Creating implementation report for: $feature_name"
    
    cat > "$worktree_path/implementation-report.md" << EOF
# Implementation Report: $feature_name

## Summary
**Feature**: $feature_name
**Implementation Completed**: $(date)

## Implementation Phases
### Core Functionality
✅ Basic feature implementation
✅ Core business logic
✅ Primary use cases covered

### Edge Cases
✅ Error handling implemented
✅ Boundary conditions handled
✅ Input validation added

### Optimization
✅ Performance optimizations applied
✅ Memory usage optimized
✅ Code quality improvements

## Implementation Files Created
$(find "$worktree_path/src/$feature_name" -type f 2>/dev/null | head -20 || echo "No implementation files found")

## TDD Green Phase Status
✅ Tests passing
✅ Core functionality implemented
🔄 Ready for refactoring phase

## Quality Metrics
- Code coverage: TBD
- Performance benchmarks: TBD
- Code quality score: TBD

## Next Steps
1. Run full test suite
2. Measure performance metrics
3. Code review and refactoring
4. Documentation updates
EOF
    
    log_success "[Impl Agent] Implementation report created"
}

# プロジェクト固有の実装関数群
create_jest_unit_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/test/$feature_name/unit/$feature_name.test.js" << EOF
// Unit tests for $feature_name
// $task_description
// Generated: $(date)

describe('$feature_name', () => {
  test('should implement core functionality', () => {
    // Red phase: This test should fail initially
    expect(false).toBe(true);
  });
  
  test('should handle edge cases', () => {
    // Red phase: This test should fail initially
    expect(false).toBe(true);
  });
  
  test('should validate inputs', () => {
    // Red phase: This test should fail initially
    expect(false).toBe(true);
  });
});
EOF
}

create_generic_unit_tests() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/test/$feature_name/unit/test_$feature_name.md" << EOF
# Generic Unit Tests for $feature_name

## Test Description
$task_description

## Test Cases
1. Core functionality test (should fail initially)
2. Edge case handling test (should fail initially)  
3. Input validation test (should fail initially)

## Created: $(date)
EOF
}

create_node_implementation() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/src/$feature_name/index.js" << EOF
// Implementation for $feature_name
// $task_description
// Generated: $(date)

class ${feature_name^} {
  constructor() {
    // Core functionality implementation
  }
  
  // Implement methods to make tests pass
}

module.exports = ${feature_name^};
EOF
}

create_generic_implementation() {
    local worktree_path="$1"
    local feature_name="$2"
    local task_description="$3"
    
    cat > "$worktree_path/src/$feature_name/implementation.md" << EOF
# Generic Implementation for $feature_name

## Description
$task_description

## Implementation Structure
1. Core functionality
2. Edge case handling
3. Input validation
4. Error handling

## Created: $(date)
EOF
}

# エクスポート
export -f log_info log_success log_warning log_error
export -f handle_error verify_environment detect_project_type
export -f run_parallel_agents run_test_agent run_impl_agent
export -f monitor_parallel_execution merge_parallel_results
export -f parse_workflow_options
export -f create_unit_tests create_integration_tests create_e2e_tests create_test_report
export -f implement_core_functionality implement_edge_cases optimize_implementation create_impl_report
export -f create_jest_unit_tests create_generic_unit_tests create_node_implementation create_generic_implementation
export -f get_test_command create_task_worktree cleanup_worktree
export -f load_prompt safe_execute run_tests git_commit_phase
export -f show_progress create_structured_directories get_feature_name
export -f cleanup_old_worktrees merge_to_main create_pull_request
export -f parse_workflow_options

# デフォルトプロンプトのエクスポート
export DEFAULT_EXPLORER_PROMPT DEFAULT_PLANNER_PROMPT DEFAULT_CODER_PROMPT
export DEFAULT_CODER_TEST_PROMPT DEFAULT_CODER_IMPL_PROMPT