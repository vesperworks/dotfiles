---
name: codebase-exploration
description: Deeply analyzes existing codebase features by tracing execution paths. Includes tech research and domain investigation capabilities (integrated from tech-domain-researcher). Use when exploring code structure, finding similar features, understanding architecture before implementation, or researching new technologies and frameworks. Specializes in dependency mapping, pattern recognition, impact analysis, and modern tech stack research with WebSearch and Context7 MCP integration. NOT for implementing features or fixing failing tests (use feature-implementation/tdd-implementation) and NOT for final QA gates (use quality-assurance/vw-reviewer).
---

# Codebase Exploration + Tech Research

## Core Purpose

Systematically investigate existing codebases and research modern technologies before implementation or refactoring.

## Basic Workflow

### Step 1: Determine Investigation Type
- **Codebase Exploration**: Analyze existing code structure, patterns, dependencies
- **Tech Research**: Research latest libraries, frameworks, best practices

### Step 2A: Codebase Exploration
1. **Keyword Search** (Grep) - Discover related code
2. **Pattern Search** (Glob) - Understand structure
3. **Code Reading** (Read) - Detailed understanding
4. **Dependency Tracing** - Identify impact scope

### Step 2B: Tech Research (Integrated Capability)
1. **WebSearch** - Find latest information
2. **Context7 MCP** - Get official documentation
3. **Comparative Analysis** - Select optimal technology
4. **Implementation Examples** - Validate practicality

### Step 3: Report Results
- Structured findings (./tmp/timestamp-explorer-report.md)
- Impact scope identification
- Tech recommendations (if research performed)
- Next step proposals

## Rollback / Recovery (調査結果が誤っていた場合)
- 調査ログと結論の根拠ファイルを明示し、誤り箇所を訂正して再保存
- 誤誘導があったタスクに対して「不要な変更は未適用」かを確認し、適用済みなら `git revert` で戻すよう開発者に明示
- 代替調査パス（別キーワード・別層の検索）を提案して再計測する

## Advanced References

For deeper analysis, see:
- [Advanced Analysis Methods](./references/advanced-analysis-methods.md)
- [Dependency Mapping Techniques](./references/dependency-mapping-techniques.md)
- [Tech Research Integration Guide](./references/tech-research-integration.md) - Integrated capability details
- [MCP Integration Patterns](./references/mcp-integration-patterns.md)
