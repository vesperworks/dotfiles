# TODO: マルチエージェントワークフロー実装の残タスク

## 🔴 未実装項目（CLAUDE.md記載内容との差分）

### 1. Testerプロンプトの作成
- [ ] `.claude/prompts/tester.md` - 品質検証・カバレッジ確認用プロンプト
- CLAUDE.mdではTesterエージェントが定義されているが、プロンプトファイルが未作成

### 2. scriptsディレクトリの整備
- [x] `.claude/scripts/worktree-utils.sh` - 実装済み
- CLAUDE.mdのプロジェクト構造に記載なし → CLAUDE.mdの更新が必要

### 3. プロジェクト状態の更新
- [ ] CLAUDE.mdの「現在はアーキテクチャ設計フェーズ」を「実装完了」に更新
- [ ] 「実際の動作コードはまだ準備中」を「運用可能」に更新
- [ ] プロジェクト構造を実際のファイル構成に合わせて更新

### 4. テストスクリプトの改善
- [ ] `test-multi-agent.sh` の実装内容確認と改善
- [ ] 各ワークフローの自動テストスクリプト作成

### 5. MCP連携機能の実装
- [ ] Context7連携の具体的な実装
- [ ] Playwright/Puppeteer統合のサンプル作成
- [ ] MCP設定ドキュメントの作成

## ✅ 実装完了項目

### Commands（全て実装済み）
- [x] `.claude/commands/multi-tdd.md` - TDDワークフロー
- [x] `.claude/commands/multi-feature.md` - 新機能開発
- [x] `.claude/commands/multi-refactor.md` - リファクタリング
- [x] `.claude/commands/s.md` - クイック検索（追加実装）

### Prompts（Tester以外実装済み）
- [x] `.claude/prompts/explorer.md` - 探索・調査専門
- [x] `.claude/prompts/planner.md` - 戦略策定専門
- [x] `.claude/prompts/coder.md` - TDD実装専門

### Templates（実装済み）
- [x] `.claude/templates/task-completion.md` - タスク完了レポート

### Scripts（実装済み）
- [x] `.claude/scripts/worktree-utils.sh` - 共通ユーティリティ

## 🟡 推奨改善項目

### 1. ドキュメント整備
- [ ] 各コマンドの詳細な使用方法ドキュメント
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

1. **高**: Testerプロンプトの作成
2. **高**: CLAUDE.mdの更新（プロジェクト状態を正確に反映）
3. **中**: テストスクリプトの改善
4. **低**: MCP連携機能の実装（別フェーズでも可）
5. **低**: 推奨改善項目（運用開始後に順次対応）

## 💡 次のアクション

1. Testerプロンプト（`.claude/prompts/tester.md`）を作成
2. CLAUDE.mdを現在の実装状態に合わせて更新
3. 基本的な動作テストを実施
4. 最終コミットでリリース準備完了

---

更新日: 2025-01-24