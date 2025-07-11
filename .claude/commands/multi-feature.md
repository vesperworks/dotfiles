# Multi-Feature Development - 役割進化型ワークフロー

新機能開発のための役割進化型ワークフローです。単一のセッションで役割を変えながら機能開発を進めます。

## 使用方法
`/multi-feature "機能の説明"`

例: `/multi-feature "ユーザー認証機能の追加"`

## オプション
- `--cleanup` - 実行後に./tmp/の古いファイルをクリーンアップ
- `--cleanup-days N` - N日以上前のファイルを削除（デフォルト: 7）

<role_evolution_flow>
単一のClaudeセッションが以下の役割を順番に担当します：

🔍 Explorer → 📊 Analyst → 🎨 Designer → 💻 Developer → ✅ Reviewer

各役割で生成される成果物は `./tmp/` ディレクトリに保存されます。

**IMPORTANT**: 実装が完了したと認められるには、以下の品質チェックをすべてパスする必要があります：
1. **Lint** - コード品質チェック
2. **Format** - コードフォーマット
3. **Test** - すべてのテストが成功
4. **Build** - ビルドが成功
</role_evolution_flow>

## 実行フロー

<explorer_phase>
**Explorer Mode 🔍 - 既存コードの調査と要件の明確化**

1. **調査タスク**:
   - 関連する既存コードの調査
   - 現在の実装パターンの理解
   - 要件と制約事項の明確化
   - 影響を受ける可能性のあるファイルのリスト作成

2. **成果物の保存**:
   - 調査結果を `./tmp/{timestamp}-explorer-report.md` に保存
   - **MUST**: 次の役割のために明確な調査結果を記録

3. **Explorer Report形式**:
   ```markdown
   # Explorer Report
   ## 要件定義
   [明確化された要件]
   
   ## 既存実装の調査
   [関連ファイルと現在の実装]
   
   ## 制約事項
   [技術的・ビジネス的制約]
   
   ## 影響範囲
   [影響を受けるファイル一覧]
   ```
</explorer_phase>

<analyst_phase>
**Analyst Mode 📊 - 影響範囲の分析とリスク評価**

1. **分析タスク**:
   - `<explorer_phase>`の調査結果を基に影響範囲を分析
   - 技術的リスクの評価
   - 実装の複雑度見積もり
   - 優先順位と段階的実装の提案

2. **前フェーズの参照**:
   - **MUST**: `load_previous_artifact("explorer")`で前の成果物を読み込み
   - 調査結果を基に深い分析を実施

3. **Analyst Report形式**:
   ```markdown
   # Analysis Report
   ## 影響分析
   [モジュール別の影響度]
   
   ## リスク評価
   - 技術リスク: [Low/Medium/High]
   - スケジュールリスク: [評価]
   
   ## 実装戦略
   [推奨される実装アプローチ]
   ```
</analyst_phase>

<designer_phase>
**Designer Mode 🎨 - アーキテクチャ設計とインターフェース定義**

1. **設計タスク**:
   - `<analyst_phase>`の分析結果を基に設計
   - APIインターフェースの定義
   - データモデルの設計
   - テスト戦略の策定

2. **設計原則**:
   - **KISS**: シンプルに保つ
   - **DRY**: 繰り返しを避ける
   - **SOLID**: 設計原則を守る

3. **Design Document形式**:
   ```markdown
   # Design Document
   ## アーキテクチャ
   [全体構成図・説明]
   
   ## インターフェース定義
   [API仕様]
   
   ## データモデル
   [エンティティ定義]
   
   ## テスト戦略
   [テストアプローチ]
   ```
</designer_phase>

<developer_phase>
**Developer Mode 💻 - 実装とユニットテスト作成**

1. **実装タスク**:
   - `<designer_phase>`の設計に基づいた実装
   - ユニットテストの作成
   - 段階的なコミット
   - 必要に応じてドキュメント更新

2. **実装原則**:
   - **TDD**: テストファーストで進める
   - **小さなコミット**: 機能単位でコミット
   - **ALWAYS**: テストが通ることを確認してからコミット

3. **品質チェックの実行**:
   ```bash
   # プロジェクトタイプを検出
   PROJECT_TYPE=$(detect_project_type)
   
   # 品質チェック実行
   if ! run_quality_checks "$PROJECT_TYPE"; then
       log_error "Quality checks failed. Fix issues before proceeding."
       return 1
   fi
   ```

4. **コミット戦略**:
   ```bash
   git_commit "[Feature] Add authentication module" "src/auth/*"
   git_commit "[Test] Add auth module tests" "test/auth/*"
   git_commit "[Doc] Update API documentation" "docs/*"
   ```
</developer_phase>

<reviewer_phase>
**Reviewer Mode ✅ - 品質確認と最終調整**

1. **レビュータスク**:
   - コードレビュー（セルフレビュー）
   - テストの実行と確認
   - ドキュメントの最終確認
   - 改善点の洗い出し

2. **最終品質チェック**:
   - **MUST**: すべての品質チェックが通ること
   ```bash
   # 最終品質チェック
   echo "🔍 Running final quality checks..."
   if ! run_quality_checks "$PROJECT_TYPE"; then
       log_error "❌ Implementation not accepted. Quality checks must pass."
       return 1
   fi
   log_success "✅ All quality checks passed!"
   ```

3. **Review Report形式**:
   ```markdown
   # Review Report
   ## Quality Check Results
   - ✅ Lint: Passed
   - ✅ Format: Passed
   - ✅ Test: All tests passing
   - ✅ Build: Build succeeded
   
   ## Code Quality
   [レビュー結果]
   
   ## コード品質
   [レビュー結果]
   
   ## 改善提案
   [今後の改善点]
   ```
</reviewer_phase>

<task_completion>
**タスク完了処理**

1. **サマリー生成**:
   - `generate_task_summary()`で全体サマリーを作成
   - すべての成果物へのリンクを含める

2. **統計情報表示**:
   - `show_statistics()`で作業統計を表示
   - 各役割での成果物数をカウント

3. **クリーンアップ**:
   - オプションで古い成果物を削除
   - **IMPORTANT**: 重要な成果物は別途保存してから実行

4. **次のステップ**:
   - PR作成の準備
   - 追加テストの検討
   - ドキュメントの最終確認
</task_completion>

## 実装スクリプト構造

```bash
#!/bin/bash
source .claude/scripts/role-utils.sh
source .claude/scripts/worktree-utils.sh

# 環境検証
verify_environment || exit 1

# オプション解析
parse_workflow_options "$@"

# タスク開始
echo "🚀 Starting Multi-Feature Development"
echo "Task: $TASK_DESCRIPTION"

# <explorer_phase>の実行
switch_role "Explorer" "既存コードの調査と要件の明確化"
# ... Explorer実装 ...

# <analyst_phase>の実行
switch_role "Analyst" "影響範囲の分析とリスク評価"
# ... Analyst実装 ...

# <designer_phase>の実行
switch_role "Designer" "アーキテクチャ設計とインターフェース定義"
# ... Designer実装 ...

# <developer_phase>の実行
switch_role "Developer" "実装とユニットテスト作成"
# ... Developer実装 ...

# <reviewer_phase>の実行
switch_role "Reviewer" "品質確認と最終調整"
# ... Reviewer実装 ...

# <task_completion>の実行
generate_task_summary "$TASK_DESCRIPTION"
show_statistics
```

<generated_artifacts>
すべての成果物は `./tmp/` ディレクトリに保存されます：

| ファイル | 説明 |
|---------|------|
| `{timestamp}-explorer-report.md` | 調査結果と要件定義 |
| `{timestamp}-analyst-report.md` | 影響分析とリスク評価 |
| `{timestamp}-designer-report.md` | 設計書とインターフェース定義 |
| `{timestamp}-developer-report.md` | 実装ログと変更内容 |
| `{timestamp}-reviewer-report.md` | レビュー結果と改善提案 |
| `{timestamp}-task-summary.md` | タスク全体のサマリー |
| `latest-*-report.md` | 各役割の最新レポートへのリンク |
</generated_artifacts>

<customization_guide>
**プロンプトのカスタマイズ**

各役割のデフォルトプロンプトは `worktree-utils.sh` で定義されています。
プロジェクト固有のプロンプトを使用する場合：

1. **プロンプトファイルの作成**:
   - `.claude/prompts/explorer.md`
   - `.claude/prompts/analyst.md`
   - `.claude/prompts/designer.md`
   - `.claude/prompts/developer.md`
   - `.claude/prompts/reviewer.md`

2. **プロンプトの読み込み**:
   ```bash
   PROMPT=$(load_prompt ".claude/prompts/explorer.md" "$DEFAULT_EXPLORER_PROMPT")
   ```
</customization_guide>

<troubleshooting>
**トラブルシューティング**

1. **途中で中断した場合**:
   - 最新の成果物は `./tmp/latest-{role}-report.md` に保存
   - そこから再開可能

2. **特定の役割だけ実行したい**:
   - 現在は手動で該当部分から実行
   - 将来的に `--start-from` オプションを追加予定

3. **./tmp/ が大きくなりすぎた**:
   - `cleanup_tmp 0` ですべての古いファイルを削除
   - **IMPORTANT**: 重要なファイルは事前にバックアップ
</troubleshooting>

<comparison_with_legacy>
**従来版との違い**

| 機能 | 従来版 | 役割進化型 |
|------|--------|-----------|
| worktree | 必須 | 不要 |
| セッション数 | 複数 | 単一 |
| 状態管理 | 環境ファイル | メモリ内 |
| 複雑度 | 高 | 低 |
| 学習コスト | 高 | 低 |
</comparison_with_legacy>

<important_notes>
**注意事項**

- このコマンドはworktreeを使用しません
- すべての作業は現在のブランチで行われます
- 成果物はgitignoreされる `./tmp/` に保存されます
- ccmanagerとの統合は最小限です（進捗表示のみ）
- **ALWAYS**: 各役割を順番に実行し、成果物を保存
- **NEVER**: 役割をスキップしたり、成果物の保存を忘れない
</important_notes>