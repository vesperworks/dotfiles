# Claude Code フックの使い始め

> シェルコマンドを登録して Claude Code の動作をカスタマイズおよび拡張する方法を学びます

Claude Code フックは、Claude Code のライフサイクルのさまざまなポイントで実行されるユーザー定義のシェルコマンドです。フックは Claude Code の動作に対して決定論的な制御を提供し、LLM が実行を選択することに依存するのではなく、特定のアクションが常に発生することを保証します。

<Tip>
  フックのリファレンスドキュメントについては、[フックリファレンス](/ja/hooks)を参照してください。
</Tip>

フックのユースケース例には以下が含まれます：

* **通知**: Claude Code があなたの入力または何かを実行する許可を待っているときに、通知を受け取る方法をカスタマイズします。
* **自動フォーマット**: すべてのファイル編集後に、.ts ファイルで `prettier` を実行し、.go ファイルで `gofmt` を実行するなど。
* **ログ記録**: コンプライアンスまたはデバッグのために、実行されたすべてのコマンドを追跡およびカウントします。
* **フィードバック**: Claude Code がコードベースの規約に従わないコードを生成したときに、自動フィードバックを提供します。
* **カスタム権限**: 本番ファイルまたは機密ディレクトリへの変更をブロックします。

これらのルールをプロンプト指示としてではなくフックとしてエンコードすることで、提案をアプリレベルのコードに変え、期待されるたびに実行されるようにします。

<Warning>
  フックを追加する際には、フックのセキュリティ上の影響を考慮する必要があります。フックはエージェントループ中に現在の環境の認証情報で自動的に実行されるためです。
  たとえば、悪意のあるフックコードはあなたのデータを流出させる可能性があります。フックを登録する前に、常にフック実装を確認してください。

  完全なセキュリティベストプラクティスについては、フックリファレンスドキュメントの[セキュリティに関する考慮事項](/ja/hooks#security-considerations)を参照してください。
</Warning>

## フックイベント概要

Claude Code は、ワークフロー内のさまざまなポイントで実行される複数のフックイベントを提供します：

* **PreToolUse**: ツール呼び出しの前に実行されます（ブロック可能）
* **PostToolUse**: ツール呼び出しが完了した後に実行されます
* **UserPromptSubmit**: ユーザーがプロンプトを送信したときに実行されます（Claude が処理する前）
* **Notification**: Claude Code が通知を送信するときに実行されます
* **Stop**: Claude Code が応答を終了するときに実行されます
* **SubagentStop**: サブエージェントタスクが完了したときに実行されます
* **PreCompact**: Claude Code がコンパクト操作を実行しようとする前に実行されます
* **SessionStart**: Claude Code が新しいセッションを開始するか、既存のセッションを再開するときに実行されます
* **SessionEnd**: Claude Code セッションが終了するときに実行されます

各イベントは異なるデータを受け取り、異なる方法で Claude の動作を制御できます。

## クイックスタート

このクイックスタートでは、Claude Code が実行するシェルコマンドをログに記録するフックを追加します。

### 前提条件

コマンドラインで JSON 処理用に `jq` をインストールします。

### ステップ 1: フック設定を開く

`/hooks` [スラッシュコマンド](/ja/slash-commands)を実行し、`PreToolUse` フックイベントを選択します。

`PreToolUse` フックはツール呼び出しの前に実行され、Claude に異なる処理方法についてのフィードバックを提供しながらそれらをブロックできます。

### ステップ 2: マッチャーを追加する

`+ Add new matcher…` を選択して、Bash ツール呼び出しのみでフックを実行します。

マッチャーに `Bash` と入力します。

<Note>すべてのツールにマッチさせるには `*` を使用できます。</Note>

### ステップ 3: フックを追加する

`+ Add new hook…` を選択して、このコマンドを入力します：

```bash  theme={null}
jq -r '"\(.tool_input.command) - \(.tool_input.description // "No description")"' >> ~/.claude/bash-command-log.txt
```

### ステップ 4: 設定を保存する

ストレージの場所として `User settings` を選択します。ホームディレクトリにログを記録しているためです。このフックは現在のプロジェクトだけでなく、すべてのプロジェクトに適用されます。

次に Esc を押して REPL に戻ります。フックが登録されました！

### ステップ 5: フックを確認する

`/hooks` を再度実行するか、`~/.claude/settings.json` をチェックして設定を確認します：

```json  theme={null}
{
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
}
```

### ステップ 6: フックをテストする

Claude に `ls` のような簡単なコマンドを実行するよう依頼し、ログファイルをチェックします：

```bash  theme={null}
cat ~/.claude/bash-command-log.txt
```

次のようなエントリが表示されるはずです：

```
ls - Lists files and directories
```

## その他の例

<Note>
  完全な実装例については、公開コードベースの [bash コマンドバリデーター例](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py)を参照してください。
</Note>

### コードフォーマットフック

編集後に TypeScript ファイルを自動的にフォーマットします：

```json  theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.ts$'; then npx prettier --write \"$file_path\"; fi; }"
          }
        ]
      }
    ]
  }
}
```

### Markdown フォーマットフック

Markdown ファイルの言語タグの欠落とフォーマットの問題を自動的に修正します：

```json  theme={null}
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/markdown_formatter.py"
          }
        ]
      }
    ]
  }
}
```

このコンテンツで `.claude/hooks/markdown_formatter.py` を作成します：

````python  theme={null}
#!/usr/bin/env python3
"""
Markdown formatter for Claude Code output.
Fixes missing language tags and spacing issues while preserving code content.
"""
import json
import sys
import re
import os

def detect_language(code):
    """Best-effort language detection from code content."""
    s = code.strip()
    
    # JSON detection
    if re.search(r'^\s*[{\[]', s):
        try:
            json.loads(s)
            return 'json'
        except:
            pass
    
    # Python detection
    if re.search(r'^\s*def\s+\w+\s*\(', s, re.M) or \
       re.search(r'^\s*(import|from)\s+\w+', s, re.M):
        return 'python'
    
    # JavaScript detection  
    if re.search(r'\b(function\s+\w+\s*\(|const\s+\w+\s*=)', s) or \
       re.search(r'=>|console\.(log|error)', s):
        return 'javascript'
    
    # Bash detection
    if re.search(r'^#!.*\b(bash|sh)\b', s, re.M) or \
       re.search(r'\b(if|then|fi|for|in|do|done)\b', s):
        return 'bash'
    
    # SQL detection
    if re.search(r'\b(SELECT|INSERT|UPDATE|DELETE|CREATE)\s+', s, re.I):
        return 'sql'
        
    return 'text'

def format_markdown(content):
    """Format markdown content with language detection."""
    # Fix unlabeled code fences
    def add_lang_to_fence(match):
        indent, info, body, closing = match.groups()
        if not info.strip():
            lang = detect_language(body)
            return f"{indent}```{lang}\n{body}{closing}\n"
        return match.group(0)
    
    fence_pattern = r'(?ms)^([ \t]{0,3})```([^\n]*)\n(.*?)(\n\1```)\s*$'
    content = re.sub(fence_pattern, add_lang_to_fence, content)
    
    # Fix excessive blank lines (only outside code fences)
    content = re.sub(r'\n{3,}', '\n\n', content)
    
    return content.rstrip() + '\n'

# Main execution
try:
    input_data = json.load(sys.stdin)
    file_path = input_data.get('tool_input', {}).get('file_path', '')
    
    if not file_path.endswith(('.md', '.mdx')):
        sys.exit(0)  # Not a markdown file
    
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        formatted = format_markdown(content)
        
        if formatted != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(formatted)
            print(f"✓ Fixed markdown formatting in {file_path}")
    
except Exception as e:
    print(f"Error formatting markdown: {e}", file=sys.stderr)
    sys.exit(1)
````

スクリプトを実行可能にします：

```bash  theme={null}
chmod +x .claude/hooks/markdown_formatter.py
```

このフックは自動的に以下を実行します：

* ラベルなしのコードブロック内のプログラミング言語を検出します
* 構文ハイライト用に適切な言語タグを追加します
* コンテンツを保持しながら過度な空行を修正します
* Markdown ファイル（`.md`、`.mdx`）のみを処理します

### カスタム通知フック

Claude が入力を必要とするときにデスクトップ通知を取得します：

```json  theme={null}
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Awaiting your input'"
          }
        ]
      }
    ]
  }
}
```

### ファイル保護フック

機密ファイルへの編集をブロックします：

```json  theme={null}
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 -c \"import json, sys; data=json.load(sys.stdin); path=data.get('tool_input',{}).get('file_path',''); sys.exit(2 if any(p in path for p in ['.env', 'package-lock.json', '.git/']) else 0)\""
          }
        ]
      }
    ]
  }
}
```

## 詳細情報

* フックのリファレンスドキュメントについては、[フックリファレンス](/ja/hooks)を参照してください。
* 包括的なセキュリティベストプラクティスと安全ガイドラインについては、フックリファレンスドキュメントの[セキュリティに関する考慮事項](/ja/hooks#security-considerations)を参照してください。
* トラブルシューティング手順とデバッグ技術については、フックリファレンスドキュメントの[デバッグ](/ja/hooks#debugging)を参照してください。
