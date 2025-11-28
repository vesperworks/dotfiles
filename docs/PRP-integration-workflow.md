# PRP統合ワークフロー使用ガイド

## 概要

vw-orchestratorエージェントにPRP（Project Requirement Plan）統合機能が追加されました。
これにより、対話的な仕様決定と完全な開発ワークフローを一貫して実行できます。

## ワークフロー比較

### パターンA: PRP統合ワークフロー（推奨）

**いつ使う？**
- 仕様が不明確で、対話的に要件を整理したい場合
- 事前にリサーチを行い、実装の成功率を高めたい場合
- 検証コマンドを明確に定義したい場合

**フロー:**
```bash
1. /contexteng-gen-prp "user-profile-upload"
   ↓ 対話的仕様決定・リサーチ・PRP生成

2. @vw-orchestrator "PRPs/user-profile-upload.md を使って実装"
   ↓ PRP検証 → 簡略探索 → 分析 → 設計 → 実装 → PRP検証ゲート → テスト

3. /sc "ユーザープロフィール画像アップロード機能を実装"
```

**利点:**
- 仕様壁打ちで要件を明確化
- 事前リサーチで実装パターンを確立
- 検証コマンドで品質保証
- Explorerフェーズが簡略化され高速

### パターンB: 直接実装ワークフロー

**いつ使う？**
- 仕様が明確で、すぐに実装を開始したい場合
- 小規模な変更や改善の場合

**フロー:**
```bash
1. @vw-orchestrator "ユーザープロフィール画像アップロード機能"
   ↓ フル探索 → 分析 → 設計 → 実装 → レビュー → テスト

2. /sc "ユーザープロフィール画像アップロード機能を実装"
```

**利点:**
- 迅速な開発開始
- シンプルなワークフロー

## PRP統合の動作詳細

### Phase 0: PRP Integration
1. PRPファイルの存在確認
2. PRP内容の読み込み
   - Context（背景情報）
   - Requirements（要件）
   - Implementation Blueprint（実装設計）
   - Validation Gates（検証コマンド）

### Phase 1: Workflow Initialization
- **PRP有り**: PRP内容を活用して初期化を簡略化
- **PRP無し**: 従来通りの完全な初期化

### Phase 2: Explorer Phase
- **PRP有り**: PRPのリサーチ結果を検証・補完（高速）
- **PRP無し**: 完全なコードベース探索（詳細）

### Phase 4: Developer Phase
- **PRP有り**: PRP Implementation Blueprintを参照して実装
- **PRP無し**: 設計仕様のみから実装

### Phase 5: Reviewer Phase
- **PRP有り**: PRP Validation Gates（Syntax/Style checks）を使用
- **PRP無し**: 標準的な品質チェック

### Phase 6: QA Tester Phase
- **PRP有り**: PRP検証コマンド（Unit/Integration/E2E tests）を実行
- **PRP無し**: 標準的なテストスイート実行

## 実装例

### 例1: ユーザープロフィール画像アップロード

```bash
# ステップ1: 仕様壁打ちとPRP生成
/contexteng-gen-prp "user-profile-upload"

# Claudeが以下を実行：
# - 既存の類似機能を調査
# - ライブラリドキュメントを検索
# - 実装パターンを提案
# - ユーザーと対話して仕様を確定
# - PRPs/user-profile-upload.md を生成

# ステップ2: PRP統合実装
@vw-orchestrator "PRPs/user-profile-upload.md を使って実装"

# Claudeが以下を実行：
# Phase 0: PRP読み込み
# Phase 1: 初期化（PRP活用）
# Phase 2: Explorer（PRP検証・補完）
# Phase 3: Analyst（影響分析）
# Phase 4: Designer（設計）
# Phase 5: Developer（実装 + PRP Blueprint活用）
# Phase 6: Reviewer（PRP Validation Gates）
# Phase 7: QA Tester（PRP検証コマンド + Playwright）

# ステップ3: コミット
/sc "ユーザープロフィール画像アップロード機能を実装"
```

### 例2: 既存機能の改善（直接実装）

```bash
# 仕様が明確な場合はPRP不要
@vw-orchestrator "認証トークンの有効期限を24時間に延長"

# フルフローで実装
# Phase 1-7: すべてのフェーズを完全実行

/sc "認証トークンの有効期限を延長"
```

## PRP生成のベストプラクティス

### 1. 明確な機能名
```bash
# Good
/contexteng-gen-prp "oauth2-login-integration"

# Bad
/contexteng-gen-prp "login"
```

### 2. リサーチの徹底
- 既存パターンの確認
- ライブラリドキュメントの参照
- 実装例の収集

### 3. 検証コマンドの明確化
```markdown
# PRPのValidation Gatesセクション例
```bash
# Syntax/Style
ruff check --fix && mypy .

# Unit Tests
uv run pytest tests/ -v

# E2E Tests
playwright test
```
```

## トラブルシューティング

### PRP読み込みエラー
```
Error: PRP file not found: PRPs/xxx.md
```
**解決**: PRPファイルのパスを確認してください

### PRP検証失敗
```
Warning: PRP referenced files are outdated
```
**解決**: vw-explorerが自動的に最新情報を補完します

### 検証コマンドの失敗
```
Error: PRP validation command failed: ruff check
```
**解決**: vw-reviewerが自動的に修正を試みます

## よくある質問

**Q: PRPは必須ですか？**
A: いいえ。PRPなしでも`@vw-orchestrator`は動作します。仕様が明確な場合はPRP不要です。

**Q: contexteng-exe-prpはどうなりますか？**
A: 非推奨になりました。`@vw-orchestrator`がPRP統合機能を持つため、より包括的なワークフローを提供します。

**Q: 既存のPRPを再利用できますか？**
A: はい。`@vw-orchestrator "PRPs/existing-prp.md を使って実装"`で再利用できます。

**Q: PRPを更新するには？**
A: `/contexteng-gen-prp`を再実行するか、PRPファイルを直接編集してください。

## まとめ

PRP統合ワークフローにより：
- ✅ 対話的な仕様決定が可能
- ✅ 事前リサーチで実装成功率が向上
- ✅ 検証コマンドで品質保証
- ✅ Explorerフェーズが高速化
- ✅ 6フェーズワークフロー全体で一貫した品質

ぜひPRP統合ワークフローをお試しください！
