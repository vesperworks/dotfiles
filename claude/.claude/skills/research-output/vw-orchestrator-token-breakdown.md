# vw-orchestrator トークン消費分析

## 視覚的トークン分布

```
Total: 43,904 tokens (100%)

vw-developer (38.8%)
████████████████████████████████████████
17,080 tokens
- Output Structure: 10,040 tokens (58.8%)
- TDD Process: 3,440 tokens (20.1%)
- Other: 3,600 tokens (21.1%)

vw-designer (21.9%)
██████████████████████
9,620 tokens
- Output Structure: 6,160 tokens (64.0%)
- Design Phases: 2,160 tokens (22.5%)
- Other: 1,300 tokens (13.5%)

vw-analyst (13.2%)
█████████████
5,800 tokens
- Output Structure: 2,480 tokens (42.8%)
- Analysis Phases: 2,160 tokens (37.2%)
- Other: 1,160 tokens (20.0%)

vw-reviewer (10.6%)
███████████
4,640 tokens
- Review Phases: 2,240 tokens (48.3%)
- Output Structure: 1,200 tokens (25.9%)
- Other: 1,200 tokens (25.8%)

vw-explorer (9.4%)
█████████
4,140 tokens
- Exploration Phases: 2,120 tokens (51.2%)
- Output Structure: 1,080 tokens (26.1%)
- Other: 940 tokens (22.7%)

vw-qa-tester (3.5%)
████
1,560 tokens
- Testing Workflow: 320 tokens (20.5%)
- Other: 1,240 tokens (79.5%)

vw-orchestrator (2.4%)
██
1,064 tokens
- Phase Overview: 300 tokens (28.2%)
- Task Assignment: 180 tokens (16.9%)
- Other: 584 tokens (54.9%)
```

## セクション別トークン分布

### 1. Output Structure (47.8% of total)

```
Total: 21,000 tokens

vw-developer
██████████████████████████████████████████████████ 10,040 (47.8%)

vw-designer
███████████████████████████████ 6,160 (29.3%)

vw-analyst
████████████ 2,480 (11.8%)

vw-reviewer
██████ 1,200 (5.7%)

vw-explorer
█████ 1,080 (5.1%)

vw-qa-tester
█ 40 (0.2%)
```

**抽出候補**: `.klaude/skills/workflow-outputs/TEMPLATES.md`
**削減効果**: ~21,000 tokens → 各エージェントは 1 行参照のみ（~40 tokens × 6 = 240 tokens）
**実質削減**: 20,760 tokens (47.3%)

---

### 2. Methodology/Phases (20.5% of total)

```
Total: 9,000 tokens

vw-developer (TDD)
████████████████████████████████████████ 3,440 (38.2%)

vw-reviewer
█████████████████████████ 2,240 (24.9%)

vw-analyst
████████████████████████ 2,160 (24.0%)

vw-designer
████████████████████████ 2,160 (24.0%)

vw-explorer
███████████████████████ 2,120 (23.6%)
```

**抽出候補**: `.klaude/skills/workflow-phases/METHODS.md`
**削減効果**: ~9,000 tokens → 各エージェントは 1 行参照のみ（~40 tokens × 5 = 200 tokens）
**実質削減**: 8,800 tokens (20.0%)

---

### 3. Code Examples (9.1% of total)

```
Total: 4,000 tokens

vw-developer
████████████████████████████████████████████████████████████ 2,400 (60.0%)

vw-designer
██████████████████████████████ 1,200 (30.0%)

vw-reviewer
██████ 400 (10.0%)
```

**抽出候補**: `.klaude/skills/code-templates/EXAMPLES.md`
**削減効果**: ~4,000 tokens → 参照のみ（~120 tokens）
**実質削減**: 3,880 tokens (8.8%)

---

## SKILL 抽出前後の比較

### 抽出前（現状）

```
vw-orchestrator:  1,064 tokens (2.4%)
vw-explorer:      4,140 tokens (9.4%)
vw-analyst:       5,800 tokens (13.2%)
vw-designer:      9,620 tokens (21.9%)
vw-developer:    17,080 tokens (38.8%)
vw-reviewer:      4,640 tokens (10.6%)
vw-qa-tester:     1,560 tokens (3.5%)
────────────────────────────────────
Total:           43,904 tokens (100%)
```

### 抽出後（推定）

```
vw-orchestrator:  1,064 tokens (13.3%)  [変更なし]
vw-explorer:        600 tokens (7.5%)   [-85.5%]
vw-analyst:         800 tokens (10.0%)  [-86.2%]
vw-designer:      1,200 tokens (15.0%)  [-87.5%]
vw-developer:     1,800 tokens (22.5%)  [-89.5%]
vw-reviewer:        800 tokens (10.0%)  [-82.8%]
vw-qa-tester:       720 tokens (9.0%)   [-53.8%]

SKILL overhead:   1,000 tokens (12.5%)  [Progressive Disclosure]
────────────────────────────────────
Total:            7,984 tokens (100%)

Reduction:       35,920 tokens (-81.8%)
```

---

## エージェント別削減効果

| エージェント | 抽出前 | 抽出後 | 削減 | 削減率 |
|------------|-------|-------|------|--------|
| vw-orchestrator | 1,064 | 1,064 | 0 | 0.0% |
| vw-explorer | 4,140 | 600 | 3,540 | **85.5%** |
| vw-analyst | 5,800 | 800 | 5,000 | **86.2%** |
| vw-designer | 9,620 | 1,200 | 8,420 | **87.5%** |
| vw-developer | 17,080 | 1,800 | 15,280 | **89.5%** |
| vw-reviewer | 4,640 | 800 | 3,840 | **82.8%** |
| vw-qa-tester | 1,560 | 720 | 840 | **53.8%** |
| **合計** | **43,904** | **7,984** | **35,920** | **81.8%** |

---

## セクション別削減優先度

### 超高優先度（即効性大）

#### 1. Output Templates
- **現状**: 21,000 tokens (47.8%)
- **削減**: 20,760 tokens
- **ROI**: **超高** - 単一 SKILL で 47% 削減

#### 2. Methodology Procedures
- **現状**: 9,000 tokens (20.5%)
- **削減**: 8,800 tokens
- **ROI**: **高** - 構造化された手順の統合

### 高優先度（重複削減）

#### 3. Code Examples
- **現状**: 4,000 tokens (9.1%)
- **削減**: 3,880 tokens
- **ROI**: **中高** - テンプレート再利用性向上

#### 4. Quality Gates
- **現状**: 720 tokens (1.6%)
- **削減**: 600 tokens
- **ROI**: **中** - 既存 SKILL に統合可能

### 中優先度（一部重複）

#### 5. Guiding Principles
- **現状**: 1,200 tokens (2.7%)
- **削減**: 1,000 tokens
- **ROI**: **低中** - 一貫性向上効果

---

## 依存関係マップ

```
┌─────────────────────────────────────────────────┐
│ vw-orchestrator (1,064 tokens)                  │
│ - フェーズ判定                                   │
│ - TodoWrite 管理                                 │
│ - Main Claude への指示                           │
└──────────┬──────────────────────────────────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐   ┌─────────┐
│ Group1  │   │ Group2  │
│ 並列実行  │   │ 直列実行  │
└────┬────┘   └────┬────┘
     │             │
  ┌──┴──┐          │
  ▼     ▼          ▼
┌────┐ ┌────┐  ┌────┐
│Expl│ │Anly│  │Dsgn│
│4.1k│ │5.8k│  │9.6k│
└────┘ └────┘  └────┘
  │     │        │
  │     │        ▼
  │     │    ┌────┐
  │     │    │Dev │ Group3 直列
  │     │    │17k │
  │     │    └─┬──┘
  │     │      │
  │     │   ┌──┴──┐
  │     │   │     │
  ▼     ▼   ▼     ▼
┌────┐ ┌────┐ ┌────┐
│Revw│ │QA  │ │Grp4│
│4.6k│ │1.5k│ │並列 │
└────┘ └────┘ └────┘

SKILL 統合後の依存:
├─ workflow-outputs/TEMPLATES.md (21k → 240)
├─ workflow-phases/METHODS.md (9k → 200)
├─ code-templates/EXAMPLES.md (4k → 120)
└─ quality-assurance/quality-gate-config.md (統合)

Progressive Disclosure:
各エージェントは SKILL 参照のみ含み、
実行時に必要な SKILL だけを読み込む
```

---

## 実装優先順序

### フェーズ 1: Output Templates（即効）
- **期間**: 1-2 日
- **削減**: 20,760 tokens (47.3%)
- **作業**:
  1. `.klaude/skills/workflow-outputs/` 作成
  2. SKILL.md + TEMPLATES.md 作成
  3. 6 エージェントから Output Structure 削除
  4. 参照行を追加

### フェーズ 2: Methodology Procedures（高効率）
- **期間**: 2-3 日
- **削減**: 8,800 tokens (20.0%)
- **作業**:
  1. `.klaude/skills/workflow-phases/` 作成
  2. SKILL.md + METHODS.md 作成
  3. 5 エージェントから Methodology 削除
  4. 参照行を追加

### フェーズ 3: Code Examples（中効率）
- **期間**: 1-2 日
- **削減**: 3,880 tokens (8.8%)
- **作業**:
  1. `.klaude/skills/code-templates/` 作成
  2. SKILL.md + EXAMPLES.md 作成
  3. 3 エージェントから Examples 削除
  4. 参照行を追加

### フェーズ 4: Quality Gates（既存統合）
- **期間**: 0.5 日
- **削減**: 600 tokens (1.4%)
- **作業**:
  1. `quality-assurance/references/quality-gate-config.md` に統合
  2. 3 エージェントから削除

### フェーズ 5: Guiding Principles（一貫性）
- **期間**: 1 日
- **削減**: 1,000 tokens (2.3%)
- **作業**:
  1. `.klaude/skills/workflow-principles/` 作成
  2. SKILL.md + PRINCIPLES.md 作成
  3. 6 エージェントから Principles 削除

---

## 累積効果

| フェーズ完了後 | 削減トークン | 累積削減 | 残存トークン | 削減率 |
|--------------|------------|----------|------------|--------|
| フェーズ 1 | 20,760 | 20,760 | 23,144 | 47.3% |
| フェーズ 2 | 8,800 | 29,560 | 14,344 | 67.3% |
| フェーズ 3 | 3,880 | 33,440 | 10,464 | 76.2% |
| フェーズ 4 | 600 | 34,040 | 9,864 | 77.5% |
| フェーズ 5 | 1,000 | 35,040 | 8,864 | 79.8% |
| **SKILL overhead** | -880 | 34,160 | 9,744 | 77.8% |

**最終効果**: 43,904 → 9,744 tokens（**77.8% 削減**）

---

## 結論

### トークン効率
- **最大削減**: vw-developer（15,280 tokens, 89.5%）
- **ROI 最高**: Output Templates（20,760 tokens, 47.3%）
- **総合削減**: 35,920 tokens（81.8%）

### 推奨アクション
1. **Output Templates** を最優先で作成（即効性）
2. **Methodology Procedures** を次に実装（高効率）
3. **Code Examples** で重複削減（中効率）

### 期待効果
- **コンテキスト効率**: 81.8% 向上
- **保守性**: 変更の局所化
- **拡張性**: 新エージェント追加の容易化
