# Multi-Agent Refactoring Workflow

<refactoring_workflow>
  <metadata>
    <workflow_type>refactoring</workflow_type>
    <task_description>$TASK_DESCRIPTION</task_description>
    <automation_level>full</automation_level>
  </metadata>

  <quality_gates>
    <gate phase="all">
      <requirement priority="CRITICAL">All existing tests MUST continue to pass</requirement>
      <requirement priority="HIGH">Code coverage MUST NOT decrease</requirement>
      <requirement priority="HIGH">Performance MUST NOT degrade</requirement>
      <requirement priority="MEDIUM">Backward compatibility MUST be maintained</requirement>
    </gate>
    <gate phase="analysis">
      <requirement>Baseline metrics MUST be captured</requirement>
      <requirement>Technical debt MUST be identified</requirement>
    </gate>
    <gate phase="refactor">
      <requirement>Each refactoring step MUST be atomic and reversible</requirement>
      <requirement>ALWAYS commit after each successful refactoring pattern</requirement>
    </gate>
  </quality_gates>

  <emphasis_guidelines>
    <level name="CRITICAL">System-breaking risks that require immediate attention</level>
    <level name="ALWAYS">Mandatory actions that must be performed every time</level>
    <level name="NEVER">Prohibited actions that could cause issues</level>
    <level name="MUST">Quality requirements that cannot be skipped</level>
    <level name="IMPORTANT">Key considerations for success</level>
  </emphasis_guidelines>
</refactoring_workflow>

あなたは現在、マルチエージェントリファクタリングワークフローのオーケストレーターです。Anthropic公式の git worktree ベストプラクティス（1タスク=1worktree）に基づき、以下の手順で**自動実行**してください。

## リファクタリング対象
$TASK_DESCRIPTION

## 利用可能なオプション
- `--keep-worktree`: worktreeを保持（デフォルト: 削除）
- `--no-merge`: mainへの自動マージをスキップ（デフォルト: マージ）
- `--pr`: GitHub PRを作成（デフォルト: 作成しない）
- `--no-draft`: 通常のPRを作成（デフォルト: ドラフト）
- `--no-cleanup`: 自動クリーンアップを無効化
- `--cleanup-days N`: N日以上前のworktreeを削除（デフォルト: 7）

## 実行方針
**1リファクタリング = 1worktree** で全フローを自動実行。既存テストを保持しながら段階的に実行。

### リファクタリングの基本原則
- **動作保証**: 既存機能の動作を完全に保持
- **段階的実行**: 小さな変更を積み重ねて安全に進行
- **テスト駆動**: 各段階でテストを実行し、グリーンを維持
- **測定可能**: パフォーマンス・可読性・保守性の改善を定量化

### Step 1: リファクタリング用Worktree作成（オーケストレーター）

**Anthropic公式パターン準拠**：

```bash
# 共通ユーティリティの読み込み
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# オプション解析
parse_workflow_options "$@"

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
WORKTREE_INFO=$(create_task_worktree "$TASK_DESCRIPTION" "refactor")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
REFACTOR_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)
FEATURE_NAME=$(echo "$WORKTREE_INFO" | cut -d'|' -f3)

# タスクIDを生成（環境ファイル名用）
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ENV_FILE=$(generate_env_file_path "refactor" "$TASK_ID" "$TIMESTAMP")

# 環境変数をファイルに保存
cat > "$ENV_FILE" << EOF
WORKTREE_PATH="$WORKTREE_PATH"
REFACTOR_BRANCH="$REFACTOR_BRANCH"
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

log_success "Refactoring worktree created"
echo "🔧 Refactoring: $TASK_DESCRIPTION"
echo "🌿 Branch: $REFACTOR_BRANCH"
echo "📁 Worktree: $WORKTREE_PATH"
echo "🏷️ Feature: $FEATURE_NAME"
echo "💾 Environment: $ENV_FILE"
echo "⚙️ Options: keep-worktree=$KEEP_WORKTREE, no-merge=$NO_MERGE, pr=$CREATE_PR"

# 環境ファイルパスを明示的にエクスポート（セッション分離対応）
export ENV_FILE
echo ""
echo "📌 IMPORTANT: Use this environment file in each phase:"
echo "   ENV_FILE='$ENV_FILE'"
```

### Step 2: Worktree内で全フロー自動実行

**Worktree**: `$WORKTREE_PATH` **Branch**: `$REFACTOR_BRANCH` **Feature**: `$FEATURE_NAME`

**重要**: 以下の全フローを**同一worktree内で連続自動実行**します：

#### Phase 1: Analysis（現状分析）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

# ClaudeCodeアクセス制限対応: cdを使用せず、worktree内で作業
log_info "Working in worktree: $WORKTREE_PATH"

show_progress "Analysis" 4 1

# フェーズ開始を記録
create_phase_status "$WORKTREE_PATH" "analysis" "started"

# Explorerプロンプトの読み込み（メインディレクトリから）
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
```

**Explorer指示**:
$EXPLORER_PROMPT

**リファクタリング対象**: $TASK_DESCRIPTION

**作業ディレクトリ**: $WORKTREE_PATH
**注意**: ClaudeCodeのアクセス制限により、直接worktreeディレクトリに移動できません。以下の方法で作業してください：
- ファイル読み取り: `Read $WORKTREE_PATH/ファイル名`
- ファイル書き込み: `Write $WORKTREE_PATH/ファイル名`
- ファイル編集: `Edit $WORKTREE_PATH/ファイル名`

**実行内容**:
1. 対象コードの構造と依存関係を調査
2. 既存テストのカバレッジと品質を確認
3. パフォーマンスのベースラインを測定
4. 技術的負債とコードの複雑度を特定
5. リファクタリングのリスクと機会を評価
6. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md` に保存

**構造化されたディレクトリ**: 
- テスト: `$WORKTREE_PATH/test/$FEATURE_NAME/`
- レポート: `$WORKTREE_PATH/report/$FEATURE_NAME/`
- ソース: `$WORKTREE_PATH/src/$FEATURE_NAME/`

```bash
# レポートディレクトリ作成
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"

# Analysis結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/analysis-results.md"
    git -C "$WORKTREE_PATH" commit -m "[ANALYSIS] Current state analyzed: $TASK_DESCRIPTION" || {
        rollback_on_error "$WORKTREE_PATH" "analysis" "Failed to commit analysis results"
        handle_error 1 "Analysis phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [ANALYSIS] Current state analyzed"
    update_phase_status "$WORKTREE_PATH" "analysis" "completed"
else
    rollback_on_error "$WORKTREE_PATH" "analysis" "report/$FEATURE_NAME/phase-results/analysis-results.md not found"
    handle_error 1 "Analysis results not created" "$WORKTREE_PATH"
fi
```

#### Phase 2: Plan（戦略策定）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

show_progress "Plan" 4 2

# 前フェーズの完了確認
if ! check_phase_completed "$WORKTREE_PATH" "analysis"; then
    log_error "Analysis phase not completed"
    handle_error 1 "Cannot proceed without analysis phase" "$WORKTREE_PATH"
fi

# フェーズ開始を記録
create_phase_status "$WORKTREE_PATH" "plan" "started"

# Plannerプロンプトの読み込み
PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
```

**Planner指示**:
$PLANNER_PROMPT

**前フェーズ結果**: `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md`
**リファクタリング対象**: $TASK_DESCRIPTION
**作業ディレクトリ**: $WORKTREE_PATH

**実行内容**:
1. Analysis結果を基に段階的なリファクタリング計画を策定
2. 各段階のテスト戦略と検証方法を定義
3. ロールバック計画とリスク軽減策を準備
4. 後方互換性の維持方法を設計
5. 成功基準と改善目標を定義
6. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md` に保存

```bash
# Plan結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/refactoring-plan.md"
    git -C "$WORKTREE_PATH" commit -m "[PLAN] Refactoring strategy defined: $TASK_DESCRIPTION" || {
        rollback_on_error "$WORKTREE_PATH" "plan" "Failed to commit plan results"
        handle_error 1 "Plan phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [PLAN] Refactoring strategy defined"
    update_phase_status "$WORKTREE_PATH" "plan" "completed"
else
    rollback_on_error "$WORKTREE_PATH" "plan" "report/$FEATURE_NAME/phase-results/refactoring-plan.md not found"
    handle_error 1 "Plan results not created" "$WORKTREE_PATH"
fi
```

#### Phase 3: Refactor（段階的実行）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

show_progress "Refactor" 4 3

# 前フェーズの完了確認
if ! check_phase_completed "$WORKTREE_PATH" "plan"; then
    log_error "Plan phase not completed"
    handle_error 1 "Cannot proceed without plan phase" "$WORKTREE_PATH"
fi

# フェーズ開始を記録
create_phase_status "$WORKTREE_PATH" "refactor" "started"

# Coderプロンプトの読み込み
CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
```

**Coder指示**:
$CODER_PROMPT

**前フェーズ結果**: 
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md`
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md`

**リファクタリング対象**: $TASK_DESCRIPTION
**作業ディレクトリ**: $WORKTREE_PATH

**実行パターン**:
- **Extract Method**: 長いメソッドを分割
- **Rename**: わかりやすい命名へ変更
- **Move**: 適切なモジュールへ移動
- **Replace**: 古いパターンを新しいパターンへ
- **Simplify**: 複雑なロジックを簡潔に

**成果物**: `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md`
- 実行した変更の詳細
- 各段階のテスト結果
- パフォーマンス比較
- コミット履歴

**リファクタリング実行順序**:
1. **準備**: ベースラインテストの実行とメトリクス取得
2. **Extract Method**: 長いメソッドを分割
3. **Rename**: わかりやすい命名へ変更
4. **Move**: 適切なモジュールへ移動
5. **Replace**: 古いパターンを新しいパターンへ
6. **Simplify**: 複雑なロジックを簡潔に
7. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md` に保存

```bash
# ベースラインテストの実行
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    rollback_on_error "$WORKTREE_PATH" "refactor" "Baseline tests failed - cannot proceed with refactoring"
    handle_error 1 "Tests must pass before refactoring" "$WORKTREE_PATH"
fi

# 段階的リファクタリングの実行（worktree内で）
# Step 1: Extract Method
if [[ -n $(git -C "$WORKTREE_PATH" diff --name-only) ]]; then
    git -C "$WORKTREE_PATH" add .
    git -C "$WORKTREE_PATH" commit -m "[REFACTOR] Extract method: $TASK_DESCRIPTION" || {
        log_warning "No changes for extract method"
    }
fi

# Step 2: Rename  
if [[ -n $(git -C "$WORKTREE_PATH" diff --name-only) ]]; then
    git -C "$WORKTREE_PATH" add .
    git -C "$WORKTREE_PATH" commit -m "[REFACTOR] Rename for clarity: $TASK_DESCRIPTION" || {
        log_warning "No rename changes"
    }
fi

# Step 3: Reorganize
if [[ -n $(git -C "$WORKTREE_PATH" diff --name-only) ]]; then
    git -C "$WORKTREE_PATH" add .
    git -C "$WORKTREE_PATH" commit -m "[REFACTOR] Reorganize structure: $TASK_DESCRIPTION" || {
        log_warning "No structural changes"
    }
fi

# 最終結果保存（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/refactoring-results.md"
    git -C "$WORKTREE_PATH" commit -m "[REFACTOR] Implementation complete: $TASK_DESCRIPTION" || {
        log_warning "Failed to commit refactoring results"
    }
    log_success "Committed: [REFACTOR] Implementation complete"
    update_phase_status "$WORKTREE_PATH" "refactor" "completed"
else
    log_warning "report/$FEATURE_NAME/phase-results/refactoring-results.md not created, but proceeding to verification"
fi
```

#### Phase 4: Verify（品質検証）
```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

show_progress "Verify" 4 4

# 前フェーズの完了確認
if ! check_phase_completed "$WORKTREE_PATH" "refactor"; then
    log_error "Refactor phase not completed"
    handle_error 1 "Cannot proceed without refactor phase" "$WORKTREE_PATH"
fi

# フェーズ開始を記録
create_phase_status "$WORKTREE_PATH" "verify" "started"

# Testerプロンプトの読み込み
TESTER_PROMPT=$(load_prompt ".claude/prompts/tester.md" "# Testerエージェント: リファクタリング後の品質検証を実施してください")
```

**Tester指示**:
$TESTER_PROMPT

**前フェーズ結果**: 
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md`
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md`
- `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md`

**リファクタリング対象**: $TASK_DESCRIPTION
**作業ディレクトリ**: $WORKTREE_PATH

**実行内容**:
1. 全テストスイートの実行
2. パフォーマンステストとベースライン比較
3. 後方互換性の確認
4. コード品質メトリクスの比較
5. 改善効果の測定
6. 結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md` に保存

```bash
# 検証結果のコミット（worktree内で実行）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/verification-report.md"
    git -C "$WORKTREE_PATH" commit -m "[VERIFY] Quality verification complete: $TASK_DESCRIPTION" || {
        rollback_on_error "$WORKTREE_PATH" "verify" "Failed to commit verification results"
        handle_error 1 "Verification phase failed" "$WORKTREE_PATH"
    }
    log_success "Committed: [VERIFY] Quality verification complete"
    update_phase_status "$WORKTREE_PATH" "verify" "completed"
else
    log_warning "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md not found, but refactoring is complete"
    update_phase_status "$WORKTREE_PATH" "verify" "completed"
fi
```

## リファクタリング固有の考慮事項

### 1. 既存機能の動作保証
- **Golden Master Test**: 変更前の動作を記録
- **Characterization Test**: 現状の振る舞いをテスト化
- **Regression Test**: 意図しない変更を検出

### 2. 段階的な変更とコミット
- **Atomic Commits**: 1つの変更=1つのコミット
- **Meaningful Messages**: 変更の意図を明確に記述
- **Reversible Steps**: 各段階でロールバック可能

### 3. パフォーマンス・可読性の改善測定
- **ベンチマーク**: 実行時間・メモリ使用量
- **複雑度メトリクス**: サイクロマティック複雑度
- **可読性スコア**: コード行数・ネストレベル
- **保守性指標**: 結合度・凝集度

### 4. 後方互換性の維持
- **Deprecation Strategy**: 段階的な非推奨化
- **Facade Pattern**: 新旧インターフェースの共存
- **Feature Toggle**: 段階的な切り替え
- **Migration Guide**: 移行ドキュメントの作成

## コミット戦略

```bash
# 段階的なコミット例
git commit -m "refactor: extract validation logic to separate method"
git commit -m "refactor: rename getUserData to fetchUserProfile for clarity"
git commit -m "refactor: replace callback with async/await pattern"
git commit -m "refactor: optimize database queries with batch processing"
git commit -m "test: add performance benchmarks for refactored code"
```

## 成功基準

### 必須要件
- ✅ 全既存テストがグリーン
- ✅ テストカバレッジ維持または向上
- ✅ パフォーマンス劣化なし
- ✅ 後方互換性の維持

### 改善目標
- 📈 コード複雑度の削減（20%以上）
- 📈 実行速度の向上（10%以上）
- 📈 メモリ使用量の削減
- 📈 可読性・保守性の向上

## エラーハンドリング

### リファクタリング中の問題
- **テスト失敗**: 即座にロールバック
- **パフォーマンス劣化**: 原因分析と代替案検討
- **依存関係の破壊**: 影響範囲の再調査
- **予期せぬ副作用**: 変更の巻き戻しと再計画

## 最終成果物

### $WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md
```markdown
# リファクタリング完了レポート

## 実施内容
- 対象: [リファクタリング対象]
- 期間: [開始〜終了]
- 変更ファイル数: X files
- 変更行数: +XXX / -XXX

## 改善結果
### パフォーマンス
- 実行時間: XX% 改善
- メモリ使用量: XX% 削減

### コード品質
- 複雑度: XX → YY
- 重複コード: XX% 削減
- テストカバレッジ: XX% → YY%

## 主な変更点
1. [変更内容1]
2. [変更内容2]
3. [変更内容3]

## 移行ガイド
[必要に応じて移行手順を記載]

## 次のステップ
- PR作成準備完了
- レビュー依頼先: [担当者]
```

### Step 3: 完了通知とPR準備

```bash
# 共通ユーティリティの再読み込み（セッション分離対応）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}

# 環境ファイルを安全に読み込み
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi

show_progress "Completion" 4 4

# 全テスト実行 - プロジェクトタイプに応じたテスト
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed after refactoring - review needed"
fi

# 完了レポート生成
cat > "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" << EOF
# Refactoring Completion Report

## Refactoring Summary
**Target**: $TASK_DESCRIPTION  
**Branch**: $REFACTOR_BRANCH
**Worktree**: $WORKTREE_PATH
**Completed**: $(date)

## Phase Results
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Analysis**: Current state and risks assessed
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Plan**: Refactoring strategy defined
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Refactor**: Changes implemented incrementally
- $(if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md" ]]; then echo "✅"; else echo "⚠️"; fi) **Verify**: Quality and compatibility confirmed
- $(if [[ -d "$WORKTREE_PATH/report/$FEATURE_NAME" ]]; then echo "✅"; else echo "⚠️"; fi) **Reports**: Quality metrics and coverage reports generated
- $(if run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then echo "✅"; else echo "⚠️"; fi) **Tests**: All tests passing

## Code Quality Improvements
- 複雑度: 詳細は`$WORKTREE_PATH/report/$FEATURE_NAME/quality/complexity-report.md`参照
- テストカバレッジ: 詳細は`$WORKTREE_PATH/report/$FEATURE_NAME/coverage/coverage-report.html`参照
- パフォーマンス: 詳細は`$WORKTREE_PATH/report/$FEATURE_NAME/performance/benchmark-results.md`参照

## Files Modified
$(git -C "$WORKTREE_PATH" diff --name-only origin/main 2>/dev/null || echo "Unable to compare with origin/main")

## Commits
$(git -C "$WORKTREE_PATH" log --oneline origin/main..HEAD 2>/dev/null || git -C "$WORKTREE_PATH" log --oneline -n 10)

## Next Steps
1. Review refactoring in worktree: $WORKTREE_PATH
2. Verify all tests pass and performance meets targets
3. Create PR: $REFACTOR_BRANCH → main
4. Clean up worktree after merge: \`git worktree remove $WORKTREE_PATH\`

## Risk Assessment
- 後方互換性: [Maintained/Breaking changes]
- 移行ガイド: [Required/Not required]

EOF

# worktree内でコミット
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" ]]; then
    git -C "$WORKTREE_PATH" add "report/$FEATURE_NAME/phase-results/task-completion-report.md"
    git -C "$WORKTREE_PATH" commit -m "[COMPLETE] Refactoring ready for review: $TASK_DESCRIPTION" || {
        log_warning "Failed to commit completion report"
    }
    log_success "Committed: [COMPLETE] Refactoring ready for review"
fi

# ローカルマージ（オプション）
if [[ "$NO_MERGE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    log_info "Merging to main branch..."
    if merge_to_main "$WORKTREE_PATH" "$REFACTOR_BRANCH" "$NO_MERGE"; then
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
    
    if create_pull_request "$WORKTREE_PATH" "$REFACTOR_BRANCH" "$TASK_DESCRIPTION" "$is_draft"; then
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
    echo "🔀 Branch: $REFACTOR_BRANCH"
    echo "📁 Worktree kept at: $WORKTREE_PATH"
    echo "💾 Environment: $ENV_FILE"
    echo "🧹 To clean up later: git worktree remove $WORKTREE_PATH && rm -f $ENV_FILE"
fi

log_success "Refactoring completed independently!"
echo ""
echo "💡 User can now proceed with other tasks."

# エラーが発生していた場合は非ゼロで終了
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH" &>/dev/null; then
    exit 1
fi
```

## 使用例

### コードのモダナイゼーション
```
/project:multi-refactor "auth/*.js を TypeScript + async/await に移行"
```

### アーキテクチャ改善
```
/project:multi-refactor "database層をRepository Patternでリファクタリング"
```

### API設計の改善
```
/project:multi-refactor "レガシーAPIをRESTful設計に改善"
```

## 実行結果

ユーザーは指示後すぐに次のタスクに移行可能。このリファクタリングは独立worktree内で以下のフローを自動完了します：

1. **分析フェーズ**: 現状調査・リスク評価・測定
2. **計画フェーズ**: 段階的実施計画・テスト戦略
3. **実装フェーズ**: 小さな変更を積み重ねて安全に実施
4. **検証フェーズ**: 品質・互換性・パフォーマンス検証
5. **完了フェーズ**: PR準備完了・改善結果レポート

全工程が自動化され、ユーザーは最終レビュー時のみ関与すれば良い設計です。