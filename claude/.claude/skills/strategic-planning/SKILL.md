---
name: strategic-planning
description: Strategic planning and requirements architecture for complex features. Includes requirement analysis and SOLID principles validation (integrated from requirements-architect). Use when defining requirements, evaluating technical approaches, making architectural decisions, assessing risks, or creating implementation roadmaps. Specializes in user needs clarification, SOLID principle-based design evaluation, technical feasibility verification, and phased implementation planning. NOT for direct coding or writing tests (use feature-implementation/test-creation) and NOT for debugging incidents (use tdd-implementation with debug flow).
---

# Strategic Planning + Requirements Architecture

## Core Purpose

Define clear requirements and create strategic implementation plans for complex features, ensuring alignment with SOLID principles.

## Quick Checklist (初期応答で必ず確認)
- 背景と目標を1文で再掲し、成功条件を列挙
- ユーザーストーリー/ユースケースを箇条書きで洗い出し
- 非機能要件（性能/セキュリティ/運用）を明文化
- 制約（技術・組織・スケジュール）を確認
- リスクと回避策を最低3件挙げる
- SOLID観点で分割/責務境界を提示
- フェーズ分割とマイルストーンを示す
- 測定可能な受け入れ基準を添える

## Basic Workflow

### Step 1: Requirement Clarification
- User needs identification
- Use case definition
- Success criteria establishment

### Step 2: SOLID Evaluation (Integrated Capability)
- Single Responsibility Principle validation
- Open/Closed Principle assessment
- Liskov Substitution Principle check
- Interface Segregation Principle review
- Dependency Inversion Principle verification

### Step 3: Technical Feasibility
- Technology stack evaluation
- Constraint identification
- Risk assessment

### Step 4: Implementation Roadmap
- Phased approach design
- Milestone definition
- Resource estimation

## Rollback / Recovery (誤った計画を立てた場合)
- 誤認した前提・制約・リスクを箇条書きで訂正し、最新版の計画を上書き保存
- 既に共有した計画があれば差分と影響範囲を明記し、実装作業を一時停止するよう通知
- 代替案（最小修正/全面再設計）を2案以上提示し、意思決定後に再着手する

## Advanced References

For detailed guidance, see:
- [SOLID Principles Deep Dive](./references/solid-principles.md)
- [Requirement Analysis Patterns](./references/requirement-analysis-patterns.md)
