---
name: multi-feature-ccm
description: 'Develop new feature with ccmanager integration: /multi-feature-ccm "feature name" [--keep-worktree] [--pr] [--no-ccm]'
---

<feature_development_workflow_ccmanager>

# Multi-Agent Feature Development with ccmanager

あなたは現在、ccmanager統合版マルチエージェント機能開発ワークフローのオーケストレーターです。ccmanagerを活用して複数の機能開発を効率的に管理します。

<configuration>
  <task_description>$ARGUMENTS</task_description>
  
  <options>
    <option name="--keep-worktree" default="false">
      <description>worktreeを保持（デフォルト: 削除）</description>
    </option>
    <option name="--no-merge" default="false">
      <description>mainへの自動マージをスキップ</description>
    </option>
    <option name="--pr" default="false">
      <description>GitHub PRを作成</description>
    </option>
    <option name="--no-draft" default="false">
      <description>通常のPRを作成（デフォルト: ドラフト）</description>
    </option>
    <option name="--no-ccm" default="false">
      <description>ccmanager統合を無効化（従来モード）</description>
    </option>
    <option name="--preset-base" default="feature">
      <description>ccmanagerプリセットのベース名</description>
    </option>
  </options>
  
  <principles>
    - **ccmanagerによるセッション管理** で並列開発を効率化
    - **プリセット駆動開発** で各フェーズを最適化
    - **ステータス可視化** で進行状況を一元管理
  </principles>
</configuration>

**IMPORTANT**: ccmanagerを使用してセッション管理とフェーズ制御を行います。

<phase name="worktree_setup_ccm">
  <objectives>
    - Create isolated worktree for feature development
    - Register worktree in ccmanager
    - Set up phase-specific presets
    - Initialize ccmanager session
  </objectives>
  
  <tools>
    - Git worktree commands
    - ccmanager CLI
    - Preset configuration
  </tools>
  
  <quality_gates>
    - MUST verify ccmanager availability
    - MUST create unique session identifier
    - ALWAYS configure phase presets
    - ALWAYS save ccmanager config
  </quality_gates>

  <implementation>
### Phase 0: Worktree Setup with ccmanager

**実行主体**: オーケストレーター
**目的**: ccmanager前提の環境初期化

```bash
# Phase 0: 初期化チェック
source .claude/scripts/worktree-utils.sh || exit 1
parse_workflow_options $ARGUMENTS

# ccmanager必須チェック
if ! command -v ccmanager &>/dev/null; then
    log_error "ccmanager is required for this workflow"
    echo "Please install ccmanager: bun install -g ccmanager"
    exit 1
fi

# プロジェクトタイプ検出
PROJECT_TYPE=$(detect_project_type)

# 環境変数保存
TASK_ID=$(echo "$TASK_DESCRIPTION" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]' | cut -c1-30)
ENV_FILE=$(generate_env_file_path "feature" "$TASK_ID" "$(date +%Y%m%d-%H%M%S)")

cat > "$ENV_FILE" << EOF
PROJECT_TYPE="$PROJECT_TYPE"
TASK_DESCRIPTION="$TASK_DESCRIPTION"
KEEP_WORKTREE="$KEEP_WORKTREE"
NO_MERGE="$NO_MERGE"
CREATE_PR="$CREATE_PR"
NO_DRAFT="$NO_DRAFT"
EOF

export ENV_FILE
log_success "Environment prepared for ccmanager workflow"
echo "📌 Environment: ENV_FILE='$ENV_FILE'"
echo "🎮 Please use 'ccm' to create worktree and start feature development"
echo "💡 Select 'feature-explorer' preset to begin Explorer phase"
```

  </implementation>
  
  <output>
    - Created worktree with ccmanager registration
    - Phase presets configured
    - Environment file with ccm settings
    - Ready for phase-based development
  </output>
</phase>

## Multi-Agent Feature Development Phases with ccmanager

**IMPORTANT**: 各フェーズはccmanagerプリセットで管理されます。

<phase name="explore_ccm">
  <implementation>
#### Phase 1: Explore with ccmanager
```bash
initialize_phase "$ENV_FILE" "Explore"

echo "🔍 Starting Explorer phase"
echo "💡 Please use ccmanager to switch to feature-explorer preset"
echo "📝 This phase will analyze requirements and constraints"
echo ""
echo "**開発機能**: $TASK_DESCRIPTION"
echo "**ccmanager操作**: Use 'ccm' to navigate to your worktree and start explorer session"

# Explorerプロンプト表示
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
echo "$EXPLORER_PROMPT"

echo ""
echo "✅ Save your exploration results to: [worktree]/report/[feature]/phase-results/explore-results.md"
echo "🔄 When complete, continue to Phase 2: Plan"
```
  </implementation>
</phase>

<phase name="plan_ccm">
  <implementation>
#### Phase 2: Plan with ccmanager
```bash
initialize_phase "$ENV_FILE" "Plan"

if [[ "$USE_CCM" == "true" ]]; then
    update_ccm_phase "planner" "active"
    
    echo "📐 Starting Planner phase in ccmanager session..."
    echo "💡 This phase will design architecture based on exploration results"
    echo ""
    
    if [[ "${AUTO_START_CCM:-false}" == "true" ]]; then
        ccmanager switch --preset "${PRESET_BASE}-planner" --resume
    else
        echo "🎮 Switch to Planner phase:"
        echo "   1. Run 'ccm' and select the feature worktree"
        echo "   2. Choose '${PRESET_BASE}-planner' preset"
    fi
else
    # 従来モード
    PLANNER_PROMPT=$(load_prompt ".claude/prompts/planner.md" "$DEFAULT_PLANNER_PROMPT")
    echo "$PLANNER_PROMPT"
    echo ""
    echo "**前フェーズ結果**: $WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md"
    echo "**開発機能**: $TASK_DESCRIPTION"
fi

# Phase 2 完了処理
if [[ "$USE_CCM" == "true" ]]; then
    echo "✅ When Planner phase is complete, results will be at:"
    echo "   $WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md"
    update_ccm_phase "planner" "completed"
else
    commit_phase_results "PLAN" "$WORKTREE_PATH" \
        "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/plan-results.md" \
        "Architecture design complete: $TASK_DESCRIPTION"
fi
```
  </implementation>
</phase>

<phase name="prototype_ccm">
  <implementation>
#### Phase 3: Prototype with ccmanager
```bash
initialize_phase "$ENV_FILE" "Prototype"

echo "🛠️ Starting Prototype phase"
echo "💡 Creating minimal working implementation"
echo ""
echo "📝 Implementing prototype based on plan..."

# プロトタイプ実装
echo "**実行内容**:"
echo "1. 最小限の動作するプロトタイプ作成"
echo "2. 基本的なUI/UXスケルトン実装"
echo "3. モックデータでの動作確認"
echo "4. プロトタイプのスクリーンショット作成"

echo "✅ When prototype is complete, commit your changes and continue to Phase 4: Coding"
```
  </implementation>
</phase>

<phase name="coding_ccm">
  <implementation>
#### Phase 4: Coding with ccmanager
```bash
initialize_phase "$ENV_FILE" "Coding"

echo "💻 Starting Coder phase"
echo "🧪 Implementing with TDD approach"
echo ""
echo "🎮 Use 'ccm' and select 'feature-coder' preset"
echo ""

# Coderプロンプト表示
CODER_PROMPT=$(load_prompt ".claude/prompts/coder.md" "$DEFAULT_CODER_PROMPT")
echo "$CODER_PROMPT"

echo ""
echo "✅ When Coder phase is complete, ensure all tests pass"
echo "🔄 Commit your implementation and continue to Phase 5: Completion"
```
  </implementation>
</phase>

<phase name="completion_ccm">
  <implementation>
#### Phase 5: Completion with ccmanager
```bash
initialize_phase "$ENV_FILE" "Completion"

echo "🎯 Starting Completion phase"
echo "📊 Final quality checks and reporting"
echo ""

# テスト実行（品質ゲート）
if ! run_tests "$PROJECT_TYPE" "$WORKTREE_PATH"; then
    log_error "Tests failed - feature may be incomplete"
fi

# 完了レポート生成
generate_completion_report "$WORKTREE_PATH" "$FEATURE_NAME" "$TASK_DESCRIPTION" \
    "$FEATURE_BRANCH" "$PROJECT_TYPE" "feature"

# 完了レポートにccmanager情報を追加
echo "" >> "[worktree]/report/[feature]/phase-results/task-completion-report.md"
echo "## Development completed with ccmanager" >> "[worktree]/report/[feature]/phase-results/task-completion-report.md"

commit_phase_results "COMPLETE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/task-completion-report.md" \
    "Feature ready for integration: $TASK_DESCRIPTION"

# マージ・PR処理
if [[ "$NO_MERGE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    merge_to_main "$WORKTREE_PATH" "$FEATURE_BRANCH" "$NO_MERGE"
fi

if [[ "$CREATE_PR" == "true" ]]; then
    local is_draft="true"
    [[ "$NO_DRAFT" == "true" ]] && is_draft="false"
    create_pull_request "$WORKTREE_PATH" "$FEATURE_BRANCH" "$TASK_DESCRIPTION" "$is_draft"
fi

# クリーンアップ
if [[ "$KEEP_WORKTREE" != "true" ]] && [[ "$CREATE_PR" != "true" ]]; then
    echo "🧹 Clean up worktree using ccmanager or git worktree remove"
    [[ -f "$ENV_FILE" ]] && rm -f "$ENV_FILE"
    echo "✨ Environment cleaned up"
else
    echo "📊 Report saved in worktree report directory"
    echo "🎮 ccmanager: Run 'ccm' to see this feature in the list"
fi

log_success "Feature development completed with ccmanager!"
echo "💡 Use 'ccm' to start your next feature development"
```
  </implementation>
</phase>

## ccmanager Configuration

プロジェクトの`~/.config/ccmanager/config.json`に以下のプリセットを追加することを推奨：

```json
{
  "commandPresets": {
    "presets": [
      {
        "id": "feature-explorer",
        "name": "Feature Explorer",
        "command": "claude",
        "args": [
          "--prompt", "@~/.claude/prompts/explorer.md",
          "--dangerously-skip-permissions"
        ]
      },
      {
        "id": "feature-planner",
        "name": "Feature Planner",
        "command": "claude",
        "args": [
          "--prompt", "@~/.claude/prompts/planner.md",
          "--resume"
        ]
      },
      {
        "id": "feature-prototype",
        "name": "Feature Prototype",
        "command": "claude",
        "args": [
          "--resume",
          "-p", "Create a minimal working prototype"
        ]
      },
      {
        "id": "feature-coder",
        "name": "Feature Coder (TDD)",
        "command": "claude",
        "args": [
          "--prompt", "@~/.claude/prompts/coder.md",
          "--resume"
        ]
      },
      {
        "id": "feature-completion",
        "name": "Feature Completion",
        "command": "claude",
        "args": [
          "--resume",
          "-p", "Run final tests and generate completion report"
        ]
      }
    ],
    "defaultPresetId": "feature-explorer"
  }
}
```

## 使用例

<example>
<description>ccmanager統合での基本的な機能開発</description>
```bash
# ccmanagerで管理される機能開発を開始
/multi-feature-ccm "ユーザープロフィール画像アップロード機能"

# ccmコマンドで進行状況確認
$ ccm
❯ ◐ user-profile-image (feature-planner)
  ○ notification-system (idle)
  ─────────────
  ⊕ New Worktree
```
</example>

<example>
<description>複数機能の並列開発</description>
```bash
# 機能1を開始
/multi-feature-ccm "決済システム統合" --keep-worktree

# 別ターミナルで機能2を開始
/multi-feature-ccm "通知システム実装" --keep-worktree

# ccmで切り替えながら作業
$ ccm
  ● payment-integration (feature-coder)
❯ ◐ notification-system (feature-explorer)
```
</example>

<example>
<description>ccmanagerなしで実行（フォールバック）</description>
```bash
/multi-feature-ccm "レガシー機能修正" --no-ccm
```
</example>

## オプション

- `--keep-worktree`: 作業用worktreeを削除せずに保持
- `--no-merge`: mainブランチへの自動マージをスキップ
- `--pr`: GitHub Pull Requestを作成
- `--no-draft`: 通常のPR作成（デフォルトはドラフト）
- `--no-ccm`: ccmanager統合を無効化（従来モード）
- `--preset-base`: ccmanagerプリセットのベース名（デフォルト: feature）

## ccmanager統合の利点

1. **並列開発の可視化**: 複数機能の進行状況を一覧表示
2. **フェーズ管理**: 各フェーズの開始・完了を明確に管理
3. **セッション永続化**: 作業を中断・再開が容易
4. **プリセット活用**: フェーズごとに最適化された起動設定
5. **統計情報**: 開発時間やフェーズ進行の記録

</feature_development_workflow_ccmanager>