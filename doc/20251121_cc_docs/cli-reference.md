# CLIリファレンス

> Claude Codeコマンドラインインターフェースの完全なリファレンス（コマンドとフラグを含む）

## CLIコマンド

| コマンド                               | 説明                                   | 例                                          |
| :--------------------------------- | :----------------------------------- | :----------------------------------------- |
| `claude`                           | インタラクティブREPLを開始                      | `claude`                                   |
| `claude "query"`                   | 初期プロンプト付きでREPLを開始                    | `claude "explain this project"`            |
| `claude -p "query"`                | SDKを介してクエリを実行してから終了                  | `claude -p "explain this function"`        |
| `cat file \| claude -p "query"`    | パイプされたコンテンツを処理                       | `cat logs.txt \| claude -p "explain"`      |
| `claude -c`                        | 最新の会話を続行                             | `claude -c`                                |
| `claude -c -p "query"`             | SDKを介して続行                            | `claude -c -p "Check for type errors"`     |
| `claude -r "<session-id>" "query"` | IDでセッションを再開                          | `claude -r "abc123" "Finish this PR"`      |
| `claude update`                    | 最新バージョンに更新                           | `claude update`                            |
| `claude mcp`                       | Model Context Protocol (MCP) サーバーを設定 | [Claude Code MCPドキュメント](/ja/mcp)を参照してください。 |

## CLIフラグ

これらのコマンドラインフラグを使用してClaude Codeの動作をカスタマイズします：

| フラグ                              | 説明                                                                                                   | 例                                                                                                  |
| :------------------------------- | :--------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------- |
| `--add-dir`                      | Claudeがアクセスできる追加の作業ディレクトリを追加します（各パスがディレクトリとして存在することを検証します）                                           | `claude --add-dir ../apps ../lib`                                                                  |
| `--agents`                       | JSON経由でカスタム[サブエージェント](/ja/sub-agents)を動的に定義します（形式については以下を参照）                                         | `claude --agents '{"reviewer":{"description":"Reviews code","prompt":"You are a code reviewer"}}'` |
| `--allowedTools`                 | [settings.jsonファイル](/ja/settings)に加えて、ユーザーに許可を求めずに許可すべきツールのリスト                                       | `"Bash(git log:*)" "Bash(git diff:*)" "Read"`                                                      |
| `--disallowedTools`              | [settings.jsonファイル](/ja/settings)に加えて、ユーザーに許可を求めずに禁止すべきツールのリスト                                       | `"Bash(git log:*)" "Bash(git diff:*)" "Edit"`                                                      |
| `--print`, `-p`                  | インタラクティブモードなしで応答を出力します（プログラム的な使用方法の詳細については[SDKドキュメント](https://docs.claude.com/en/docs/agent-sdk)を参照） | `claude -p "query"`                                                                                |
| `--system-prompt`                | システムプロンプト全体をカスタムテキストに置き換えます（インタラクティブモードと出力モードの両方で機能します。v2.0.14で追加）                                   | `claude --system-prompt "You are a Python expert"`                                                 |
| `--system-prompt-file`           | ファイルからシステムプロンプトを読み込み、デフォルトプロンプトを置き換えます（出力モードのみ。v1.0.54で追加）                                           | `claude -p --system-prompt-file ./custom-prompt.txt "query"`                                       |
| `--append-system-prompt`         | デフォルトシステムプロンプトの末尾にカスタムテキストを追加します（インタラクティブモードと出力モードの両方で機能します。v1.0.55で追加）                              | `claude --append-system-prompt "Always use TypeScript"`                                            |
| `--output-format`                | 出力モードの出力形式を指定します（オプション：`text`、`json`、`stream-json`）                                                  | `claude -p "query" --output-format json`                                                           |
| `--input-format`                 | 出力モードの入力形式を指定します（オプション：`text`、`stream-json`）                                                         | `claude -p --output-format json --input-format stream-json`                                        |
| `--include-partial-messages`     | 出力にパーシャルストリーミングイベントを含めます（`--print`と`--output-format=stream-json`が必要）                                 | `claude -p --output-format stream-json --include-partial-messages "query"`                         |
| `--verbose`                      | 詳細ログを有効にし、ターンバイターンの完全な出力を表示します（出力モードとインタラクティブモードの両方でデバッグに役立ちます）                                      | `claude --verbose`                                                                                 |
| `--max-turns`                    | 非インタラクティブモードでのエージェンティックターン数を制限します                                                                    | `claude -p --max-turns 3 "query"`                                                                  |
| `--model`                        | 現在のセッションのモデルを、最新モデルのエイリアス（`sonnet`または`opus`）またはモデルの完全な名前で設定します                                       | `claude --model claude-sonnet-4-5-20250929`                                                        |
| `--permission-mode`              | 指定された[許可モード](/ja/iam#permission-modes)で開始します                                                         | `claude --permission-mode plan`                                                                    |
| `--permission-prompt-tool`       | 非インタラクティブモードで許可プロンプトを処理するMCPツールを指定します                                                                | `claude -p --permission-prompt-tool mcp_auth_tool "query"`                                         |
| `--resume`                       | IDでセッションを再開するか、インタラクティブモードで選択します                                                                     | `claude --resume abc123 "query"`                                                                   |
| `--continue`                     | 現在のディレクトリで最新の会話を読み込みます                                                                               | `claude --continue`                                                                                |
| `--dangerously-skip-permissions` | 許可プロンプトをスキップします（注意して使用してください）                                                                        | `claude --dangerously-skip-permissions`                                                            |

<Tip>
  `--output-format json`フラグはスクリプトと自動化に特に役立ち、Claudeの応答をプログラム的に解析できます。
</Tip>

### エージェントフラグの形式

`--agents`フラグは、1つ以上のカスタムサブエージェントを定義するJSONオブジェクトを受け入れます。各サブエージェントには、一意の名前（キーとして）と、以下のフィールドを持つ定義オブジェクトが必要です：

| フィールド         | 必須  | 説明                                                                         |
| :------------ | :-- | :------------------------------------------------------------------------- |
| `description` | はい  | サブエージェントをいつ呼び出すべきかの自然言語説明                                                  |
| `prompt`      | はい  | サブエージェントの動作をガイドするシステムプロンプト                                                 |
| `tools`       | いいえ | サブエージェントが使用できる特定のツールの配列（例：`["Read", "Edit", "Bash"]`）。省略した場合、すべてのツールを継承します |
| `model`       | いいえ | 使用するモデルエイリアス：`sonnet`、`opus`、または`haiku`。省略した場合、デフォルトのサブエージェントモデルを使用します     |

例：

```bash  theme={null}
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  },
  "debugger": {
    "description": "Debugging specialist for errors and test failures.",
    "prompt": "You are an expert debugger. Analyze errors, identify root causes, and provide fixes."
  }
}'
```

サブエージェントの作成と使用の詳細については、[サブエージェントドキュメント](/ja/sub-agents)を参照してください。

### システムプロンプトフラグ

Claude Codeは、システムプロンプトをカスタマイズするための3つのフラグを提供し、それぞれ異なる目的を果たします：

| フラグ                      | 動作                      | モード           | ユースケース                             |
| :----------------------- | :---------------------- | :------------ | :--------------------------------- |
| `--system-prompt`        | **デフォルトプロンプト全体を置き換えます** | インタラクティブ + 出力 | Claudeの動作と指示を完全に制御                 |
| `--system-prompt-file`   | **ファイルの内容で置き換えます**      | 出力のみ          | 再現性とバージョン管理のためにファイルからプロンプトを読み込む    |
| `--append-system-prompt` | **デフォルトプロンプトに追加します**    | インタラクティブ + 出力 | デフォルトのClaude Code動作を保持しながら特定の指示を追加 |

**各フラグを使用する場合：**

* **`--system-prompt`**：Claudeのシステムプロンプトを完全に制御する必要がある場合に使用します。これにより、すべてのデフォルトClaude Code指示が削除され、白紙の状態が得られます。
  ```bash  theme={null}
  claude --system-prompt "You are a Python expert who only writes type-annotated code"
  ```

* **`--system-prompt-file`**：ファイルからカスタムプロンプトを読み込みたい場合に使用します。チームの一貫性またはバージョン管理されたプロンプトテンプレートに役立ちます。
  ```bash  theme={null}
  claude -p --system-prompt-file ./prompts/code-review.txt "Review this PR"
  ```

* **`--append-system-prompt`**：Claude Codeのデフォルト機能を保持しながら特定の指示を追加したい場合に使用します。これはほとんどのユースケースで最も安全なオプションです。
  ```bash  theme={null}
  claude --append-system-prompt "Always use TypeScript and include JSDoc comments"
  ```

<Note>
  `--system-prompt`と`--system-prompt-file`は相互に排他的です。両方のフラグを同時に使用することはできません。
</Note>

<Tip>
  ほとんどのユースケースでは、`--append-system-prompt`が推奨されます。これはClaude Codeの組み込み機能を保持しながらカスタム要件を追加します。`--system-prompt`または`--system-prompt-file`は、システムプロンプトを完全に制御する必要がある場合にのみ使用してください。
</Tip>

出力形式、ストリーミング、詳細ログ、プログラム的な使用方法を含む出力モード（`-p`）の詳細については、[SDKドキュメント](https://docs.claude.com/en/docs/agent-sdk)を参照してください。

## 関連項目

* [インタラクティブモード](/ja/interactive-mode) - ショートカット、入力モード、インタラクティブ機能
* [スラッシュコマンド](/ja/slash-commands) - インタラクティブセッションコマンド
* [クイックスタートガイド](/ja/quickstart) - Claude Codeの開始方法
* [一般的なワークフロー](/ja/common-workflows) - 高度なワークフローとパターン
* [設定](/ja/settings) - 設定オプション
* [SDKドキュメント](https://docs.claude.com/en/docs/agent-sdk) - プログラム的な使用方法と統合
