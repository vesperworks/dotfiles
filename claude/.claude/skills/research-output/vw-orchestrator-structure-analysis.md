# vw-orchestrator 構造分析レポート

**分析日時**: 2025-12-10
**分析対象**: vw-orchestrator.md および関連 vw-* エージェント群
**分析目的**: 現状構造の詳細把握と SKILL 抽出候補の特定

---

## エグゼクティブサマリー

vw-orchestrator は 6 エージェント（Explorer → Analyst → Designer → Developer → Reviewer → Tester）を 5 フェーズで調整するデリゲーション専用オーケストレータです。自身では Task を実行せず、Main Claude に実行指示を出し、コンテキスト整備・TodoWrite 更新・成果統合に集中する設計です。

**主要な特徴**:
- **完全デリゲーション型**: 自分でサブエージェントを呼ばず、Main Claude に指示
- **並列実行最適化**: Group1（Explorer+Analyst）と Group4（Reviewer+Tester）で並列実行
- **引き算設計**: KISS/DRY/YAGNI 原則に基づく最小限の指示
- **PRP 統合**: PRP があれば活用する任意機能

**トークン消費推定**:
- vw-orchestrator: 約 230 行 → **約 920 トークン**
- 全 6 エージェント合計: 約 3,500 行 → **約 14,000 トークン**

---

## 1. vw-orchestrator.md 詳細分析

### 1.1 セクション構成とトークン推定

| セクション | 行範囲 | 行数 | 推定トークン | 内容 |
|----------|-------|------|------------|------|
| **Frontmatter** | 1-6 | 6 | ~24 | name, description, tools, model |
| **コア原則** | 10-15 | 6 | ~150 | 役割・禁止事項・並列化・言語・設計 |
| **フェーズ概要** | 17-22 | 6 | ~300 | 5 フェーズの最短説明 |
| **タスク担当と並列ポイント** | 24-29 | 6 | ~180 | 4 グループの担当と並列実行指定 |
| **フェーズ判定** | 31-34 | 4 | ~80 | context-*.json → プロンプト → Phase1 |
| **指示テンプレ** | 36-42 | 7 | ~120 | Parallel/Sequential 指示例と TodoWrite |
| **PRP 扱い** | 44-46 | 3 | ~40 | PRP 存在確認・要約・Validation Gates |
| **出力フォーマット** | 48-52 | 5 | ~80 | 4 項目の共通フォーマット |
| **アンチパターン** | 54-55 | 2 | ~40 | 避けるべき 4 パターン |
| **最終メッセージ** | 57 | 1 | ~50 | 引き算版ガイドの意図説明 |

**合計**: 58 行（空行・見出し除く） → **約 1,064 トークン**

---

### 1.2 プロンプト構造の特徴

#### 強み
1. **極限まで削ぎ落とされた設計**: KISS/DRY/YAGNI を徹底
2. **明確なデリゲーションモデル**: 「自分で Task を呼ばない」を厳守
3. **並列実行の明示**: Group1/4 で並列化して効率化
4. **フェーズ判定の優先順位**: context-*.json → プロンプト → Phase1

#### 改善余地
1. **指示テンプレの冗長性**: 日本語の例示が毎回読み込まれる
2. **PRP 統合ロジック**: 任意機能だが毎回プロンプトに含まれる
3. **出力フォーマット**: 4 項目のフォーマット説明が固定

---

## 2. 6 エージェント詳細分析

### 2.1 vw-explorer.md

| セクション | 行範囲 | 行数 | 推定トークン |
|----------|-------|------|------------|
| Frontmatter + Description | 1-7 | 7 | ~400 |
| Core Responsibilities | 9-17 | 9 | ~180 |
| Exploration Methodology (Phase 1-4) | 18-70 | 53 | ~2,120 |
| Output Structure | 71-124 | 54 | ~1,080 |
| Guiding Principles | 126-135 | 10 | ~200 |
| Special Considerations | 137-144 | 8 | ~160 |

**合計**: 145 行 → **約 4,140 トークン**

#### 重複・抽出候補
- **Exploration Methodology**: 4 フェーズの詳細手順（dependency-mapping-techniques.md に類似）
- **Output Structure**: マークダウンテンプレート（共通化可能）
- **Guiding Principles**: 汎用的な原則（SKILL に抽出可能）

---

### 2.2 vw-analyst.md

| セクション | 行範囲 | 行数 | 推定トークン |
|----------|-------|------|------------|
| Frontmatter + Description | 1-7 | 7 | ~400 |
| Core Responsibilities | 9-17 | 9 | ~180 |
| Analysis Methodology (Phase 1-4) | 18-71 | 54 | ~2,160 |
| Output Structure | 72-195 | 124 | ~2,480 |
| Guiding Principles | 197-206 | 10 | ~200 |
| Analysis Techniques | 208-226 | 19 | ~380 |

**合計**: 228 行 → **約 5,800 トークン**

#### 重複・抽出候補
- **Analysis Methodology**: 4 フェーズの手順（Explorer と類似構造）
- **Output Structure**: 超長大なマークダウンテンプレート（テンプレート化必須）
- **Risk Assessment Frameworks**: STRIDE 分析等（SKILL に抽出可能）

---

### 2.3 vw-designer.md

| セクション | 行範囲 | 行数 | 推定トークン |
|----------|-------|------|------------|
| Frontmatter + Description | 1-7 | 7 | ~400 |
| Core Responsibilities | 9-17 | 9 | ~180 |
| Design Methodology (Phase 1-4) | 18-71 | 54 | ~2,160 |
| Output Structure | 72-379 | 308 | **~6,160** |
| Guiding Principles | 381-390 | 10 | ~200 |
| Design Methodologies | 392-417 | 26 | ~520 |

**合計**: 418 行 → **約 9,620 トークン**

#### 重複・抽出候補
- **Output Structure**: **超巨大テンプレート（308 行）**、最大の抽出候補
- **Design Patterns**: SOLID/DDD/C4 Model（solid-principles.md に類似）
- **OpenAPI/SQL スキーマ**: コード例テンプレート（TEMPLATES.md に抽出可能）

---

### 2.4 vw-developer.md

| セクション | 行範囲 | 行数 | 推定トークン |
|----------|-------|------|------------|
| Frontmatter + Description | 1-7 | 7 | ~400 |
| Core Responsibilities | 9-17 | 9 | ~180 |
| TDD Implementation Methodology | 18-65 | 48 | ~1,920 |
| Development Process (Step 1-4) | 66-151 | 86 | **~3,440** |
| Output Structure | 152-653 | 502 | **~10,040** |
| Guiding Principles | 655-665 | 11 | ~220 |
| TDD Best Practices | 667-685 | 19 | ~380 |
| Quality Assurance Framework | 687-705 | 19 | ~380 |
| ロールバック手順 | 708-713 | 6 | ~120 |

**合計**: 707 行 → **約 17,080 トークン**

#### 重複・抽出候補
- **Output Structure**: **超巨大（502 行）**、Designer と同等の最大候補
- **TDD Cycle**: Red-Green-Refactor（red-green-refactor.md に類似）
- **Code Examples**: JavaScript/TypeScript/Dockerfile 例（TEMPLATES.md に抽出可能）
- **Quality Standards**: Lint/Format/Test/Build（quality-gate-config.md に類似）

---

### 2.5 vw-reviewer.md

| セクション | 行範囲 | 行数 | 推定トークン |
|----------|-------|------|------------|
| Frontmatter + Description | 1-7 | 7 | ~400 |
| Core Responsibilities | 9-22 | 14 | ~280 |
| Review Methodology (Phase 1-5) | 23-78 | 56 | ~2,240 |
| Output Structure | 80-139 | 60 | ~1,200 |
| ロールバック手順 | 141-145 | 5 | ~100 |
| Guiding Principles | 147-156 | 10 | ~200 |
| Critical Quality Gates | 158-168 | 11 | ~220 |

**合計**: 170 行 → **約 4,640 トークン**

#### 重複・抽出候補
- **Review Methodology**: 5 フェーズの手順（共通化可能）
- **Quality Gates**: Lint/Format/Test/Build（quality-gate-config.md に完全一致）
- **CLAUDE.md Standards**: セキュリティ・パフォーマンス・エラーハンドリング（重複）

---

### 2.6 vw-qa-tester.md

| セクション | 行範囲 | 行数 | 推定トークン |
|----------|-------|------|------------|
| Frontmatter + Description | 1-7 | 7 | ~400 |
| Playwright MCP Policy | 11-19 | 9 | ~180 |
| Core Responsibilities | 21-26 | 6 | ~120 |
| Testing Workflow | 28-43 | 16 | ~320 |
| Reporting Standards | 45-49 | 5 | ~100 |
| Error Handling Protocol | 51-59 | 9 | ~180 |
| Quality Standards | 61-66 | 6 | ~120 |
| Communication Style | 68-73 | 6 | ~120 |
| Goal Statement | 75 | 1 | ~20 |

**合計**: 76 行 → **約 1,560 トークン**

#### 重複・抽出候補
- **Playwright MCP Policy**: 重要な制約だが毎回読み込み不要
- **Testing Workflow**: 5 ステップの手順（SKILL に抽出可能）
- **Quality Standards**: Reviewer と重複

---

## 3. エージェント間の依存関係

### 3.1 実行フロー

```
vw-orchestrator (Phase 判定・TodoWrite 管理)
       │
       ├─ Phase1: Group1 並列
       │   ├─ vw-explorer (コードベース探索)
       │   └─ vw-analyst (影響分析・リスク評価)
       │
       ├─ Phase2: Group2 直列
       │   └─ vw-designer (設計確定・IF 定義)
       │
       ├─ Phase3: Group3 直列
       │   └─ vw-developer (TDD 実装・ユニットテスト)
       │
       ├─ Phase4: Group4 並列
       │   ├─ vw-reviewer (静的レビュー・品質ゲート)
       │   └─ vw-qa-tester (動的検証・E2E テスト)
       │
       └─ Phase5: Orchestrator のみ（統合・ゲート評価・最終レポート）
```

### 3.2 データフロー

- **Explorer → Analyst**: コードベース探索結果を影響分析に利用
- **Analyst → Designer**: リスク評価・依存関係を設計に反映
- **Designer → Developer**: 設計仕様を実装に渡す
- **Developer → Reviewer/Tester**: 実装コードを並列でレビュー・テスト

### 3.3 共通保存先

全エージェントが `.brain/vw/{timestamp}-{role}.md` に成果物を保存

---

## 4. トークン消費の内訳

### 4.1 エージェント別トークン推定

| エージェント | 行数 | 推定トークン | 比率 |
|------------|------|------------|------|
| vw-orchestrator | 58 | 1,064 | 2.4% |
| vw-explorer | 145 | 4,140 | 9.4% |
| vw-analyst | 228 | 5,800 | 13.2% |
| vw-designer | 418 | **9,620** | **21.9%** |
| vw-developer | 707 | **17,080** | **38.8%** |
| vw-reviewer | 170 | 4,640 | 10.6% |
| vw-qa-tester | 76 | 1,560 | 3.5% |
| **合計** | **1,802** | **43,904** | **100%** |

**重要**: Developer と Designer だけで **60.7%** を占める

### 4.2 セクション別トークン消費

| セクション種別 | 推定トークン | 比率 | 抽出可能性 |
|--------------|------------|------|----------|
| **Output Structure (テンプレート)** | ~21,000 | 47.8% | **超高** |
| **Methodology (手順)** | ~9,000 | 20.5% | **高** |
| **Guiding Principles** | ~1,200 | 2.7% | 中 |
| **Code Examples** | ~4,000 | 9.1% | **高** |
| **Frontmatter/Description** | ~2,800 | 6.4% | 低 |
| **その他** | ~5,904 | 13.5% | 低 |

**重要**: Output Structure だけで **約 47.8%**

---

## 5. SKILL 抽出候補の特定

### 5.1 超高優先度（即効性大）

#### A. Output Templates（~21,000 トークン削減）

**対象**:
- vw-explorer.md: Output Structure（54 行, ~1,080 トークン）
- vw-analyst.md: Output Structure（124 行, ~2,480 トークン）
- vw-designer.md: Output Structure（308 行, **~6,160 トークン**）
- vw-developer.md: Output Structure（502 行, **~10,040 トークン**）
- vw-reviewer.md: Output Structure（60 行, ~1,200 トークン）

**抽出方法**:
```
.klaude/skills/workflow-outputs/
├── SKILL.md (参照メタデータのみ)
├── TEMPLATES.md (全テンプレート統合)
├── templates/
│   ├── explorer-report.md
│   ├── analyst-report.md
│   ├── designer-spec.md
│   ├── developer-report.md
│   └── reviewer-report.md
```

**効果**: 各エージェントは「詳細は SKILL.md → TEMPLATES.md を参照」で済む

---

#### B. Methodology Procedures（~9,000 トークン削減）

**対象**:
- vw-explorer: 4 Phase Methodology（53 行, ~2,120 トークン）
- vw-analyst: 4 Phase Methodology（54 行, ~2,160 トークン）
- vw-designer: 4 Phase Methodology（54 行, ~2,160 トークン）
- vw-developer: TDD Process（86 行, ~3,440 トークン）
- vw-reviewer: 5 Phase Methodology（56 行, ~2,240 トークン）

**抽出方法**:
```
.klaude/skills/workflow-phases/
├── SKILL.md (Progressive Disclosure)
├── METHODS.md
│   ├── exploration-phases.md
│   ├── analysis-phases.md
│   ├── design-phases.md
│   ├── tdd-phases.md
│   └── review-phases.md
```

**効果**: 「詳細手順は SKILL.md → METHODS.md 参照」

---

### 5.2 高優先度（重複削減）

#### C. Code Examples（~4,000 トークン削減）

**対象**:
- vw-designer: OpenAPI/SQL スキーマ例（~1,200 トークン）
- vw-developer: JavaScript/TypeScript/Docker 例（~2,400 トークン）
- vw-reviewer: Bash コマンド例（~400 トークン）

**抽出方法**:
```
.klaude/skills/code-templates/
├── SKILL.md
├── EXAMPLES.md
│   ├── api-specs/ (OpenAPI, GraphQL)
│   ├── database/ (SQL, NoSQL)
│   ├── testing/ (Jest, Pytest, Cargo)
│   └── deployment/ (Docker, CI/CD)
```

---

#### D. Quality Gates（重複削減）

**対象**:
- vw-developer: Quality Gates（19 行, ~380 トークン）
- vw-reviewer: Quality Gates（11 行, ~220 トークン）
- vw-qa-tester: Quality Standards（6 行, ~120 トークン）

**抽出方法**:
既存の `quality-assurance/references/quality-gate-config.md` に統合

---

### 5.3 中優先度（一部重複）

#### E. Guiding Principles（~1,200 トークン削減）

**対象**:
- 全 6 エージェントに類似の Guiding Principles セクション

**抽出方法**:
```
.klaude/skills/workflow-principles/
├── SKILL.md
└── PRINCIPLES.md
    ├── exploration-principles.md
    ├── analysis-principles.md
    ├── design-principles.md
    └── tdd-principles.md
```

---

## 6. 現状構造の課題

### 6.1 トークン効率

1. **Output Structure の巨大化**: Developer と Designer だけで ~16,200 トークン
2. **Methodology の重複**: 各エージェントが独自の Phase 構造を持つ
3. **Code Examples の冗長性**: 類似例が複数エージェントに散在

### 6.2 保守性

1. **テンプレート変更の波及**: Output Structure 変更が 6 エージェントに影響
2. **手順の不整合リスク**: Methodology が各エージェントで微妙に異なる
3. **原則の一貫性**: Guiding Principles が統一されていない

### 6.3 拡張性

1. **新エージェント追加コスト**: 同じ構造を毎回記述
2. **共通ロジックの分離不足**: PRP 統合・フェーズ判定等が固定

---

## 7. SKILL 抽出による期待効果

### 7.1 トークン削減効果

| SKILL 抽出 | 削減トークン | 削減率 |
|-----------|------------|--------|
| Output Templates | ~21,000 | 47.8% |
| Methodology Procedures | ~9,000 | 20.5% |
| Code Examples | ~4,000 | 9.1% |
| Quality Gates | ~720 | 1.6% |
| Guiding Principles | ~1,200 | 2.7% |
| **合計** | **~35,920** | **81.8%** |

**残存トークン**: ~7,984 トークン（18.2%）

---

### 7.2 保守性向上

1. **単一責任**: 各 SKILL が特定の知識を管理
2. **変更の局所化**: テンプレート変更は SKILL 内のみ
3. **バージョン管理**: SKILL 単位で変更履歴を追跡

---

### 7.3 拡張性向上

1. **新エージェント追加**: 既存 SKILL を参照するだけ
2. **Progressive Disclosure**: 必要な時だけ詳細を読み込み
3. **SubAgent パターン**: PRP-orchestrator 同様の構造

---

## 8. 推奨アクション

### Phase 1: 超高優先度（即効性大）

1. **Output Templates SKILL 作成**
   - `.klaude/skills/workflow-outputs/` を作成
   - 6 エージェントのテンプレートを統合
   - 各エージェントから Output Structure を削除
   - **削減効果**: ~21,000 トークン（47.8%）

2. **Methodology Procedures SKILL 作成**
   - `.klaude/skills/workflow-phases/` を作成
   - 各エージェントの Phase 構造を統合
   - 各エージェントから Methodology を削除
   - **削減効果**: ~9,000 トークン（20.5%）

### Phase 2: 高優先度（重複削減）

3. **Code Examples SKILL 作成**
   - `.klaude/skills/code-templates/` を作成
   - OpenAPI/SQL/Jest/Docker 例を統合
   - **削減効果**: ~4,000 トークン（9.1%）

4. **Quality Gates 統合**
   - `quality-assurance/references/quality-gate-config.md` に統合
   - **削減効果**: ~720 トークン（1.6%）

### Phase 3: 中優先度（一部重複）

5. **Guiding Principles SKILL 作成**
   - `.klaude/skills/workflow-principles/` を作成
   - **削減効果**: ~1,200 トークン（2.7%）

### 検証フェーズ

6. **動作検証**
   - 実際に vw-orchestrator を実行
   - Progressive Disclosure が正常に動作するか確認
   - トークン消費を測定

---

## 9. 結論

vw-orchestrator と 6 エージェントは、以下の特徴を持つ：

### 強み
- **完全デリゲーション型**: Main Claude への指示に特化
- **並列実行最適化**: Group1/4 で効率化
- **引き算設計**: KISS/DRY/YAGNI 徹底

### 課題
- **トークン消費**: 合計 ~43,904 トークン
- **Output Structure の巨大化**: Developer/Designer で 60.7%
- **Methodology の重複**: 各エージェントが独自の Phase 構造

### SKILL 抽出による改善効果
- **81.8% のトークン削減**（~35,920 トークン）
- **保守性向上**: 変更の局所化
- **拡張性向上**: 新エージェント追加の容易化

### 推奨アクション
1. **Output Templates SKILL**: 最優先（47.8% 削減）
2. **Methodology Procedures SKILL**: 次優先（20.5% 削減）
3. **Code Examples SKILL**: 高優先（9.1% 削減）

---

**次のステップ**: Phase 1 の Output Templates SKILL 作成を開始
