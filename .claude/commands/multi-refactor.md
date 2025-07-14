# Multi-Refactor - 役割進化型ワークフロー

既存コードのリファクタリングに特化した役割進化型ワークフローです。品質向上と保守性改善を段階的に実施します。

## 使用方法
`/multi-refactor "リファクタリング対象の説明"`

例:
- `/multi-refactor "認証モジュールを async/await パターンに移行"`
- `/multi-refactor "レガシーコードをTypeScriptに段階的移行"`
- `/multi-refactor "重複したコードをユーティリティ関数に統合"`

## オプション
- `--cleanup` - 実行後に./tmp/の古いファイルをクリーンアップ
- `--cleanup-days N` - N日以上前のファイルを削除（デフォルト: 7）

<refactor_evolution_flow>
リファクタリングに特化した役割進化：

📊 Analyzer → 📋 Planner → 🔧 Refactorer → ✅ Validator
  (現状分析)   (戦略策定)   (段階的実行)    (品質検証)

**IMPORTANT**: リファクタリング中は機能追加を行わず、常にテストが通る状態を維持します。
</refactor_evolution_flow>

## 実行フロー

<analyzer_phase>
**Analyzer Mode 📊 - 現在のコード品質分析**

1. **分析タスク**:
   - 対象コードの現状分析
   - コード品質メトリクスの測定
   - 技術的負債の特定
   - リファクタリング候補の洗い出し

2. **成果物の保存**:
   - 分析結果を `./tmp/{timestamp}-analyzer-report.md` に保存
   - **MUST**: ベースラインメトリクスを記録

3. **Code Analysis Report形式**:
   ```markdown
   # Code Analysis Report
   
   ## Target: [リファクタリング対象]
   
   ## Current State:
   - Lines of Code: [行数]
   - Complexity: [複雑度]
   - Test Coverage: [カバレッジ]
   - Code Smells: [問題点リスト]
   
   ## Refactoring Opportunities:
   1. [改善可能な箇所1]
   2. [改善可能な箇所2]
   
   ## Risk Assessment:
   - Breaking Changes: [Yes/No]
   - Estimated Effort: [Small/Medium/Large]
   ```
</analyzer_phase>

<planner_phase>
**Planner Mode 📋 - リファクタリング戦略の策定**

1. **戦略策定タスク**:
   - `<analyzer_phase>`の分析結果を基に戦略策定
   - 段階的な実行計画の作成
   - 各段階でのテスト戦略
   - リスク軽減策の検討

2. **計画原則**:
   - **Small Steps**: 小さな変更の積み重ね
   - **Preserve Behavior**: 機能は変更しない
   - **ALWAYS**: 各ステップでテストを実行

3. **Refactoring Plan形式**:
   ```markdown
   # Refactoring Plan
   
   ## Strategy: [戦略名]
   
   ## Phases:
   ### Phase 1: [初期準備]
   - Add comprehensive tests
   - Document current behavior
   
   ### Phase 2: [構造改善]
   - Extract methods
   - Remove duplication
   
   ### Phase 3: [最適化]
   - Performance improvements
   - Final cleanup
   
   ## Success Criteria:
   - All tests passing
   - No regression
   - Improved metrics
   ```
</planner_phase>

<refactorer_phase>
**Refactorer Mode 🔧 - 段階的なリファクタリング実行**

1. **実行タスク**:
   - `<planner_phase>`の計画に従った段階的実行
   - 各段階でのテスト実行
   - 小さく安全な変更の積み重ね
   - 各段階でのコミット

2. **リファクタリング手法**:
   - **Extract Method**: 長いメソッドを分割
   - **Rename**: 明確な命名への変更
   - **Move**: 適切な場所への移動
   - **Inline**: 不要な中間変数の削除
   - **Extract Interface**: インターフェースの抽出

3. **段階的コミット**:
   ```bash
   # Phase 1: テスト追加
   git_commit "[Refactor-Prep] Add tests for existing behavior"
   
   # Phase 2: 構造改善
   git_commit "[Refactor] Extract helper methods"
   git_commit "[Refactor] Remove code duplication"
   
   # Phase 3: 最終調整
   git_commit "[Refactor] Optimize performance and cleanup"
   ```

4. **各段階での確認**:
   - **MUST**: テストが通ることを確認
   - **NEVER**: 大きな変更を一度に行わない
   - **ALWAYS**: 小さくコミット
</refactorer_phase>

<validator_phase>
**Validator Mode ✅ - 品質検証と互換性確認**

1. **検証タスク**:
   - すべてのテストが通ることを確認
   - パフォーマンスの測定と比較
   - コード品質メトリクスの再測定
   - 後方互換性の確認

2. **検証項目**:
   - **Test Results**: すべてのテストが成功
   - **Code Quality**: メトリクスが改善
   - **Performance**: パフォーマンスの維持/向上
   - **Breaking Changes**: 破壊的変更なし

3. **Validation Report形式**:
   ```markdown
   # Validation Report
   
   ## Test Results:
   - Unit Tests: [Pass/Fail]
   - Integration Tests: [Pass/Fail]
   - Coverage: [Before]% → [After]%
   
   ## Code Quality:
   - Complexity: [Before] → [After]
   - Duplication: [Before]% → [After]%
   - Maintainability Index: [Before] → [After]
   
   ## Performance:
   - Execution Time: [Before]ms → [After]ms
   - Memory Usage: [Before]MB → [After]MB
   
   ## Breaking Changes:
   - API Changes: [None/List]
   - Behavioral Changes: [None/List]
   ```
</validator_phase>

<refactor_completion>
**リファクタリング完了処理**

1. **成果サマリー**:
   ```bash
   echo "📊 Refactoring Summary"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "✅ Code analyzed and issues identified"
   echo "✅ Refactoring plan created and executed"
   echo "✅ All tests passing"
   echo "✅ Code quality improved"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   ```

2. **改善メトリクス表示**:
   ```bash
   echo "📈 Improvements:"
   echo "- Code complexity reduced"
   echo "- Test coverage increased"
   echo "- Performance optimized"
   echo "- Maintainability improved"
   ```

3. **次のステップ**:
   - 追加のリファクタリング検討
   - パフォーマンスベンチマーク
   - ドキュメント更新
</refactor_completion>

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
echo "🚀 Starting Refactoring Process"
echo "Task: $TASK_DESCRIPTION"

# <analyzer_phase>の実行
switch_role "Analyzer" "現在のコード品質分析"
# ... Analyzer実装 ...

# <planner_phase>の実行
switch_role "Planner" "リファクタリング戦略の策定"
# ... Planner実装 ...

# <refactorer_phase>の実行
switch_role "Refactorer" "段階的なリファクタリング実行"
# ... Refactorer実装 ...

# <validator_phase>の実行
switch_role "Validator" "品質検証と互換性確認"
# ... Validator実装 ...

# <refactor_completion>の実行
generate_task_summary "$TASK_DESCRIPTION"
show_improvement_metrics
```

<generated_artifacts>
すべての成果物は `./tmp/` ディレクトリに保存されます：

| ファイル | 説明 |
|---------|------|
| `{timestamp}-analyzer-report.md` | 現状分析とコード品質メトリクス |
| `{timestamp}-planner-report.md` | リファクタリング戦略と実行計画 |
| `{timestamp}-refactorer-report.md` | 実行したリファクタリング内容 |
| `{timestamp}-validator-report.md` | 品質検証と改善結果 |
| `{timestamp}-task-summary.md` | リファクタリング全体のサマリー |
| `latest-*-report.md` | 各役割の最新レポートへのリンク |
</generated_artifacts>

<refactoring_best_practices>
**リファクタリングのベストプラクティス**

1. **Boy Scout Rule**:
   - 「コードは見つけたときよりも綺麗にして去る」

2. **Small Steps**:
   - 一度に大きな変更をしない
   - 各ステップでテストを実行
   - 頻繁にコミット

3. **Preserve Behavior**:
   - 機能は変更しない
   - テストでカバー
   - 後方互換性を維持

4. **Measure Impact**:
   - Before/Afterのメトリクス比較
   - パフォーマンスへの影響確認
   - 改善効果の定量化
</refactoring_best_practices>

<supported_refactoring_patterns>
**サポートされるリファクタリングパターン**

1. **構造的リファクタリング**:
   - Extract Method/Function
   - Inline Method/Function
   - Extract Variable
   - Inline Variable
   - Extract Class
   - Move Method/Field

2. **名前のリファクタリング**:
   - Rename Variable/Function/Class
   - Use Consistent Naming Convention

3. **条件式のリファクタリング**:
   - Decompose Conditional
   - Consolidate Conditional Expression
   - Replace Nested Conditional with Guard Clauses

4. **データ構造のリファクタリング**:
   - Replace Array with Object
   - Encapsulate Collection
   - Replace Magic Number with Named Constant
</supported_refactoring_patterns>

<important_notes>
**注意事項**

- リファクタリング中は機能追加をしません
- 各段階でテストが通ることを確認します
- パフォーマンスへの影響を常に監視します
- 後方互換性の破壊に注意します
- すべての変更は `./tmp/` に記録されます
- **ALWAYS**: テストが通る状態を維持
- **NEVER**: 機能を変更しない
- **MUST**: 小さなステップで進める
</important_notes>