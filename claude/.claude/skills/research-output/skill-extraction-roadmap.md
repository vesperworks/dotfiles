# SKILL 抽出ロードマップ

**目的**: vw-* エージェント群のトークン消費を 81.8% 削減（43,904 → 7,984 tokens）

---

## フェーズ 1: Output Templates SKILL（超高優先度）

### 目標
- **削減トークン**: 20,760 tokens (47.3%)
- **期間**: 1-2 日
- **ROI**: 超高

### 作成する SKILL 構造

```
.klaude/skills/workflow-outputs/
├── SKILL.md (Progressive Disclosure メタデータ)
├── TEMPLATES.md (全テンプレート統合)
└── templates/
    ├── explorer-report.md
    ├── analyst-report.md
    ├── designer-spec.md
    ├── developer-report.md
    ├── reviewer-report.md
    └── qa-tester-report.md
```

### 抽出対象セクション

#### 1. vw-explorer.md
**行範囲**: 71-124 (54 行, ~1,080 tokens)
**セクション**: `## Output Structure`
**抽出内容**:
```markdown
# Codebase Exploration Report

## Executive Summary
- Project overview and purpose
- Key findings and recommendations
- Critical observations and concerns

## Technology Stack Analysis
...
```

**置き換え後**:
```markdown
## Output Structure

For detailed output format, see: `.klaude/skills/workflow-outputs/templates/explorer-report.md`

Save results to: `./.brain/vw/{timestamp}-explorer.md`
```

---

#### 2. vw-analyst.md
**行範囲**: 72-195 (124 行, ~2,480 tokens)
**セクション**: `## Output Structure`
**抽出内容**:
```markdown
# Impact Analysis and Risk Assessment Report

## Executive Summary
- High-level impact overview
- Critical risks and mitigation priorities
- Implementation complexity assessment
- Strategic recommendations

## Dependency Impact Analysis
### Direct Dependencies
...
```

**置き換え後**:
```markdown
## Output Structure

For detailed output format, see: `.klaude/skills/workflow-outputs/templates/analyst-report.md`

Save results to: `./.brain/vw/{timestamp}-analyst.md`
```

---

#### 3. vw-designer.md ⭐ 最大削減対象
**行範囲**: 72-379 (308 行, **~6,160 tokens**)
**セクション**: `## Output Structure`
**抽出内容**:
```markdown
# System Architecture Design Specification

## Executive Summary
- High-level architecture overview
- Key design decisions and rationale
- Technology stack recommendations
- Implementation priorities and phases

## System Architecture
### Overall Architecture
...

## Interface Specifications
### API Design
#### REST API Endpoints
```yaml
openapi: 3.0.0
...
```

#### Event-Driven Interfaces
...

### Data Models
#### Entity-Relationship Design
```sql
CREATE TABLE [entity_name] (
...
```

## Component Design
...

[massive template continues for 308 lines]
```

**置き換え後**:
```markdown
## Output Structure

For detailed output format, see: `.klaude/skills/workflow-outputs/templates/designer-spec.md`

Save results to: `./.brain/vw/{timestamp}-designer.md`

Key sections include:
- System Architecture (Overall, Service, Data)
- Interface Specifications (REST API, Events, Data Models)
- Component Design (Core, Infrastructure)
- Test Strategy Design
- Security Design
- Performance and Scalability Design
- Implementation Guidelines
```

---

#### 4. vw-developer.md ⭐ 最大削減対象
**行範囲**: 152-653 (502 行, **~10,040 tokens**)
**セクション**: `## Output Structure`
**抽出内容**:
```markdown
# TDD Implementation Report

## Executive Summary
- Feature/component implemented
- Test coverage statistics
- Quality gate results
- Key technical decisions and rationale

## Implementation Overview
### Components Implemented
...

## TDD Cycle Implementation
### Red Phase: Test Creation
#### Unit Tests
```[language]
describe('[Component]', () => {
...
```

#### Integration Tests
...

### Green Phase: Implementation
#### Core Implementation
```[language]
class [ClassName] {
...
```

## Test Results and Coverage
...

[massive template continues for 502 lines]
```

**置き換え後**:
```markdown
## Output Structure

For detailed output format, see: `.klaude/skills/workflow-outputs/templates/developer-report.md`

Save results to: `./.brain/vw/{timestamp}-developer.md`

Key sections include:
- TDD Cycle Implementation (Red, Green, Refactor phases)
- Test Results and Coverage
- Quality Gates Results
- Implementation Details
- API Documentation
- Database Implementation
- Configuration and Environment
- Deployment and Operations
```

---

#### 5. vw-reviewer.md
**行範囲**: 80-139 (60 行, ~1,200 tokens)
**セクション**: `## Output Structure`
**抽出内容**:
```markdown
# Final Quality Review Report

## Implementation Summary
- Task: [Original task description]
- Implementation Status: [COMPLETE/INCOMPLETE/NEEDS_IMPROVEMENTS]
- Quality Gate Status: [PASSED/FAILED]

## Quality Gate Results
### Lint Check: [✅ PASSED / ❌ FAILED]
...
```

**置き換え後**:
```markdown
## Output Structure

For detailed output format, see: `.klaude/skills/workflow-outputs/templates/reviewer-report.md`

Save results to: `./.brain/vw/{timestamp}-reviewer.md`
```

---

#### 6. vw-qa-tester.md
**行範囲**: なし（Output Structure セクションなし）
**アクション**: qa-tester-report.md テンプレートを新規作成

---

### SKILL.md の内容

```markdown
---
name: workflow-outputs
description: Standard output templates for all vw-* workflow agents (Explorer, Analyst, Designer, Developer, Reviewer, QA-Tester). Provides consistent reporting formats with Progressive Disclosure pattern.
---

# Workflow Output Templates

## Purpose

Centralized repository of output templates used by vw-* workflow agents to ensure consistent documentation structure and reduce token consumption.

## Usage

Each workflow agent references the appropriate template:

### vw-explorer
```markdown
See: `.klaude/skills/workflow-outputs/templates/explorer-report.md`
Save to: `./.brain/vw/{timestamp}-explorer.md`
```

### vw-analyst
```markdown
See: `.klaude/skills/workflow-outputs/templates/analyst-report.md`
Save to: `./.brain/vw/{timestamp}-analyst.md`
```

### vw-designer
```markdown
See: `.klaude/skills/workflow-outputs/templates/designer-spec.md`
Save to: `./.brain/vw/{timestamp}-designer.md`
```

### vw-developer
```markdown
See: `.klaude/skills/workflow-outputs/templates/developer-report.md`
Save to: `./.brain/vw/{timestamp}-developer.md`
```

### vw-reviewer
```markdown
See: `.klaude/skills/workflow-outputs/templates/reviewer-report.md`
Save to: `./.brain/vw/{timestamp}-reviewer.md`
```

### vw-qa-tester
```markdown
See: `.klaude/skills/workflow-outputs/templates/qa-tester-report.md`
Save to: `./.brain/vw/{timestamp}-qa-tester.md`
```

## Progressive Disclosure

Templates are only loaded when an agent needs to generate output. Agents include only a single-line reference in their prompt, reducing baseline token consumption by ~21,000 tokens (47.3%).

## Template Index

For complete templates, see:
- [TEMPLATES.md](./TEMPLATES.md) - All templates in one file
- [templates/](./templates/) - Individual template files
```

---

## フェーズ 2: Methodology Procedures SKILL（高優先度）

### 目標
- **削減トークン**: 8,800 tokens (20.0%)
- **期間**: 2-3 日
- **ROI**: 高

### 作成する SKILL 構造

```
.klaude/skills/workflow-phases/
├── SKILL.md (Progressive Disclosure メタデータ)
├── METHODS.md (全手順の統合インデックス)
└── methods/
    ├── exploration-4phases.md
    ├── analysis-4phases.md
    ├── design-4phases.md
    ├── tdd-process.md
    └── review-5phases.md
```

### 抽出対象セクション

#### 1. vw-explorer.md
**行範囲**: 18-70 (53 行, ~2,120 tokens)
**セクション**: `## Exploration Methodology`
**抽出内容**:
```markdown
### Phase 1: Initial Discovery
1. **Project Structure Analysis**: Examine directory structure, configuration files, and entry points
   - Review package.json, requirements.txt, Cargo.toml, or equivalent dependency files
   - Identify main application entry points and configuration patterns
   - Map directory structure and understand project organization

2. **Technology Stack Identification**: Document all technologies and frameworks in use
   - Programming languages and versions
   - Frameworks and libraries with versions
   - Development tools and build systems
   - Database systems and external services

### Phase 2: Code Pattern Investigation
...

### Phase 3: Dependency Mapping
...

### Phase 4: Requirement Synthesis
...
```

**置き換え後**:
```markdown
## Exploration Methodology

Follow the 4-phase exploration process detailed in: `.klaude/skills/workflow-phases/methods/exploration-4phases.md`

**Quick Reference**:
- Phase 1: Initial Discovery (Project Structure, Tech Stack)
- Phase 2: Code Pattern Investigation (Architecture, Implementation Style)
- Phase 3: Dependency Mapping (Module Relationships, Impact Zones)
- Phase 4: Requirement Synthesis (Functional Requirements, Technical Constraints)
```

---

#### 2. vw-analyst.md
**行範囲**: 18-71 (54 行, ~2,160 tokens)
**セクション**: `## Analysis Methodology`
**抽出内容**:
```markdown
### Phase 1: Dependency Mapping
1. **Module Relationship Analysis**: Create comprehensive dependency graphs
   - Direct dependencies and their impact radius
   - Transitive dependencies and cascade effects
   - Circular dependencies and potential conflicts
   - External service dependencies and integration points

2. **Data Flow Impact Assessment**: Analyze how changes affect data processing
   - Database schema modifications and migration requirements
   - API contract changes and versioning needs
   - Message format changes and serialization impacts
   - Cache invalidation and data consistency requirements

### Phase 2: Risk Matrix Construction
...

### Phase 3: Complexity Assessment
...

### Phase 4: Strategic Planning
...
```

**置き換え後**:
```markdown
## Analysis Methodology

Follow the 4-phase analysis process detailed in: `.klaude/skills/workflow-phases/methods/analysis-4phases.md`

**Quick Reference**:
- Phase 1: Dependency Mapping (Module Relationships, Data Flow Impact)
- Phase 2: Risk Matrix Construction (Risk Identification, Quantification)
- Phase 3: Complexity Assessment (Implementation Complexity, Integration Complexity)
- Phase 4: Strategic Planning (Phased Implementation, Resource Estimation)
```

---

#### 3. vw-designer.md
**行範囲**: 18-71 (54 行, ~2,160 tokens)
**セクション**: `## Design Methodology`
**抽出内容**:
```markdown
### Phase 1: Architecture Foundation
1. **System Decomposition**: Break down complex systems into manageable components
   - Service boundary identification and definition
   - Component responsibility allocation
   - Dependency minimization and decoupling strategies
   - Cross-cutting concern identification and handling

2. **Layered Architecture Design**: Establish clear architectural layers
   - Presentation layer design and patterns
   - Business logic layer organization
   - Data access layer abstraction
   - Infrastructure layer separation

### Phase 2: Interface Specification
...

### Phase 3: Data Architecture
...

### Phase 4: Quality Assurance Design
...
```

**置き換え後**:
```markdown
## Design Methodology

Follow the 4-phase design process detailed in: `.klaude/skills/workflow-phases/methods/design-4phases.md`

**Quick Reference**:
- Phase 1: Architecture Foundation (System Decomposition, Layered Architecture)
- Phase 2: Interface Specification (API Design, Data Contracts)
- Phase 3: Data Architecture (Database Design, Data Flow)
- Phase 4: Quality Assurance Design (Testing Architecture, Monitoring)
```

---

#### 4. vw-developer.md
**行範囲**: 66-151 (86 行, ~3,440 tokens)
**セクション**: `## Development Process`
**抽出内容**:
```markdown
### Step 1: Design Specification Analysis
- Review vw-designer specifications and requirements
- Identify all interfaces, data models, and business logic components
- Plan implementation phases and testing strategies
- Establish quality gates and acceptance criteria

### Step 2: Test Creation (Red Phase)
```javascript
// Example: User Authentication Service Tests
describe('UserAuthenticationService', () => {
  describe('authenticateUser', () => {
    it('should return valid token for correct credentials', async () => {
      // Arrange
      const userCredentials = { email: 'user@example.com', password: 'validPassword' };
      const mockUser = { id: 1, email: 'user@example.com', hashedPassword: 'hashedValue' };

      // Act & Assert (initially failing)
      expect(false).toBe(true); // RED: Intentionally failing test
    });
    ...
  });
});
```

### Step 3: Implementation (Green Phase)
```javascript
// Example: Minimal Implementation to Pass Tests
class UserAuthenticationService {
  constructor(userRepository, tokenService, rateLimiter) {
    this.userRepository = userRepository;
    this.tokenService = tokenService;
    this.rateLimiter = rateLimiter;
  }
  ...
}
```

### Step 4: Quality Assurance and Refactoring
...
```

**置き換え後**:
```markdown
## Development Process

Follow the TDD process detailed in: `.klaude/skills/workflow-phases/methods/tdd-process.md`

**Quick Reference**:
- Step 1: Design Specification Analysis
- Step 2: Test Creation (Red Phase) - Write failing tests first
- Step 3: Implementation (Green Phase) - Minimal code to pass tests
- Step 4: Quality Assurance and Refactoring

For detailed code examples and patterns, also see:
- `.klaude/skills/tdd-implementation/references/red-green-refactor.md`
- `.klaude/skills/tdd-implementation/references/test-patterns.md`
```

---

#### 5. vw-reviewer.md
**行範囲**: 23-78 (56 行, ~2,240 tokens)
**セクション**: `## Review Methodology`
**抽出内容**:
```markdown
### Phase 1: Pre-Review Preparation
- Read and analyze the task requirements and implementation scope
- Review previous workflow outputs from vw-explorer, vw-analyst, vw-designer, and vw-developer
- Identify the project type and applicable quality check commands
- Establish review criteria based on CLAUDE.md standards

### Phase 2: Code Quality Assessment
- Perform comprehensive code review against CLAUDE.md standards:
  - **可読性・保守性**: Variable names, function responsibility, nesting levels, comments
  - **セキュリティ**: Input validation, SQL injection prevention, sensitive data management
  - **パフォーマンス**: Database queries, memory management, pagination
  - **エラーハンドリング**: API error handling, user-friendly messages, logging
- Check integration points and system consistency
- Validate documentation and code comments

### Phase 3: Mandatory Quality Checks
...

### Phase 4: Integration and Completion Validation
...

### Phase 5: Report Generation and Recommendations
...
```

**置き換え後**:
```markdown
## Review Methodology

Follow the 5-phase review process detailed in: `.klaude/skills/workflow-phases/methods/review-5phases.md`

**Quick Reference**:
- Phase 1: Pre-Review Preparation
- Phase 2: Code Quality Assessment (CLAUDE.md standards)
- Phase 3: Mandatory Quality Checks (Lint → Format → Test → Build)
- Phase 4: Integration and Completion Validation
- Phase 5: Report Generation and Recommendations

For quality gate details, see: `.klaude/skills/quality-assurance/references/quality-gate-config.md`
```

---

### SKILL.md の内容

```markdown
---
name: workflow-phases
description: Standard methodology and phase structures for all vw-* workflow agents. Provides systematic procedures for exploration, analysis, design, development, and review with Progressive Disclosure pattern.
---

# Workflow Phase Methodologies

## Purpose

Centralized repository of systematic methodologies used by vw-* workflow agents to ensure consistent process execution and reduce token consumption.

## Usage

Each workflow agent references the appropriate methodology:

### vw-explorer: 4-Phase Exploration
```markdown
See: `.klaude/skills/workflow-phases/methods/exploration-4phases.md`
Phases: Initial Discovery → Code Pattern Investigation → Dependency Mapping → Requirement Synthesis
```

### vw-analyst: 4-Phase Analysis
```markdown
See: `.klaude/skills/workflow-phases/methods/analysis-4phases.md`
Phases: Dependency Mapping → Risk Matrix Construction → Complexity Assessment → Strategic Planning
```

### vw-designer: 4-Phase Design
```markdown
See: `.klaude/skills/workflow-phases/methods/design-4phases.md`
Phases: Architecture Foundation → Interface Specification → Data Architecture → QA Design
```

### vw-developer: TDD Process
```markdown
See: `.klaude/skills/workflow-phases/methods/tdd-process.md`
Steps: Design Analysis → Test Creation (Red) → Implementation (Green) → Refactoring
```

### vw-reviewer: 5-Phase Review
```markdown
See: `.klaude/skills/workflow-phases/methods/review-5phases.md`
Phases: Pre-Review → Code Quality → Quality Checks → Integration Validation → Report Generation
```

## Progressive Disclosure

Methodologies are only loaded when an agent needs detailed process guidance. Agents include only quick-reference summaries in their prompt, reducing baseline token consumption by ~8,800 tokens (20.0%).

## Methodology Index

For complete methodologies, see:
- [METHODS.md](./METHODS.md) - All methodologies in one file
- [methods/](./methods/) - Individual methodology files
```

---

## フェーズ 3: Code Examples SKILL（中高優先度）

### 目標
- **削減トークン**: 3,880 tokens (8.8%)
- **期間**: 1-2 日
- **ROI**: 中高

### 作成する SKILL 構造

```
.klaude/skills/code-templates/
├── SKILL.md (Progressive Disclosure メタデータ)
├── EXAMPLES.md (全例の統合インデックス)
└── examples/
    ├── api-specs/
    │   ├── openapi-rest.yaml
    │   ├── graphql-schema.graphql
    │   └── grpc-proto.proto
    ├── database/
    │   ├── sql-schema.sql
    │   ├── nosql-schema.md
    │   └── migration-template.sql
    ├── testing/
    │   ├── jest-unit.test.js
    │   ├── pytest-unit.py
    │   ├── cargo-test.rs
    │   └── integration-test.md
    └── deployment/
        ├── dockerfile
        ├── docker-compose.yml
        ├── github-actions.yml
        └── kubernetes-deployment.yaml
```

### 抽出対象セクション

#### 1. vw-designer.md
**抽出対象**:
- OpenAPI 仕様例（行 109-138, ~580 tokens）
- SQL スキーマ例（行 149-161, ~260 tokens）
- NoSQL スキーマ例（行 163-167, ~100 tokens）
- 合計: ~940 tokens

#### 2. vw-developer.md
**抽出対象**:
- Jest テスト例（行 74-101, ~540 tokens）
- 実装クラス例（行 106-143, ~740 tokens）
- Dockerfile 例（行 498-510, ~260 tokens）
- GitHub Actions 例（行 474-494, ~420 tokens）
- Health Check 例（行 514-534, ~420 tokens）
- 合計: ~2,380 tokens

#### 3. vw-reviewer.md
**抽出対象**:
- Bash コマンド例（行 43-65, ~440 tokens）

---

## フェーズ 4: Quality Gates 統合（既存 SKILL 活用）

### 目標
- **削減トークン**: 600 tokens (1.4%)
- **期間**: 0.5 日
- **ROI**: 中

### 統合先

既存の `.klaude/skills/quality-assurance/references/quality-gate-config.md` に統合

### 抽出対象セクション

#### 1. vw-developer.md
**行範囲**: 299-314 (16 行, ~320 tokens)
**セクション**: `## Quality Gates Results`

#### 2. vw-reviewer.md
**行範囲**: 43-65 (23 行, ~460 tokens)
**セクション**: `### Phase 3: Mandatory Quality Checks`

#### 3. vw-qa-tester.md
**行範囲**: 61-66 (6 行, ~120 tokens)
**セクション**: `**Quality Standards**`

---

## フェーズ 5: Guiding Principles SKILL（中優先度）

### 目標
- **削減トークン**: 1,000 tokens (2.3%)
- **期間**: 1 日
- **ROI**: 低中

### 作成する SKILL 構造

```
.klaude/skills/workflow-principles/
├── SKILL.md (Progressive Disclosure メタデータ)
├── PRINCIPLES.md (全原則の統合)
└── principles/
    ├── exploration-principles.md
    ├── analysis-principles.md
    ├── design-principles.md
    ├── tdd-principles.md
    └── review-principles.md
```

### 抽出対象セクション

各エージェントの `## Guiding Principles` セクション（各 10-11 行, ~200 tokens）を統合

---

## 実装チェックリスト

### フェーズ 1: Output Templates
- [ ] `.klaude/skills/workflow-outputs/` ディレクトリ作成
- [ ] `SKILL.md` 作成（Progressive Disclosure メタデータ）
- [ ] `TEMPLATES.md` 作成（全テンプレート統合）
- [ ] `templates/explorer-report.md` 作成
- [ ] `templates/analyst-report.md` 作成
- [ ] `templates/designer-spec.md` 作成（最大 6,160 tokens）
- [ ] `templates/developer-report.md` 作成（最大 10,040 tokens）
- [ ] `templates/reviewer-report.md` 作成
- [ ] `templates/qa-tester-report.md` 作成
- [ ] vw-explorer.md の Output Structure セクション削除 & 参照追加
- [ ] vw-analyst.md の Output Structure セクション削除 & 参照追加
- [ ] vw-designer.md の Output Structure セクション削除 & 参照追加
- [ ] vw-developer.md の Output Structure セクション削除 & 参照追加
- [ ] vw-reviewer.md の Output Structure セクション削除 & 参照追加
- [ ] 動作検証（実際に vw-orchestrator 実行）
- [ ] トークン消費測定

### フェーズ 2: Methodology Procedures
- [ ] `.klaude/skills/workflow-phases/` ディレクトリ作成
- [ ] `SKILL.md` 作成
- [ ] `METHODS.md` 作成
- [ ] `methods/exploration-4phases.md` 作成
- [ ] `methods/analysis-4phases.md` 作成
- [ ] `methods/design-4phases.md` 作成
- [ ] `methods/tdd-process.md` 作成
- [ ] `methods/review-5phases.md` 作成
- [ ] vw-explorer.md の Methodology セクション削除 & 参照追加
- [ ] vw-analyst.md の Methodology セクション削除 & 参照追加
- [ ] vw-designer.md の Methodology セクション削除 & 参照追加
- [ ] vw-developer.md の Development Process セクション削除 & 参照追加
- [ ] vw-reviewer.md の Methodology セクション削除 & 参照追加
- [ ] 動作検証
- [ ] トークン消費測定

### フェーズ 3: Code Examples
- [ ] `.klaude/skills/code-templates/` ディレクトリ作成
- [ ] `SKILL.md` 作成
- [ ] `EXAMPLES.md` 作成
- [ ] `examples/api-specs/` 作成
- [ ] `examples/database/` 作成
- [ ] `examples/testing/` 作成
- [ ] `examples/deployment/` 作成
- [ ] vw-designer.md のコード例削除 & 参照追加
- [ ] vw-developer.md のコード例削除 & 参照追加
- [ ] vw-reviewer.md のコード例削除 & 参照追加
- [ ] 動作検証
- [ ] トークン消費測定

### フェーズ 4: Quality Gates
- [ ] `quality-assurance/references/quality-gate-config.md` 更新
- [ ] vw-developer.md の Quality Gates 削除 & 参照追加
- [ ] vw-reviewer.md の Quality Checks 削除 & 参照追加
- [ ] vw-qa-tester.md の Quality Standards 削除 & 参照追加
- [ ] 動作検証

### フェーズ 5: Guiding Principles
- [ ] `.klaude/skills/workflow-principles/` ディレクトリ作成
- [ ] `SKILL.md` 作成
- [ ] `PRINCIPLES.md` 作成
- [ ] 全エージェントの Guiding Principles 削除 & 参照追加
- [ ] 動作検証

---

## 検証方法

### トークン消費測定

```bash
# 抽出前
wc -l .klaude/agents/vw-*.md
# 合計行数 × 4 ≈ トークン数

# 抽出後
wc -l .klaude/agents/vw-*.md
wc -l .klaude/skills/workflow-outputs/**/*.md
wc -l .klaude/skills/workflow-phases/**/*.md
# 合計行数 × 4 ≈ トークン数
```

### 動作検証

```bash
# vw-orchestrator 実行テスト
# PRP なしで簡単なタスクを実行
@vw-orchestrator "既存の README.md を分析して改善提案を作成"

# 各フェーズで SKILL 参照が正しく動作するか確認
# .brain/vw/{timestamp}-*.md が正しく生成されるか確認
```

---

## 期待効果まとめ

| フェーズ | 削減トークン | 累積削減率 | 所要期間 |
|---------|------------|----------|---------|
| フェーズ 1 | 20,760 | 47.3% | 1-2 日 |
| フェーズ 2 | 8,800 | 67.3% | 2-3 日 |
| フェーズ 3 | 3,880 | 76.2% | 1-2 日 |
| フェーズ 4 | 600 | 77.5% | 0.5 日 |
| フェーズ 5 | 1,000 | 79.8% | 1 日 |
| **合計** | **35,040** | **79.8%** | **6-8.5 日** |

**最終トークン消費**: 43,904 → 8,864 tokens（**79.8% 削減**）

---

## 次のステップ

1. **フェーズ 1 から開始**: Output Templates SKILL 作成（最大の ROI）
2. **段階的実装**: 各フェーズ完了後に動作検証
3. **トークン測定**: 各フェーズでトークン消費を測定
4. **ドキュメント更新**: CLAUDE.md と LOG.md を更新
