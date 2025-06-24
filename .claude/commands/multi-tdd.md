# Multi-Agent TDD Workflow

あなたは現在、マルチエージェント TDD ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1タスク=1worktree）に基づき、以下の手順で**自動実行**してください。

## 実行タスク
$ARGUMENTS

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

# 環境検証
verify_environment || exit 1

# プロジェクトタイプの検出
PROJECT_TYPE=$(detect_project_type)
log_info "Detected project type: $PROJECT_TYPE"

# worktree作成
WORKTREE_INFO=$(create_task_worktree "$ARGUMENTS" "tdd")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
TASK_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)

log_success "Task worktree created"
echo "📋 Task: $ARGUMENTS"
echo "🌿 Branch: $TASK_BRANCH"
echo "📁 Worktree: $WORKTREE_PATH"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$TASK_BRANCH`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Explore（探索・調査）
```bash
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
5. 結果を `explore-results.md` に保存

```bash
# Explore結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/explore-results.md" ]]; then
    # worktree内でコミット
    git -C "$WORKTREE_PATH" add explore-results.md
    git -C "$WORKTREE_PATH" commit -m "[EXPLORE] Analysis complete: $ARGUMENTS" || {
        log_error "Failed to commit explore results"
        handle_error 1 "Explore phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [EXPLORE] Analysis complete"
else
    log_warning "$WORKTREE_PATH/explore-results.md not found, skipping commit"
fi
```

#### Phase 2: Plan（計画策定）
```bash
show_progress "Plan" 4 2

# Plannerプロンプトの読み込み
PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
```

**Planner指示**:
$PLANNER_PROMPT

**前フェーズ結果**: `$WORKTREE_PATH/explore-results.md`
**タスク**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

**実行内容**:
1. Explore結果を基に実装戦略を策定
2. TDD手順（Test First）での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果を `plan-results.md` に保存

```bash
# Plan結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/plan-results.md" ]]; then
    git -C "$WORKTREE_PATH" add plan-results.md
    git -C "$WORKTREE_PATH" commit -m "[PLAN] Strategy complete: $ARGUMENTS" || {
        log_error "Failed to commit plan results"
        handle_error 1 "Plan phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [PLAN] Strategy complete"
else
    log_warning "$WORKTREE_PATH/plan-results.md not found, skipping commit"
fi
```

#### Phase 3: Coding（TDD実装）
```bash
show_progress "Coding" 4 3

# Coderプロンプトの読み込み
CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
```

**Coder指示**:
$CODER_PROMPT

**前フェーズ結果**: 
- `$WORKTREE_PATH/explore-results.md`
- `$WORKTREE_PATH/plan-results.md`

**タスク**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

**TDD実行順序**:
1. **Write tests › Commit** - 失敗するテストを先に作成
2. **Code › Iterate** - テストを通すための最小実装
3. **Refactor › Commit** - コード品質向上

```bash
# TDD RED Phase - テスト作成（worktree内で実行）
if [[ -d "$WORKTREE_PATH/tests/" ]] || [[ -n $(find "$WORKTREE_PATH" -name "*test*" -type f 2>/dev/null) ]]; then
    git -C "$WORKTREE_PATH" add tests/ *test* 2>/dev/null
    git -C "$WORKTREE_PATH" commit -m "[TDD-RED] Failing tests: $ARGUMENTS" || {
        log_warning "No test files to commit in RED phase"
    }
else
    log_warning "No test directory found in worktree"
fi

# TDD GREEN Phase - 実装（worktree内で実行）
if [[ -d "$WORKTREE_PATH/src/" ]] || [[ -n $(git -C "$WORKTREE_PATH" diff --name-only) ]]; then
    git -C "$WORKTREE_PATH" add src/ *.js *.ts *.py *.go 2>/dev/null
    git -C "$WORKTREE_PATH" commit -m "[TDD-GREEN] Implementation: $ARGUMENTS" || {
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
if [[ -f "$WORKTREE_PATH/coding-results.md" ]]; then
    git -C "$WORKTREE_PATH" add coding-results.md
    git -C "$WORKTREE_PATH" commit -m "[CODING] Implementation complete: $ARGUMENTS" || {
        log_warning "Failed to commit coding results"
    }
    log_success "Committed: [CODING] Implementation complete"
fi
```

### Step 3: 完了通知とPR準備

```bash
show_progress "Completion" 4 4

# 最終検証 - プロジェクトタイプに応じたテスト実行
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - task may be incomplete"
    # テスト失敗してもレポートは生成する
fi

# 完了レポート生成（メインディレクトリに一時作成してからコピー）
cat > /tmp/task-completion-report.md << EOF
# Task Completion Report

## Task Summary
**Task**: $ARGUMENTS  
**Branch**: $TASK_BRANCH
**Worktree**: $WORKTREE_PATH
**Project Type**: $PROJECT_TYPE
**Completed**: $(date)

## Phase Results
- $(if [[ -f "$WORKTREE_PATH/explore-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Explore**: Root cause analysis
- $(if [[ -f "$WORKTREE_PATH/plan-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Plan**: Implementation strategy
- $(if [[ -f "$WORKTREE_PATH/coding-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Code**: TDD implementation
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

## Next Steps
1. Review implementation in worktree: $WORKTREE_PATH
2. Create PR: $TASK_BRANCH → main
3. Clean up worktree after merge: \`git worktree remove $WORKTREE_PATH\`

EOF

# 完了レポートをworktreeにコピーしてコミット
cp /tmp/task-completion-report.md "$WORKTREE_PATH/task-completion-report.md"
rm /tmp/task-completion-report.md

# worktree内でコミット
if [[ -f "$WORKTREE_PATH/task-completion-report.md" ]]; then
    git -C "$WORKTREE_PATH" add task-completion-report.md
    git -C "$WORKTREE_PATH" commit -m "[COMPLETE] Task finished: $ARGUMENTS" || {
        log_warning "Failed to commit completion report"
    }
    log_success "Committed: [COMPLETE] Task finished"
fi

log_success "Task completed independently!"
echo "📊 Report: $WORKTREE_PATH/task-completion-report.md"
echo "🔀 Ready for PR: $TASK_BRANCH → main"
echo ""
echo "💡 User can now proceed with next tasks."
echo "🧹 Cleanup: git worktree remove $WORKTREE_PATH (after PR merge)"

# エラーが発生していた場合は非ゼロで終了
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then
    exit 1
fi
```

**使用例**: `/project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"`

**結果**: ユーザーは指示後すぐに次のタスクに移行可能。このタスクは独立worktree内で自動完了し、PR準備まで完了。