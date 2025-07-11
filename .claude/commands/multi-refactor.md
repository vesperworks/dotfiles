# Multi-Agent Refactoring Workflow

<refactoring_guidelines>
リファクタリングワークフローの基本原則：

1. **動作保証**: 既存機能の動作を完全に保持
   - MUST: 全ての既存テストがパスすること
   - NEVER: テストが失敗したままコミットしない
   - ALWAYS: 各段階でテストを実行

2. **段階的実行**: 小さな変更を積み重ねて安全に進行
   - ALWAYS: 1つの変更 = 1つのコミット
   - MUST: 各変更をアトミックで可逆的にする
   - IMPORTANT: ロールバック可能な状態を維持

3. **測定可能性**: 改善効果を定量的に評価
   - パフォーマンスベンチマーク
   - コード複雑度メトリクス
   - テストカバレッジ率

4. **品質ゲート**: 各フェーズでの必須要件
   - MUST: コードカバレッジが低下しない
   - MUST: パフォーマンスが劣化しない
   - MUST: 後方互換性を維持する
</refactoring_guidelines>

<refactoring_patterns>
リファクタリングの実行パターン：

1. **Extract Method**: 長いメソッドを分割
   - 20行以上のメソッドを対象
   - 単一責任の原則に従う
   - 意味のある名前を付ける

2. **Rename**: わかりやすい命名へ変更
   - 変数・関数・クラス名の改善
   - 一貫性のある命名規則適用
   - ドメイン用語への統一

3. **Move**: 適切なモジュールへ移動
   - 凝集度の高いモジュール構成
   - 結合度の低減
   - 依存関係の整理

4. **Replace**: 古いパターンを新しいパターンへ
   - コールバックからasync/awaitへ
   - forループからmap/filterへ
   - クラスベースから関数型へ

5. **Simplify**: 複雑なロジックを簡潔に
   - ネストの削減
   - 条件分岐の簡素化
   - 重複コードの除去
</refactoring_patterns>

<emphasis_words>
強調語の使用ガイドライン：

**CRITICAL**: システム破壊リスクがある重要事項
**ALWAYS**: 毎回必ず実行すべきアクション
**NEVER**: 絶対に行ってはいけない禁止事項
**MUST**: スキップできない品質要件
**IMPORTANT**: 成功のための重要な考慮事項
</emphasis_words>

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
# 明示的に ./.worktrees/ ディレクトリ以下に作成
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

<analysis_phase>
分析フェーズの実行内容：

1. **対象コードの構造調査**
   - ファイル構成の確認
   - モジュール間の依存関係
   - 外部ライブラリの使用状況

2. **テストカバレッジの確認**
   - 現在のカバレッジ率測定
   - テストの品質評価
   - 不足しているテストケースの特定

3. **パフォーマンスベースライン**
   - 実行時間の測定
   - メモリ使用量の記録
   - リソース消費パターンの分析

4. **技術的負債の特定**
   - コード複雑度の測定
   - 重複コードの検出
   - デザインパターンの不一致

5. **リスク評価**
   - 変更による影響範囲
   - 後方互換性への影響
   - 潜在的な破壊的変更

**MUST**: 全てのメトリクスを記録し、後で比較可能にする
**IMPORTANT**: 主観的な評価ではなく、測定可能な指標を使用
</analysis_phase>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_refactor_phase "${ENV_FILE:-}" "Analysis" "" 4 1; then
    exit 1
fi

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

**実行内容**: <analysis_phase>ブロックの手順に従って分析を実施

**構造化されたディレクトリ**: 
- テスト: `$WORKTREE_PATH/test/$FEATURE_NAME/`
- レポート: `$WORKTREE_PATH/report/$FEATURE_NAME/`
- ソース: `$WORKTREE_PATH/src/$FEATURE_NAME/`

結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md` に保存してください。

```bash
# レポートディレクトリ作成
mkdir -p "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results"

# Analysis結果のコミット（共通関数使用）
commit_refactor_phase "$WORKTREE_PATH" "analysis" "ANALYSIS" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md" \
    "Current state analyzed" "$TASK_DESCRIPTION"
```

#### Phase 2: Plan（戦略策定）

<planning_phase>
計画フェーズの実行内容：

1. **段階的リファクタリング計画**
   - 各段階の具体的な変更内容
   - 推定作業時間と複雑度
   - 段階間の依存関係

2. **テスト戦略**
   - 各段階でのテスト方法
   - 新規テストケースの追加計画
   - リグレッションテストの実行タイミング

3. **ロールバック計画**
   - 各段階でのロールバック手順
   - チェックポイントの設定
   - 失敗時の復旧手順

4. **後方互換性維持策**
   - 非推奨化の段階的実施
   - 移行期間の設定
   - 利用者への影響最小化

5. **成功基準の定義**
   - 定量的な改善目標
   - 品質メトリクスの閾値
   - 完了判定の基準

**ALWAYS**: 小さく安全な変更から始める
**NEVER**: 一度に大きな変更を行わない
</planning_phase>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_refactor_phase "${ENV_FILE:-}" "Plan" "analysis" 4 2; then
    exit 1
fi

# Plannerプロンプトの読み込み
PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
```

**Planner指示**:
$PLANNER_PROMPT

**前フェーズ結果**: `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/analysis-results.md`
**リファクタリング対象**: $TASK_DESCRIPTION
**作業ディレクトリ**: $WORKTREE_PATH

**実行内容**: <planning_phase>ブロックの手順に従って計画を策定

結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md` に保存してください。

```bash
# Plan結果のコミット（共通関数使用）
commit_refactor_phase "$WORKTREE_PATH" "plan" "PLAN" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-plan.md" \
    "Refactoring strategy defined" "$TASK_DESCRIPTION"
```

#### Phase 3: Refactor（段階的実行）

<refactor_execution>
リファクタリング実行の手順：

1. **ベースライン確立**
   - MUST: 全テストがグリーンであることを確認
   - 現在のメトリクスを記録
   - スナップショットの作成

2. **段階的実行**
   - Step 1: Extract Method（メソッド抽出）
   - Step 2: Rename（命名改善）
   - Step 3: Move（構造整理）
   - Step 4: Replace（パターン置換）
   - Step 5: Simplify（簡素化）

3. **各段階での検証**
   - ALWAYS: 変更後にテストを実行
   - ALWAYS: グリーンを確認してからコミット
   - NEVER: テスト失敗のままコミットしない

4. **進捗記録**
   - 各段階の変更内容
   - テスト結果
   - パフォーマンス影響

**CRITICAL**: テストが失敗したら即座にロールバック
**IMPORTANT**: 1つの段階が完了するまで次に進まない
</refactor_execution>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_refactor_phase "${ENV_FILE:-}" "Refactor" "plan" 4 3; then
    exit 1
fi

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

**実行内容**: 
1. <refactoring_patterns>ブロックのパターンを適用
2. <refactor_execution>ブロックの手順に従って段階的に実行
3. <refactoring_guidelines>ブロックの原則を遵守

**成果物**: `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md`に以下を記録：
- 実行した変更の詳細
- 各段階のテスト結果
- パフォーマンス比較
- コミット履歴

```bash
# ベースラインテストの実行
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    rollback_on_error "$WORKTREE_PATH" "refactor" "Baseline tests failed - cannot proceed with refactoring"
    handle_error 1 "Tests must pass before refactoring" "$WORKTREE_PATH"
fi

# 段階的リファクタリングの実行（共通関数使用）
# Step 1: Extract Method
commit_refactor_step "$WORKTREE_PATH" "extract-method" "Extract method" "$TASK_DESCRIPTION"

# Step 2: Rename  
commit_refactor_step "$WORKTREE_PATH" "rename" "Rename for clarity" "$TASK_DESCRIPTION"

# Step 3: Reorganize
commit_refactor_step "$WORKTREE_PATH" "reorganize" "Reorganize structure" "$TASK_DESCRIPTION"

# 最終結果保存（共通関数使用）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md" ]]; then
    commit_refactor_phase "$WORKTREE_PATH" "refactor" "REFACTOR" \
        "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/refactoring-results.md" \
        "Implementation complete" "$TASK_DESCRIPTION"
else
    log_warning "report/$FEATURE_NAME/phase-results/refactoring-results.md not created, but proceeding to verification"
    update_phase_status "$WORKTREE_PATH" "refactor" "completed"
fi
```

#### Phase 4: Verify（品質検証）

<verification_phase>
検証フェーズの実行内容：

1. **全テストスイートの実行**
   - 単体テスト
   - 統合テスト
   - E2Eテスト

2. **パフォーマンス検証**
   - ベースラインとの比較
   - ボトルネックの特定
   - 改善効果の測定

3. **後方互換性チェック**
   - APIの互換性
   - 動作の一貫性
   - エッジケースの確認

4. **コード品質評価**
   - 複雑度の変化
   - 可読性の改善度
   - 保守性指標

5. **改善効果のまとめ**
   - 定量的な改善結果
   - 定性的な改善点
   - 残された課題

**MUST**: 全ての品質基準を満たすことを確認
**IMPORTANT**: 劣化が見つかった場合は原因を特定
</verification_phase>

```bash
# フェーズ初期化（共通関数使用）
if ! initialize_refactor_phase "${ENV_FILE:-}" "Verify" "refactor" 4 4; then
    exit 1
fi

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

**実行内容**: <verification_phase>ブロックの手順に従って品質検証を実施

結果を `$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md` に保存してください。

```bash
# 検証結果のコミット（共通関数使用）
if [[ -f "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md" ]]; then
    commit_refactor_phase "$WORKTREE_PATH" "verify" "VERIFY" \
        "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md" \
        "Quality verification complete" "$TASK_DESCRIPTION"
else
    log_warning "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/verification-report.md not found, but refactoring is complete"
    update_phase_status "$WORKTREE_PATH" "verify" "completed"
fi
```

<quality_assurance>
リファクタリング固有の品質保証：

1. **Golden Master Test**
   - 変更前の動作を完全に記録
   - 出力の完全一致を検証
   - 意図しない変更を検出

2. **Characterization Test**
   - 現状の振る舞いをテスト化
   - 未文書化の仕様を明確化
   - 暗黙の依存関係を発見

3. **Regression Test**
   - 既存機能の動作確認
   - エッジケースの検証
   - パフォーマンス劣化の検出

4. **Migration Support**
   - 段階的な移行パスの提供
   - 非推奨警告の実装
   - 移行ガイドの作成

**ALWAYS**: 測定可能な改善を達成する
**NEVER**: 「リファクタリングのためのリファクタリング」をしない
</quality_assurance>

<commit_strategy>
段階的コミット戦略：

1. **アトミックコミット**
   ```bash
   git commit -m "refactor: extract validation logic to separate method"
   git commit -m "refactor: rename getUserData to fetchUserProfile for clarity"
   git commit -m "refactor: replace callback with async/await pattern"
   ```

2. **意味のあるメッセージ**
   - 変更の種類を明示（refactor:）
   - 具体的な変更内容を記述
   - 変更の理由や効果を含める

3. **ロールバック可能性**
   - 各コミットが独立して動作
   - テストがパスする状態を維持
   - 依存関係を明確に管理

**MUST**: 各コミットでテストがグリーンであること
**IMPORTANT**: コミットメッセージから変更内容が理解できること
</commit_strategy>

## 成功基準

<success_criteria>
リファクタリングの成功基準：

**必須要件（MUST）**:
- ✅ 全既存テストがグリーン
- ✅ テストカバレッジ維持または向上
- ✅ パフォーマンス劣化なし
- ✅ 後方互換性の維持

**改善目標**:
- 📈 コード複雑度の削減（20%以上）
- 📈 実行速度の向上（10%以上）
- 📈 メモリ使用量の削減
- 📈 可読性・保守性の向上

**測定指標**:
- サイクロマティック複雑度
- コード行数（LOC）
- テスト実行時間
- ビルド時間
</success_criteria>

<error_handling>
エラー時の対処方針：

1. **テスト失敗時**
   - ALWAYS: 即座にロールバック
   - 失敗原因を特定して記録
   - 代替アプローチを検討

2. **パフォーマンス劣化時**
   - プロファイリングで原因特定
   - 最適化の余地を探る
   - トレードオフを明確化

3. **依存関係の破壊時**
   - 影響範囲を再調査
   - 段階的な移行計画を立案
   - 互換性レイヤーの実装

4. **予期せぬ副作用時**
   - 変更を巻き戻す
   - より小さな単位で再実行
   - テストケースを追加

**CRITICAL**: 破壊的な変更は絶対に避ける
**IMPORTANT**: エラーは学習の機会として活用
</error_handling>

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

# 完了レポート生成（共通関数使用）
generate_refactor_completion_report "$WORKTREE_PATH" "$FEATURE_NAME" "$TASK_DESCRIPTION" "$REFACTOR_BRANCH" "$PROJECT_TYPE"

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

1. **分析フェーズ**: 現状調査・リスク評価・測定（<analysis_phase>参照）
2. **計画フェーズ**: 段階的実施計画・テスト戦略（<planning_phase>参照）
3. **実装フェーズ**: 小さな変更を積み重ねて安全に実施（<refactor_execution>参照）
4. **検証フェーズ**: 品質・互換性・パフォーマンス検証（<verification_phase>参照）
5. **完了フェーズ**: PR準備完了・改善結果レポート

全工程が自動化され、ユーザーは最終レビュー時のみ関与すれば良い設計です。