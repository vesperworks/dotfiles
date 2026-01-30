---
name: notetaking
description: Atomic Notes形式で技術用語を記録・整理。Use when saving term explanations to .brain/thoughts/atomic/. Provides output format templates and MOC generation logic. NOT for general research (use vw:research) and NOT for code documentation (use codebase-exploration).
---

# Notetaking Skill

## Core Purpose

技術学習で得た知識をAtomic Notes形式で記録し、Obsidian移植可能なナレッジベースを構築する。

## Output Format Template

### Term Explanation (用語解説)

```markdown
# {Term}

{1文目: 定義 - 何であるか}
{2文目: 特徴 - 何が違うか}
{3文目: 強み - なぜ使うか}

## 詳細
- {ポイント1}: {説明}
- {ポイント2}: {説明}
- {ポイント3}: {説明}

## なぜ生まれたか
- {背景1}
- {背景2}

## 文脈での使い道
{現在の学習コンテキストでの活用方法を1-2文で}

#{tag1} #{tag2} #{tag3}
```

### Save Location

- **ファイルパス**: `.brain/thoughts/atomic/{term-kebab-case}.md`
- **命名規則**: 小文字、スペースはハイフン、特殊文字除去
- **例**: "React Hooks" → `.brain/thoughts/atomic/react-hooks.md`

## MOC (Map of Content) Generation

### Trigger Condition

同一タグを持つファイルが **10個を超過** した時に自動提案。

### MOC Template

```markdown
# {Category} MOC

このマップは {category} に関連する用語を整理します。

## 概念マップ

### 基礎概念
- [[{term-1}]] - {one-line description}
- [[{term-2}]] - {one-line description}

### 応用概念
- [[{term-3}]] - {one-line description}

## 関連タグ
#{tag1} #{tag2}

---
*自動生成: {YYYY-MM-DD}*
```

### MOC Save Location

`.brain/thoughts/atomic/_moc-{category}.md`

## Tag Extraction Rules

1. **カテゴリタグ**: 技術領域（例: `#react`, `#typescript`, `#devops`）
2. **概念タグ**: 概念種別（例: `#hooks`, `#pattern`, `#architecture`）
3. **レベルタグ（任意）**: `#beginner`, `#intermediate`, `#advanced`

**タグ数**: 2-5個を推奨

## MOC Check Workflow

1. **タグ抽出**: 保存時にインラインタグを解析
2. **カウント**: `.brain/thoughts/atomic/` 内の同タグファイル数を確認
3. **閾値判定**: 10個超過でMOC提案
4. **提案表示**:

```
💡 #{tag} タグのノートが {count} 個になりました。
MOC（Map of Content）を作成しますか？
```

## Duplicate Check

保存前に同名ファイルの存在を確認:

```
⚠️ `.brain/thoughts/atomic/{filename}.md` は既に存在します。
- 上書き: 既存の内容を置き換え
- スキップ: 保存せずに終了
- 比較: 既存と新規を並べて表示
```

## Advanced References

For detailed MOC patterns and Obsidian best practices:
- [MOC Patterns](./references/moc-patterns.md) (future)
