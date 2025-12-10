---
name: research-output
description: リサーチ結果の出力フォーマット。/research コマンドやリサーチ系エージェントで使用。
triggers:
  - リサーチ結果を保存
  - 調査レポートを作成
  - research output format
---

# Research Output Skill

リサーチ結果を統一フォーマットで出力するためのスキル。

## 出力場所

```
thoughts/shared/research/{YYYY-MM-DD}-{topic-kebab-case}.md
```

**例**: `thoughts/shared/research/2025-12-10-pagination-patterns.md`

## ドキュメント構造

### Frontmatter

```yaml
---
date: {ISO 8601 timestamp with timezone}
researcher: Claude Code
topic: "{user's original question}"
tags: [research, {relevant-tags}]
status: active | complete
iteration: 1
---
```

### 本文テンプレート

```markdown
# Research: {Topic}

**調査日時**: {YYYY-MM-DD HH:MM}
**依頼内容**: {original user query}

## サマリー

{2-3文の高レベルな回答}

## 詳細な調査結果

### 1. コードベースの調査

#### 関連ファイル
- `path/to/file.ts:45-67` - {description}
- `another/file.py:123` - {description}

#### 実装パターン
{発見したパターンとコード例}

### 2. ドキュメント調査（thoughts/）

#### 過去の決定事項
- `thoughts/shared/research/previous.md` - {key insight}
- `PRPs/done/related-feature.md` - {context}

### 3. Web調査結果（該当する場合）

#### 公式ドキュメント
- [Title](URL) - {summary}

#### ベストプラクティス
- [Source](URL) - {key points}

## 結論

{エビデンスに基づく直接的な回答}

## 追加の検討事項

- {consideration 1}
- {consideration 2}

## 次のステップの提案

- {suggested action 1}
- {suggested action 2}
```

## ユーザーへの提示フォーマット

調査完了時、**詳細ドキュメントではなく簡潔なサマリー**を提示：

```markdown
## 調査完了 ✅

**テーマ**: {topic}

### 主な発見

1. **{Finding 1}**
   - {Detail with file:line reference}

2. **{Finding 2}**
   - {Detail}

3. **{Finding 3}**
   - {Detail}

### 結論

{1-2文の直接的な回答}

---

📄 詳細レポート: `thoughts/shared/research/{filename}`

---

**フォローアップ質問はありますか？**
```

## イテレーション時の更新

フォローアップ質問があった場合：

1. **新規ファイルを作成しない** - 既存ドキュメントを更新
2. **frontmatter更新**: `iteration: {n+1}`
3. **セクション追加**:

```markdown
---

## Iteration {n+1} ({YYYY-MM-DD HH:MM})

**追加質問**: {follow-up question}

### 追加調査結果

{new findings}

### 更新された結論

{revised conclusion if needed}
```

## 品質基準

### 必須項目
- [ ] file:line 参照（コード調査時）
- [ ] URL（Web調査時）
- [ ] 調査日時
- [ ] 明確な結論

### 推奨項目
- [ ] 複数ソースからの裏付け
- [ ] トレードオフの記載
- [ ] 次のステップの提案
