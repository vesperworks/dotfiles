---
name: cc-customization
description: Claude Codeカスタマイズの統合ガイドライン。SKILL、Agent（hl-*/vw-*）、Slash Commandを作成する際に使用。公式仕様、プロジェクト規約、テンプレート、ベストプラクティスを含む。NOT for 既存ファイルの修正（直接編集）and NOT for Claude Code自体の使い方（claude-code-guide参照）。
---

# Claude Code Customization Skill

SKILL、Agent、Slash Commandを作成・設計するための統合ガイドライン。

## Core Purpose

Claude Codeのカスタマイズ（SKILL/Agent/Command）を作成する際に参照し、公式仕様とプロジェクト規約に準拠した高品質なファイルを作成する。

## Quick Reference: 何を作るか

| 作成対象 | ファイル配置 | テンプレート |
|----------|-------------|-------------|
| **SKILL** | `.klaude/skills/{name}/SKILL.md` | [skill-template.md](./references/skill-template.md) |
| **hl-\*エージェント** | `.klaude/agents/hl-{name}.md` | [agent-lightweight-template.md](./references/agent-lightweight-template.md) |
| **vw-\*エージェント** | `.klaude/agents/vw-{name}.md` | [agent-orchestration-template.md](./references/agent-orchestration-template.md) |
| **Slash Command** | `.klaude/commands/{name}.md` | [slash-command-template.md](./references/slash-command-template.md) |

## 使い分けガイド

```
「頻繁に同じプロンプト使う？」
  YES → Slash Command
  NO  ↓
「独立したタスクとして並列実行？」
  YES → Agent
  NO  ↓
「複数エージェントで共有する知識？」
  YES → SKILL
  NO  → Slash Command or Agent
```

### 詳細な使い分け

| 観点 | SKILL | Agent | Slash Command |
|------|-------|-------|---------------|
| **発動方式** | 自動（文脈認識） | 自動 or 明示的 | 明示的（`/cmd`） |
| **コンテキスト** | メイン会話内 | 独立ウィンドウ | メイン会話内 |
| **並列実行** | ❌ | ✅ | ❌ |
| **複数ファイル** | ✅（references/） | ❌（単一） | ❌（単一） |
| **用途** | 専門知識・ガイドライン | タスク実行エンジン | よく使うプロンプト |

## 公式仕様サマリー

### SKILL

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | ✅ | kebab-case（64文字以内） |
| `description` | ✅ | 「何を」＋「いつ使うか」（1024文字以内） |
| `allowed-tools` | ❌ | 許可ツール（カンマ区切り） |

### Agent

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `name` | ✅ | kebab-case |
| `description` | ✅ | トリガー条件 + `<example>`タグ |
| `tools` | ❌ | 許可ツール（デフォルト: 全継承） |
| `model` | ❌ | `sonnet`/`opus`/`haiku`/`inherit` |
| `color` | ❌ | UI表示色 |

### Slash Command

| フィールド | 必須 | 説明 |
|-----------|------|------|
| `description` | ✅* | /helpに表示（SlashCommandツール使用時必須） |
| `argument-hint` | ❌ | 引数パターン（例: `[message]`） |
| `allowed-tools` | ❌ | 許可ツール（カンマ区切り） |
| `model` | ❌ | 使用モデル |

## ディレクトリ構成ルール

### SKILL（Progressive Disclosure）

```
.klaude/skills/{skill-name}/
├── SKILL.md                    # エントリーポイント（常時ロード）
└── references/                 # 詳細ガイド（必要時ロード）
    └── {topic}.md              # kebab-case命名
```

### Agent

```
.klaude/agents/{agent-name}.md  # 単一ファイル
```

### Slash Command

```
.klaude/commands/{command-name}.md  # 単一ファイル
```

## 命名規則

| 対象 | パターン | 例 |
|------|----------|-----|
| SKILL | `{domain}` | `cc-customization`, `prp-generation` |
| hl-\*Agent | `hl-{category}-{action}` | `hl-codebase-locator` |
| vw-\*Agent | `vw-{domain}-{role}` | `vw-dev-orchestra` |
| Command | `vw:{action}` or `{action}` | `vw:commit`, `vw:research` |

## カラーコーディング（Agent）

| 色 | 役割 |
|----|------|
| `cyan` | ドキュメンテーション・分析 |
| `yellow` | 外部検索・Web |
| `green` | 構築・実装 |
| `purple` | オーケストレーション |
| `blue` | プロジェクト管理 |
| `orange` | テスト |

## モデル選択

| モデル | 用途 |
|--------|------|
| `sonnet` | 標準（複雑な推論） |
| `haiku` | 軽量・高速（YAGNI特化） |
| `opus` | 最高品質（コスト高） |
| `inherit` | メイン会話と同じ |

## 重要な設計原則

### 1. Progressive Disclosure（SKILL）
- SKILL.mdはエントリーポイントのみ
- 詳細は`references/`に分離
- **約70%のコンテキスト削減**

### 2. XMLタグ構造（vw-\*Agent）
- `<role>`: 役割定義
- `<workflow>`: 実行フロー
- `<constraints>`: 禁止・必須事項
- `<skill_references>`: スキル参照
- `<rollback>`: 失敗時復旧

### 3. 改善禁止の3重強調（hl-\*Agent）
1. `CRITICAL`セクション
2. `What NOT to Do`セクション
3. `REMEMBER`セクション

### 4. 引数処理（Slash Command）
- `$ARGUMENTS`: 全引数
- `$1`, `$2`, `$3`: 個別引数
- `!`バッククォート: Bash実行
- `@`ファイル参照: ファイル内容展開

## 発動率向上のコツ

### SKILL
```yaml
# descriptionに具体的トリガーを含める
description: ...Use when {specific trigger}. NOT for {anti-pattern}.
```

### Agent
```yaml
# <example>タグで使用例を埋め込む
description: |
  {説明}

  Examples:
  <example>
  Context: {状況}
  user: "{入力}"
  assistant: "{応答}"
  </example>
```

### Slash Command
```yaml
# argument-hintで引数形式を明示
argument-hint: [message] [priority]
```

## Rollback / Recovery

- **SKILL破損時**: `git restore .klaude/skills/{name}/`
- **Agent破損時**: `git restore .klaude/agents/{name}.md`
- **Command破損時**: `git restore .klaude/commands/{name}.md`

## Advanced References

For detailed templates and specifications, see:
- [SKILL Template](./references/skill-template.md)
- [Agent Lightweight Template (hl-\*)](./references/agent-lightweight-template.md)
- [Agent Orchestration Template (vw-\*)](./references/agent-orchestration-template.md)
- [Slash Command Template](./references/slash-command-template.md)
- [Official Spec Summary](./references/official-spec.md)
