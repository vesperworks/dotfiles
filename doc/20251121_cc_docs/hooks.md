# フックリファレンス

> このページでは、Claude Codeでフックを実装するためのリファレンスドキュメントを提供します。

<Tip>
  クイックスタートガイドと例については、[Claude Codeフックの開始](/ja/hooks-guide)を参照してください。
</Tip>

## 設定

Claude Codeフックは[設定ファイル](/ja/settings)で設定されます：

* `~/.claude/settings.json` - ユーザー設定
* `.claude/settings.json` - プロジェクト設定
* `.claude/settings.local.json` - ローカルプロジェクト設定（コミットされない）
* エンタープライズ管理ポリシー設定

### 構造

フックはマッチャーで整理され、各マッチャーは複数のフックを持つことができます：

```json  theme={null}
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

* **matcher**: ツール名にマッチするパターン、大文字小文字を区別します（`PreToolUse`と`PostToolUse`にのみ適用可能）
  * シンプルな文字列は正確にマッチします：`Write`はWriteツールのみにマッチします
  * 正規表現をサポートします：`Edit|Write`または`Notebook.*`
  * `*`を使用してすべてのツールにマッチします。空の文字列（`""`）を使用することもできます、または`matcher`を空白のままにします。
* **hooks**: パターンがマッチしたときに実行するフックの配列
  * `type`: フック実行タイプ - bashコマンドの場合は`"command"`、LLMベースの評価の場合は`"prompt"`
  * `command`: （`type: "command"`の場合）実行するbashコマンド（`$CLAUDE_PROJECT_DIR`環境変数を使用できます）
  * `prompt`: （`type: "prompt"`の場合）LLMに送信する評価用プロンプト
  * `timeout`: （オプション）フックが実行される時間（秒単位）、その特定のフックをキャンセルする前に

`UserPromptSubmit`、`Notification`、`Stop`、`SubagentStop`などのマッチャーを使用しないイベントの場合、matcherフィールドを省略できます：

```json  theme={null}
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/prompt-validator.py"
          }
        ]
      }
    ]
  }
}
```

### プロジェクト固有のフックスクリプト

環境変数`CLAUDE_PROJECT_DIR`（Claude Codeがフックコマンドを生成するときのみ利用可能）を使用して、プロジェクトに保存されているスクリプトを参照できます。これにより、Claude Codeの現在のディレクトリに関係なく機能することが保証されます：

```json  theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-style.sh"
          }
        ]
      }
    ]
  }
}
```

### プラグインフック

[プラグイン](/ja/plugins)は、ユーザーおよびプロジェクトフックとシームレスに統合するフックを提供できます。プラグインフックは、プラグインが有効になると自動的に設定とマージされます。

**プラグインフックの仕組み**：

* プラグインフックはプラグインの`hooks/hooks.json`ファイル、または`hooks`フィールドにカスタムパスで指定されたファイルで定義されます。
* プラグインが有効になると、そのフックはユーザーおよびプロジェクトフックとマージされます
* 異なるソースからの複数のフックが同じイベントに応答できます
* プラグインフックは`${CLAUDE_PLUGIN_ROOT}`環境変数を使用してプラグインファイルを参照します

**プラグインフック設定の例**：

```json  theme={null}
{
  "description": "自動コードフォーマット",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

<Note>
  プラグインフックは通常のフックと同じ形式を使用し、フックの目的を説明するオプションの`description`フィールドがあります。
</Note>

<Note>
  プラグインフックはカスタムフックと並行して実行されます。複数のフックがイベントにマッチする場合、すべてが並行して実行されます。
</Note>

**プラグイン用の環境変数**：

* `${CLAUDE_PLUGIN_ROOT}`: プラグインディレクトリへの絶対パス
* `${CLAUDE_PROJECT_DIR}`: プロジェクトルートディレクトリ（プロジェクトフックと同じ）
* すべての標準環境変数が利用可能です

プラグインフックの作成の詳細については、[プラグインコンポーネントリファレンス](/ja/plugins-reference#hooks)を参照してください。

## プロンプトベースのフック

bashコマンドフック（`type: "command"`）に加えて、Claude Codeはプロンプトベースのフック（`type: "prompt"`）をサポートしており、LLMを使用してアクションを許可するかブロックするかを評価します。プロンプトベースのフックは現在`Stop`と`SubagentStop`フックのみでサポートされており、インテリジェントでコンテキスト認識の決定を可能にします。

### プロンプトベースのフックの仕組み

bashコマンドを実行する代わりに、プロンプトベースのフックは：

1. フック入力とプロンプトを高速LLM（Haiku）に送信します
2. LLMは決定を含む構造化JSONで応答します
3. Claude Codeは決定を自動的に処理します

### 設定

```json  theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Claudeが停止すべきかどうかを評価してください：$ARGUMENTS。すべてのタスクが完了しているかどうかを確認してください。"
          }
        ]
      }
    ]
  }
}
```

**フィールド：**

* `type`: `"prompt"`である必要があります
* `prompt`: LLMに送信するプロンプトテキスト
  * フック入力JSONのプレースホルダーとして`$ARGUMENTS`を使用します
  * `$ARGUMENTS`が存在しない場合、入力JSONはプロンプトに追加されます
* `timeout`: （オプション）タイムアウト（秒単位）（デフォルト：30秒）

### レスポンススキーマ

LLMは以下を含むJSONで応答する必要があります：

```json  theme={null}
{
  "decision": "approve" | "block",
  "reason": "決定の説明",
  "continue": false,  // オプション：Claude全体を停止します
  "stopReason": "ユーザーに表示されるメッセージ",  // オプション：カスタム停止メッセージ
  "systemMessage": "警告またはコンテキスト"  // オプション：ユーザーに表示されます
}
```

**レスポンスフィールド：**

* `decision`: `"approve"`はアクションを許可し、`"block"`はそれを防ぎます
* `reason`: 決定が`"block"`の場合、Claudeに表示される説明
* `continue`: （オプション）`false`の場合、Claude全体の実行を停止します
* `stopReason`: （オプション）`continue`がfalseの場合に表示されるメッセージ
* `systemMessage`: （オプション）ユーザーに表示される追加メッセージ

### サポートされているフックイベント

プロンプトベースのフックはすべてのフックイベントで機能しますが、以下に最も有用です：

* **Stop**: Claudeが作業を続けるべきかどうかをインテリジェントに決定します
* **SubagentStop**: サブエージェントがそのタスクを完了したかどうかを評価します
* **UserPromptSubmit**: LLM支援でユーザープロンプトを検証します
* **PreToolUse**: コンテキスト認識の権限決定を行います

### 例：インテリジェントStopフック

```json  theme={null}
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Claudeが作業を停止すべきかどうかを評価しています。コンテキスト：$ARGUMENTS\n\n会話を分析し、以下を判断してください：\n1. すべてのユーザーがリクエストしたタスクが完了しているか\n2. 対処する必要があるエラーがあるか\n3. フォローアップ作業が必要か\n\nJSON形式で応答してください：{\"decision\": \"approve\"または\"block\"、\"reason\": \"あなたの説明\"}",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### 例：カスタムロジックを使用したSubagentStop

```json  theme={null}
{
  "hooks": {
    "SubagentStop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "このサブエージェントが停止すべきかどうかを評価してください。入力：$ARGUMENTS\n\n以下を確認してください：\n- サブエージェントが割り当てられたタスクを完了したか\n- 修正が必要なエラーが発生したか\n- 追加のコンテキスト収集が必要か\n\n戻り値：{\"decision\": \"approve\"または\"block\"、\"reason\": \"説明\"}"
          }
        ]
      }
    ]
  }
}
```

### bashコマンドフックとの比較

| 機能             | Bashコマンドフック  | プロンプトベースのフック  |
| -------------- | ------------ | ------------- |
| **実行**         | bashスクリプトを実行 | LLMにクエリ       |
| **決定ロジック**     | コードで実装       | LLMがコンテキストを評価 |
| **セットアップの複雑さ** | スクリプトファイルが必要 | プロンプトを設定するだけ  |
| **コンテキスト認識**   | スクリプトロジックに限定 | 自然言語理解        |
| **パフォーマンス**    | 高速（ローカル実行）   | 低速（APIコール）    |
| **ユースケース**     | 決定論的ルール      | コンテキスト認識の決定   |

### ベストプラクティス

* **プロンプトで具体的に**: LLMに評価してほしいことを明確に述べてください
* **決定基準を含める**: LLMが考慮すべき要因をリストアップしてください
* **プロンプトをテストする**: LLMがユースケースに対して正しい決定を下すことを確認してください
* **適切なタイムアウトを設定する**: デフォルトは30秒です、必要に応じて調整してください
* **複雑な決定に使用する**: Bashフックはシンプルで決定論的なルールに適しています

プラグインフックの作成の詳細については、[プラグインコンポーネントリファレンス](/ja/plugins-reference#hooks)を参照してください。

## フックイベント

### PreToolUse

Claudeがツールパラメータを作成した後、ツール呼び出しを処理する前に実行されます。

**一般的なマッチャー：**

* `Task` - サブエージェントタスク（[サブエージェントドキュメント](/ja/sub-agents)を参照）
* `Bash` - シェルコマンド
* `Glob` - ファイルパターンマッチング
* `Grep` - コンテンツ検索
* `Read` - ファイル読み取り
* `Edit` - ファイル編集
* `Write` - ファイル書き込み
* `WebFetch`、`WebSearch` - ウェブ操作

### PostToolUse

ツールが正常に完了した直後に実行されます。

PreToolUseと同じマッチャー値を認識します。

### Notification

Claude Codeが通知を送信するときに実行されます。通知は以下の場合に送信されます：

1. Claudeがツールを使用する権限が必要な場合。例：「Claudeがbashを使用する権限が必要です」
2. プロンプト入力が少なくとも60秒間アイドル状態にある場合。「Claudeはあなたの入力を待っています」

### UserPromptSubmit

ユーザーがプロンプトを送信するときに実行されます。Claudeがそれを処理する前に実行されます。これにより、プロンプト/会話に基づいて追加のコンテキストを追加したり、プロンプトを検証したり、特定の種類のプロンプトをブロックしたりできます。

### Stop

メインClaude Codeエージェントが応答を完了したときに実行されます。ユーザー割り込みが原因で停止が発生した場合は実行されません。

### SubagentStop

Claude Codeサブエージェント（Taskツール呼び出し）が応答を完了したときに実行されます。

### PreCompact

Claude Codeがコンパクト操作を実行しようとする前に実行されます。

**マッチャー：**

* `manual` - `/compact`から呼び出された
* `auto` - 自動コンパクトから呼び出された（コンテキストウィンドウが満杯のため）

### SessionStart

Claude Codeが新しいセッションを開始するか、既存のセッションを再開するときに実行されます（現在、内部的には新しいセッションを開始します）。既存の問題や最近のコードベースの変更などの開発コンテキストをロードしたり、依存関係をインストールしたり、環境変数を設定したりするのに便利です。

**マッチャー：**

* `startup` - スタートアップから呼び出された
* `resume` - `--resume`、`--continue`、または`/resume`から呼び出された
* `clear` - `/clear`から呼び出された
* `compact` - 自動または手動コンパクトから呼び出された。

#### 環境変数の永続化

SessionStartフックは`CLAUDE_ENV_FILE`環境変数にアクセスでき、後続のbashコマンドの環境変数を永続化できるファイルパスを提供します。

**例：個別の環境変数を設定する**

```bash  theme={null}
#!/bin/bash

if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
  echo 'export API_KEY=your-api-key' >> "$CLAUDE_ENV_FILE"
  echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
fi

exit 0
```

**例：フックからのすべての環境変更を永続化する**

セットアップが環境を変更する場合（例：`nvm use`）、環境をdiffして、すべての変更をキャプチャして永続化します：

```bash  theme={null}
#!/bin/bash

ENV_BEFORE=$(export -p | sort)

# 環境を変更するセットアップコマンドを実行します
source ~/.nvm/nvm.sh
nvm use 20

if [ -n "$CLAUDE_ENV_FILE" ]; then
  ENV_AFTER=$(export -p | sort)
  comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
fi

exit 0
```

このファイルに書き込まれた変数は、セッション中にClaude Codeが実行するすべての後続のbashコマンドで利用可能になります。

<Note>
  `CLAUDE_ENV_FILE`はSessionStartフックでのみ利用可能です。他のフックタイプはこの変数にアクセスできません。
</Note>

### SessionEnd

Claude Codeセッションが終了するときに実行されます。クリーンアップタスク、セッション統計のログ、またはセッション状態の保存に便利です。

フック入力の`reason`フィールドは以下のいずれかになります：

* `clear` - /clearコマンドでセッションがクリアされた
* `logout` - ユーザーがログアウトした
* `prompt_input_exit` - プロンプト入力が表示されている間にユーザーが終了した
* `other` - その他の終了理由

## フック入力

フックはstdinを介してセッション情報とイベント固有のデータを含むJSONデータを受け取ります：

```typescript  theme={null}
{
  // 共通フィールド
  session_id: string
  transcript_path: string  // 会話JSONへのパス
  cwd: string              // フックが呼び出されるときの現在の作業ディレクトリ
  permission_mode: string  // 現在の権限モード："default"、"plan"、"acceptEdits"、または"bypassPermissions"

  // イベント固有フィールド
  hook_event_name: string
  ...
}
```

### PreToolUse入力

`tool_input`の正確なスキーマはツールによって異なります。

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/file.txt",
    "content": "file content"
  }
}
```

### PostToolUse入力

`tool_input`と`tool_response`の正確なスキーマはツールによって異なります。

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "PostToolUse",
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

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "Notification",
  "message": "Task completed successfully"
}
```

### UserPromptSubmit入力

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "UserPromptSubmit",
  "prompt": "数値の階乗を計算する関数を書いてください"
}
```

### StopおよびSubagentStop入力

`stop_hook_active`は、Claude Codeがすでにstopフックの結果として続行している場合、trueです。この値をチェックするか、トランスクリプトを処理して、Claude Codeが無限に実行されるのを防ぎます。

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "permission_mode": "default",
  "hook_event_name": "Stop",
  "stop_hook_active": true
}
```

### PreCompact入力

`manual`の場合、`custom_instructions`はユーザーが`/compact`に渡すものから来ます。`auto`の場合、`custom_instructions`は空です。

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "permission_mode": "default",
  "hook_event_name": "PreCompact",
  "trigger": "manual",
  "custom_instructions": ""
}
```

### SessionStart入力

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "permission_mode": "default",
  "hook_event_name": "SessionStart",
  "source": "startup"
}
```

### SessionEnd入力

```json  theme={null}
{
  "session_id": "abc123",
  "transcript_path": "~/.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "SessionEnd",
  "reason": "exit"
}
```

## フック出力

フックがClaude Codeに出力を返す方法は2つあります。出力は、ブロックするかどうか、およびClaudeとユーザーに表示されるべきフィードバックを通信します。

### シンプル：終了コード

フックは終了コード、stdout、stderrを通じてステータスを通信します：

* **終了コード0**: 成功。`stdout`はトランスクリプトモード（CTRL-R）でユーザーに表示されます。ただし、`UserPromptSubmit`と`SessionStart`の場合を除き、stdoutはコンテキストに追加されます。
* **終了コード2**: ブロッキングエラー。`stderr`はClaudeに自動的にフィードバックされます。フックイベントごとの動作については以下を参照してください。
* **その他の終了コード**: ブロッキングなしのエラー。`stderr`はユーザーに表示され、実行は続行されます。

<Warning>
  リマインダー：Claude Codeは終了コードが0の場合、stdoutを見ません。ただし、`UserPromptSubmit`フックの場合を除き、stdoutはコンテキストに注入されます。
</Warning>

#### 終了コード2の動作

| フックイベント            | 動作                                     |
| ------------------ | -------------------------------------- |
| `PreToolUse`       | ツール呼び出しをブロックし、stderrをClaudeに表示         |
| `PostToolUse`      | stderrをClaudeに表示（ツールはすでに実行済み）          |
| `Notification`     | N/A、stderrはユーザーのみに表示                   |
| `UserPromptSubmit` | プロンプト処理をブロック、プロンプトを消去、stderrはユーザーのみに表示 |
| `Stop`             | 停止をブロック、stderrをClaudeに表示               |
| `SubagentStop`     | 停止をブロック、stderrをClaudeサブエージェントに表示       |
| `PreCompact`       | N/A、stderrはユーザーのみに表示                   |
| `SessionStart`     | N/A、stderrはユーザーのみに表示                   |
| `SessionEnd`       | N/A、stderrはユーザーのみに表示                   |

### 高度な：JSON出力

フックはより高度な制御のために`stdout`で構造化JSONを返すことができます：

#### 共通JSONフィールド

すべてのフックタイプは以下のオプションフィールドを含むことができます：

```json  theme={null}
{
  "continue": true, // フック実行後にClaudeが続行するかどうか（デフォルト：true）
  "stopReason": "string", // continueがfalseの場合に表示されるメッセージ

  "suppressOutput": true, // トランスクリプトモードからstdoutを非表示（デフォルト：false）
  "systemMessage": "string" // ユーザーに表示されるオプションの警告メッセージ
}
```

`continue`がfalseの場合、フックが実行された後、Claudeは処理を停止します。

* `PreToolUse`の場合、これは`"permissionDecision": "deny"`と異なります。これは特定のツール呼び出しのみをブロックし、Claudeに自動フィードバックを提供します。
* `PostToolUse`の場合、これは`"decision": "block"`と異なります。これはClaudeに自動フィードバックを提供します。
* `UserPromptSubmit`の場合、これはプロンプトが処理されるのを防ぎます。
* `Stop`と`SubagentStop`の場合、これは任意の`"decision": "block"`出力よりも優先されます。
* すべての場合において、`"continue" = false`は任意の`"decision": "block"`出力よりも優先されます。

`stopReason`は`continue`に付随し、ユーザーに表示される理由を示し、Claudeには表示されません。

#### `PreToolUse`決定制御

`PreToolUse`フックはツール呼び出しが進行するかどうかを制御できます。

* `"allow"`は権限システムをバイパスします。`permissionDecisionReason`はユーザーに表示されますが、Claudeには表示されません。
* `"deny"`はツール呼び出しが実行されるのを防ぎます。`permissionDecisionReason`はClaudeに表示されます。
* `"ask"`はUIでユーザーにツール呼び出しを確認するよう求めます。`permissionDecisionReason`はユーザーに表示されますが、Claudeには表示されません。

さらに、フックは`updatedInput`を使用して実行前にツール入力を変更できます：

* `updatedInput`を使用すると、ツールが実行される前にツールの入力パラメータを変更できます。これは変更または追加したいフィールドを含む`Record<string, unknown>`オブジェクトです。
* これは`"permissionDecision": "allow"`で最も有用で、ツール呼び出しを変更して承認します。

```json  theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
    "permissionDecisionReason": "ここに理由を入力",
    "updatedInput": {
      "field_to_modify": "new value"
    }
  }
}
```

<Note>
  `decision`と`reason`フィールドはPreToolUseフックでは非推奨です。
  代わりに`hookSpecificOutput.permissionDecision`と
  `hookSpecificOutput.permissionDecisionReason`を使用してください。非推奨フィールド
  `"approve"`と`"block"`は`"allow"`と`"deny"`にマップされます。
</Note>

#### `PostToolUse`決定制御

`PostToolUse`フックはツール実行後にClaudeにフィードバックを提供できます。

* `"block"`は自動的に`reason`でClaudeにプロンプトを表示します。
* `undefined`は何もしません。`reason`は無視されます。
* `"hookSpecificOutput.additionalContext"`はClaudeが考慮するコンテキストを追加します。

```json  theme={null}
{
  "decision": "block" | undefined,
  "reason": "決定の説明",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Claudeが考慮する追加情報"
  }
}
```

#### `UserPromptSubmit`決定制御

`UserPromptSubmit`フックはユーザープロンプトが処理されるかどうかを制御できます。

* `"block"`はプロンプトが処理されるのを防ぎます。送信されたプロンプトはコンテキストから消去されます。`"reason"`はユーザーに表示されますが、コンテキストには追加されません。
* `undefined`はプロンプトが通常通り進行することを許可します。`"reason"`は無視されます。
* `"hookSpecificOutput.additionalContext"`はブロックされていない場合、文字列をコンテキストに追加します。

```json  theme={null}
{
  "decision": "block" | undefined,
  "reason": "決定の説明",
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "ここに追加コンテキストを入力"
  }
}
```

#### `Stop`/`SubagentStop`決定制御

`Stop`と`SubagentStop`フックはClaudeが続行する必要があるかどうかを制御できます。

* `"block"`はClaudeが停止されるのを防ぎます。Claudeが進行方法を知るために`reason`を入力する必要があります。
* `undefined`はClaudeが停止することを許可します。`reason`は無視されます。

```json  theme={null}
{
  "decision": "block" | undefined,
  "reason": "Claudeが停止されるのをブロックする場合は必須"
}
```

#### `SessionStart`決定制御

`SessionStart`フックはセッションの開始時にコンテキストをロードできます。

* `"hookSpecificOutput.additionalContext"`は文字列をコンテキストに追加します。
* 複数のフックの`additionalContext`値は連結されます。

```json  theme={null}
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "ここに追加コンテキストを入力"
  }
}
```

#### `SessionEnd`決定制御

`SessionEnd`フックはセッションが終了するときに実行されます。セッション終了をブロックすることはできませんが、クリーンアップタスクを実行できます。

#### 終了コード例：Bashコマンド検証

```python  theme={null}
#!/usr/bin/env python3
import json
import re
import sys

# 検証ルールを（正規表現パターン、メッセージ）タプルのリストとして定義
VALIDATION_RULES = [
    (
        r"\bgrep\b(?!.*\|)",
        "パフォーマンスと機能を向上させるために、'grep'の代わりに'rg'（ripgrep）を使用してください",
    ),
    (
        r"\bfind\s+\S+\s+-name\b",
        "パフォーマンスを向上させるために、'find -name'の代わりに'rg --files | rg pattern'または'rg --files -g pattern'を使用してください",
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
    print(f"エラー：無効なJSON入力：{e}", file=sys.stderr)
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

#### JSON出力例：コンテキストと検証を追加するUserPromptSubmit

<Note>
  `UserPromptSubmit`フックの場合、以下のいずれかの方法を使用してコンテキストを注入できます：

  * 終了コード0とstdout：Claudeはコンテキストを見ます（`UserPromptSubmit`の特殊ケース）
  * JSON出力：動作をより細かく制御できます
</Note>

```python  theme={null}
#!/usr/bin/env python3
import json
import sys
import re
import datetime

# stdinから入力をロード
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"エラー：無効なJSON入力：{e}", file=sys.stderr)
    sys.exit(1)

prompt = input_data.get("prompt", "")

# 機密パターンをチェック
sensitive_patterns = [
    (r"(?i)\b(password|secret|key|token)\s*[:=]", "プロンプトに潜在的なシークレットが含まれています"),
]

for pattern, message in sensitive_patterns:
    if re.search(pattern, prompt):
        # JSON出力を使用して特定の理由でブロック
        output = {
            "decision": "block",
            "reason": f"セキュリティポリシー違反：{message}。機密情報なしでリクエストを言い換えてください。"
        }
        print(json.dumps(output))
        sys.exit(0)

# コンテキストに現在の時刻を追加
context = f"現在の時刻：{datetime.datetime.now()}"
print(context)

"""
以下も同等です：
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": context,
  },
}))
"""

# 追加コンテキストでプロンプトを続行することを許可
sys.exit(0)
```

#### JSON出力例：承認を使用したPreToolUse

```python  theme={null}
#!/usr/bin/env python3
import json
import sys

# stdinから入力をロード
try:
    input_data = json.load(sys.stdin)
except json.JSONDecodeError as e:
    print(f"エラー：無効なJSON入力：{e}", file=sys.stderr)
    sys.exit(1)

tool_name = input_data.get("tool_name", "")
tool_input = input_data.get("tool_input", {})

# 例：ドキュメントファイルのファイル読み取りを自動承認
if tool_name == "Read":
    file_path = tool_input.get("file_path", "")
    if file_path.endswith((".md", ".mdx", ".txt", ".json")):
        # JSON出力を使用してツール呼び出しを自動承認
        output = {
            "decision": "approve",
            "reason": "ドキュメントファイルは自動承認されました",
            "suppressOutput": True  # トランスクリプトモードで表示しない
        }
        print(json.dumps(output))
        sys.exit(0)

# その他の場合は、通常の権限フローを続行
sys.exit(0)
```

## MCPツールの操作

Claude Codeフックは[Model Context Protocol（MCP）ツール](/ja/mcp)とシームレスに機能します。MCPサーバーがツールを提供する場合、フックでマッチできる特別な命名パターンで表示されます。

### MCPツール命名

MCPツールは`mcp__<server>__<tool>`パターンに従います。例えば：

* `mcp__memory__create_entities` - メモリサーバーのエンティティ作成ツール
* `mcp__filesystem__read_file` - ファイルシステムサーバーのファイル読み取りツール
* `mcp__github__search_repositories` - GitHubサーバーの検索ツール

### MCPツール用のフックの設定

特定のMCPツールまたはMCPサーバー全体をターゲットにできます：

```json  theme={null}
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

<Tip>
  コードフォーマット、通知、ファイル保護を含む実用的な例については、スタートガイドの[その他の例](/ja/hooks-guide#more-examples)を参照してください。
</Tip>

## セキュリティに関する考慮事項

### 免責事項

**自己責任で使用してください**：Claude Codeフックはシステム上で任意のシェルコマンドを自動的に実行します。フックを使用することで、以下を認めます：

* 設定したコマンドについてのみ責任があります
* フックはユーザーアカウントがアクセスできるファイルを変更、削除、またはアクセスできます
* 悪意のある、または不十分に書かれたフックはデータ損失またはシステム損害を引き起こす可能性があります
* Anthropicは保証を提供せず、フック使用から生じるいかなる損害についても責任を負いません
* 本番環境で使用する前に、安全な環境でフックを十分にテストする必要があります

設定にフックコマンドを追加する前に、常にレビューして理解してください。

### セキュリティベストプラクティス

より安全なフックを書くための重要なプラクティスは以下の通りです：

1. **入力を検証およびサニタイズする** - 入力データを盲目的に信頼しないでください
2. **常にシェル変数をクォートする** - `$VAR`ではなく`"$VAR"`を使用してください
3. **パストラバーサルをブロックする** - ファイルパスで`..`をチェックしてください
4. **絶対パスを使用する** - スクリプトの完全パスを指定してください（プロジェクトパスには`"$CLAUDE_PROJECT_DIR"`を使用）
5. **機密ファイルをスキップする** - `.env`、`.git/`、キーなどを避けてください

### 設定セーフティ

設定ファイルのフックへの直接編集は即座には有効になりません。Claude Codeは：

1. スタートアップ時にフックのスナップショットをキャプチャします
2. セッション全体でこのスナップショットを使用します
3. フックが外部で変更された場合に警告します
4. 変更を適用するために`/hooks`メニューでレビューが必要です

これにより、悪意のあるフック変更が現在のセッションに影響するのを防ぎます。

## フック実行の詳細

* **タイムアウト**: デフォルトでは60秒の実行制限、コマンドごとに設定可能です。
  * 個別のコマンドのタイムアウトは他のコマンドに影響しません。
* **並列化**: マッチするすべてのフックが並行して実行されます
* **重複排除**: 同一のフックコマンドは自動的に重複排除されます
* **環境**: 現在のディレクトリでClaude Codeの環境で実行されます
  * `CLAUDE_PROJECT_DIR`環境変数が利用可能で、プロジェクトルートディレクトリへの絶対パスが含まれます（Claude Codeが開始された場所）
  * `CLAUDE_CODE_REMOTE`環境変数はフックがリモート（ウェブ）環境（`"true"`）で実行されているか、ローカルCLI環境（設定されていないか空）で実行されているかを示します。実行コンテキストに基づいて異なるロジックを実行するために使用してください。
* **入力**: stdinを介したJSON
* **出力**：
  * PreToolUse/PostToolUse/Stop/SubagentStop：トランスクリプトに進行状況を表示（Ctrl-R）
  * Notification/SessionEnd：デバッグのみにログ（`--debug`）
  * UserPromptSubmit/SessionStart：stdoutはClaudeのコンテキストとして追加

## デバッグ

### 基本的なトラブルシューティング

フックが機能していない場合：

1. **設定をチェック** - `/hooks`を実行してフックが登録されているかどうかを確認
2. **構文を検証** - JSON設定が有効であることを確認
3. **コマンドをテスト** - フックコマンドを手動で最初に実行
4. **権限をチェック** - スクリプトが実行可能であることを確認
5. **ログをレビュー** - `claude --debug`を使用してフック実行の詳細を確認

一般的な問題：

* **エスケープされていないクォート** - JSON文字列内で`\"`を使用してください
* **間違ったマッチャー** - ツール名が正確にマッチすることを確認してください（大文字小文字を区別）
* **コマンドが見つからない** - スクリプトに完全なパスを使用してください

### 高度なデバッグ

複雑なフック問題の場合：

1. **フック実行を検査** - `claude --debug`を使用して詳細なフック実行を確認
2. **JSONスキーマを検証** - 外部ツールでフック入力/出力をテスト
3. **環境変数をチェック** - Claude Codeの環境が正しいことを確認
4. **エッジケースをテスト** - 異常なファイルパスまたは入力でフックを試す
5. **システムリソースを監視** - フック実行中のリソース枯渇をチェック
6. **構造化ログを使用** - フックスクリプトにログを実装

### デバッグ出力例

`claude --debug`を使用してフック実行の詳細を確認：

```
[DEBUG] PostToolUse:Writeのフックを実行中
[DEBUG] クエリ用のマッチングフックコマンドを取得中：Write
[DEBUG] 設定で1つのフックマッチャーを見つけました
[DEBUG] クエリ「Write」に対して1つのフックにマッチしました
[DEBUG] 実行するフックコマンド1つを見つけました
[DEBUG] フックコマンドを実行中：<Your command> タイムアウト60000ms
[DEBUG] フックコマンドはステータス0で完了：<Your stdout>
```

進行状況メッセージはトランスクリプトモード（Ctrl-R）に表示されます：

* どのフックが実行されているか
* 実行されているコマンド
* 成功/失敗ステータス
* 出力またはエラーメッセージ
