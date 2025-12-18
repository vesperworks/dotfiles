# Anthropic公式仕様サマリー

Claude Code SKILL/Agent/Slash Commandの公式仕様（2025年11月更新）をまとめたリファレンス。

## SKILL公式スキーマ

### YAMLフロントマター

```yaml
---
name: {skill-name}
description: {what it does and when to use it}
allowed-tools: Read, Grep, Glob  # オプション
---
```

### 必須フィールド

| フィールド | 型 | 制限 |
|-----------|------|------|
| `name` | string | 小文字・数字・ハイフン（最大64文字） |
| `description` | string | 最大1024文字 |

### オプションフィールド

| フィールド | 型 | 説明 |
|-----------|------|------|
| `allowed-tools` | string | カンマ区切り（例: `Read, Grep, Glob`） |
| `license` | string | ライセンス情報 |
| `metadata` | object | カスタムキー・バリューペア |

### ファイル配置

| 場所 | パス | 優先度 |
|------|------|--------|
| User-level | `~/.claude/skills/{name}/SKILL.md` | 2 |
| Project-level | `.claude/skills/{name}/SKILL.md` | 1（最高） |
| Plugin-level | `{plugin}/skills/{name}/SKILL.md` | 3 |

### Markdownボディ

制限なし。自由な記述が可能。

---

## Agent公式スキーマ

### YAMLフロントマター

```yaml
---
name: {agent-name}
description: |
  {what it does and when to use it}

  Examples:
  <example>
  Context: {situation}
  user: "{user input}"
  assistant: "{agent response}"
  </example>

tools: Read, Write, Grep
model: sonnet
color: blue
skills: skill1, skill2  # オプション
---
```

### 必須フィールド

| フィールド | 型 | 説明 |
|-----------|------|------|
| `name` | string | 小文字・ハイフン（3-50文字） |
| `description` | string | トリガー条件と使用例 |

### オプションフィールド

| フィールド | デフォルト | 説明 |
|-----------|----------|------|
| `tools` | 全継承 | カンマ区切りリスト |
| `model` | sonnet | `sonnet`, `opus`, `haiku`, `inherit` |
| `color` | - | UI表示色 |
| `skills` | - | 自動ロードするスキル |
| `permissionMode` | default | 権限モード |

### サポートされるモデル

| 値 | 説明 |
|------|------|
| `sonnet` | Claude 3.5 Sonnet（推奨） |
| `opus` | Claude Opus（最強） |
| `haiku` | Claude 3.5 Haiku（高速） |
| `inherit` | メイン会話と同じ |

### サポートされるカラー

```
blue, cyan, green, yellow, magenta, red, orange, purple
```

### ファイル配置

| 場所 | パス | 優先度 |
|------|------|--------|
| Project-level | `.claude/agents/{name}.md` | 1（最高） |
| User-level | `~/.claude/agents/{name}.md` | 2 |
| CLI-based | `--agents` フラグ | 動的 |

### Markdownボディ

システムプロンプトとして使用される。

---

## Slash Command公式スキーマ

### YAMLフロントマター

```yaml
---
description: "コマンドの説明"
argument-hint: "[引数パターン]"
allowed-tools: "Tool1, Tool2"
model: "sonnet"
disable-model-invocation: false
---
```

### 必須フィールド

| フィールド | 型 | 説明 |
|-----------|------|------|
| `description` | string | /helpに表示（SlashCommandツール使用時は必須） |

**注意**: `description` は2つの方法で指定可能：
1. Frontmatterに明示的に記載（推奨）
2. ファイルの最初のテキスト行を自動使用

### オプションフィールド

| フィールド | デフォルト | 説明 |
|-----------|----------|------|
| `argument-hint` | なし | 引数形式のヒント（例: `[message]`） |
| `allowed-tools` | 会話設定継承 | 許可ツール（カンマ区切り） |
| `model` | 会話設定継承 | 使用モデル |
| `name` | ファイル名 | 別名を使用する場合 |
| `disable-model-invocation` | false | trueでSlashCommandツール経由の自動実行禁止 |

### ファイル配置

| 場所 | パス | 優先度 | /help表示 |
|------|------|--------|----------|
| Project-level | `.claude/commands/{name}.md` | 1（最高） | "(project)" |
| User-level | `~/.claude/commands/{name}.md` | 2 | "(user)" |

### 引数の使用方法

| 変数 | 説明 | 例 |
|------|------|-----|
| `$ARGUMENTS` | 全引数を一括取得 | `/cmd a b c` → `"a b c"` |
| `$1`, `$2`, `$3` | 個別引数 | `/cmd a b c` → `$1="a"`, `$2="b"` |

### 特殊構文

| 構文 | 説明 | 例 |
|------|------|-----|
| `!`バッククォート | Bash実行 | `!`git status`` |
| `@`プレフィックス | ファイル参照 | `@src/file.ts` |

### ネームスペーシング

サブディレクトリで組織化可能：

```
.claude/commands/
├── frontend/
│   └── component.md     → /component (project:frontend)
├── backend/
│   └── test.md          → /test (project:backend)
└── review.md            → /review (project)
```

---

## ベストプラクティス（公式）

### description の書き方

**良い例**:
```yaml
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
```

**悪い例**:
```yaml
description: Helps with documents  # 曖昧すぎる
```

**ポイント**:
1. 「何をするか」を具体的に
2. 「いつ使うか」を明記
3. トリガーワードを含める

### セキュリティ警告

> 「信頼できるソース（自分で作成したもの、またはAnthropicから入手したもの）からのみSkillsを使用してください」

**リスク**:
- 悪意のあるSkillはClaudeに不適切なツール呼び出しを指示可能
- 記述された目的と一致しない方法でコードを実行可能

---

## CLI動的定義（参考）

```bash
claude --agents '{
  "reviewer": {
    "description": "Expert code reviewer...",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

---

## 参照URL

- https://code.claude.com/docs/en/skills.md
- https://code.claude.com/docs/en/sub-agents.md
- https://code.claude.com/docs/en/slash-commands.md
- https://code.claude.com/docs/en/plugins-reference.md
- https://code.claude.com/docs/en/cli-reference.md
