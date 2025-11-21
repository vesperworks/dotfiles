---
created: 2025-06-06T10:30
updated: 2025-06-12T18:40
---
# SDK

> SDKを使用してClaude Codeをプログラムでアプリケーションに統合します。

Claude Code SDKを使用すると、開発者はClaude Codeをプログラムでアプリケーションに統合できます。これにより、Claude Codeをサブプロセスとして実行し、Claudeの機能を活用したAIパワードのコーディングアシスタントやツールを構築する方法を提供します。

SDKは現在、コマンドライン使用をサポートしています。TypeScriptとPython SDKは近日公開予定です。

## 基本的なSDKの使用方法

Claude Code SDKを使用すると、アプリケーションから非インタラクティブモードでClaude Codeを使用できます。基本的な例を示します：

```bash
# 単一のプロンプトを実行して終了（プリントモード）
$ claude -p "Write a function to calculate Fibonacci numbers"

# パイプを使用して標準入力を提供
$ echo "Explain this code" | claude -p

# メタデータを含むJSON形式で出力
$ claude -p "Generate a hello world function" --output-format json

# 到着したらJSONをストリーミング出力
$ claude -p "Build a React component" --output-format stream-json
```

## 高度な使用方法

### 複数ターンの会話

複数ターンの会話では、会話を再開したり、最新のセッションから続行したりできます：

```bash
# 最新の会話を続行
$ claude --continue

# 続行して新しいプロンプトを提供
$ claude --continue "Now refactor this for better performance"

# セッションIDで特定の会話を再開
$ claude --resume 550e8400-e29b-41d4-a716-446655440000

# プリントモード（非インタラクティブ）で再開
$ claude -p --resume 550e8400-e29b-41d4-a716-446655440000 "Update the tests"

# プリントモード（非インタラクティブ）で続行
$ claude -p --continue "Add error handling"
```

### カスタムシステムプロンプト

Claudeの動作を導くためのカスタムシステムプロンプトを提供できます：

```bash
# システムプロンプトをオーバーライド（--printでのみ機能）
$ claude -p "Build a REST API" --system-prompt "You are a senior backend engineer. Focus on security, performance, and maintainability."

# 特定の要件を持つシステムプロンプト
$ claude -p "Create a database schema" --system-prompt "You are a database architect. Use PostgreSQL best practices and include proper indexing."
```

デフォルトのシステムプロンプトに指示を追加することもできます：

```bash
# システムプロンプトを追加（--printでのみ機能）
$ claude -p "Build a REST API" --append-system-prompt "After writing code, be sure to code review yourself."
```

### MCP設定

Model Context Protocol（MCP）を使用すると、外部サーバーから追加のツールやリソースでClaude Codeを拡張できます。`--mcp-config`フラグを使用して、データベースアクセス、API統合、カスタムツールなどの特殊な機能を提供するMCPサーバーを読み込むことができます。

MCPサーバーを含むJSON設定ファイルを作成します：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/allowed/files"
      ]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your-github-token"
      }
    }
  }
}
```

そしてClaude Codeで使用します：

```bash
# 設定からMCPサーバーを読み込む
$ claude -p "List all files in the project" --mcp-config mcp-servers.json

# 重要：MCPツールは--allowedToolsを使用して明示的に許可する必要があります
# MCPツールは次の形式に従います：mcp__$serverName__$toolName
$ claude -p "Search for TODO comments" \
  --mcp-config mcp-servers.json \
  --allowedTools "mcp__filesystem__read_file,mcp__filesystem__list_directory"

# 非インタラクティブモードで権限プロンプトを処理するためのMCPツールを使用
$ claude -p "Deploy the application" \
  --mcp-config mcp-servers.json \
  --allowedTools "mcp__permissions__approve" \
  --permission-prompt-tool mcp__permissions__approve
```

注意：MCPツールを使用する場合は、`--allowedTools`フラグを使用して明示的に許可する必要があります。MCPツール名は`mcp__<serverName>__<toolName>`のパターンに従います。ここで：

* `serverName`はMCP設定ファイルのキーです
* `toolName`はそのサーバーが提供する特定のツールです

このセキュリティ対策により、MCPツールは明示的に許可された場合にのみ使用されます。

## 利用可能なCLIオプション

SDKはClaude Codeで利用可能なすべてのCLIオプションを活用します。SDK使用のための主要なオプションは次のとおりです：

| フラグ                        | 説明                                   | 例                                                              |
| :------------------------- | :----------------------------------- | :------------------------------------------------------------- |
| `--print`, `-p`            | 非インタラクティブモードで実行                      | `claude -p "query"`                                            |
| `--output-format`          | 出力形式を指定（`text`、`json`、`stream-json`） | `claude -p --output-format json`                               |
| `--resume`, `-r`           | セッションIDで会話を再開                        | `claude --resume abc123`                                       |
| `--continue`, `-c`         | 最新の会話を続行                             | `claude --continue`                                            |
| `--verbose`                | 詳細なログを有効にする                          | `claude --verbose`                                             |
| `--max-turns`              | 非インタラクティブモードでのエージェントターンを制限           | `claude --max-turns 3`                                         |
| `--system-prompt`          | システムプロンプトをオーバーライド（`--print`でのみ）      | `claude --system-prompt "Custom instruction"`                  |
| `--append-system-prompt`   | システムプロンプトに追加（`--print`でのみ）           | `claude --append-system-prompt "Custom instruction"`           |
| `--allowedTools`           | 許可されたツールのカンマ/スペース区切りリスト（MCPツールを含む）   | `claude --allowedTools "Bash(npm install),mcp__filesystem__*"` |
| `--disallowedTools`        | 拒否されたツールのカンマ/スペース区切りリスト              | `claude --disallowedTools "Bash(git commit),mcp__github__*"`   |
| `--mcp-config`             | JSONファイルからMCPサーバーを読み込む               | `claude --mcp-config servers.json`                             |
| `--permission-prompt-tool` | 権限プロンプトを処理するためのMCPツール（`--print`でのみ）  | `claude --permission-prompt-tool mcp__auth__prompt`            |

CLIオプションと機能の完全なリストについては、[CLI使用方法](/ja/docs/claude-code/cli-usage)のドキュメントを参照してください。

## 出力形式

SDKは複数の出力形式をサポートしています：

### テキスト出力（デフォルト）

応答テキストのみを返します：

```bash
$ claude -p "Explain file src/components/Header.tsx"
# 出力: This is a React component showing...
```

### JSON出力

メタデータを含む構造化データを返します：

```bash
$ claude -p "How does the data layer work?" --output-format json
```

応答形式：

```json
{
  "type": "result",
  "subtype": "success",
  "cost_usd": 0.003,
  "is_error": false,
  "duration_ms": 1234,
  "duration_api_ms": 800,
  "num_turns": 6,
  "result": "The response text here...",
  "session_id": "abc123"
}
```

### ストリーミングJSON出力

受信したメッセージをストリーミングします：

```bash
$ claude -p "Build an application" --output-format stream-json
```

各会話は初期の`init`システムメッセージで始まり、ユーザーとアシスタントのメッセージのリストが続き、最後に統計情報を含む`result`システムメッセージで終わります。各メッセージは別々のJSONオブジェクトとして出力されます。

## メッセージスキーマ

JSON APIから返されるメッセージは、次のスキーマに従って厳密に型付けされています：

```ts
type Message =
  // アシスタントメッセージ
  | {
      type: "assistant";
      message: APIAssistantMessage; // Anthropic SDKから
      session_id: string;
    }

  // ユーザーメッセージ
  | {
      type: "user";
      message: APIUserMessage; // Anthropic SDKから
      session_id: string;
    }

  // 最後のメッセージとして出力
  | {
      type: "result";
      subtype: "success";
      cost_usd: float;
      duration_ms: float;
      duration_api_ms: float;
      is_error: boolean;
      num_turns: int;
      result: string;
      session_id: string;
    }

  // 最大ターン数に達した場合、最後のメッセージとして出力
  | {
      type: "result";
      subtype: "error_max_turns";
      cost_usd: float;
      duration_ms: float;
      duration_api_ms: float;
      is_error: boolean;
      num_turns: int;
      session_id: string;
    }

  // 会話の開始時に最初のメッセージとして出力
  | {
      type: "system";
      subtype: "init";
      session_id: string;
      tools: string[];
      mcp_servers: {
        name: string;
        status: string;
      }[];
    };
```

これらの型はまもなくJSONSchema互換形式で公開される予定です。このフォーマットの破壊的変更を伝えるために、メインのClaude Codeパッケージではセマンティックバージョニングを使用しています。

## 例

### シンプルなスクリプト統合

```bash
#!/bin/bash

# Claudeを実行して終了コードをチェックするシンプルな関数
run_claude() {
    local prompt="$1"
    local output_format="${2:-text}"

    if claude -p "$prompt" --output-format "$output_format"; then
        echo "Success!"
    else
        echo "Error: Claude failed with exit code $?" >&2
        return 1
    fi
}

# 使用例
run_claude "Write a Python function to read CSV files"
run_claude "Optimize this database query" "json"
```

### Claudeでファイルを処理する

```bash
# ファイルをClaudeで処理
$ cat mycode.py | claude -p "Review this code for bugs"

# 複数のファイルを処理
$ for file in *.js; do
    echo "Processing $file..."
    claude -p "Add JSDoc comments to this file:" < "$file" > "${file}.documented"
done

# パイプラインでClaudeを使用
$ grep -l "TODO" *.py | while read file; do
    claude -p "Fix all TODO items in this file" < "$file"
done
```

### セッション管理

```bash
# セッションを開始してセッションIDをキャプチャ
$ claude -p "Initialize a new project" --output-format json | jq -r '.session_id' > session.txt

# 同じセッションを続行
$ claude -p --resume "$(cat session.txt)" "Add unit tests"

# 最近のセッションを一覧表示
$ claude logs
```

## ベストプラクティス

1. **JSON出力形式を使用**して応答をプログラムで解析する：

   ```bash
   # jqでJSON応答を解析
   result=$(claude -p "Generate code" --output-format json)
   code=$(echo "$result" | jq -r '.result')
   cost=$(echo "$result" | jq -r '.cost_usd')
   ```

2. **エラーを適切に処理する** - 終了コードとstderrをチェック：

   ```bash
   if ! claude -p "$prompt" 2>error.log; then
       echo "Error occurred:" >&2
       cat error.log >&2
       exit 1
   fi
   ```

3. **セッション管理を使用**して複数ターンの会話でコンテキストを維持する

4. **長時間実行される操作にはタイムアウトを考慮**する：

   ```bash
   timeout 300 claude -p "$complex_prompt" || echo "Timed out after 5 minutes"
   ```

5. **複数のリクエストを行う場合は、呼び出し間に遅延を追加してレート制限を尊重**する

## 実際のアプリケーション

Claude Code SDKは、開発ワークフローとの強力な統合を可能にします。注目すべき例として、[Claude Code GitHub Actions](/ja/docs/claude-code/github-actions)があります。これはSDKを使用して、GitHub内で直接自動コードレビュー、PR作成、課題トリアージ機能を提供します。

## 関連リソース

* [CLI使用方法とコントロール](/ja/docs/claude-code/cli-usage) - 完全なCLIドキュメント
* [GitHub Actions統合](/ja/docs/claude-code/github-actions) - ClaudeでGitHubワークフローを自動化
* [チュートリアル](/ja/docs/claude-code/tutorials) - 一般的なユースケースのステップバイステップガイド
