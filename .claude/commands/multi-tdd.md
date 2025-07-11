---
name: multi-tdd
description: TDD（テスト駆動開発）で実装 - Red→Green→Refactorサイクルを自動実行
usage: /multi-tdd "実装するタスクの説明" [--keep-worktree] [--pr] [--no-cleanup]
---

# Multi-Agent TDD Workflow

あなたは現在、マルチエージェント TDD ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1タスク=1worktree）に基づき、以下の手順で**自動実行**してください。

## 実行タスク
$ARGUMENTS

<workflow_options>
利用可能なオプション：
- `--keep-worktree`: worktreeを保持（デフォルト: 削除）
- `--no-merge`: mainへの自動マージをスキップ（デフォルト: マージ）
- `--pr`: GitHub PRを作成（デフォルト: 作成しない）
- `--no-draft`: 通常のPRを作成（デフォルト: ドラフト）
- `--no-cleanup`: 自動クリーンアップを無効化
- `--cleanup-days N`: N日以上前のworktreeを削除（デフォルト: 7）
</workflow_options>

<execution_policy>
実行方針：
1. **ユーザーは指示後、次のタスクに移行可能**
2. このタスクは独立したworktree内で**全フローを自動完了**
3. **ALWAYS**: 各フェーズを順番に実行し、飛ばさない
4. **MUST**: 各フェーズの結果をコミットしてからのみ次に進む
5. **NEVER**: ユーザーの確認を待たずに自動進行する
</execution_policy>

## Step 1: タスク用Worktree作成（オーケストレーター）

<worktree_creation_rules>
Anthropic公式パターン準拠のWorktree作成：
1. **MUST**: worktree-utils.shの共通関数を使用
2. **ALWAYS**: ./.worktrees/サブディレクトリ内に作成（明示的に./.worktrees/を指定）
3. **NEVER**: メインディレクトリで直接作業しない
4. 1タスク = 1worktree = 1ブランチのルールを厳守
5. **IMPORTANT**: 環境ファイルを使用してセッション間でのデータ共有を実現
</worktree_creation_rules>

```bash
# 共通ユーティリティの読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# オプション解析とタスク説明の抽出
parse_workflow_options $ARGUMENTS

# 環境検証とプロジェクト情報取得
verify_environment || exit 1
PROJECT_TYPE=$(detect_project_type)
log_info "Detected project type: $PROJECT_TYPE"

# 古いworktreeのクリーンアップ（オプション）
if [[ "$AUTO_CLEANUP" == "true" ]]; then
    cleanup_old_worktrees "$CLEANUP_DAYS"
fi

# worktree作成（共通関数使用）
# 明示的に ./.worktrees/ ディレクトリ以下に作成
WORKTREE_INFO=$(create_task_worktree "$TASK_DESCRIPTION" "tdd")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
TASK_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)
FEATURE_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f3)

# 環境ファイルの生成
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ENV_FILE=$(generate_env_file_path "tdd" "$TASK_ID" "$TIMESTAMP")

# 環境変数の保存
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
echo "💾 Environment: $ENV_FILE"
echo "⚙️ Options: keep-worktree=$KEEP_WORKTREE, no-merge=$NO_MERGE, pr=$CREATE_PR"

# 環境ファイルパスを明示的にエクスポート
export ENV_FILE
echo ""
echo "📌 IMPORTANT: Use this environment file in each phase:"
echo "   ENV_FILE='$ENV_FILE'"
```

## Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$TASK_BRANCH` **Feature**: `$FEATURE_NAME`

<auto_execution_rules>
全フロー自動実行の原則：
1. **MUST**: 同一worktree内で連続自動実行
2. **ALWAYS**: 各フェーズの結果をコミットしてから次へ進む
3. **NEVER**: フェーズをスキップしない
4. **IMPORTANT**: ClaudeCodeのアクセス制限により、cdコマンドは使用せず、git -Cとファイルフルパスで操作
</auto_execution_rules>

### Phase 1: Explore（探索・調査）

<explore_phase_instructions>
Explorer指示：
1. 現在のコードベースを調査・分析
2. 問題の根本原因を特定
3. 影響範囲と依存関係を明確化
4. 要件と制約を整理
5. 結果を `explore-results.md` に保存

**作業方法**（ClaudeCodeアクセス制限対応）:
- ファイル読み取り: `Read $WORKTREE_PATH/ファイル名`
- ファイル書き込み: `Write $WORKTREE_PATH/ファイル名`
- ファイル編集: `Edit $WORKTREE_PATH/ファイル名`
</explore_phase_instructions>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_phase "${ENV_FILE:-}" "Explore"; then
    exit 1
fi

show_progress "Explore" 4 1

# Explorerプロンプトの読み込み
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
```

**Explorer指示**:
$EXPLORER_PROMPT

**タスク**: $ARGUMENTS
**作業ディレクトリ**: $WORKTREE_PATH

実行内容:
1. 現在のコードベースを調査・分析
2. 問題の根本原因を特定
3. 影響範囲と依存関係を明確化
4. 要件と制約を整理
5. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md` に保存

**テストファイルの配置**: `$WORKTREE_PATH/test/$FEATURE_NAME/`以下に配置してください

```bash
# レポートディレクトリ作成
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"

# Explore結果のコミット（共通関数使用）
commit_phase_results "EXPLORE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md" \
    "Analysis complete: $ARGUMENTS"
```

### Phase 2: Plan（計画策定）

<plan_phase_instructions>
Planner指示：
1. Explore結果を基に実装戦略を策定
2. TDD手順（Test First）での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果を `plan-results.md` に保存
</plan_phase_instructions>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_phase "${ENV_FILE:-}" "Plan"; then
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

実行内容:
1. Explore結果を基に実装戦略を策定
2. TDD手順（Test First）での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md` に保存

```bash
# Plan結果のコミット（共通関数使用）
commit_phase_results "PLAN" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md" \
    "Strategy complete: $ARGUMENTS"
```

### Phase 3: Coding（TDD実装）

<tdd_implementation_rules>
TDD実装の原則：
1. **ALWAYS**: Red → Green → Refactor サイクルを厳守
2. **MUST**: テストを先に書いてからのみ実装を開始
3. **NEVER**: テストなしでコードをコミットしない
4. **IMPORTANT**: 各ステップを個別にコミットして進捗を可視化
</tdd_implementation_rules>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_phase "${ENV_FILE:-}" "Coding"; then
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
# TDD RED Phase - テスト作成
if [[ -d "$WORKTREE_PATH/test/$FEATURE_NAME" ]]; then
    git -C "$WORKTREE_PATH" add "test/$FEATURE_NAME" 2>/dev/null
    git -C "$WORKTREE_PATH" commit -m "[TDD-RED] Failing tests for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No test files to commit in RED phase"
    }
else
    log_warning "No test directory found for feature: $FEATURE_NAME"
fi

# TDD GREEN Phase - 実装
if [[ -d "$WORKTREE_PATH/src/$FEATURE_NAME" ]]; then
    git -C "$WORKTREE_PATH" add "src/$FEATURE_NAME" 2>/dev/null
    git -C "$WORKTREE_PATH" commit -m "[TDD-GREEN] Implementation for $FEATURE_NAME: $ARGUMENTS" || {
        log_warning "No implementation files to commit in GREEN phase"
    }
fi

# TDD REFACTOR Phase - リファクタリング
if [[ -n $(git -C "$WORKTREE_PATH" diff --name-only) ]]; then
    git -C "$WORKTREE_PATH" add .
    git -C "$WORKTREE_PATH" commit -m "[TDD-REFACTOR] Code quality improvements: $ARGUMENTS" || {
        log_warning "No changes to commit in REFACTOR phase"
    }
fi

# 最終結果保存
commit_phase_results "CODING" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/coding-results.md" \
    "Implementation complete: $ARGUMENTS"
```

## Step 3: 完了通知とPR準備

<completion_requirements>
完了時の必須事項：
1. **MUST**: 全テストが通ることを確認
2. **ALWAYS**: 完了レポートを生成してコミット
3. オプションに応じてPR作成またはローカルマージ
4. **IMPORTANT**: worktreeクリーンアップの判断は設定に従う
</completion_requirements>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_phase "${ENV_FILE:-}" "Completion"; then
    exit 1
fi

show_progress "Completion" 4 4

# 最終検証 - プロジェクトタイプに応じたテスト実行
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - task may be incomplete"
fi

# 完了レポート生成（共通関数使用）
generate_completion_report "$WORKTREE_PATH" "$FEATURE_NAME" "$TASK_DESCRIPTION" \
    "$TASK_BRANCH" "$PROJECT_TYPE" "tdd"

# 完了レポートのコミット
commit_phase_results "COMPLETE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" \
    "Task finished: $TASK_DESCRIPTION"

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
    echo "💾 Environment: $ENV_FILE"
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

<usage_example>
使用例：
```
/multi-tdd "認証機能のJWT有効期限チェック不具合を修正"
/multi-tdd "ユーザー登録時のメール重複チェックのバグ修正" --pr
/multi-tdd "API レートリミット機能の実装" --keep-worktree --no-merge
```
</usage_example>

## 詳細な使用例

### バグ修正でTDD実践
```bash
# 失敗するテストを先に書いてから修正
/multi-tdd "ユーザー名に絵文字が含まれる場合のバリデーションエラー修正"
```

### 新機能をTDDで実装
```bash
# テストファーストで新機能を追加
/multi-tdd "パスワードリセット機能の実装" --pr --no-draft
```

### 複雑なロジックの実装
```bash
# worktreeを保持してステップごとに確認
/multi-tdd "価格計算ロジックの割引適用処理" --keep-worktree
```

## オプション

- `--keep-worktree`: 作業用worktreeを削除せずに保持
- `--no-merge`: mainブランチへの自動マージをスキップ
- `--pr`: GitHub Pull Requestを作成
- `--no-draft`: 通常のPR作成（デフォルトはドラフト）
- `--no-cleanup`: 古いworktreeの自動クリーンアップを無効化
- `--cleanup-days N`: N日以上前のworktreeを削除（デフォルト: 7）

<expected_result>
期待される結果：
- ユーザーは指示後すぐに次のタスクに移行可能
- タスクは独立worktree内で自動完了
- TDDサイクルに従った品質の高い実装
- PR準備まで完了した状態
</expected_result>