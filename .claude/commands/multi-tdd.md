# Multi-Agent TDD Workflow

あなたは現在、マルチエージェント TDD ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1タスク=1worktree）に基づき、以下の手順で**自動実行**してください。

## 実行タスク
$ARGUMENTS

## 利用可能なオプション
- `--keep-worktree`: worktreeを保持（デフォルト: 削除）
- `--no-merge`: mainへの自動マージをスキップ（デフォルト: マージ）
- `--pr`: GitHub PRを作成（デフォルト: 作成しない）
- `--no-draft`: 通常のPRを作成（デフォルト: ドラフト）
- `--no-cleanup`: 自動クリーンアップを無効化
- `--cleanup-days N`: N日以上前のworktreeを削除（デフォルト: 7）

## 実行方針
**ユーザーは指示後、次のタスクに移行可能**。このタスクは独立したworktree内で**全フローを自動完了**します。

### Step 1: タスク用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 共通ユーティリティの読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# オプション解析
parse_workflow_options $ARGUMENTS

# 環境検証
verify_environment || exit 1

# プロジェクトタイプの検出
PROJECT_TYPE=$(detect_project_type)
log_info "Detected project type: $PROJECT_TYPE"

# 古いworktreeのクリーンアップ（オプション）
if [[ "$AUTO_CLEANUP" == "true" ]]; then
    cleanup_old_worktrees "$CLEANUP_DAYS"
fi

# worktree作成
WORKTREE_INFO=$(create_task_worktree "$TASK_DESCRIPTION" "tdd")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
TASK_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)
FEATURE_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f3)

# タスクIDを生成（環境ファイル名用）
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
ENV_FILE=".worktrees/.env-${TASK_ID}-$(date +%Y%m%d-%H%M%S)"

# 環境変数をファイルに保存
cat > "$ENV_FILE" << EOF
WORKTREE_PATH="$WORKTREE_PATH"
TASK_BRANCH="$TASK_BRANCH"
FEATURE_NAME="$FEATURE_NAME"
PROJECT_TYPE="$PROJECT_TYPE"
TASK_DESCRIPTION="$TASK_DESCRIPTION"
KEEP_WORKTREE="$KEEP_WORKTREE"
NO_MERGE="$NO_MERGE"
CREATE_PR="$CREATE_PR"
NO_DRAFT="$NO_DRAFT"
AUTO_CLEANUP="$AUTO_CLEANUP"
CLEANUP_DAYS="$CLEANUP_DAYS"
EOF

log_success "Task worktree created"
echo "📋 Task: $TASK_DESCRIPTION"
echo "🌿 Branch: $TASK_BRANCH"
echo "📁 Worktree: $WORKTREE_PATH"
echo "🏷️ Feature: $FEATURE_NAME"
echo "🔧 Env file: $ENV_FILE"
echo "⚙️ Options: keep-worktree=$KEEP_WORKTREE, no-merge=$NO_MERGE, pr=$CREATE_PR"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$TASK_BRANCH` **Feature**: `$FEATURE_NAME`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Explore（探索・調査）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 最新の環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    log_info "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

# ClaudeCodeアクセス制限対応: cdを使用せず、worktree内で作業
log_info "Working in worktree: $WORKTREE_PATH"

show_progress "Explore" 4 1

# Explorerプロンプトの読み込み（メインディレクトリから）
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
```

**Explorer指示**:
$EXPLORER_PROMPT

**タスク**: $ARGUMENTS

**作業ディレクトリ**: $WORKTREE_PATH
**注意**: ClaudeCodeのアクセス制限により、直接worktreeディレクトリに移動できません。以下の方法で作業してください：
- ファイル読み取り: `Read $WORKTREE_PATH/ファイル名`
- ファイル書き込み: `Write $WORKTREE_PATH/ファイル名`
- ファイル編集: `Edit $WORKTREE_PATH/ファイル名`

**実行内容**:
1. 現在のコードベースを調査・分析
2. 問題の根本原因を特定
3. 影響範囲と依存関係を明確化
4. 要件と制約を整理
5. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md` に保存

**テストファイルの配置**: `$WORKTREE_PATH/test/$FEATURE_NAME/`以下に配置してください

```bash
# レポートディレクトリ作成
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"

# Explore結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md" ]]; then
    # worktree内でコミット
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/explore-results.md"
    git -C "$WORKTREE_PATH" commit -m "[EXPLORE] Analysis complete: $ARGUMENTS" || {
        log_error "Failed to commit explore results"
        handle_error 1 "Explore phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [EXPLORE] Analysis complete"
else
    log_warning "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md not found, skipping commit"
fi
```

#### Phase 2: Plan（計画策定）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 最新の環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    log_info "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

show_progress "Plan" 4 2

# Plannerプロンプトの読み込み
PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
```

**Planner指示**:
$PLANNER_PROMPT

**前フェーズ結果**: `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md`
**タスク**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

**実行内容**:
1. Explore結果を基に実装戦略を策定
2. TDD手順（Test First）での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md` に保存

```bash
# Plan結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/plan-results.md"
    git -C "$WORKTREE_PATH" commit -m "[PLAN] Strategy complete: $ARGUMENTS" || {
        log_error "Failed to commit plan results"
        handle_error 1 "Plan phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [PLAN] Strategy complete"
else
    log_warning "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md not found, skipping commit"
fi
```

#### Phase 3: Coding（TDD実装）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 最新の環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    log_info "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

show_progress "Coding" 4 3

# Coderプロンプトの読み込み
CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
```

**Coder指示**:
$CODER_PROMPT

**前フェーズ結果**: 
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md`
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md`

**タスク**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

**TDD実行順序**:
1. **Write tests › Commit** - 失敗するテストを先に作成
   - テストファイルは `test/$FEATURE_NAME/unit/test-$FEATURE_NAME.js` 等に配置
2. **Code › Iterate** - テストを通すための最小実装
   - 実装ファイルは `src/$FEATURE_NAME/` 以下に配置
3. **Refactor › Commit** - コード品質向上
   - レポートは `report/$FEATURE_NAME/quality/` に保存

```bash
# TDD RED Phase - テスト作成（worktree内で実行）
if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME" ]]; then
    git -C "$WORKTREE_PATH" add "test/$FEATURE_NAME" 2>/dev/null
    git -C "$WORKTREE_PATH" commit -m "[TDD-RED] Failing tests for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No test files to commit in RED phase"
    }
else
    log_warning "No test directory found for feature: $FEATURE_NAME"
fi

# TDD GREEN Phase - 実装（worktree内で実行）
if [[ -d "$WORKTREE_PATH/src/$FEATURE_NAME" ]]; then
    git -C "$WORKTREE_PATH" add "src/$FEATURE_NAME" 2>/dev/null
    git -C "$WORKTREE_PATH" commit -m "[TDD-GREEN] Implementation for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No implementation files to commit in GREEN phase"
    }
fi

# TDD REFACTOR Phase - リファクタリング（worktree内で実行）
if [[ -n $(git -C "$WORKTREE_PATH" diff --name-only) ]]; then
    git -C "$WORKTREE_PATH" add .
    git -C "$WORKTREE_PATH" commit -m "[TDD-REFACTOR] Code quality improvements: $ARGUMENTS" || {
        log_warning "No changes to commit in REFACTOR phase"
    }
fi

# 最終結果保存（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/coding-results.md"
    git -C "$WORKTREE_PATH" commit -m "[CODING] Implementation complete: $ARGUMENTS" || {
        log_warning "Failed to commit coding results"
    }
    log_success "Committed: [CODING] Implementation complete"
fi
```

### Step 3: 完了通知とPR準備

```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 最新の環境ファイルを探して読み込み
ENV_FILE=$(ls -t .worktrees/.env-* 2>/dev/null | head -1)
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
    log_info "Environment loaded from: $ENV_FILE"
else
    echo "Error: Environment file not found"
    exit 1
fi

show_progress "Completion" 4 4

# 最終検証 - プロジェクトタイプに応じたテスト実行
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - task may be incomplete"
    # テスト失敗してもレポートは生成する
fi

# 完了レポート生成
cat > "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" << EOF
# Task Completion Report

## Task Summary
**Task**: $ARGUMENTS  
**Branch**: $TASK_BRANCH
**Worktree**: $WORKTREE_PATH
**Project Type**: $PROJECT_TYPE
**Completed**: $(date)

## Phase Results
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Explore**: Root cause analysis
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Plan**: Implementation strategy
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Code**: TDD implementation
- $(if run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then echo "✅"; else echo "⚠️"; fi) **Tests**: All tests passing

## Files Modified
$(git -C "$WORKTREE_PATH" diff --name-only origin/main 2>/dev/null || echo "Unable to compare with origin/main")

## Commits
$(git -C "$WORKTREE_PATH" log --oneline origin/main..HEAD 2>/dev/null || git -C "$WORKTREE_PATH" log --oneline -n 10)

## Test Results
$(if command -v "$PROJECT_TYPE" &>/dev/null; then
    run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" 2>&1 | tail -20
else
    echo "Test command not found for project type: $PROJECT_TYPE"
fi)

## Test Coverage Report
Saved in: $WORKTREE_PATH/report/$FEATURE_NAME/coverage/

## Code Quality Report  
Saved in: $WORKTREE_PATH/report/$FEATURE_NAME/quality/

## Next Steps
1. Review implementation in worktree: $WORKTREE_PATH
2. Create PR: $TASK_BRANCH → main
3. Clean up worktree after merge: \`git worktree remove $WORKTREE_PATH\`

EOF

# worktree内でコミット
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/task-completion-report.md"
    git -C "$WORKTREE_PATH" commit -m "[COMPLETE] Task finished: $TASK_DESCRIPTION" || {
        log_warning "Failed to commit completion report"
    }
    log_success "Committed: [COMPLETE] Task finished"
fi

# ローカルマージ（オプション）
if [[ "$NO_MERGE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    log_info "Merging to main branch..."
    if merge_to_main "$WORKTREE_PATH" "$TASK_BRANCH" "$NO_MERGE"; then
        log_success "Successfully merged to main"
    else
        log_warning "Merge failed - manual intervention required"
    fi
fi

# PR作成（オプション）
if [[ "$CREATE_PR" == "true" ]]; then
    log_info "Creating pull request..."
    local is_draft="true"
    [[ "$NO_DRAFT" == "true" ]] && is_draft="false"
    
    if create_pull_request "$WORKTREE_PATH" "$TASK_BRANCH" "$TASK_DESCRIPTION" "$is_draft"; then
        log_success "Pull request created"
    else
        log_warning "Failed to create PR - you can create it manually"
    fi
fi

# worktreeクリーンアップ（オプション）
if [[ "$KEEP_WORKTREE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    cleanup_worktree "$WORKTREE_PATH" "$KEEP_WORKTREE"
    # 環境ファイルも削除
    if [[ -f "$ENV_FILE" ]]; then
        rm -f "$ENV_FILE"
        log_info "Environment file cleaned up: $ENV_FILE"
    fi
    echo "✨ Worktree cleaned up automatically"
else
    echo "📊 Report: $WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md"
    echo "🔀 Branch: $TASK_BRANCH"
    echo "📁 Worktree kept at: $WORKTREE_PATH"
    echo "🔧 Env file: $ENV_FILE"
    echo "🧹 To clean up later: git worktree remove $WORKTREE_PATH && rm -f $ENV_FILE"
fi

log_success "Task completed independently!"
echo ""
echo "💡 User can now proceed with next tasks."

# エラーが発生していた場合は非ゼロで終了
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then
    exit 1
fi
```

**使用例**: `/project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"`

**結果**: ユーザーは指示後すぐに次のタスクに移行可能。このタスクは独立worktree内で自動完了し、PR準備まで完了。