# 廃止エージェント（Deprecated Agents）

**移動日時**: 2025-12-10
**移動理由**: PRP-008: vw-dev シリーズ移行

## 廃止理由

現行の6フェーズワークフロー（Explorer → Analyst → Designer → Developer → Reviewer → QA-Tester）のうち、**前半3フェーズ（explorer, analyst, designer）は PRP と /research コマンドと実質的に重複**していることが判明。新しい `vw-dev-orchestra` を設計し、**PRPから直接TDD実装 → 検証ループ**に特化させることで、オーバーヘッドを削減。

### 詳細リサーチ

`thoughts/shared/research/2025-12-10-vw-dev-orchestra-redesign.md` を参照。

## 廃止されたエージェント

| ファイル | 旧役割 | 廃止理由 |
|---------|-------|---------|
| `vw-orchestrator.md` | 6フェーズワークフロー統括 | vw-dev-orchestraに置換 |
| `vw-explorer.md` | コードベース探索 | /research でカバー |
| `vw-analyst.md` | 影響分析・リスク評価 | PRP でカバー |
| `vw-designer.md` | アーキテクチャ設計 | PRP でカバー |
| `vw-developer.md` | TDD実装 | Main Claude 直接実行 |
| `vw-reviewer.md` | コードレビュー | vw-dev-reviewer にリネーム |
| `vw-qa-tester.md` | E2Eテスト | vw-dev-tester にリネーム |

## 新アーキテクチャ

```
【新ワークフロー】

/research        → 探索・技術調査（hl-* subAgents）
      │
      ▼
/contexteng-gen-prp → PRP生成（vw-prp-orchestrator）
      │
      ▼
/contexteng-exe-prp → PRP実行（vw-dev-orchestra）
      │               ├── Main Claude: TDD実装（直接実行）
      │               ├── vw-dev-reviewer: 静的解析（subAgent）
      │               └── vw-dev-tester: E2E（subAgent）
      ▼
/sc              → スマートコミット
```

## 新エージェント構成

```
.klaude/agents/
├── vw-dev-orchestra.md     # 🆕 新設: 実装オーケストレーター
├── vw-dev-reviewer.md      # 🔄 リネーム: vw-reviewer → vw-dev-reviewer
├── vw-dev-tester.md        # 🔄 リネーム: vw-qa-tester → vw-dev-tester
├── vw-task-manager.md      # ✅ 維持
├── vw-prp-orchestrator.md  # ✅ 維持
├── vw-prp-plan-minimal.md  # ✅ 維持
├── vw-prp-plan-architect.md    # ✅ 維持
├── vw-prp-plan-pragmatist.md   # ✅ 維持
└── vw-prp-plan-conformist.md   # ✅ 維持
```

## ロールバック手順

問題が発生した場合：

```bash
# Step 1: バックアップから復元
rm -rf .klaude/agents
mv .klaude/agents.backup-20251210 .klaude/agents

# Step 2: 新コマンドを元に戻す（必要に応じて）
git checkout HEAD~1 -- .klaude/commands/contexteng-exe-prp.md

# Step 3: このディレクトリから廃止エージェントを復元（必要に応じて）
mv remove/agents/vw-*.md .klaude/agents/

# Step 4: CLAUDE.md を以前の状態に戻す
git checkout HEAD~1 -- CLAUDE.md
```

## 参照

- **PRP**: `PRPs/PRP-008-vw-dev-series-migration.md`
- **リサーチ**: `thoughts/shared/research/2025-12-10-vw-dev-orchestra-redesign.md`
- **PRP-007（キャンセル済み）**: `PRPs/cancel/PRP-007-vw-agent-refactoring.md`
