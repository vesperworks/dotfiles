# Slash Command Template

スラッシュコマンド作成用テンプレート。

## ファイル配置

```
.klaude/commands/{command-name}.md
```

**例**: `.klaude/commands/vw:review.md` → `/vw:review`

## テンプレート（シンプル版）

以下をコピーして使用してください：

---

```markdown
---
description: '{コマンドの説明}'
argument-hint: [{引数パターン}]
allowed-tools: Tool1, Tool2
---

{コマンドの本体}

$ARGUMENTS
```

---

## テンプレート（複雑版・XMLタグ使用）

複雑なワークフローが必要な場合：

---

```markdown
---
description: '{コマンドの説明}'
argument-hint: [{引数パターン}]
allowed-tools: Tool1, Tool2, AskUserQuestion
model: sonnet
---

<role>
{役割定義}
</role>

<workflow>

## Phase 1: {Phase名}

### If NO argument provided:

{引数なしの場合の処理}

### If argument provided:

{引数ありの場合の処理}

1. Parse: $ARGUMENTS
2. {ステップ2}
3. {ステップ3}

## Phase 2: {Phase名}

{次のフェーズ}

</workflow>

<guidelines>

### {ガイドライン1}
- {ポイント}

### {ガイドライン2}
- {ポイント}

</guidelines>
```

---

## YAML Frontmatter フィールド

### 必須フィールド

| フィールド | 説明 | 例 |
|-----------|------|-----|
| `description` | /helpに表示、SlashCommandツール使用時必須 | `'Smart commit helper'` |

### オプションフィールド

| フィールド | デフォルト | 説明 | 例 |
|-----------|----------|------|-----|
| `argument-hint` | なし | 引数形式のヒント | `[message]`, `[pr-number] [priority]` |
| `allowed-tools` | 会話設定継承 | 許可ツール（カンマ区切り） | `Bash(git:*), Read, Task` |
| `model` | 会話設定継承 | 使用モデル | `sonnet`, `opus`, `haiku` |
| `name` | ファイル名 | 別名を使用する場合 | `sc`（vw:commit.md内で） |
| `disable-model-invocation` | false | trueで自動実行禁止 | `true` |

---

## 引数の使い方

### 全引数を一括取得

```markdown
# コマンド: /review 123 high-priority
$ARGUMENTS  → "123 high-priority"
```

### 個別引数を取得

```markdown
# コマンド: /review 123 high alice
$1  → "123"
$2  → "high"
$3  → "alice"
```

### 引数の有無で分岐

```markdown
## モード判定

- `$ARGUMENTS` が**空**の場合 → 対話モード
- `$ARGUMENTS` が**ある**場合 → 即時実行モード
```

---

## 特殊構文

### Bash実行（!バッククォート）

```markdown
---
allowed-tools: Bash(git status:*), Bash(git diff:*)
---

## Context

- Current git status: !`git status`
- Current branch: !`git branch --show-current`
```

### ファイル参照（@プレフィックス）

```markdown
Review the implementation in @src/utils/helpers.js

Compare @src/old.js with @src/new.js
```

---

## allowed-tools の書き方

### 基本形式

```yaml
allowed-tools: Tool1(pattern:*), Tool2(pattern), Tool3
```

### よく使うパターン

```yaml
# Git操作
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)

# ファイル操作
allowed-tools: Read, Write, Edit

# Web操作
allowed-tools: WebSearch, WebFetch

# GitHub CLI
allowed-tools: Bash(gh:*)

# Task（サブエージェント起動）
allowed-tools: Task, AskUserQuestion
```

---

## 作成時チェックリスト

### YAML Frontmatter
- [ ] `description`: 明確な説明（SlashCommandツール使用時必須）
- [ ] `argument-hint`: 引数パターンを明示
- [ ] `allowed-tools`: 必要最小限のツールのみ許可

### 本体
- [ ] `$ARGUMENTS` または `$1`, `$2` で引数を使用
- [ ] 引数なし/ありの分岐を考慮
- [ ] 複雑な場合はXMLタグで構造化

### テスト
- [ ] `/command` で動作確認
- [ ] `/command arg1 arg2` で引数ありも確認
- [ ] `/help` に表示されるか確認

---

## タイプ別テンプレート

### Type A: シンプルコマンド

```yaml
---
description: 'Quick code review'
allowed-tools: Read, Grep
---

Review this code for bugs and improvements.

Focus on: $ARGUMENTS
```

### Type B: 引数分岐コマンド

```yaml
---
description: 'Smart commit: /sc (interactive) or /sc "message" (quick)'
---

## Mode Detection

- `$ARGUMENTS` empty → Interactive mode (step by step)
- `$ARGUMENTS` exists → Quick mode (immediate commit)

## Quick Mode

git commit -m "$ARGUMENTS"

## Interactive Mode

1. Analyze changes
2. Group by purpose
3. Create commits
```

### Type C: オーケストレーションコマンド

```yaml
---
description: 'Research assistant for investigation'
argument-hint: [optional topic]
allowed-tools: Task, AskUserQuestion, WebSearch
model: opus
---

<role>
You are an expert research assistant.
</role>

<workflow>
## Phase 1: Initial Contact

### If NO argument:
Display welcome message, STOP.

### If argument:
1. Parse topic from $ARGUMENTS
2. Use AskUserQuestion to clarify scope
3. Proceed to Phase 2

## Phase 2: Research Execution

Spawn sub-agents for parallel research...
</workflow>
```

### Type D: 外部ツール連携

```yaml
---
description: 'Web search via Gemini CLI'
allowed-tools: Bash(gemini:*)
---

## Gemini Web Search

Execute: `gemini -p 'google_web_search: $ARGUMENTS'`
```

---

## ベストプラクティス

### DO（推奨）

1. **descriptionを明確に**
   ```yaml
   description: 'Create git commit with conventional format'
   ```

2. **argument-hintで形式を示す**
   ```yaml
   argument-hint: [message] [scope]
   ```

3. **allowed-toolsを最小限に**
   ```yaml
   # 良い：必要なものだけ
   allowed-tools: Bash(git:*), Read
   ```

4. **複雑なロジックはXMLタグで構造化**
   ```markdown
   <workflow>
   ## Phase 1: ...
   </workflow>
   ```

### DON'T（非推奨）

1. **過度に広いツール許可**
   ```yaml
   # 悪い
   allowed-tools: Bash(*), Write(*)
   ```

2. **descriptionの省略**（SlashCommandツールが使えなくなる）

3. **複雑すぎるコマンド**
   - 複雑になったらSKILLに移行を検討

---

## Slash Command vs SKILL vs Agent

| 判断基準 | 選択 |
|----------|------|
| 頻繁に使う短いプロンプト | Slash Command |
| 複数ファイル・複雑なワークフロー | SKILL |
| 独立タスクとして並列実行 | Agent |
| `references/`で詳細分離したい | SKILL |

---

## 参照

- **公式仕様**: https://code.claude.com/docs/en/slash-commands.md
- **既存実装例**: `.klaude/commands/vw:commit.md`, `.klaude/commands/vw:research.md`
