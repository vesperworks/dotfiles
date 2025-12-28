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

---

## Atomic Note形式（Obsidian向け）

リサーチ完了時に使用する、短く焦点を絞ったノート形式。

### Atomic Note Frontmatter

```yaml
---
date: {YYYY-MM-DD}
type: research
question: "{調べたかったこと（1文）}"
answer: "{答え（1-2文）}"
aliases:
  - "{別名1}"
  - "{別名2}"
tags:
  - research
  - "{topic-tag}"
  - "{technology-tag}"
sources:
  - "{file:line or URL}"
related:
  - "[[related-note-1]]"
  - "[[related-note-2]]"
---
```

### Atomic Note Template

```markdown
# {Topic Title}

> **Q**: {調べたかったこと}
>
> **A**: {答え}

## 背景・文脈

{なぜこの質問が生まれたか、1-2文}

## 詳細

{重要なポイントを箇条書きで}

- {Point 1}
- {Point 2}
- {Point 3}

## エビデンス

{根拠となるソース}

- `{file:line}` - {概要}
- [{Title}]({URL}) - {概要}

## 関連ノート

- [[{related-topic-1}]]
- [[{related-topic-2}]]

---

*調査日: {YYYY-MM-DD}*
```

### Atomic Note例

```markdown
---
date: 2025-12-28
type: research
question: "Claude CodeのHooksでstdoutをキャプチャできるか？"
answer: "可能。PreToolUse/PostToolUseフックでstdout/stderrをパイプで取得し、環境変数経由でコンテキストにアクセスできる。"
aliases:
  - "Hooks stdout capture"
  - "Claude Code hook output"
tags:
  - research
  - claude-code
  - hooks
sources:
  - "https://docs.anthropic.com/claude-code/hooks"
related:
  - "[[claude-code-hooks]]"
  - "[[shell-stdout-capture]]"
---

# Claude Code Hooksでstdoutをキャプチャする方法

> **Q**: Claude CodeのHooksでstdoutをキャプチャできるか？
>
> **A**: 可能。PreToolUse/PostToolUseフックでstdout/stderrをパイプで取得し、環境変数経由でコンテキストにアクセスできる。

## 背景・文脈

Hooksの出力を加工して別の処理に渡したい場面があった。

## 詳細

- `PreToolUse`/`PostToolUse`フックはJSON形式でツール情報を受け取る
- stdoutに出力した内容はClaudeのコンテキストに追加される
- 環境変数`CLAUDE_*`でセッション情報にアクセス可能

## エビデンス

- [Claude Code Hooks Documentation](https://docs.anthropic.com/claude-code/hooks) - 公式ドキュメント

## 関連ノート

- [[claude-code-hooks]]
- [[shell-stdout-capture]]

---

*調査日: 2025-12-28*
```

### 使い分け

| 形式 | 用途 |
|------|------|
| 詳細レポート形式 | 複雑な調査、複数の発見事項、イテレーション |
| Atomicノート形式 | 単一の質問への回答、素早い参照用、Obsidian連携 |
