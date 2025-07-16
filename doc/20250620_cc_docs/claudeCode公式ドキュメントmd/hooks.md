# フック

> シェルコマンドを登録してClaude Codeの動作をカスタマイズし、拡張します

# はじめに

Claude Codeフックは、Claude Codeのライフサイクルの様々な時点で実行されるユーザー定義のシェルコマンドです。フックは、Claude Codeの動作に対する決定論的な制御を提供し、LLMが実行を選択することに依存するのではなく、特定のアクションが常に実行されることを保証します。

使用例には以下が含まれます：

* **通知**: Claude Codeがあなたの入力や何かを実行する許可を待っているときの通知方法をカスタマイズします。
* **自動フォーマット**: ファイル編集後に.tsファイルに対して`prettier`を実行し、.goファイルに対して`gofmt`を実行するなど。
* **ログ記録**: コンプライアンスやデバッグのために実行されたすべてのコマンドを追跡し、カウントします。
* **フィードバック**: Claude Codeがあなたのコードベース規約に従わないコードを生成したときに自動化されたフィードバックを提供します。
* **カスタム権限**: 本番ファイルや機密ディレクトリへの変更をブロックします。

これらのルールをプロンプト指示ではなくフックとしてエンコードすることで、提案を実行されることが期待されるたびに実行されるアプリレベルのコードに変換します。

<Warning>
  フックは確認なしにあなたの完全なユーザー権限でシェルコマンドを実行します。フックが安全でセキュアであることを確保する責任はあなたにあります。Anthropicは、フックの使用によるデータ損失やシステム損害について責任を負いません。[セキュリティ考慮事項](#security-considerations)を確認してください。
</Warning>

## クイックスタート

このクイックスタートでは、Claude Codeが実行するシェルコマンドをログに記録するフックを追加します。

クイックスタートの前提条件：コマンドラインでのJSON処理のために`jq`をインストールしてください。

### ステップ1: フック設定を開く

`/hooks` [スラッシュコマンド](/ja/docs/claude-code/slash-commands)を実行し、`PreToolUse`フックイベントを選択します。

`PreToolUse`フックはツール呼び出しの前に実行され、Claudeに何を異なって行うべきかのフィードバックを提供しながらそれらをブロックできます。

### ステップ2: マッチャーを追加

`+ Add new matcher…`を選択して、Bashツール呼び出しのみでフックを実行します。

マッチャーに`Bash`と入力します。

### ステップ3: フックを追加

`+ Add new hook…`を選択し、このコマンドを入力します：

```bash
jq -r '"\(.tool_input.command) - \(.tool_input.description // "No description")"' >> ~/.claude/bash-command-log.txt
```

### ステップ4: 設定を保存

保存場所として、ホームディレクトリにログを記録するため`User settings`を選択します。このフックは現在のプロジェクトだけでなく、すべてのプロジェクトに適用されます。

次にEscキーを押してREPLに戻ります。フックが登録されました！

### ステップ5: フックを確認

再度`/hooks`を実行するか、`~/.claude/settings.json`をチェックして設定を確認します：

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "jq -r '\"\\(.tool_input.command) - \\(.tool_input.description // \"No description\")\"' >> ~/.claude/bash-command-log.txt"
        }
      ]
    }
  ]
}
```

## 設定

Claude Codeフックは[設定ファイル](/ja/docs/claude-code/settings)で設定されます：

* `~/.claude/settings.json` - ユーザー設定
* `.claude/settings.json` - プロジェクト設定
* `.claude/settings.local.json` - ローカルプロジェクト設定（コミットされない）
* エンタープライズ管理ポリシー設定

### 構造

フックはマッチャーによって整理され、各マッチャーは複数のフックを持つことができます：

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here"
          }
        ]
      }
    ]
  }
}
```

* **matcher**: ツール名にマッチするパターン（`PreToolUse`と`PostToolUse`にのみ適用）
  * 単純な文字列は完全一致：`Write`はWriteツールのみにマッチ
  * 正規表現をサポート：`Edit|Write`または`Notebook.*`
  * 省略または空文字列の場合、すべてのマッチングイベントでフックが実行
* **hooks**: パターンがマッチしたときに実行するコマンドの配列
  * `type`: 現在は`"command"`のみサポート
  * `command`: 実行するbashコマンド
  * `timeout`: （オプション）進行中のすべてのフックをキャンセルする前に、コマンドが実行される時間（秒）

## フックイベント

### PreToolUse

Claudeがツールパラメータを作成した後、ツール呼び出しを処理する前に実行されます。

**一般的なマッチャー：**

* `Task` - エージェントタスク
* `Bash` - シェルコマンド
* `Glob` - ファイルパターンマッチング
* `Grep` - コンテンツ検索
* `Read` - ファイル読み取り
* `Edit`, `MultiEdit` - ファイル編集
* `Write` - ファイル書き込み
* `WebFetch`, `WebSearch` - Web操作

### PostToolUse

ツールが正常に完了した直後に実行されます。

PreToolUseと同じマッチャー値を認識します。

### Notification

Claude Codeが通知を送信するときに実行されます。

### Stop

メインのClaude Codeエージェントが応答を完了したときに実行されます。

### SubagentStop

Claude Codeサブエージェント（Taskツール呼び出し）が応答を完了したときに実行されます。

## フック入力

フックは、セッション情報とイベント固有のデータを含むJSONデータをstdinを介して受信します：

```typescript
{
  // 共通フィールド
  session_id: string
  transcript_path: string  // 会話JSONへのパス

  // イベント固有フィールド
  ...
}
```

### PreToolUse入力

`tool_input`の正確なスキーマはツールによって異なります。

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  }
}
```

### PostToolUse入力

`tool_input`と`tool_response`の正確なスキーマはツールによって異なります。

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  },
  "tool_response": {
    "filePath": "/path/to/file.txt",
    "success": true
  }
}
```

### Notification入力

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "message": "Task completed successfully",
  "title": "Claude Code"
}
```

### StopとSubagentStop入力

`stop_hook_active`は、Claude Codeがストップフックの結果として既に継続している場合にtrueです。Claude Codeが無限に実行されることを防ぐために、この値をチェックするかトランスクリプトを処理してください。

```json
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "stop_hook_active": true
}
```

## フック出力

フックがClaude Codeに出力を返す方法は2つあります。出力は、ブロックするかどうかと、Claudeとユーザーに表示されるべきフィードバックを伝達します。

### シンプル: 終了コード

フックは終了コード、stdout、stderrを通じてステータスを伝達します：

* **終了コード0**: 成功。`stdout`はトランスクリプトモード（CTRL-R）でユーザーに表示されます。
* **終了コード2**: ブロッキングエラー。`stderr`は自動的に処理するためにClaudeにフィードバックされます。以下のフックイベントごとの動作を参照してください。
* **その他の終了コード**: 非ブロッキングエラー。`stderr`はユーザーに表示され、実行が継続されます。

<Warning>
  注意：終了コードが0の場合、Claude Codeはstdoutを見ません。
</Warning>

#### 終了コード2の動作

| フックイベント        | 動作                             |
| -------------- | ------------------------------ |
| `PreToolUse`   | ツール呼び出しをブロックし、Claudeにエラーを表示    |
| `PostToolUse`  | Claudeにエラーを表示（ツールは既に実行済み）      |
| `Notification` | N/A、ユーザーにのみstderrを表示           |
| `Stop`         | 停止をブロックし、Claudeにエラーを表示         |
| `SubagentStop` | 停止をブロックし、Claudeサブエージェントにエラーを表示 |

### 高度: JSON出力

フックは、より洗練された制御のために`stdout`で構造化されたJSONを返すことができます：

#### 共通JSONフィールド

すべてのフックタイプは、これらのオプションフィールドを含むことができます：

```json
{
  "continue": true, // フック実行後にClaudeが継続すべきかどうか（デフォルト: true）
  "stopReason": "string" // continueがfalseの場合に表示されるメッセージ
  "suppressOutput": true, // トランスクリプトモードからstdoutを隠す（デフォルト: false）
}
```

`continue`がfalseの場合、Claudeはフック実行後に処理を停止します。

* `PreToolUse`の場合、これは特定のツール呼び出しのみをブロックしてClaudeに自動フィードバックを提供する`"decision": "block"`とは異なります。
* `PostToolUse`の場合、これはClaudeに自動フィードバックを提供する`"decision": "block"`とは異なります。
* `Stop`と`SubagentStop`の場合、これは任意の`"decision": "block"`出力よりも優先されます。
* すべての場合において、`"continue" = false`は任意の`"decision": "block"`出力よりも優先されます。

`stopReason`は`continue`に伴い、ユーザーに表示される理由を提供しますが、Claudeには表示されません。

#### `PreToolUse`決定制御

`PreToolUse`フックは、ツール呼び出しが進行するかどうかを制御できます。

* "approve"は権限システムをバイパスします。`reason`はユーザーに表示されますが、Claudeには表示されません。
* "block"はツール呼び出しの実行を防ぎます。`reason`はClaudeに表示されます。
* `undefined`は既存の権限フローにつながります。`reason`は無視されます。

```json
{
  "decision": "approve" | "block" | undefined,
  "reason": "決定の説明"
}
```

#### `PostToolUse`決定制御

`PostToolUse`フックは、ツール呼び出しが進行するかどうかを制御できます。

* "block"は`reason`でClaudeに自動的にプロンプトします。
* `undefined`は何もしません。`reason`は無視されます。

```json
{
  "decision": "block" | undefined,
  "reason": "決定の説明"
}
```

#### `Stop`/`SubagentStop`決定制御

`Stop`と`SubagentStop`フックは、Claudeが継続する必要があるかどうかを制御できます。

* "block"はClaudeの停止を防ぎます。Claudeがどのように進行するかを知るために`reason`を入力する必要があります。
* `undefined`はClaudeの停止を許可します。`reason`は無視されます。

```json
{
  "decision": "block" | undefined,
  "reason": "Claudeが停止をブロックされた場合に提供する必要があります"
}
```

#### JSON出力例: Bashコマンド編集

```python
#!/usr/bin/env python3
import json
import re
import sys

# 検証ルールを（正規表現パターン、メッセージ）タプルのリストとして定義
VALIDATION_RULES = [
    (
        r"\bgrep\b(?!.*\|)",
        "より良いパフォーマンスと機能のために'grep'の代わりに'rg'（ripgrep）を使用してください",
    ),
    (
        r"\bfind\s+\S+\s+-name\b",
        "より良いパフォーマンスのために'find -name'の代わりに'rg --files | rg pattern'または'rg --files -g pattern'を使用してください",
    ),
]


def validate_command(command: str) -> list[str]:
    issues = []
    for pattern, message in VALIDATION_RULES:
        if re.search(pattern, command):
            issues.append(message)
    return issues


try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"エラー: 無効なJSON入力: {e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})
command = tool_input.get("command", "")

if tool_name != "Bash" or not command:
    sys.exit(1)

# コマンドを検証
issues = validate_command(command)

if issues:
    for message in issues:
        print(f"• {message}", file=sys.stderr)
    # 終了コード2はツール呼び出しをブロックし、stderrをClaudeに表示
    sys.exit(2)
```

## MCPツールとの連携

Claude Codeフックは[Model Context Protocol（MCP）ツール](/ja/docs/claude-code/mcp)とシームレスに連携します。MCPサーバーがツールを提供する場合、フックでマッチできる特別な命名パターンで表示されます。

### MCPツールの命名

MCPツールは`mcp__<server>__<tool>`のパターンに従います。例：

* `mcp__memory__create_entities` - Memoryサーバーのエンティティ作成ツール
* `mcp__filesystem__read_file` - Filesystemサーバーのファイル読み取りツール
* `mcp__github__search_repositories` - GitHubサーバーの検索ツール

### MCPツール用のフック設定

特定のMCPツールまたはMCPサーバー全体をターゲットにできます：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__memory__.*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Memory operation initiated' >> ~/mcp-operations.log"
          }
        ]
      },
      {
        "matcher": "mcp__.*__write.*",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/scripts/validate-mcp-write.py"
          }
        ]
      }
    ]
  }
}
```

## 例

### コードフォーマット

ファイル変更後にコードを自動的にフォーマット：

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "/home/user/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

### 通知

Claude Codeが許可を要求するときやプロンプト入力がアイドル状態になったときに送信される通知をカスタマイズします。

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/my_custom_notifier.py"
          }
        ]
      }
    ]
  }
}
```

## セキュリティ考慮事項

### 免責事項

**自己責任で使用してください**: Claude Codeフックは、システム上で任意のシェルコマンドを自動的に実行します。フックを使用することで、以下を認識します：

* 設定するコマンドについて単独で責任を負います
* フックは、ユーザーアカウントがアクセスできる任意のファイルを変更、削除、またはアクセスできます
* 悪意のあるまたは不適切に書かれたフックは、データ損失やシステム損害を引き起こす可能性があります
* Anthropicは保証を提供せず、フック使用による損害について責任を負いません
* 本番使用前に安全な環境でフックを徹底的にテストする必要があります

設定に追加する前に、フックコマンドを常に確認し、理解してください。

### セキュリティベストプラクティス

より安全なフックを書くための主要な実践方法：

1. **入力を検証し、サニタイズする** - 入力データを盲目的に信頼しない
2. **常にシェル変数を引用符で囲む** - `$VAR`ではなく`"$VAR"`を使用
3. **パストラバーサルをブロックする** - ファイルパスで`..`をチェック
4. **絶対パスを使用する** - スクリプトの完全パスを指定
5. **機密ファイルをスキップする** - `.env`、`.git/`、キーなどを避ける

### 設定の安全性

設定ファイルでのフックの直接編集は、すぐには有効になりません。Claude Codeは：

1. 起動時にフックのスナップショットをキャプチャ
2. セッション全体でこのスナップショットを使用
3. フックが外部で変更された場合に警告
4. 変更を適用するために`/hooks`メニューでの確認が必要

これにより、悪意のあるフック変更が現在のセッションに影響することを防ぎます。

## フック実行の詳細

* **タイムアウト**: デフォルトで60秒の実行制限、コマンドごとに設定可能。
  * 個別のコマンドがタイムアウトした場合、進行中のすべてのフックがキャンセルされます。
* **並列化**: マッチするすべてのフックが並列で実行
* **環境**: Claude Codeの環境で現在のディ レクトリで実行
* **入力**: stdinを介したJSON
* **出力**:
  * PreToolUse/PostToolUse/Stop: トランスクリプトに進行状況が表示（Ctrl-R）
  * Notification: デバッグのみにログ記録（`--debug`）

## デバッグ

フックのトラブルシューティング：

1. `/hooks`メニューが設定を表示するかチェック
2. [設定ファイル](/ja/docs/claude-code/settings)が有効なJSONであることを確認
3. コマンドを手動でテスト
4. 終了コードをチェック
5. stdoutとstderrフォーマットの期待値を確認
6. 適切な引用符エスケープを確保
7. フックをデバッグするために`claude --debug`を使用。成功したフックの出力は以下のように表示されます。

```
[DEBUG] Executing hooks for PostToolUse:Write
[DEBUG] Getting matching hook commands for PostToolUse with query: Write
[DEBUG] Found 1 hook matchers in settings
[DEBUG] Matched 1 hooks for query "Write"
[DEBUG] Found 1 hook commands to execute
[DEBUG] Executing hook command: <Your command> with timeout 60000ms
[DEBUG] Hook command completed with status 0: <Your stdout>
```

進行状況メッセージはトランスクリプトモード（Ctrl-R）に表示され、以下を示します：

* どのフックが実行されているか
* 実行されているコマンド
* 成功/失敗ステータス
* 出力またはエラーメッセージ
