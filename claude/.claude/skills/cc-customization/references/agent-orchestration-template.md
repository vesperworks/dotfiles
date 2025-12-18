# Agent (Orchestration) Template - vw-* 型

重量・オーケストレーション型のエージェント用テンプレートです。
実行権限を持ち、複数Phaseで複雑なフローを制御します。
XMLタグを使用してLLMの構造認識精度を向上させます。

## ファイル配置

```
~/.claude/agents/vw-{domain}-{role}.md
```

## テンプレート

以下をコピーして使用してください：

---

```markdown
---
name: vw-{domain}-{role}
description: |
  {複数行の機能説明}

  Examples:
  <example>
  Context: {使用シナリオ}
  user: "{ユーザー入力例}"
  assistant: "{エージェント応答例}"
  </example>
  <example>
  Context: {別のシナリオ}
  user: "{ユーザー入力例}"
  assistant: "{エージェント応答例}"
  </example>

tools: Read, Write, Edit, Glob, Grep, LS, Bash, TodoWrite
model: sonnet
color: green
---

<role>
{役割の定義（2-3行）}

責任:
- {責任1}
- {責任2}
- {責任3}
</role>

<workflow>
## Phase 1: {Phase Name}

1. {Step}
2. {Step}
3. {Step}

## Phase 2: {Phase Name}

### Step 2.1: {Substep Name}

{詳細な説明}

### Step 2.2: {Substep Name}

{詳細な説明}

## Phase 3: {Phase Name}

| {Column} | {Column} | {Column} |
|----------|----------|----------|
| {Data}   | {Data}   | {Data}   |

</workflow>

<constraints>
- **禁止**: {禁止事項1}
- **禁止**: {禁止事項2}
- **必須**: {必須事項1}
- **必須**: {必須事項2}
- **出力**: {出力先}
</constraints>

<skill_references>
- {skill-name-1}: {説明}
- {skill-name-2}: {説明}
</skill_references>

<rollback>
- **{失敗シナリオ1}**: {ロールバック手順}
- **{失敗シナリオ2}**: {ロールバック手順}
- **緊急時**: {緊急対応手順}
  \`\`\`bash
  {ロールバックコマンド}
  \`\`\`
</rollback>
```

---

## 作成時チェックリスト

### YAML Frontmatter
- [ ] `name`: `vw-{domain}-{role}` 形式
- [ ] `description`: ブロック形式 + 2-3個の `<example>` タグ
- [ ] `tools`: 必要な権限を含む（Write/Edit/Bash等）
- [ ] `model`: `sonnet`（標準）または `haiku`（軽量・高速）
- [ ] `color`: 役割に応じた色を選択

### XML Tags（必須）
- [ ] `<role>`: 役割定義と責任範囲
- [ ] `<workflow>`: 複数Phaseの実行フロー
- [ ] `<constraints>`: 禁止・必須事項

### XML Tags（推奨）
- [ ] `<skill_references>`: 外部スキル参照（Progressive Disclosure）
- [ ] `<rollback>`: 失敗時の復旧手順

---

## カラー選択ガイド

| 色 | 用途 | 選択基準 |
|----|------|----------|
| `green` | 構築・実装 | コード生成、ビルド、実装 |
| `purple` | オーケストレーション | 複数エージェント制御、フロー管理 |
| `blue` | プロジェクト管理 | タスク管理、計画、PM |
| `orange` | テスト | テスト実行、E2E、検証 |
| `cyan` | レビュー・分析 | コードレビュー、品質チェック |

---

## モデル選択ガイド

| モデル | 用途 | 選択基準 |
|--------|------|----------|
| `sonnet` | 標準 | 複雑な推論、高品質な出力が必要 |
| `haiku` | 軽量・高速 | シンプルなタスク、YAGNI特化 |
| `opus` | 最高品質 | 最も複雑な推論が必要（コスト高） |
| `inherit` | 継承 | メイン会話と同じモデル |

---

## ツール選択ガイド

| カテゴリ | ツール | 用途 |
|---------|--------|------|
| **読取** | Read, Grep, Glob, LS | ファイル検索・読取 |
| **書込** | Write, Edit, MultiEdit | ファイル作成・編集 |
| **実行** | Bash, BashOutput, KillBash | コマンド実行 |
| **進捗** | TodoWrite | タスク管理 |
| **MCP** | mcp__playwright-server__\* | E2Eテスト（Playwright） |
| **MCP** | mcp__context7__\* | 公式ドキュメント参照 |

---

## XMLタグの目的

| タグ | 目的 |
|------|------|
| `<role>` | LLMに役割境界を明確に認識させる |
| `<workflow>` | 実行順序を構造化して認識精度向上 |
| `<constraints>` | 禁止・必須事項を強調 |
| `<skill_references>` | Progressive Disclosureでコンテキスト効率化 |
| `<rollback>` | 失敗時の復旧手順を明確化 |

---

## description内の `<example>` タグパターン

```yaml
description: |
  {機能説明}

  Examples:
  <example>
  Context: {どのような状況で使うか}
  user: "{ユーザーが言いそうなフレーズ}"
  assistant: "{エージェントの応答}"
  </example>
```

**効果**:
- Claude Codeが適切なタイミングでエージェントを自動起動
- ユーザーがエージェント選択時の参考
- 発動率の向上（25% → 100%）

---

## constraints の書き方

```markdown
<constraints>
- **禁止**: {してはいけないこと}
- **禁止**: {別のしてはいけないこと}
- **必須**: {必ずすること}
- **必須**: {別の必ずすること}
- **出力**: {出力先（.brain/vw/ または PRPs/）}
</constraints>
```

**フォーマット**:
- 必ず `**禁止**:` または `**必須**:` プレフィックス
- 箇条書き形式で列挙
- 簡潔に（1行1制約）

---

## rollback の書き方

```markdown
<rollback>
- **Phase 2 失敗**: `git restore .` で変更取り消し
- **Phase 3 失敗**: 検証エラーに応じてデバッグ指示
- **全体失敗**: `git reset --hard HEAD~` で直前コミットに戻る
- **緊急時**: バックアップから復元
  \`\`\`bash
  rm -rf ~/.claude/agents
  mv ~/.claude/agents.backup-YYYYMMDD ~/.claude/agents
  \`\`\`
</rollback>
```

**パターン**:
- 失敗シナリオごとに具体的なコマンド提示
- コードブロックで実行可能な形式

---

## 参照

- **公式仕様**: https://code.claude.com/docs/en/sub-agents.md
- **既存実装例**: `~/.claude/agents/vw-dev-orchestra.md`
- **XMLタグガイド**: `thoughts/shared/ccPromptEngineering/use-xml-tags.md`
- **プロジェクト設計**: `thoughts/shared/research/2025-12-18-skill-agent-template-design.md`
