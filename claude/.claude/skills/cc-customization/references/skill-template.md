# SKILL Template

このテンプレートを使用してSKILLを作成します。

## ディレクトリ構成

```
.klaude/skills/{skill-name}/
├── SKILL.md                    # このテンプレートをコピー
└── references/                 # 詳細ガイド（必要に応じて追加）
    └── {topic}.md              # kebab-case命名
```

## SKILL.md テンプレート

以下をコピーして使用してください：

---

```markdown
---
name: {skill-name}
description: {1-3文。「何をするか」＋「いつ使うか」＋「何に使わないか」を含める}
---

# {Skill Display Name}

## Core Purpose

{1-2文でスキルの主目的を説明}

## Quick Checklist (初期応答で必ず確認)

<!-- ワークフロー型の場合。フォーマット仕様型の場合は削除 -->
- [ ] {確認項目1}
- [ ] {確認項目2}
- [ ] {確認項目3}

## Basic Workflow

### Step 1: {ステップ名}

1. {アクション1}
2. {アクション2}

### Step 2: {ステップ名}

1. {アクション1}
2. {アクション2}

### Step 3: {ステップ名}

1. {アクション1}
2. {アクション2}

## Output Deliverables

<!-- 成果物を生成する場合 -->
Save to `./.brain/report/{timestamp}-{output-name}.md`:
- {成果物1}
- {成果物2}

## Rollback / Recovery ({失敗シナリオ})

- {問題特定方法}
- {復旧手順（git revert/restore等）}
- {レポート保存・共有方法}

## Advanced References

For detailed {methodologies|patterns|guidance}, see:
- [{Reference Title 1}](./references/{filename-1}.md)
- [{Reference Title 2}](./references/{filename-2}.md)
```

---

## references/ ファイルテンプレート

```markdown
# {Reference Title}

## Overview

{このリファレンスが提供する情報の概要}

## {Main Section 1}

### {Subsection}

{詳細な説明、コード例、パターン等}

## {Main Section 2}

### {Subsection}

{詳細な説明}

## Best Practices

- {ベストプラクティス1}
- {ベストプラクティス2}

## Common Pitfalls

- {よくある落とし穴1}
- {よくある落とし穴2}
```

---

## 作成時チェックリスト

### YAML Frontmatter
- [ ] `name`: kebab-case、小文字・数字・ハイフン（最大64文字）
- [ ] `description`: 「何を」＋「いつ使うか」＋「何に使わないか（NOT for...）」

### Markdown Body
- [ ] `## Core Purpose`: 1-2文の目的説明
- [ ] `## Basic Workflow` or `## Quick Checklist`: 実行手順
- [ ] `## Rollback / Recovery`: 失敗時の対処（フォーマット仕様型を除く）
- [ ] `## Advanced References`: references/へのリンク

### references/ ディレクトリ
- [ ] ファイル名は `{topic}-{type}.md`（kebab-case）
- [ ] SKILL.mdからリンクされている
- [ ] 詳細な技術情報、ベストプラクティス、パターンを含む

---

## description の書き方ガイド

### 推奨パターン

```yaml
description: {Primary purpose}. {Integration note if applicable}. Use when {use cases}. Specializes in {capabilities}. {MCP integration if applicable}. NOT for {anti-patterns} (use {alternative-skill} instead).
```

### 良い例

```yaml
description: Deeply analyzes existing codebase features by tracing execution paths. Use when exploring code structure, finding similar features, or understanding architecture before implementation. Specializes in dependency mapping, pattern recognition, and impact analysis. NOT for implementing features (use feature-implementation) and NOT for final QA gates (use quality-assurance).
```

### 悪い例

```yaml
description: Helps with code analysis  # 曖昧すぎる、トリガー条件がない
```

---

## 参照

- **公式仕様**: https://code.claude.com/docs/en/skills.md
- **プロジェクト設計**: `thoughts/shared/research/2025-12-18-skill-agent-template-design.md`
