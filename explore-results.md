# Explore Results: multi-feature.mdのセッション分離問題修正

## 分析日時
2025-06-25

## 問題の概要
multi-feature.mdでもmulti-tdd.mdと同じセッション分離問題が発生しています。Bashツールの各実行が独立したセッションで行われるため、`source`で読み込んだ関数や設定した環境変数が次のコマンド実行時に保持されません。

## 影響範囲

### Step 1: 機能用Worktree作成
- worktree-utils.shの関数を読み込み
- 環境変数（WORKTREE_PATH、FEATURE_BRANCH、FEATURE_NAME等）を設定

### 影響を受けるフェーズ（全5フェーズ）
1. **Phase 1: Explore** - line 65-114
   - `log_info()`, `show_progress()`, `load_prompt()`の呼び出し
   - 環境変数（$WORKTREE_PATH、$ARGUMENTS）の参照

2. **Phase 2: Plan** - line 116-158
   - `show_progress()`, `load_prompt()`の呼び出し
   - 環境変数の参照

3. **Phase 3: Prototype** - line 160-186
   - `show_progress()`, `git_commit_phase()`の呼び出し
   - 環境変数の参照

4. **Phase 4: Coding** - line 188-258
   - `show_progress()`, `load_prompt()`の呼び出し
   - 環境変数（$WORKTREE_PATH、$FEATURE_NAME）の参照

5. **Step 3: 完了通知とPR準備** - line 260-413
   - `show_progress()`, `run_tests()`, `merge_to_main()`, `create_pull_request()`, `cleanup_worktree()`の呼び出し
   - すべての環境変数の参照

## 修正方針

### 1. 環境変数の永続化
- Step 1で`.worktrees/.env-{task-id}`ファイルに全環境変数を保存
- 各フェーズの開始時に環境ファイルを読み込み

### 2. 関数の再読み込み
- 各フェーズの開始時に`source .claude/scripts/worktree-utils.sh`を実行
- 必要な関数が利用可能になることを保証

### 3. multi-tdd.mdとの一貫性
- multi-tdd.mdで実装したパターンと同じ方式を採用
- コードの一貫性と保守性を確保

## 必要な変更

### Step 1への追加（環境変数保存）
```bash
# タスクIDを生成（環境ファイル名用）
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
ENV_FILE=".worktrees/.env-${TASK_ID}-$(date +%Y%m%d-%H%M%S)"

# 環境変数をファイルに保存
cat > "$ENV_FILE" << EOF
WORKTREE_PATH="$WORKTREE_PATH"
FEATURE_BRANCH="$FEATURE_BRANCH"
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
```

### 各フェーズへの追加（環境復元）
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
```

### クリーンアップへの追加
```bash
# 環境ファイルも削除
if [[ -f "$ENV_FILE" ]]; then
    rm -f "$ENV_FILE"
    log_info "Environment file cleaned up: $ENV_FILE"
fi
```

## リスクと制約

1. **並行実行時の問題**
   - 複数のmulti-featureタスクを同時実行した場合、`ls -t`で最新ファイルを取得する方式に問題が生じる可能性
   - 将来的にはStep 1で生成したENV_FILEパスを各フェーズに明示的に渡す方式への改善が望ましい

2. **エラーハンドリング**
   - 環境ファイルが見つからない場合のエラーメッセージを改善する余地がある

## テスト計画

1. 修正後のmulti-feature.mdで簡単なタスクを実行
2. 各フェーズで関数と環境変数が正しく利用できることを確認
3. クリーンアップ時に環境ファイルが削除されることを確認