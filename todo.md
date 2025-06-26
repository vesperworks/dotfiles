# TODO: マルチエージェントワークフロー実装の残タスク

更新日: 2025-06-26（todo.md整理 - 並列実行を低優先度へ移動）

## 🔴 最優先度タスク（即座に実施）

### 残存worktreeのクリーンアップ [推定: 0.5時間]
- [ ] 4つの残存worktree（feature-user-auth、refactor-logging、tdd-auth-jwt、tdd-multi-tdd）を削除
- [ ] クリーンアップ機能の動作確認

### CLAUDE.mdの軽微な更新 [推定: 0.5時間]
- [ ] test-worktree-access.shの正しい配置場所（.claude/test/）を反映
- [ ] 新しいコマンド（p.md、t.md）をプロジェクト構造に追加

## 🟠 高優先度タスク（1週間以内）

### 全multiコマンドの統合テスト [推定: 4-6時間]
- [ ] 各コマンドで実際のタスクを実行
- [ ] エラーハンドリングの動作確認
- [ ] 並行実行時の動作検証
- **依存**: 環境ファイル管理の改善完了後

### テストスクリプトの作成 [推定: 2-3時間]
- [ ] test-multi-agent.shの作成（.claude/test/配下）
- [ ] test-parallel-tdd.shの作成（.claude/test/配下）
- [ ] 基本的な動作確認テストの実装

### multi-feature.md改善（XMLタグ構造導入） [推定: 2-3時間]
- [ ] **XMLタグ構造の導入**
  - [ ] `<feature_development_workflow>`でワークフロー全体を囲む
  - [ ] 各フェーズを`<phase name="explore">`等でマークアップ
  - [ ] `<objectives>`, `<tools>`, `<output>`で各フェーズ内容を構造化
  - [ ] `<quality_gates>`で品質基準を明確化
- [ ] **強調語の体系的使用**
  - [ ] `ALWAYS`: 必須のコミット、テスト実行に使用
  - [ ] `NEVER`: 未テストのコミット、main直接編集の禁止に使用
  - [ ] `MUST`: ファイル作成前の確認、品質ゲート通過に使用
  - [ ] `IMPORTANT`: 重要な注意事項に限定使用

### multi-refactor.md改善（multi-feature.md分析を適用） [推定: 2-3時間]
- [ ] **外部関数化による重複削除**
  - [ ] 各フェーズで重複する環境設定・初期化処理を`initialize_phase()`関数化
  - [ ] Git コミット処理を`commit_phase_results()`関数として統一
  - [ ] フェーズ前処理チェックを`verify_previous_phase()`関数化
  - [ ] 完了レポート生成を外部テンプレート化
- [ ] **XMLタグ構造の導入**
  - [ ] `<refactoring_workflow>`でワークフロー全体を囲む
  - [ ] 各フェーズを`<phase name="analysis">`等でマークアップ
  - [ ] `<refactoring_patterns>`でリファクタリングパターンを構造化
  - [ ] `<quality_metrics>`で品質改善指標を明確化
- [ ] **簡潔性の改善**
  - [ ] 100行を超えるbashコードブロックを関数呼び出しに置換
  - [ ] "ClaudeCodeアクセス制限対応"の重複説明を1箇所に集約
  - [ ] worktree作業説明の重複を削除
- [ ] **強調語の体系的使用**
  - [ ] `ALWAYS`: 既存テストのパス維持、段階的コミット
  - [ ] `NEVER`: 未テストのリファクタリング、破壊的変更
  - [ ] `MUST`: ベースラインテスト実行、後方互換性維持
  - [ ] `IMPORTANT`: リファクタリング固有の注意事項に限定

### multi-tdd.mdリファクタリング（外部関数化、XMLタグ導入、TDDサイクル構造化） [推定: 3-4時間]
- [ ] **外部関数化による重複削除**
  - [ ] 各フェーズで4回重複する環境設定・初期化処理を`initialize_phase()`関数化
  - [ ] Git コミット処理を`commit_tdd_phase()`関数として統一（RED/GREEN/REFACTOR対応）
  - [ ] レポートディレクトリ作成を`setup_report_dirs()`関数化
  - [ ] 完了レポート生成（300-340行）を外部テンプレート化
- [ ] **XMLタグ構造の導入**
  - [ ] `<tdd_workflow>`でワークフロー全体を囲む
  - [ ] 各フェーズを`<phase name="explore|plan|tdd">`でマークアップ
  - [ ] `<tdd_cycle>`でRED-GREEN-REFACTORサイクルを明確に構造化
  - [ ] `<test_strategy>`でテスト戦略を独立セクション化
- [ ] **TDD固有の構造改善**
  - [ ] `<red_phase>`: テスト先行作成のルールと品質基準
  - [ ] `<green_phase>`: 最小実装の原則とコミット基準
  - [ ] `<refactor_phase>`: リファクタリング対象と品質指標
  - [ ] テストファイルと実装ファイルの配置ルールを`<file_structure>`で明確化
- [ ] **簡潔性の改善**
  - [ ] 400行のコードを200行以下に圧縮（外部関数活用）
  - [ ] "ClaudeCodeアクセス制限対応"の説明を冒頭1箇所に集約
  - [ ] bashコードブロックを関数呼び出しに置換
- [ ] **強調語の体系的使用**
  - [ ] `ALWAYS`: テスト先行作成、段階的コミット、カバレッジ確認
  - [ ] `NEVER`: 実装先行、テスト無しコミット、品質基準スキップ
  - [ ] `MUST`: RED→GREEN→REFACTORの順序遵守、各フェーズ独立コミット
  - [ ] `IMPORTANT`: TDD原則の重要事項に限定

## 🟡 中優先度タスク（1ヶ月以内）

### 各ワークフローの自動テストスクリプト作成 [推定: 6-8時間]
- [ ] multi-tdd.shの統合テストスクリプト
- [ ] multi-feature.shの統合テストスクリプト
- [ ] multi-refactor.shの統合テストスクリプト
- [ ] CI/CDパイプラインへの統合準備
- **依存**: 全multiコマンドの統合テスト完了後

### ドキュメント整備 [推定: 4-5時間]
- [ ] トラブルシューティングガイド
- [ ] ベストプラクティス集
- [ ] CLAUDE.mdのプロジェクト構造更新
- [ ] ユーザーガイドの作成

### エラーハンドリング強化 [推定: 5-6時間]
- [ ] worktree作成失敗時のリトライ機能
- [ ] ネットワークエラー時の対処
- [ ] 不完全なタスクのリカバリー機能
- [ ] エラーログの構造化と分析機能

## 🟢 低優先度タスク（将来実装）

### MCP連携機能の実装 [推定: 10-15時間]
- [ ] Context7連携の具体的な実装
- [ ] Playwright/Puppeteer統合のサンプル作成
- [ ] MCP設定ドキュメントの作成
- [ ] 外部ツール連携のベストプラクティス

### 監視・ログ機能 [推定: 8-10時間]
- [ ] タスク実行履歴の記録
- [ ] パフォーマンスメトリクスの収集
- [ ] 成功/失敗率の可視化
- [ ] ダッシュボード機能の実装

### 設定のカスタマイズ [推定: 4-6時間]
- [ ] `.claude/config.json` - ユーザー設定ファイル
- [ ] タイムアウト値の調整機能
- [ ] デフォルトブランチ名のカスタマイズ
- [ ] プロジェクト別設定のサポート

### TDDサイクルの並列化による効率化 [推定: 6-8時間]
- [ ] Testerエージェントの早期投入
- [ ] MCP連携の専門化
- [ ] 効果測定（運用後実施予定）

### 並列TDD機能のコマンド統合 [推定: 3-4時間]
- [ ] multi-tdd.mdに`--parallel`オプションを追加
- [ ] オプション指定時に`run_parallel_agents()`を呼び出す
- [ ] デフォルトは従来の順次実行を維持
- [ ] 使用例とパフォーマンス比較をドキュメント化

## 📝 multi-tdd.md リファクタリング分析レポート（2025-06-26）

### 1. 外部関数化すべき部分

#### 1.1 環境設定・初期化処理（4箇所で重複）
```bash
# 94-106行目、155-165行目、204-214行目、280-289行目で同一パターン
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi
```
**推奨**: `initialize_tdd_phase()` 関数として worktree-utils.sh に追加

#### 1.2 TDD固有のコミット処理
各TDDフェーズ（RED/GREEN/REFACTOR）で類似パターンが重複：
```bash
# 240-248行目（RED）、250-256行目（GREEN）、258-264行目（REFACTOR）
git -C "$WORKTREE_PATH" add "path"
git -C "$WORKTREE_PATH" commit -m "[TDD-PHASE] message" || {
    log_warning "Failed to commit"
}
```
**推奨**: `commit_tdd_phase()` 関数として外部化（フェーズ名を引数に）

#### 1.3 完了レポート生成
300-340行目の巨大なレポート生成処理は独立したテンプレートファイルに分離すべき
**推奨**: `.claude/templates/tdd-completion-report.md` として外部化

### 2. XMLタグ構造の欠如

#### 2.1 構造の不明確さ
- フェーズ構造がMarkdownセクションのみで表現されている
- TDDのRED-GREEN-REFACTORサイクルが埋もれている（240-264行目）
- 品質基準やテスト戦略が散在している

**推奨構造**:
```xml
<tdd_workflow>
  <phase name="explore">...</phase>
  <phase name="plan">...</phase>
  <phase name="tdd">
    <tdd_cycle>
      <red_phase>
        <objectives>失敗するテストを先に作成</objectives>
        <quality_gates>テストが失敗することを確認</quality_gates>
      </red_phase>
      <green_phase>
        <objectives>テストを通す最小実装</objectives>
        <quality_gates>全テストがパス</quality_gates>
      </green_phase>
      <refactor_phase>
        <objectives>コード品質向上</objectives>
        <quality_gates>テストが継続的にパス</quality_gates>
      </refactor_phase>
    </tdd_cycle>
  </phase>
</tdd_workflow>
```

### 3. TDD固有の改善点

#### 3.1 テストファイル配置ルールの散在
- 134行目: `test/$FEATURE_NAME/` への配置指示
- 233行目: `test/$FEATURE_NAME/unit/test-$FEATURE_NAME.js` への配置指示
- 一貫性のない説明

#### 3.2 TDDサイクルの可視性
現状: bashコードに埋もれている（240-264行目）
改善: 明確な`<tdd_cycle>`セクションとして独立

### 4. 簡潔性の改善点

#### 4.1 重複する説明の削除
- "ClaudeCodeアクセス制限対応" が107行目と121-125行目で重複
- 各フェーズでworktree作業の説明が重複
- プロンプト読み込み処理が各フェーズで重複

#### 4.2 コード例の簡素化
現状: 23-84行目の初期化処理が61行
改善後の例:
```bash
# 関数呼び出しによる簡潔な表現
initialize_tdd_workflow "$ARGUMENTS"
setup_tdd_environment
create_tdd_worktree "$TASK_DESCRIPTION"
save_tdd_environment "$ENV_FILE"
```

### 5. 強調語の体系化

現状: 日本語での**重要**、**注意**などが散在
改善案:
- **ALWAYS**: テスト先行作成、各フェーズ後のコミット、カバレッジ測定
- **NEVER**: 実装先行、テスト未実行でのコミット、mainブランチ直接編集
- **MUST**: RED→GREEN→REFACTORの順序、各フェーズの品質ゲート通過
- **IMPORTANT**: TDD原則に関する重要事項のみ

### 6. 実装優先度

1. **即実施（高優先度タスクとして）**:
   - 外部関数化による重複削除
   - XMLタグ構造の導入
   - TDDサイクルの明確な構造化
   - 強調語の体系的使用

2. **次フェーズで実施**:
   - レポートテンプレートの外部化
   - テストファイル配置ルールの統一
   - コード圧縮（400行→200行）

## 📝 multi-feature.md改善分析レポート（2025-06-26）

### 1. 外部関数化すべき部分

#### 1.1 環境設定・初期化処理
```bash
# 以下のパターンが5回以上繰り返されている
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi
```
**推奨**: `initialize_phase()` 関数として worktree-utils.sh に追加

#### 1.2 Git コミット処理
各フェーズで類似のコミット処理が重複：
```bash
git -C "$WORKTREE_PATH" add "path"
git -C "$WORKTREE_PATH" commit -m "[TAG] message" || {
    log_warning "Failed to commit"
}
```
**推奨**: `commit_phase_results()` 関数として外部化

#### 1.3 レポート生成テンプレート
536-609行目の巨大なレポート生成処理は独立したテンプレートファイルに分離すべき
**推奨**: `.claude/templates/feature-completion-report.md` として外部化

### 2. XMLタグ使用の問題点

#### 2.1 一貫性の欠如
- `<quality_gates>` (21-37行目) が突然現れ、フェーズ構造と統合されていない
- phaseタグ内のサブ要素が不統一：
  - 一部は `<objectives>`, `<tools>`, `<output>` を持つ
  - 一部はMarkdownセクションのみ

**推奨構造**:
```xml
<phase name="name" priority="high">
  <objectives>...</objectives>
  <tools>...</tools>
  <quality_gates>...</quality_gates>
  <implementation>...</implementation>
  <output>...</output>
</phase>
```

#### 2.2 exampleタグの誤用
`<example>` タグ内に100行を超えるbashコードが入っており、例示の範囲を超えている
**推奨**: 実装コードは `<implementation>` タグに移動し、`<example>` は短い使用例のみに限定

### 3. 簡潔性の改善点

#### 3.1 重複する説明の削除
- "ClaudeCodeアクセス制限対応" の説明が3箇所で繰り返されている（163, 180-184行目等）
- 各フェーズで同じworktree作業説明が重複

#### 3.2 強調語の体系化
現状の散発的な使用を、research_lead_agent.mdのような体系的な使用に改善：
- **ALWAYS**: 必須アクション（テスト実行、コミット前の検証）
- **NEVER**: 禁止事項（未テストコードのコミット、main直接編集）
- **MUST**: 品質ゲート要件（カバレッジ80%以上、セキュリティ検証）
- **IMPORTANT**: 重要な注意事項のみに限定

#### 3.3 コード例の簡素化
bashコードブロックを最小限の例示に留め、詳細実装は外部関数参照にする：
```bash
# 現状: 20行のコード
# 改善後:
initialize_phase "$ENV_FILE"
show_progress "Explore" 5 1
run_explorer_phase "$WORKTREE_PATH" "$TASK_DESCRIPTION"
commit_phase_results "EXPLORE" "$WORKTREE_PATH"
```

### 4. research_lead_agent.mdから学ぶベストプラクティス

#### 4.1 明確な番号付きプロセス
research_processのような番号付きステップで全体フローを明確化

#### 4.2 ガイドラインの独立
`<subagent_count_guidelines>` のように、特定のトピックを独立したXMLブロックで管理

#### 4.3 具体例の効果的な使用
短く具体的な例を適切な箇所に配置（簡潔で理解しやすい）

### 5. 実装優先度

1. **即実施（Day 5-6で対応）**:
   - 外部関数化（worktree-utils.shへの共通処理追加）
   - XMLタグ構造の統一化
   - 強調語の体系的使用

2. **次フェーズで実施**:
   - レポートテンプレートの外部化
   - exampleタグの適切な使用への修正
   - 重複説明の削除とコンパクト化

## 📋 実施順序サマリー

### 完了済みタスク（2025-06-26 更新）
✅ 全multiコマンドのセッション分離問題修正
✅ 環境ファイル管理の改善（セキュリティ・並行実行対応）
✅ 修正フェーズ3: 検証とテスト（基本動作確認完了）
✅ test-worktree-access.shの作成完了（.claude/test/配下）

### 今週の実施計画
1. **Day 1**: 残存worktreeクリーンアップ、CLAUDE.md更新（🔴最優先）
2. **Day 2-3**: 全multiコマンドの統合テスト（🟠高優先）
3. **Day 3-4**: テストスクリプトの作成（🟠高優先）
4. **Day 5**: multi-feature.md改善（🟠高優先）
5. **Day 6**: multi-tdd.mdリファクタリング（🟠高優先）
6. **Day 7**: multi-refactor.md改善（🟠高優先）

### 重要な依存関係
- 統合テストは環境ファイル管理改善の完了により実施可能
- 自動テストスクリプトは統合テスト完了後に実施
- ドキュメント整備は各機能の実装・テスト完了後に実施
- multi-tdd.mdリファクタリングはmulti-feature.md分析を基に実施

### multi-tdd.mdリファクタリング実施手順
1. **Step 1**: worktree-utils.shに共通関数を追加
   - `initialize_tdd_phase()`: 環境設定・初期化の共通処理
   - `commit_tdd_phase()`: TDD各フェーズのコミット処理
   - `setup_report_dirs()`: レポートディレクトリ作成

2. **Step 2**: XMLタグ構造の導入
   - 全体を`<tdd_workflow>`で囲む
   - TDDサイクルを`<tdd_cycle>`として明確に分離
   - 各フェーズに品質ゲートを設定

3. **Step 3**: 簡潔性の改善
   - bashコードを関数呼び出しに置換
   - 重複説明の削除
   - 400行を200行以下に圧縮

4. **Step 4**: 強調語の体系的適用
   - ALWAYS/NEVER/MUST/IMPORTANTの一貫した使用
   - TDD原則に基づく強調ポイントの明確化

