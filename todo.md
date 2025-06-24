# TODO: マルチエージェントワークフロー実装の残タスク

## ✅ 完了済み：multi-featureコマンドのエラー修正

### 0. worktreeアクセス問題の修正【完了】
- [x] 孤立したworktreeのクリーンアップ（親ディレクトリの../DeepResearchSh-*）✅
- [x] worktree-utils.shのClaudeCodeアクセス制限対応 ✅
  - [x] .worktreesサブディレクトリ内での作業確認 ✅
  - [x] ファイル操作の代替手段実装（cpの代わりにRead/Write使用）✅
- [x] マルチエージェントコマンドの更新 ✅
  - [x] multi-tdd.mdの.worktrees対応 ✅
  - [x] multi-feature.mdの.worktrees対応 ✅
  - [x] multi-refactor.mdの.worktrees対応 ✅
- [x] エラーハンドリングとフォールバック処理 ✅
  - [x] worktree作成失敗時の処理 ✅
  - [x] アクセス制限時の代替処理 ✅
- [x] 動作確認テストスクリプトの作成 ✅

## 🔴 未実装項目（CLAUDE.md記載内容との差分）

### 1. Testerプロンプトの作成
- [x] `.claude/prompts/tester.md` - 品質検証・カバレッジ確認用プロンプト ✅ 完了済み

### 2. scriptsディレクトリの整備
- [x] `.claude/scripts/worktree-utils.sh` - 実装済み
- CLAUDE.mdのプロジェクト構造に記載なし → CLAUDE.mdの更新が必要

### 3. プロジェクト状態の更新
- [x] CLAUDE.mdの「現在はアーキテクチャ設計フェーズ」を「実装完了」に更新 ✅
- [x] 「実際の動作コードはまだ準備中」を「運用可能」に更新 ✅
- [x] プロジェクト構造を実際のファイル構成に合わせて更新 ✅

### 4. テストスクリプトの改善
- [x] `test-multi-agent.sh` の実装内容確認と改善 ✅ 完了
- [ ] 各ワークフローの自動テストスクリプト作成

### 5. ファイル構造の改善【完了】
- [x] テストファイルを`/test/{feature-name}/`に配置するよう変更 ✅
- [x] レポートファイルを`/report/{feature-name}/`に配置するよう変更 ✅
- [x] ファイル名にfeature名を含めて明示的にする（例: `test-auth-unit.js`、`report-auth-coverage.md`）✅
- [x] worktree-utils.shにディレクトリ作成機能を追加 ✅

### 6. TDDサイクルの並列化による効率化【完了】
- [x] worktree-utils.shに`run_parallel_agents()`関数を追加 ✅
- [x] TDD RED-GREENサイクルの並列実行機能 ✅
  - [x] Coder-Testエージェント（テスト作成専門）✅
  - [x] Coder-Implエージェント（実装専門）✅
  - [x] 両者の結果をマージする仕組み ✅
- [x] 並列実行監視とレポート機能 ✅
  - [x] リアルタイム進捗表示（スピナー付き）✅
  - [x] 統合レポート自動生成 ✅
  - [x] Git自動コミット機能 ✅
- [ ] Testerエージェントの早期投入（将来拡張）
  - [ ] 各TDDサイクル完了後に即座にTesterを起動
  - [ ] Coderの次サイクルとTesterの検証を並列実行
- [ ] MCP連携の専門化（将来拡張）
  - [ ] MCP-Testerサブエージェント（Playwright/Puppeteer専門）
  - [ ] E2Eテストの自動生成・実行を並列化
- [ ] 効果測定（運用後実施予定）
  - [ ] TDDサイクル時間の短縮率を計測（目標：30-40%短縮）
  - [ ] 早期品質問題発見率の向上

### 6.1 並列TDD機能のコマンド統合
- [ ] multi-tdd.mdに`--parallel`オプションを追加
- [ ] オプション指定時に`run_parallel_agents()`を呼び出す
- [ ] デフォルトは従来の順次実行を維持
- [ ] 使用例とパフォーマンス比較をドキュメント化

### 7. MCP連携機能の実装
- [ ] Context7連携の具体的な実装
- [ ] Playwright/Puppeteer統合のサンプル作成
- [ ] MCP設定ドキュメントの作成

### 8. ワークフロー実装の改善【完了】
- [x] **ブランチ切り替えの確認と修正** ✅
  - [x] worktree作成時に新しいfeatureブランチが正しく作成されているか確認 ✅
  - [x] コミットがmainブランチではなくfeatureブランチに行われているか検証 ✅
  - [x] 必要に応じてブランチ切り替えロジックを修正 ✅
- [x] **worktreeの自動クリーンアップ機能** ✅
  - [x] 各コマンドの最後にworktreeをクリーンアップするオプション追加 ✅
  - [x] `--keep-worktree`フラグでクリーンアップをスキップ可能に ✅
  - [x] 古いworktreeを定期的に削除するユーティリティ関数 ✅
- [x] **ローカル完結型マージ機能の追加** ✅
  - [x] `merge_to_main()`関数の実装（デフォルト動作）✅
  - [x] worktree完了後の自動マージ（--no-mergeで無効化）✅
  - [x] マージ完了後の自動クリーンアップ ✅
- [x] **PR作成オプションの追加** ✅
  - [x] `--pr`フラグでGitHub PR作成モードを有効化 ✅
  - [x] `create_pull_request()`関数の実装（gh CLI使用）✅
  - [x] 完了レポートをPR本文として使用 ✅
  - [x] ドラフトPRとして作成（--no-draftで通常PR）✅

## ✅ 実装完了項目

### Commands（全て実装済み）
- [x] `.claude/commands/multi-tdd.md` - TDDワークフロー
- [x] `.claude/commands/multi-feature.md` - 新機能開発
- [x] `.claude/commands/multi-refactor.md` - リファクタリング
- [x] `.claude/commands/s.md` - クイック検索（追加実装）
- [x] `.claude/commands/p.md` - 計画モード（リサーチ・計画・管理）✅ NEW

### Prompts（全て実装済み）
- [x] `.claude/prompts/explorer.md` - 探索・調査専門
- [x] `.claude/prompts/planner.md` - 戦略策定専門
- [x] `.claude/prompts/coder.md` - TDD実装専門
- [x] `.claude/prompts/coder-test.md` - テスト作成専門（並列TDD対応）✅ NEW
- [x] `.claude/prompts/coder-impl.md` - 実装専門（並列TDD対応）✅ NEW
- [x] `.claude/prompts/tester.md` - 品質検証・カバレッジ確認専門 ✅

### Templates（実装済み）
- [x] `.claude/templates/task-completion.md` - タスク完了レポート

### Scripts（実装済み）
- [x] `.claude/scripts/worktree-utils.sh` - 共通ユーティリティ
- [x] `.claude/scripts/test-worktree-access.sh` - worktreeアクセステスト ✅ NEW

### Test（実装済み）
- [x] `.claude/test/test-multi-agent.sh` - 統合テストスクリプト ✅ NEW
- [x] `.claude/test/test-structured-directories.sh` - 構造化ディレクトリテスト ✅ NEW
- [x] `.claude/test/test-workflow-improvements.sh` - ワークフロー改善テスト ✅ NEW
- [x] `.claude/test/test-parallel-tdd.sh` - 並列TDD機能テスト ✅ NEW

## 🔴 緊急修正項目：multi-refactor設計上のバグ

### 1. ~~Taskツール制御フロー設計バグ（高優先度）~~ ✅ 再確認により問題なし
- [x] **再確認結果**: multi-refactor.md:82-92行はTaskツールではなく、マークダウン内の直接指示
  - [x] 実際にはTaskツールは呼ばれていない（誤認識でした）
  - [x] Explorer指示は既に直接実行方式になっている
  - [x] 修正不要と判断

### 2. ~~Bashスクリプト関数の不完全実装（高優先度）~~ ✅ 修正済み
- [x] **問題確認**: worktree-utils.shの関数エクスポートが不足していた
- [x] **修正完了**: worktree-utils.sh:606-613行に関数エクスポートが追加済み
  - [x] `parse_workflow_options`, `verify_environment` を含む全必要関数がエクスポート済み
  - [x] parallel-agent-utils.shへの分離も完了済み
  - [x] 関数スコープ問題は解決済み

### 3. 変数スコープとエラーハンドリングバグ（中優先度）
- [ ] **Problem**: 変数の初期化とエラー処理が不完全
  - [ ] **新たな発見**: `$ARGUMENTS` と `$TASK_DESCRIPTION` の変数名不一致問題
  - [ ] multi-refactor.mdで`$ARGUMENTS`使用、worktree-utils.shで`$TASK_DESCRIPTION`に変換
  - [ ] タスクID生成時の文字列処理エラー（日本語文字列対応不備）
  - [ ] ブランチ名が空文字列になり `fatal: '' is not a valid branch name` エラー
- [ ] **Solution**: 変数管理とパラメータ処理の修正
  - [ ] **Step 1**: 変数名を統一（`$ARGUMENTS` vs `$TASK_DESCRIPTION`）
  - [ ] **Step 2**: multi-refactor.md全体で一貫性のある変数使用に修正
  - [ ] **Step 3**: 日本語文字列処理の改善（sedコマンド修正、UTF-8対応）
  - [ ] **Step 4**: ブランチ名生成の堅牢化（デフォルト値設定、特殊文字除去）
  - [ ] **Step 5**: エラーケースの網羅的テスト（空文字列、特殊文字、長い文字列）

### 4. Phase間の依存関係管理バグ（中優先度）
- [ ] **Problem**: 各フェーズ間の依存関係と状態管理が未実装
  - [ ] Analysis -> Plan -> Refactor -> Verify の順序制御なし
  - [ ] 前フェーズの失敗時の処理が不明確
  - [ ] 並行実行との競合状態の可能性
  - [ ] ファイル作成確認の条件分岐が機能しない
- [ ] **Solution**: フェーズ管理システムの実装
  - [ ] **Step 1**: フェーズ状態管理システムの設計（.status ファイル利用）
  - [ ] **Step 2**: 前フェーズ完了確認の実装（ファイル存在チェック強化）
  - [ ] **Step 3**: エラー時のロールバック機能追加（worktree削除、状態リセット）
  - [ ] **Step 4**: フェーズ間データ受け渡しの標準化（JSON形式の採用）
  - [ ] **Step 5**: 並行実行との競合回避機能（ロックファイル機構）

## 🟡 推奨改善項目

### 1. ドキュメント整備
- [x] 各コマンドの詳細な使用方法ドキュメント ✅（workflow-improvements-usage.md作成済み）
- [ ] トラブルシューティングガイド
- [ ] ベストプラクティス集

### 2. エラーハンドリング強化
- [ ] worktree作成失敗時のリトライ機能
- [ ] ネットワークエラー時の対処
- [ ] 不完全なタスクのリカバリー機能

### 3. 監視・ログ機能
- [ ] タスク実行履歴の記録
- [ ] パフォーマンスメトリクスの収集
- [ ] 成功/失敗率の可視化

### 4. 設定のカスタマイズ
- [ ] `.claude/config.json` - ユーザー設定ファイル
- [ ] タイムアウト値の調整機能
- [ ] デフォルトブランチ名のカスタマイズ

## 📅 優先順位

### 🔄 進行中タスク（並列エージェント機能のリファクタリング）
1. **高**: `parallel-agent-utils.sh`ファイルの作成 - run_parallel_agents()など並列実行機能の切り出し
2. **高**: `worktree-utils.sh`から並列機能を削除し、新ファイルをsource文で読み込み
3. **中**: 既存テストスクリプトでの動作確認と回帰テスト実施

### 🚨 緊急対応（multi-refactorバグ修正）
1. **最優先**: Taskツール制御フロー設計バグの修正
2. **最優先**: Bashスクリプト関数の不完全実装の修正
3. **高**: 変数スコープとエラーハンドリングバグの修正
4. **高**: Phase間の依存関係管理バグの修正

### 📈 従来の優先順位
1. ~~**最優先**: worktreeアクセス問題の修正（multi-featureコマンドのエラー対応）~~ ✅ 完了
2. ~~**高**: CLAUDE.mdの更新（プロジェクト状態を正確に反映）~~ ✅ 完了
3. ~~**高**: ファイル構造の改善（テスト・レポートの整理）~~ ✅ 完了
4. ~~**高**: ワークフロー実装の改善（ブランチ切り替え・クリーンアップ）~~ ✅ 完了
5. ~~**中**: TDDサイクルの並列化による効率化~~ ✅ 基盤実装完了
6. **高**: 並列TDD機能のコマンド統合（ユーザーが使える状態にする）
7. **中**: 各ワークフローの自動テストスクリプト作成
8. **低**: MCP連携機能の実装（別フェーズでも可）
9. **低**: 推奨改善項目（運用開始後に順次対応）

## 💡 次のアクション

### ✅ 完了済み（並列エージェント機能のリファクタリング）
- [x] `parallel-agent-utils.sh`ファイルを作成し、run_parallel_agents()など並列実行機能をworktree-utils.shから切り出す ✅
- [x] `worktree-utils.sh`から並列実行機能を削除し、新ファイルをsource文で読み込む ✅
- [x] 既存テストスクリプト(test-parallel-tdd.sh)での動作確認と回帰テスト実施 ✅

**結果**: 並列エージェント機能の切り出しが完了しました。
- **モジュール化**: 並列実行機能が独立ファイルに分離
- **再利用性**: 他プロジェクトでの並列エージェント機能の活用が可能
- **保守性**: 機能別の責任分離により、個別の機能修正が容易
- **動作確認済み**: 主要機能（エージェント関数、結果マージ、プロンプト）が正常動作

### 🔧 期待される効果
- **モジュール化**: 並列実行機能の独立管理
- **再利用性**: 他プロジェクトでの活用可能
- **保守性**: 機能別の責任分離により修正が容易
- **拡張性**: 新しいエージェントタイプの追加が容易

### ✅ 完了済み
1. ~~worktree-utils.shのアクセス制限対応を実装~~ ✅ 完了
2. ~~マルチエージェントコマンドを.worktreesサブディレクトリ対応に更新~~ ✅ 完了
3. ~~CLAUDE.mdを現在の実装状態に合わせて更新~~ ✅ 完了
4. ~~動作確認テストの実施~~ ✅ 完了
5. ~~最終コミットでリリース準備完了~~ ✅ 完了

## 🛠️ multi-refactorバグ修正の詳細実装手順

### ✅ 修正フェーズ1: 基盤修正（完了）
1. ~~**Taskツール制御フロー修正**~~ - 再確認により修正不要と判断
2. ~~**Bash関数スコープ修正**~~ - worktree-utils.shの関数エクスポート追加済み

### 🔧 修正フェーズ2: 機能修正（実施中）  
3. **変数処理修正** - `$ARGUMENTS`と`$TASK_DESCRIPTION`の統一が必要
4. **フェーズ管理修正** - 状態管理システムとエラーハンドリングの実装

### 📝 修正フェーズ3: 検証とテスト（予定）
5. **統合テスト** - 修正後の動作確認とエラーケーステスト
6. **ドキュメント更新** - 修正内容の反映と使用方法の更新

### 修正完了の検証手順
- [ ] **テスト1**: 日本語パラメータでのworktree作成テスト
- [ ] **テスト2**: 各フェーズの順次実行テスト（Analysis→Plan→Refactor→Verify）
- [ ] **テスト3**: エラー発生時の適切な処理テスト（rollback動作確認）
- [ ] **テスト4**: 最終的なリファクタリング完了テスト（実際のコード整理）

## 🚨 緊急次のアクション（multi-refactorバグ修正）

### ✅ 完了項目
1. ~~**multi-refactor.mdのTaskツール呼び出し削除**~~ - 修正不要（誤認識）
2. ~~**worktree-utils.shの関数スコープ修正**~~ - エクスポート追加済み

### 🔧 実施予定項目
3. **変数名統一の修正** - `$ARGUMENTS`と`$TASK_DESCRIPTION`の一貫性確保
4. **日本語パラメータ処理の修正** - 文字列処理とブランチ名生成修正
5. **フェーズ管理システムの実装** - 状態管理とエラーハンドリング

## 🎯 従来の次のアクション

1. **並列TDD機能のコマンド統合** - multi-tdd.mdに`--parallel`オプションを追加
2. 各ワークフローの自動テストスクリプト作成
3. MCP連携機能の実装検討
4. エラーハンドリング強化（リトライ機能など）

---

更新日: 2025-06-24（並列TDD機能完了、multi-refactorバグ再確認、2/4項目が既に解決済み）

## 📝 完了した改善内容

### ワークフロー実装の改善（2025-01-24完了）
1. **ブランチ管理の強化**
   - worktree作成時のブランチ確認機能
   - 正しいブランチでのコミット保証

2. **自動化機能の追加**
   - 古いworktreeの自動クリーンアップ（7日以上）
   - ローカルマージ機能（PR不要の場合）
   - GitHub PR自動作成（gh CLI使用）

3. **柔軟なオプションシステム**
   - `--keep-worktree`: 作業後もworktree保持
   - `--no-merge`: 自動マージをスキップ
   - `--pr`: GitHub PR作成
   - `--no-draft`: 通常PR（非ドラフト）
   - `--cleanup-days N`: クリーンアップ期間指定

4. **ドキュメントとテスト**
   - workflow-improvements-usage.md: 詳細な使用方法
   - test-workflow-improvements.sh: 機能テスト

### 並列TDD機能の実装（2025-06-24完了）
1. **並列実行アーキテクチャ**
   - `run_parallel_agents()`: メイン並列実行関数
   - Test Agent と Implementation Agent の同時実行
   - プロセス管理とPID追跡システム

2. **専門エージェントの実装**
   - Coder-Test Agent: TDD Red phase専門（テスト作成）
   - Coder-Impl Agent: TDD Green phase専門（実装）
   - 独立したログファイルと進捗管理

3. **監視・統合機能**
   - リアルタイム進捗監視（スピナー表示）
   - 並列実行結果の自動マージ
   - 統合レポート生成（parallel-tdd-report.md）
   - Git自動コミット機能

4. **専門プロンプトとテスト**
   - coder-test.md: テスト作成専門プロンプト
   - coder-impl.md: 実装専門プロンプト  
   - test-parallel-tdd.sh: 包括的機能テスト