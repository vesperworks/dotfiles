# ccmanager統合版マルチエージェント開発ワークフロー解説

## 概要

ccmanager統合版のマルチエージェント機能開発ワークフローは、従来の自動化重視のアプローチから、**ccmanagerとの協調による手動制御重視**のアプローチに変更されました。

### 設計思想の変化

#### 従来版（582行）
- **完全自動化**: worktree作成から統計収集まで全て自動
- **複雑な状態管理**: .ccmanager/feature-config.jsonによる詳細な状態追跡
- **自動セッション切り替え**: プリセットの自動起動とフェーズ管理

#### 簡素化版（403行）
- **ccmanager協調**: UI操作はccmanager、ワークフロー制御はコマンド
- **シンプルな状態管理**: ccmanager内部の状態管理に委譲
- **手動セッション制御**: ユーザーがccmanager UIで操作

## ワークフローの詳細

### Phase 0: 初期化（簡素化済み）

**従来版の問題**:
```bash
# 複雑なworktree作成ロジック（約80行）
WORKTREE_INFO=$(create_task_worktree "$TASK_DESCRIPTION" "feature")
WORKTREE_PATH=$(echo "$WORKTREE_INFO" | cut -d'|' -f1)
FEATURE_BRANCH=$(echo "$WORKTREE_INFO" | cut -d'|' -f2)

# 詳細な設定ファイル作成（約40行）
cat > .ccmanager/feature-config.json << EOF
{
  "featureName": "$FEATURE_NAME",
  "phases": { ... },
  "currentPhase": "explorer"
}
EOF
```

**簡素化版の改善**:
```bash
# ccmanager必須チェックのみ
if ! command -v ccmanager &>/dev/null; then
    log_error "ccmanager is required for this workflow"
    exit 1
fi

# 環境変数の最小限の設定
echo "🎮 Please use 'ccm' to create worktree and start feature development"
```

### Phase 1-5: 各フェーズの簡素化

**従来版の複雑さ**:
```bash
# 各フェーズで状態更新関数を呼び出し
update_ccm_phase() {
    jq ".phases.${phase}.status = \"${status}\"" \
        .ccmanager/feature-config.json > .ccmanager/feature-config.tmp
}
update_ccm_phase "explorer" "active"

# 自動セッション起動
if [[ "${AUTO_START_CCM:-false}" == "true" ]]; then
    ccmanager start --preset "${PRESET_BASE}-explorer"
fi
```

**簡素化版のアプローチ**:
```bash
# シンプルなガイダンス
echo "🔍 Starting Explorer phase"
echo "💡 Please use ccmanager to switch to feature-explorer preset"

# プロンプトの表示のみ
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md")
echo "$EXPLORER_PROMPT"
```

## ccmanager統合のメリット・デメリット

### メリット

1. **コード保守性の向上**
   - 403行（-31%）でメンテナンスが容易
   - 責任分離によりバグの発生箇所が明確

2. **ccmanagerの強みを活用**
   - リアルタイムなセッション状態表示
   - 直感的なTUIでの操作
   - 複数プロジェクトの並列管理

3. **安定性の向上**
   - 複雑な状態管理を削除
   - ccmanagerの成熟したworktree管理を活用

### デメリット

1. **自動化レベルの低下**
   - ユーザーが手動でworktree作成・セッション切り替え
   - フェーズ間の自動遷移がなくなった

2. **ccmanager依存**
   - ccmanagerがないと動作しない
   - ccmanagerの不具合がワークフローに影響

3. **学習コストの増加**
   - ccmanagerとコマンドの2つのツールを理解する必要
   - 操作が分散して複雑

## 具体的な使用手順

### 1. 事前準備

```bash
# ccmanagerのインストール
bun install -g ccmanager

# プリセット設定の確認
cat ~/.config/ccmanager/config.json
```

### 2. 機能開発の開始

```bash
# Step 1: ワークフロー初期化
/multi-feature-ccm "ユーザープロフィール画像アップロード機能"

# Step 2: ccmanagerでworktree作成
ccm
# ⊕ New Worktree を選択
# worktree名: user-profile-image-upload
# ブランチ: feature/user-profile-image-upload
```

### 3. 各フェーズの実行

#### Phase 1: Explorer
```bash
# ccmanagerでExplorerプリセットを選択
ccm
# feature-explorer プリセットを選択

# Explorerの作業
# - 要件分析
# - 技術調査
# - 制約事項の特定
# 結果を explore-results.md に保存
```

#### Phase 2: Planner
```bash
# ccmanagerでPlannerプリセットに切り替え
ccm
# feature-planner プリセットを選択

# Plannerの作業
# - アーキテクチャ設計
# - 実装計画
# - TDD計画
# 結果を plan-results.md に保存
```

#### Phase 3: Prototype
```bash
# プロトタイプの実装
# - 最小限の動作実装
# - UI/UXスケルトン
# - モックデータでの動作確認
```

#### Phase 4: Coder
```bash
# ccmanagerでCoderプリセットに切り替え
ccm
# feature-coder プリセットを選択

# TDD実装
# - テスト作成
# - 実装
# - リファクタリング
```

#### Phase 5: Completion
```bash
# 最終チェックとレポート生成
# - テスト実行
# - 品質チェック
# - 完了レポート作成
```

### 4. 完了・統合

```bash
# マージまたはPR作成
git checkout main
git merge feature/user-profile-image-upload

# または
gh pr create --title "feat: ユーザープロフィール画像アップロード機能"
```

## トラブルシューティング

### よくある問題と対処法

1. **ccmanagerが見つからない**
   ```bash
   Error: ccmanager is required for this workflow
   Solution: bun install -g ccmanager
   ```

2. **プリセットが設定されていない**
   ```bash
   Problem: feature-explorer プリセットが見つからない
   Solution: ~/.config/ccmanager/config.json に設定を追加
   ```

3. **worktreeの作成に失敗**
   ```bash
   Problem: worktree名の重複
   Solution: ccmanagerで別の名前を指定
   ```

## 改善案

### 今後の拡張予定

1. **プリセット自動設定**
   - コマンド実行時にccmanagerプリセットを自動追加
   - 設定ファイルの自動生成

2. **フェーズ進行の可視化**
   - 各フェーズの完了状況をccmanagerで表示
   - 進行状況のプログレスバー

3. **エラーハンドリングの強化**
   - ccmanager連携のエラー処理
   - フォールバック機能の改善

4. **テンプレート機能**
   - プロジェクトタイプ別のテンプレート
   - カスタマイズ可能な設定

## まとめ

ccmanager統合版は、**完全自動化から協調型へ**のパラダイムシフトを実現しています。

### 適用場面

- **ccmanager統合版が適している場合**:
  - 複数の機能を並列開発
  - ccmanagerの操作に慣れている
  - 手動制御を好む開発者

- **従来版が適している場合**:
  - 完全自動化を重視
  - ccmanagerを使いたくない
  - シンプルな単一機能開発

### 開発効率への影響

| 項目 | 従来版 | ccmanager統合版 |
|------|--------|-----------------|
| セットアップ時間 | 短い | 中程度 |
| 操作の複雑さ | 低い | 中程度 |
| 並列開発 | 制限あり | 優秀 |
| 可視化 | 基本的 | 豊富 |
| 保守性 | 低い | 高い |

ccmanager統合版は、**初期学習コストと引き換えに、長期的な開発効率と保守性を向上**させる設計となっています。