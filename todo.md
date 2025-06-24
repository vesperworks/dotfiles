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

### 6. TDDサイクルの並列化による効率化
- [ ] worktree-utils.shに`run_parallel_agents()`関数を追加
- [ ] TDD RED-GREENサイクルの並列実行機能
  - [ ] Coder-Testエージェント（テスト作成専門）
  - [ ] Coder-Implエージェント（実装専門）
  - [ ] 両者の結果をマージする仕組み
- [ ] Testerエージェントの早期投入
  - [ ] 各TDDサイクル完了後に即座にTesterを起動
  - [ ] Coderの次サイクルとTesterの検証を並列実行
- [ ] MCP連携の専門化
  - [ ] MCP-Testerサブエージェント（Playwright/Puppeteer専門）
  - [ ] E2Eテストの自動生成・実行を並列化
- [ ] 効果測定
  - [ ] TDDサイクル時間の短縮率を計測（目標：30-40%短縮）
  - [ ] 早期品質問題発見率の向上

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
- [x] `.claude/prompts/tester.md` - 品質検証・カバレッジ確認専門 ✅ NEW

### Templates（実装済み）
- [x] `.claude/templates/task-completion.md` - タスク完了レポート

### Scripts（実装済み）
- [x] `.claude/scripts/worktree-utils.sh` - 共通ユーティリティ
- [x] `.claude/scripts/test-worktree-access.sh` - worktreeアクセステスト ✅ NEW

### Test（実装済み）
- [x] `.claude/test/test-multi-agent.sh` - 統合テストスクリプト ✅ NEW
- [x] `.claude/test/test-structured-directories.sh` - 構造化ディレクトリテスト ✅ NEW
- [x] `.claude/test/test-workflow-improvements.sh` - ワークフロー改善テスト ✅ NEW

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

1. ~~**最優先**: worktreeアクセス問題の修正（multi-featureコマンドのエラー対応）~~ ✅ 完了
2. ~~**高**: CLAUDE.mdの更新（プロジェクト状態を正確に反映）~~ ✅ 完了
3. ~~**高**: ファイル構造の改善（テスト・レポートの整理）~~ ✅ 完了
4. ~~**高**: ワークフロー実装の改善（ブランチ切り替え・クリーンアップ）~~ ✅ 完了
5. **中**: TDDサイクルの並列化による効率化
6. **中**: 各ワークフローの自動テストスクリプト作成
7. **低**: MCP連携機能の実装（別フェーズでも可）
8. **低**: 推奨改善項目（運用開始後に順次対応）

## 💡 次のアクション

1. ~~worktree-utils.shのアクセス制限対応を実装~~ ✅ 完了
2. ~~マルチエージェントコマンドを.worktreesサブディレクトリ対応に更新~~ ✅ 完了
3. ~~CLAUDE.mdを現在の実装状態に合わせて更新~~ ✅ 完了
4. ~~動作確認テストの実施~~ ✅ 完了
5. ~~最終コミットでリリース準備完了~~ ✅ 完了

## 🎯 新しい次のアクション

1. TDDサイクルの並列化による効率化の検討
2. 各ワークフローの自動テストスクリプト作成
3. MCP連携機能の実装検討
4. エラーハンドリング強化（リトライ機能など）

---

更新日: 2025-01-24（ワークフロー改善完了）

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