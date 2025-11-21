---
created: 2025-06-06T10:29
updated: 2025-06-12T18:40
---
# CLIの使用法とコントロール

> コマンドラインからClaude Codeを使用する方法（CLIコマンド、フラグ、スラッシュコマンドを含む）を学びます。

## はじめに

Claude Codeには主に2つの操作方法があります：

* **インタラクティブモード**：`claude`を実行してREPLセッションを開始
* **ワンショットモード**：`claude -p "クエリ"`を使用して素早くコマンドを実行

```bash
# インタラクティブモードを開始
claude

# 初期クエリで開始
claude "このプロジェクトを説明して"

# 単一コマンドを実行して終了
claude -p "この関数は何をするの？"

# パイプされたコンテンツを処理
cat logs.txt | claude -p "これらのエラーを分析して"
```

## CLIコマンド

| コマンド                          | 説明                            | 例                                                                                       |
| :---------------------------- | :---------------------------- | :-------------------------------------------------------------------------------------- |
| `claude`                      | インタラクティブREPLを開始               | `claude`                                                                                |
| `claude "クエリ"`                | 初期プロンプトでREPLを開始               | `claude "このプロジェクトを説明して"`                                                                |
| `claude -p "クエリ"`             | 一回限りのクエリを実行して終了               | `claude -p "この関数を説明して"`                                                                 |
| `cat ファイル \| claude -p "クエリ"` | パイプされたコンテンツを処理                | `cat logs.txt \| claude -p "説明して"`                                                      |
| `claude -c`                   | 最新の会話を継続                      | `claude -c`                                                                             |
| `claude -c -p "クエリ"`          | 印刷モードで継続                      | `claude -c -p "型エラーをチェックして"`                                                            |
| `claude -r "<セッションID>" "クエリ"` | IDでセッションを再開                   | `claude -r "abc123" "このPRを完了して"`                                                        |
| `claude update`               | 最新バージョンに更新                    | `claude update`                                                                         |
| `claude mcp`                  | Model Context Protocolサーバーを設定 | [チュートリアルのMCPセクションを参照](/ja/docs/claude-code/tutorials#set-up-model-context-protocol-mcp) |

## CLIフラグ

これらのコマンドラインフラグでClaude Codeの動作をカスタマイズできます：

| フラグ                              | 説明                                                                                | 例                                                        |
| :------------------------------- | :-------------------------------------------------------------------------------- | :------------------------------------------------------- |
| `--allowedTools`                 | [settings.jsonファイル](/ja/docs/claude-code/settings)に加えて、ユーザーの許可を求めずに許可されるべきツールのリスト | `"Bash(git log:*)" "Bash(git diff:*)" "Write"`           |
| `--disallowedTools`              | [settings.jsonファイル](/ja/docs/claude-code/settings)に加えて、ユーザーの許可を求めずに禁止されるべきツールのリスト | `"Bash(git log:*)" "Bash(git diff:*)" "Write"`           |
| `--print`, `-p`                  | インタラクティブモードなしでレスポンスを表示（プログラムによる使用の詳細は[SDKドキュメント](/ja/docs/claude-code/sdk)を参照）    | `claude -p "クエリ"`                                        |
| `--output-format`                | 印刷モードの出力形式を指定（オプション：`text`、`json`、`stream-json`）                                  | `claude -p "クエリ" --output-format json`                   |
| `--verbose`                      | 詳細なログを有効化し、ターンごとの完全な出力を表示（印刷モードとインタラクティブモードの両方でデバッグに役立つ）                          | `claude --verbose`                                       |
| `--max-turns`                    | 非インタラクティブモードでのエージェントのターン数を制限                                                      | `claude -p --max-turns 3 "クエリ"`                          |
| `--model`                        | 最新モデルのエイリアス（`sonnet`または`opus`）またはモデルの完全な名前で現在のセッションのモデルを設定                        | `claude --model claude-sonnet-4-20250514`                |
| `--permission-prompt-tool`       | 非インタラクティブモードで許可プロンプトを処理するMCPツールを指定                                                | `claude -p --permission-prompt-tool mcp_auth_tool "クエリ"` |
| `--resume`                       | IDで特定のセッションを再開、またはインタラクティブモードで選択                                                  | `claude --resume abc123 "クエリ"`                           |
| `--continue`                     | 現在のディレクトリで最新の会話を読み込む                                                              | `claude --continue`                                      |
| `--dangerously-skip-permissions` | 許可プロンプトをスキップ（注意して使用）                                                              | `claude --dangerously-skip-permissions`                  |

<Tip>
  `--output-format json`フラグは特にスクリプト作成や自動化に役立ち、Claudeの応答をプログラムで解析できるようにします。
</Tip>

印刷モード（`-p`）に関する詳細情報（出力形式、ストリーミング、詳細ログ、プログラムによる使用を含む）については、[SDKドキュメント](/ja/docs/claude-code/sdk)を参照してください。

## スラッシュコマンド

インタラクティブセッション中にClaudeの動作を制御します：

| コマンド              | 目的                                               |
| :---------------- | :----------------------------------------------- |
| `/bug`            | バグを報告（会話をAnthropicに送信）                           |
| `/clear`          | 会話履歴をクリア                                         |
| `/compact [指示]`   | オプションの焦点指示で会話を圧縮                                 |
| `/config`         | 設定を表示/変更                                         |
| `/cost`           | トークン使用統計を表示                                      |
| `/doctor`         | Claude Codeのインストール状態を確認                          |
| `/help`           | 使用方法のヘルプを取得                                      |
| `/init`           | CLAUDE.mdガイドでプロジェクトを初期化                          |
| `/login`          | Anthropicアカウントを切り替え                              |
| `/logout`         | Anthropicアカウントからサインアウト                           |
| `/memory`         | CLAUDE.mdメモリファイルを編集                              |
| `/model`          | AIモデルを選択または変更                                    |
| `/permissions`    | [権限](settings#permissions)を表示または更新               |
| `/pr_comments`    | プルリクエストのコメントを表示                                  |
| `/review`         | コードレビューをリクエスト                                    |
| `/status`         | アカウントとシステムのステータスを表示                              |
| `/terminal-setup` | 改行用のShift+Enterキーバインディングをインストール（iTerm2とVSCodeのみ） |
| `/vim`            | 挿入モードとコマンドモードを切り替えるvimモードに入る                     |

## 特別なショートカット

### `#`でのクイックメモリ

入力を`#`で始めることで、メモリを即座に追加できます：

```
# 常に説明的な変数名を使用する
```

どのメモリファイルに保存するかを選択するよう促されます。

### ターミナルでの改行

次の方法で複数行のコマンドを入力できます：

* **クイックエスケープ**：`\`に続けてEnterを押す
* **キーボードショートカット**：Option+Enter（または設定されている場合はShift+Enter）

ターミナルでOption+Enterを設定するには：

**Mac Terminal.appの場合：**

1. 設定 → プロファイル → キーボードを開く
2. 「Optionをメタキーとして使用」をチェック

**iTerm2とVSCodeターミナルの場合：**

1. 設定 → プロファイル → キーを開く
2. 一般で、左/右Optionキーを「Esc+」に設定

**iTerm2とVSCodeユーザー向けのヒント**：Claude Code内で`/terminal-setup`を実行して、より直感的な代替手段としてShift+Enterを自動的に設定できます。

設定の詳細については[設定のターミナルセットアップ](/ja/docs/claude-code/settings#line-breaks)を参照してください。

## Vimモード

Claude Codeは`/vim`で有効化または`/config`で設定できるVimキーバインディングのサブセットをサポートしています。

サポートされているサブセットには以下が含まれます：

* モード切替：`Esc`（NORMALモードへ）、`i`/`I`、`a`/`A`、`o`/`O`（INSERTモードへ）
* ナビゲーション：`h`/`j`/`k`/`l`、`w`/`e`/`b`、`0`/`$`/`^`、`gg`/`G`
* 編集：`x`、`dw`/`de`/`db`/`dd`/`D`、`cw`/`ce`/`cb`/`cc`/`C`、`.`（繰り返し）
