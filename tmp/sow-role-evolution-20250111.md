# Statement of Work (SOW) - 改訂版
## 役割進化型multi-系コマンドリデザイン

### プロジェクト概要

**プロジェクト名**: 役割進化型ワークフローへの移行  
**期間**: 3-4日（大幅短縮）  
**目的**: worktreeとccmanager役割分担を廃止し、シンプルで直感的なワークフローを実現

### 根本的な変更点

1. **worktree廃止**
   - `.worktrees/`ディレクトリ不要
   - 複雑なgit worktree操作を排除
   - 現在のブランチで直接作業

2. **ccmanager役割分担廃止**
   - プリセット切り替え不要
   - 複数セッション管理不要
   - ccmは進捗表示のみ（オプション）

3. **単一セッション・役割進化**
   - 1つのClaudeセッションが役割を変えながら進行
   - Explorer → Analyst → Designer → Developer → Reviewer
   - 各役割で明確な成果物を生成

### スコープ定義

#### 含まれる作業

1. **新しいユーティリティ関数の作成**
   ```bash
   # role-utils.sh（新規作成）
   - switch_role()      # 役割切り替え
   - save_artifact()    # 成果物保存
   - show_progress()    # 進捗表示
   - get_current_role() # 現在の役割取得
   ```

2. **コマンドファイルの全面改訂**
   - multi-feature.md → 役割進化型へ
   - multi-tdd.md → TDD特化の役割進化
   - multi-refactor.md → リファクタリング特化の役割進化
   - multi-feature-ccm.md → 廃止または統合

3. **worktree-utils.sh の整理**
   - worktree関連関数の削除
   - 環境ファイル関連の削除
   - 役割進化に必要な関数のみ残す

4. **ドキュメント更新**
   - シンプルな使用例
   - 役割の説明
   - 移行ガイド

#### 削除される機能

- git worktree 全般
- 環境ファイル（.env-*）
- ccmanagerプリセット管理
- 並列エージェント実行
- フェーズ状態管理（JSON）

### 成果物

1. **簡素化されたコード**
   - role-utils.sh（200行程度）
   - 各multi-*.md（300行以下に削減）
   - 削除されるコード（約1000行）

2. **明確な成果物構造**
   ```
   project/
   ├── explorer-report.md
   ├── analysis-report.md
   ├── design-doc.md
   ├── implementation-log.md
   └── review-report.md
   ```

3. **シンプルなドキュメント**
   - README.md（使い方中心）
   - 役割説明書
   - クイックスタートガイド

### タイムライン（短縮版）

```
Day 1: 基盤作成
  - role-utils.sh 作成
  - worktree-utils.sh クリーンアップ
  - 基本的な役割切り替え実装

Day 2-3: コマンド実装
  - multi-feature.md 改訂
  - multi-tdd.md 改訂
  - multi-refactor.md 改訂
  - テスト実施

Day 4: 仕上げ
  - ドキュメント作成
  - サンプル実行
  - 最終調整
```

### 技術要件（大幅簡素化）

1. **必須要件**
   - Git（基本機能のみ）
   - Bash 4.x以上

2. **オプション**
   - ccmanager（進捗表示用）
   - jq（不要）

### 実装例

#### multi-feature.md（新版）の構造

```bash
#!/bin/bash
source .claude/scripts/role-utils.sh

# Step 1: Explorer
switch_role "Explorer"
echo "🔍 Exploring: $TASK_DESCRIPTION"
# ユーザーが調査を実行
save_artifact "explorer" "$EXPLORATION_RESULTS"

# Step 2: Analyst  
switch_role "Analyst"
echo "📊 Analyzing based on exploration..."
# ユーザーが分析を実行
save_artifact "analyst" "$ANALYSIS_RESULTS"

# Step 3: Designer
switch_role "Designer"
echo "🎨 Designing solution..."
# ユーザーが設計を実行
save_artifact "designer" "$DESIGN_DOCS"

# Step 4: Developer
switch_role "Developer"
echo "💻 Implementing..."
# ユーザーが実装を実行
save_artifact "developer" "$IMPLEMENTATION_LOG"

# Step 5: Reviewer
switch_role "Reviewer"
echo "✅ Reviewing and finalizing..."
# ユーザーがレビューを実行
save_artifact "reviewer" "$REVIEW_REPORT"
```

### リスクと対策（簡素化）

| リスク | 影響度 | 対策 |
|-------|-------|------|
| 既存ユーザーの混乱 | 中 | 明確な移行ガイド、旧版の一時保持 |
| 機能の喪失 | 低 | 本質的な機能は維持 |
| 学習曲線 | 低 | よりシンプルになるため問題なし |

### 成功基準

1. **シンプルさ**
   - コード行数50%削減
   - 設定ファイル不要
   - 5分で理解可能

2. **使いやすさ**
   - 単一コマンドで開始
   - 明確な進捗表示
   - エラーからの回復容易

3. **保守性**
   - 依存関係最小化
   - テスト容易
   - ドキュメント明確

### メリットまとめ

1. **即効性**: worktree作成待ち時間なし
2. **直感的**: 役割ベースで理解しやすい
3. **軽量**: ファイルシステム負荷最小
4. **柔軟**: 途中から再開・やり直しが容易
5. **学習容易**: Git高度な知識不要

### 承認事項

この大幅に簡素化されたアプローチについて：

1. worktree完全廃止で問題ないか
2. ccmanager統合を最小限にすることで良いか
3. 役割進化アプローチが直感的か
4. 実装を進めて良いか

---
作成日: 2025年1月11日  
作成者: Claude Code Assistant