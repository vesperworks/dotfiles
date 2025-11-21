# プラグインリファレンス

> Claude Codeプラグインシステムの完全な技術リファレンス。スキーマ、CLIコマンド、コンポーネント仕様を含みます。

<Tip>
  実践的なチュートリアルと実用的な使用方法については、[プラグイン](/ja/plugins)を参照してください。チーム全体とコミュニティ全体でのプラグイン管理については、[プラグインマーケットプレイス](/ja/plugin-marketplaces)を参照してください。
</Tip>

このリファレンスは、Claude Codeプラグインシステムの完全な技術仕様を提供します。コンポーネントスキーマ、CLIコマンド、開発ツールを含みます。

## プラグインコンポーネントリファレンス

このセクションでは、プラグインが提供できる5つのタイプのコンポーネントについて説明します。

### コマンド

プラグインは、Claude Codeのコマンドシステムとシームレスに統合するカスタムスラッシュコマンドを追加します。

**場所**: プラグインルートの`commands/`ディレクトリ

**ファイル形式**: フロントマター付きのMarkdownファイル

プラグインコマンド構造、呼び出しパターン、機能の詳細については、[プラグインコマンド](/ja/slash-commands#plugin-commands)を参照してください。

### エージェント

プラグインは、特定のタスク用の特殊なサブエージェントを提供でき、Claude が必要に応じて自動的に呼び出すことができます。

**場所**: プラグインルートの`agents/`ディレクトリ

**ファイル形式**: エージェント機能を説明するMarkdownファイル

**エージェント構造**:

```markdown  theme={null}
---
description: このエージェントが専門とする内容
capabilities: ["task1", "task2", "task3"]
---

# エージェント名

エージェントの役割、専門知識、およびClaudeがそれを呼び出すべき時期の詳細な説明。

## 機能
- エージェントが得意とする特定のタスク
- もう1つの特殊な機能
- このエージェントと他のエージェントを使い分ける時期

## コンテキストと例
このエージェントを使用すべき時期と、解決できる問題の種類の例を提供します。
```

**統合ポイント**:

* エージェントは`/agents`インターフェイスに表示されます
* Claudeはタスクコンテキストに基づいてエージェントを自動的に呼び出すことができます
* エージェントはユーザーによって手動で呼び出すことができます
* プラグインエージェントは組み込みのClaudeエージェントと一緒に動作します

### スキル

プラグインは、Claudeの機能を拡張するエージェントスキルを提供できます。スキルはモデル呼び出し型です。Claudeはタスクコンテキストに基づいて自律的に使用するかどうかを決定します。

**場所**: プラグインルートの`skills/`ディレクトリ

**ファイル形式**: フロントマター付きの`SKILL.md`ファイルを含むディレクトリ

**スキル構造**:

```
skills/
├── pdf-processor/
│   ├── SKILL.md
│   ├── reference.md (オプション)
│   └── scripts/ (オプション)
└── code-reviewer/
    └── SKILL.md
```

**統合動作**:

* プラグインスキルはプラグインがインストールされると自動的に検出されます
* Claudeはタスクコンテキストのマッチングに基づいてスキルを自律的に呼び出します
* スキルはSKILL.mdの隣にサポートファイルを含めることができます

SKILL.md形式と完全なスキル作成ガイダンスについては、以下を参照してください:

* [Claude CodeでスキルをUse](/ja/skills)
* [エージェントスキル概要](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview#skill-structure)

### フック

プラグインは、Claude Codeイベントに自動的に応答するイベントハンドラーを提供できます。

**場所**: プラグインルートの`hooks/hooks.json`、またはplugin.jsonにインライン

**形式**: イベントマッチャーとアクションを含むJSON設定

**フック設定**:

```json  theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

**利用可能なイベント**:

* `PreToolUse`: Claudeがツールを使用する前
* `PostToolUse`: Claudeがツールを使用した後
* `UserPromptSubmit`: ユーザーがプロンプトを送信するとき
* `Notification`: Claude Codeが通知を送信するとき
* `Stop`: Claudeが停止しようとするとき
* `SubagentStop`: サブエージェントが停止しようとするとき
* `SessionStart`: セッションの開始時
* `SessionEnd`: セッションの終了時
* `PreCompact`: 会話履歴がコンパクト化される前

**フックタイプ**:

* `command`: シェルコマンドまたはスクリプトを実行
* `validation`: ファイルコンテンツまたはプロジェクト状態を検証
* `notification`: アラートまたはステータス更新を送信

### MCPサーバー

プラグインは、Model Context Protocol (MCP)サーバーをバンドルして、Claude Codeを外部ツールおよびサービスに接続できます。

**場所**: プラグインルートの`.mcp.json`、またはplugin.jsonにインライン

**形式**: 標準MCPサーバー設定

**MCPサーバー設定**:

```json  theme={null}
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data"
      }
    },
    "plugin-api-client": {
      "command": "npx",
      "args": ["@company/mcp-server", "--plugin-mode"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```

**統合動作**:

* プラグインMCPサーバーはプラグインが有効になると自動的に起動します
* サーバーはClaudeのツールキットに標準MCPツールとして表示されます
* サーバー機能はClaudeの既存ツールとシームレスに統合されます
* プラグインサーバーはユーザーMCPサーバーとは独立して設定できます

***

## プラグインマニフェストスキーマ

`plugin.json`ファイルはプラグインのメタデータと設定を定義します。このセクションでは、サポートされているすべてのフィールドとオプションについて説明します。

### 完全なスキーマ

```json  theme={null}
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json"
}
```

### 必須フィールド

| フィールド  | タイプ    | 説明                     | 例                    |
| :----- | :----- | :--------------------- | :------------------- |
| `name` | string | 一意の識別子 (ケバブケース、スペースなし) | `"deployment-tools"` |

### メタデータフィールド

| フィールド         | タイプ    | 説明            | 例                                                  |
| :------------ | :----- | :------------ | :------------------------------------------------- |
| `version`     | string | セマンティックバージョン  | `"2.1.0"`                                          |
| `description` | string | プラグイン目的の簡潔な説明 | `"Deployment automation tools"`                    |
| `author`      | object | 著者情報          | `{"name": "Dev Team", "email": "dev@company.com"}` |
| `homepage`    | string | ドキュメンテーションURL | `"https://docs.example.com"`                       |
| `repository`  | string | ソースコードURL     | `"https://github.com/user/plugin"`                 |
| `license`     | string | ライセンス識別子      | `"MIT"`, `"Apache-2.0"`                            |
| `keywords`    | array  | 検出タグ          | `["deployment", "ci-cd"]`                          |

### コンポーネントパスフィールド

| フィールド        | タイプ            | 説明                 | 例                                       |
| :----------- | :------------- | :----------------- | :-------------------------------------- |
| `commands`   | string\|array  | 追加のコマンドファイル/ディレクトリ | `"./custom/cmd.md"` または `["./cmd1.md"]` |
| `agents`     | string\|array  | 追加のエージェントファイル      | `"./custom/agents/"`                    |
| `hooks`      | string\|object | フック設定パスまたはインライン設定  | `"./hooks.json"`                        |
| `mcpServers` | string\|object | MCP設定パスまたはインライン設定  | `"./mcp.json"`                          |

### パス動作ルール

**重要**: カスタムパスはデフォルトディレクトリを置き換えるのではなく、補足します。

* `commands/`が存在する場合、カスタムコマンドパスに加えて読み込まれます
* すべてのパスはプラグインルートに相対的で、`./`で始まる必要があります
* カスタムパスからのコマンドは同じ命名とネームスペーシングルールを使用します
* 複数のパスを配列として指定して柔軟性を確保できます

**パスの例**:

```json  theme={null}
{
  "commands": [
    "./specialized/deploy.md",
    "./utilities/batch-process.md"
  ],
  "agents": [
    "./custom-agents/reviewer.md",
    "./custom-agents/tester.md"
  ]
}
```

### 環境変数

**`${CLAUDE_PLUGIN_ROOT}`**: プラグインディレクトリへの絶対パスを含みます。フック、MCPサーバー、スクリプトで使用して、インストール場所に関係なく正しいパスを確保します。

```json  theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh"
          }
        ]
      }
    ]
  }
}
```

***

## プラグインディレクトリ構造

### 標準プラグインレイアウト

完全なプラグインは以下の構造に従います:

```
enterprise-plugin/
├── .claude-plugin/           # メタデータディレクトリ
│   └── plugin.json          # 必須: プラグインマニフェスト
├── commands/                 # デフォルトコマンド場所
│   ├── status.md
│   └──  logs.md
├── agents/                   # デフォルトエージェント場所
│   ├── security-reviewer.md
│   ├── performance-tester.md
│   └── compliance-checker.md
├── skills/                   # エージェントスキル
│   ├── code-reviewer/
│   │   └── SKILL.md
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
├── hooks/                    # フック設定
│   ├── hooks.json           # メインフック設定
│   └── security-hooks.json  # 追加フック
├── .mcp.json                # MCPサーバー定義
├── scripts/                 # フックとユーティリティスクリプト
│   ├── security-scan.sh
│   ├── format-code.py
│   └── deploy.js
├── LICENSE                  # ライセンスファイル
└── CHANGELOG.md             # バージョン履歴
```

<Warning>
  `.claude-plugin/`ディレクトリには`plugin.json`ファイルが含まれています。他のすべてのディレクトリ(commands/、agents/、skills/、hooks/)は、`.claude-plugin/`内ではなく、プラグインルートにある必要があります。
</Warning>

### ファイル場所リファレンス

| コンポーネント     | デフォルト場所                      | 目的                      |
| :---------- | :--------------------------- | :---------------------- |
| **マニフェスト**  | `.claude-plugin/plugin.json` | 必須メタデータファイル             |
| **コマンド**    | `commands/`                  | スラッシュコマンドMarkdownファイル   |
| **エージェント**  | `agents/`                    | サブエージェントMarkdownファイル    |
| **スキル**     | `skills/`                    | SKILL.mdファイル付きエージェントスキル |
| **フック**     | `hooks/hooks.json`           | フック設定                   |
| **MCPサーバー** | `.mcp.json`                  | MCPサーバー定義               |

***

## デバッグと開発ツール

### デバッグコマンド

`claude --debug`を使用してプラグイン読み込みの詳細を確認します:

```bash  theme={null}
claude --debug
```

これは以下を表示します:

* どのプラグインが読み込まれているか
* プラグインマニフェストのエラー
* コマンド、エージェント、フック登録
* MCPサーバー初期化

### 一般的な問題

| 問題            | 原因                             | 解決策                                           |
| :------------ | :----------------------------- | :-------------------------------------------- |
| プラグインが読み込まれない | 無効な`plugin.json`               | JSON構文を検証                                     |
| コマンドが表示されない   | ディレクトリ構造が間違っている                | `commands/`が`.claude-plugin/`内ではなくルートにあることを確認 |
| フックが発火しない     | スクリプトが実行可能でない                  | `chmod +x script.sh`を実行                       |
| MCPサーバーが失敗する  | `${CLAUDE_PLUGIN_ROOT}`が見つからない | すべてのプラグインパスに変数を使用                             |
| パスエラー         | 絶対パスが使用されている                   | すべてのパスは相対的で`./`で始まる必要があります                    |

***

## 配布とバージョン管理リファレンス

### バージョン管理

プラグインリリースのセマンティックバージョニングに従います:

```json  theme={null}

## 関連項目

- [プラグイン](/ja/plugins) - チュートリアルと実用的な使用方法
- [プラグインマーケットプレイス](/ja/plugin-marketplaces) - マーケットプレイスの作成と管理
- [スラッシュコマンド](/ja/slash-commands) - コマンド開発の詳細
- [サブエージェント](/ja/sub-agents) - エージェント設定と機能
- [エージェントスキル](/ja/skills) - Claudeの機能を拡張
- [フック](/ja/hooks) - イベント処理と自動化
- [MCP](/ja/mcp) - 外部ツール統合
- [設定](/ja/settings) - プラグインの設定オプション
```
