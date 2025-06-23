# Multi-Agent Refactoring Workflow

リファクタリングを独立worktreeで自動実行します。

## リファクタリング対象
$ARGUMENTS

## 実行方針
**1リファクタリング = 1worktree** で全フローを自動実行。既存テストを保持しながら段階的に実行。

### リファクタリングの基本原則
- **動作保証**: 既存機能の動作を完全に保持
- **段階的実行**: 小さな変更を積み重ねて安全に進行
- **テスト駆動**: 各段階でテストを実行し、グリーンを維持
- **測定可能**: パフォーマンス・可読性・保守性の改善を定量化

### 実行フロー（自動化）
1. **Worktree作成**: `../project-refactor-{target}`
2. **自動実行**: Analysis → Plan → Refactor → Verify
3. **PR準備**: テスト通過確認後、PR準備完了

## 詳細な実行ステップ

### Phase 1: Analysis（現状分析）
```bash
# Explorerエージェントが以下を調査
- 対象コードの構造と依存関係
- 既存テストのカバレッジと品質
- パフォーマンスのベースライン測定
- 技術的負債の特定
- リファクタリングのリスク評価
```

**成果物**: `analysis-results.md`
- コード品質メトリクス
- 依存関係マップ
- リスク評価レポート
- 改善機会の特定

### Phase 2: Plan（戦略策定）
```bash
# Plannerエージェントが以下を策定
- 段階的なリファクタリング計画
- 各段階のテスト戦略
- ロールバック計画
- 後方互換性の維持方法
- 成功基準の定義
```

**成果物**: `refactoring-plan.md`
- ステップバイステップの実行計画
- 各段階の検証方法
- リスク軽減策
- 期待される改善効果

### Phase 3: Refactor（段階的実行）
```bash
# Coderエージェントが以下を実行
1. 小さな単位でリファクタリング
2. 各変更後にテスト実行
3. グリーンを維持しながら進行
4. 意味のある単位でコミット
5. パフォーマンス測定
```

**実行パターン**:
- **Extract Method**: 長いメソッドを分割
- **Rename**: わかりやすい命名へ変更
- **Move**: 適切なモジュールへ移動
- **Replace**: 古いパターンを新しいパターンへ
- **Simplify**: 複雑なロジックを簡潔に

**成果物**: `refactoring-results.md`
- 実行した変更の詳細
- 各段階のテスト結果
- パフォーマンス比較
- コミット履歴

### Phase 4: Verify（品質検証）
```bash
# Testerエージェントが以下を検証
- 全テストスイートの実行
- パフォーマンステスト
- 後方互換性の確認
- コード品質メトリクスの比較
- 改善効果の測定
```

**成果物**: `verification-report.md`
- テスト結果サマリー
- パフォーマンス改善レポート
- コード品質の向上度
- 残存リスクの評価

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

### task-completion-report.md
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

## 使用例

```bash
/project:multi-refactor "auth/*.js を TypeScript + async/await に移行"
/project:multi-refactor "database層をRepository Patternでリファクタリング"
/project:multi-refactor "レガシーAPIをRESTful設計に改善"
```

---

**注意**: このワークフローは完全自動実行されます。ユーザーは最終的なPRレビュー時のみ関与が必要です。