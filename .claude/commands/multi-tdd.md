# Multi-Agent TDD Workflow

あなたは現在、マルチエージェント TDD ワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1タスク=1worktree）に基づき、以下の手順で**自動実行**してください。

## 実行タスク
$ARGUMENTS

## 実行方針
**ユーザーは指示後、次のタスクに移行可能**。このタスクは独立したworktree内で**全フローを自動完了**します。

### Step 1: タスク用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 1. タスク識別子生成
PROJECT_ROOT=$(basename $(pwd))
TASK_ID=$(echo "$ARGUMENTS" | sed 's/[^a-zA-Z0-9]/-/g' | cut -c1-20)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TASK_BRANCH="bugfix/jwt-${TIMESTAMP}"
WORKTREE_PATH="../${PROJECT_ROOT}-${TASK_ID}"

# 2. Featureブランチ作成とWorktree作成（公式パターン）
git worktree add "$WORKTREE_PATH" -b "$TASK_BRANCH"

# 3. .claude設定をコピー
cp -r .claude "$WORKTREE_PATH/"

echo "🚀 Task worktree created: $WORKTREE_PATH"
echo "📋 Task: $ARGUMENTS"
echo "🌿 Branch: $TASK_BRANCH"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$TASK_BRANCH`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Explore（探索・調査）
```bash
cd "$WORKTREE_PATH"

# Explorerエージェント実行
echo "🔍 Phase 1: Exploring..."
```

**Explorer指示**:
$(cat .claude/prompts/explorer.md)

**タスク**: $ARGUMENTS

**実行内容**:
1. 現在のコードベースを調査・分析
2. 問題の根本原因を特定
3. 影響範囲と依存関係を明確化
4. 要件と制約を整理
5. 結果を `explore-results.md` に保存

```bash
git add explore-results.md
git commit -m "[EXPLORE] Analysis complete: $ARGUMENTS"
```

#### Phase 2: Plan（計画策定）
```bash
echo "📋 Phase 2: Planning..."
```

**Planner指示**:
$(cat .claude/prompts/planner.md)

**前フェーズ結果**: `explore-results.md`
**タスク**: $ARGUMENTS

**実行内容**:
1. Explore結果を基に実装戦略を策定
2. TDD手順（Test First）での開発計画
3. 実装の優先順位と段階分け
4. テスト戦略とカバレッジ計画
5. 結果を `plan-results.md` に保存

```bash
git add plan-results.md
git commit -m "[PLAN] Strategy complete: $ARGUMENTS"
```

#### Phase 3: Coding（TDD実装）
```bash
echo "💻 Phase 3: Coding with TDD..."
```

**Coder指示**:
$(cat .claude/prompts/coder.md)

**前フェーズ結果**: `explore-results.md`, `plan-results.md`
**タスク**: $ARGUMENTS

**TDD実行順序**:
1. **Write tests › Commit** - 失敗するテストを先に作成
2. **Code › Iterate** - テストを通すための最小実装
3. **Refactor › Commit** - コード品質向上

```bash
# TDD Cycle
git add tests/
git commit -m "[TDD-RED] Failing tests: $ARGUMENTS"

git add src/
git commit -m "[TDD-GREEN] Implementation: $ARGUMENTS"

git add .
git commit -m "[TDD-REFACTOR] Code quality improvements: $ARGUMENTS"

# 最終結果保存
git add coding-results.md
git commit -m "[CODING] Implementation complete: $ARGUMENTS"
```

### Step 3: 完了通知とPR準備

```bash
echo "✅ Phase 4: Task completion..."

# 最終検証
npm test || echo "⚠️ Tests need attention"

# 完了レポート生成
cat > task-completion-report.md << EOF
# Task Completion Report

## Task Summary
**Task**: $ARGUMENTS  
**Branch**: $TASK_BRANCH
**Worktree**: $WORKTREE_PATH
**Completed**: $(date)

## Phase Results
- ✅ **Explore**: Root cause analysis complete
- ✅ **Plan**: Implementation strategy defined  
- ✅ **Code**: TDD implementation finished
- ✅ **Ready**: PR ready for review

## Files Modified
$(git diff --name-only origin/main)

## Commits
$(git log --oneline origin/main..HEAD)

## Next Steps
1. Review implementation in worktree: $WORKTREE_PATH
2. Create PR: $TASK_BRANCH → main
3. Clean up worktree after merge

EOF

git add task-completion-report.md
git commit -m "[COMPLETE] Task finished: $ARGUMENTS"

echo "🎉 Task completed independently!"
echo "📊 Report: $WORKTREE_PATH/task-completion-report.md"
echo "🔀 Ready for PR: $TASK_BRANCH → main"
echo ""
echo "💡 User can now proceed with next tasks."
echo "🧹 Cleanup: git worktree remove $WORKTREE_PATH (after PR merge)"
```

**使用例**: `/project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"`

**結果**: ユーザーは指示後すぐに次のタスクに移行可能。このタスクは独立worktree内で自動完了し、PR準備まで完了。