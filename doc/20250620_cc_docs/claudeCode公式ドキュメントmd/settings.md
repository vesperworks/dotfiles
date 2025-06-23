---
created: 2025-06-06T10:29
updated: 2025-06-12T18:40
---
# Claude Codeの設定

> グローバル設定、プロジェクトレベルの設定、テーマ、環境変数を使用してClaude Codeを構成する方法を学びます。

Claude Codeはニーズに合わせて動作を設定するための様々な設定を提供しています。インタラクティブREPLを使用する際に`/config`コマンドを実行することでClaude Codeを設定できます。

## 設定ファイル

新しい`settings.json`ファイル形式は、階層的な設定を通じてClaude Codeを構成するための公式メカニズムです：

* **ユーザー設定**は`~/.claude/settings.json`で定義され、すべてのプロジェクトに適用されます。
* **プロジェクト設定**はプロジェクトディレクトリ内の`.claude/settings.json`（共有設定用）と`.claude/settings.local.json`（ローカルプロジェクト設定用）に保存されます。Claude Codeは作成時に`.claude/settings.local.json`をgitで無視するように設定します。
* Claude Codeのエンタープライズデプロイメントでは、**エンタープライズ管理ポリシー設定**もサポートしています。これらはユーザーおよびプロジェクト設定よりも優先されます。システム管理者はmacOSでは`/Library/Application Support/ClaudeCode/policies.json`に、LinuxおよびWSL経由のWindowsでは`/etc/claude-code/policies.json`にポリシーをデプロイできます。

```JSON Example settings.json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp"
  }
}
```

### 利用可能な設定

`settings.json`は多くのオプションをサポートしています：

| キー                    | 説明                                                               | 例                                     |
| :-------------------- | :--------------------------------------------------------------- | :------------------------------------ |
| `apiKeyHelper`        | Anthropic APIキーを生成するカスタムスクリプト                                    | `/bin/generate_temp_api_key.sh`       |
| `cleanupPeriodDays`   | チャット記録をローカルに保持する期間（デフォルト：30日）                                    | `20`                                  |
| `env`                 | すべてのセッションに適用される環境変数                                              | `{"FOO": "bar"}`                      |
| `includeCoAuthoredBy` | gitコミットとプルリクエストに`co-authored-by Claude`の署名を含めるかどうか（デフォルト：`true`） | `false`                               |
| `permissions`         | `allow`と`deny`キーは[権限ルール](#permissions)のリスト                       | `{"allow": [ "Bash(npm run lint)" ]}` |

### 設定の優先順位

設定は優先順位の順に適用されます：

1. エンタープライズポリシー
2. コマンドライン引数
3. ローカルプロジェクト設定
4. 共有プロジェクト設定
5. ユーザー設定

## 権限

`/permissions`を使用してClaude Codeのツール権限を表示・管理できます。このUIはすべての権限ルールとそれらが取得されるsettings.jsonファイルを一覧表示します。

* **許可**ルールは、Claude Codeが指定されたツールを手動承認なしで使用できるようにします。
* **拒否**ルールは、Claude Codeが指定されたツールを使用できないようにします。拒否ルールは許可ルールよりも優先されます。

権限ルールは次の形式を使用します：`Tool(optional-specifier)`

ツール名だけのルールは、そのツールのあらゆる使用に一致します。
例えば、許可ルールのリストに`Bash`を追加すると、Claude Codeはユーザー承認を必要とせずにBashツールを使用できるようになります。[Claudeが利用できるツールのリスト](security#tools-available-to-claude)を参照してください。

### ツール固有の権限ルール

一部のツールでは、より細かい権限制御のためにオプションの指定子を使用します。
例えば、`Bash(git diff:*)`を含む許可ルールは、`git diff`で始まるBashコマンドを許可します。以下のツールは指定子を持つ権限ルールをサポートしています：

#### Bash

* `Bash(npm run build)` 正確なBashコマンド`npm run build`に一致します
* `Bash(npm run test:*)` `npm run test`で始まるBashコマンドに一致します。

<Tip>
  Claude Codeはシェル演算子（`&&`など）を認識しているため、`Bash(safe-cmd:*)`のようなプレフィックス一致ルールでは、`safe-cmd && other-cmd`のようなコマンドを実行する権限は与えられません
</Tip>

#### Read & Edit

`Edit`ルールはファイルを編集するすべての組み込みツールに適用されます。
Claudeは`Read`ルールをGrep、Glob、LSなどのファイルを読み取るすべての組み込みツールに最善の努力で適用します。

ReadとEditのルールはどちらも
[gitignore](https://git-scm.com/docs/gitignore)仕様に従います。パターンは
`.claude/settings.json`を含むディレクトリからの相対パスで解決されます。絶対パスを参照するには、`//`を使用します。ホームディレクトリからの相対パスには、`~/`を使用します。

* `Edit(docs/**)` プロジェクトの`docs`ディレクトリ内のファイルの編集に一致します
* `Read(~/.zshrc)` `~/.zshrc`ファイルの読み取りに一致します
* `Edit(//tmp/scratch.txt)` `/tmp/scratch.txt`の編集に一致します

#### WebFetch

* `WebFetch(domain:example.com)` example.comへのフェッチリクエストに一致します

#### MCP

* `mcp__puppeteer` `puppeteer`サーバー（Claude Codeで設定された名前）によって提供されるあらゆるツールに一致します
* `mcp__puppeteer__puppeteer_navigate` `puppeteer`サーバーによって提供される`puppeteer_navigate`ツールに一致します

## 自動更新プログラムの権限オプション

Claude Codeがグローバルnpmプレフィックスディレクトリ（自動更新に必要）に書き込むための十分な権限がないことを検出すると、このドキュメントページを指す警告が表示されます。自動更新プログラムの問題に関する詳細なソリューションについては、[トラブルシューティングガイド](/ja/docs/claude-code/troubleshooting#auto-updater-issues)を参照してください。

### 推奨：新しいユーザー書き込み可能なnpmプレフィックスを作成する

```bash
# まず、既存のグローバルパッケージのリストを後で移行するために保存します
npm list -g --depth=0 > ~/npm-global-packages.txt

# グローバルパッケージ用のディレクトリを作成します
mkdir -p ~/.npm-global

# 新しいディレクトリパスを使用するようにnpmを設定します
npm config set prefix ~/.npm-global

# 注意：~/.bashrcを、お使いのシェルに適した~/.zshrc、~/.profile、または他の適切なファイルに置き換えてください
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc

# 新しいPATH設定を適用します
source ~/.bashrc

# 新しい場所にClaude Codeを再インストールします
npm install -g @anthropic-ai/claude-code

# オプション：以前のグローバルパッケージを新しい場所に再インストールします
# ~/npm-global-packages.txtを見て、保持したいパッケージをインストールします
# npm install -g package1 package2 package3...
```

**このオプションを推奨する理由：**

* システムディレクトリの権限を変更する必要がありません
* グローバルnpmパッケージ用のクリーンで専用の場所を作成します
* セキュリティのベストプラクティスに従います

Claude Codeは積極的に開発中であるため、上記の推奨オプションを使用して自動更新を設定することをお勧めします。

### 自動更新プログラムの無効化

権限を修正する代わりに自動更新プログラムを無効にしたい場合は、`DISABLE_AUTOUPDATER` [環境変数](#environment-variables)を`1`に設定できます

## ターミナル設定の最適化

Claude Codeは、ターミナルが適切に設定されている場合に最も効果的に動作します。以下のガイドラインに従って、エクスペリエンスを最適化してください。

**サポートされているシェル**：

* Bash
* Zsh
* Fish

### テーマと外観

Claudeはターミナルのテーマを制御できません。それはターミナルアプリケーションによって処理されます。オンボーディング中または`/config`コマンドを使用していつでもClaude Codeのテーマをターミナルに合わせることができます

### 改行

Claude Codeに改行を入力するためのいくつかのオプションがあります：

* **クイックエスケープ**：`\`に続けてEnterを押して改行を作成します
* **キーボードショートカット**：適切な設定でOption+Enter（Meta+Enter）を押します

Option+Enterをターミナルで設定するには：

**Mac Terminal.appの場合：**

1. 設定 → プロファイル → キーボードを開きます
2. 「Optionをメタキーとして使用」をチェックします

**iTerm2とVSCodeターミナルの場合：**

1. 設定 → プロファイル → キーを開きます
2. 一般の下で、左/右のOptionキーを「Esc+」に設定します

**iTerm2とVSCodeユーザーへのヒント**：Claude Code内で`/terminal-setup`を実行して、より直感的な代替手段としてShift+Enterを自動的に設定します。

### 通知設定

適切な通知設定により、Claudeがタスクを完了したときを見逃さないようにします：

#### ターミナルベル通知

タスクが完了したときにサウンドアラートを有効にします：

```sh
claude config set --global preferredNotifChannel terminal_bell
```

**macOSユーザーの場合**：システム設定 → 通知 → \[ターミナルアプリ]で通知権限を有効にすることを忘れないでください。

#### iTerm 2システム通知

タスクが完了したときにiTerm 2アラートを表示するには：

1. iTerm 2環境設定を開きます
2. プロファイル → ターミナルに移動します
3. 「ベルを無音にする」と「フィルターアラート」→「エスケープシーケンス生成アラートを送信する」を有効にします
4. 希望する通知遅延を設定します

これらの通知はiTerm 2に固有のものであり、デフォルトのmacOSターミナルでは利用できないことに注意してください。

### 大量の入力の処理

広範なコードや長い指示を扱う場合：

* **直接貼り付けを避ける**：Claude Codeは非常に長い貼り付けられたコンテンツで苦労する場合があります
* **ファイルベースのワークフローを使用する**：コンテンツをファイルに書き込み、Claudeに読み取りを依頼します
* **VS Codeの制限に注意する**：VS Codeターミナルは特に長い貼り付けを切り詰める傾向があります

### Vimモード

Claude Codeは`/vim`または`/config`を介して有効にできるVimキーバインディングのサブセットをサポートしています。

サポートされているサブセットには以下が含まれます：

* モード切り替え：`Esc`（NORMALモードへ）、`i`/`I`、`a`/`A`、`o`/`O`（INSERTモードへ）
* ナビゲーション：`h`/`j`/`k`/`l`、`w`/`e`/`b`、`0`/`$`/`^`、`gg`/`G`
* 編集：`x`、`dw`/`de`/`db`/`dd`/`D`、`cw`/`ce`/`cb`/`cc`/`C`、`.`（繰り返し）

## 環境変数

Claude Codeは、その動作を制御するために以下の環境変数をサポートしています：

<Note>
  すべての環境変数は[`settings.json`](#available-settings)でも設定できます。これは
  各セッションの環境変数を自動的に設定したり、
  チーム全体や組織全体の環境変数セットをロールアウトしたりするのに便利です。
</Note>

| 変数                                         | 目的                                                                                                    |
| :----------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| `ANTHROPIC_API_KEY`                        | APIキー、Claude SDKを使用する場合のみ（インタラクティブな使用の場合は`/login`を実行）                                                 |
| `ANTHROPIC_AUTH_TOKEN`                     | `Authorization`および`Proxy-Authorization`ヘッダーのカスタム値（ここで設定した値には`Bearer `が前に付きます）                         |
| `ANTHROPIC_CUSTOM_HEADERS`                 | リクエストに追加したいカスタムヘッダー（`Name: Value`形式）                                                                  |
| `ANTHROPIC_MODEL`                          | 使用するカスタムモデルの名前（[モデル設定](/ja/docs/claude-code/bedrock-vertex-proxies#model-configuration)を参照）           |
| `ANTHROPIC_SMALL_FAST_MODEL`               | [バックグラウンドタスク用のHaikuクラスモデル](/ja/docs/claude-code/costs)                                                |
| `BASH_DEFAULT_TIMEOUT_MS`                  | 長時間実行されるbashコマンドのデフォルトタイムアウト                                                                          |
| `BASH_MAX_TIMEOUT_MS`                      | 長時間実行されるbashコマンドに対してモデルが設定できる最大タイムアウト                                                                 |
| `BASH_MAX_OUTPUT_LENGTH`                   | 中間で切り詰められる前のbash出力の最大文字数                                                                              |
| `CLAUDE_CODE_API_KEY_HELPER_TTL_MS`        | 認証情報を更新する間隔（`apiKeyHelper`を使用する場合）                                                                    |
| `CLAUDE_CODE_USE_BEDROCK`                  | Bedrockを使用する（[BedrockとVertex](/ja/docs/claude-code/bedrock-vertex-proxies)を参照）                        |
| `CLAUDE_CODE_USE_VERTEX`                   | Vertexを使用する（[BedrockとVertex](/ja/docs/claude-code/bedrock-vertex-proxies)を参照）                         |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH`             | VertexのためのGoogle認証をスキップする（例：プロキシを使用する場合）                                                              |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `DISABLE_AUTOUPDATER`、`DISABLE_BUG_COMMAND`、`DISABLE_ERROR_REPORTING`、および`DISABLE_TELEMETRY`を設定するのと同等 |
| `DISABLE_AUTOUPDATER`                      | `1`に設定すると自動更新プログラムを無効にします                                                                             |
| `DISABLE_BUG_COMMAND`                      | `1`に設定すると`/bug`コマンドを無効にします                                                                            |
| `DISABLE_COST_WARNINGS`                    | `1`に設定するとコスト警告メッセージを無効にします                                                                            |
| `DISABLE_ERROR_REPORTING`                  | `1`に設定するとSentryエラーレポートをオプトアウトします                                                                      |
| `DISABLE_TELEMETRY`                        | `1`に設定するとStatsigテレメトリをオプトアウトします（Statsigイベントにはコード、ファイルパス、bashコマンドなどのユーザーデータは含まれないことに注意してください）          |
| `HTTP_PROXY`                               | ネットワーク接続用のHTTPプロキシサーバーを指定します                                                                          |
| `HTTPS_PROXY`                              | ネットワーク接続用のHTTPSプロキシサーバーを指定します                                                                         |
| `MAX_THINKING_TOKENS`                      | モデル予算の思考を強制します                                                                                        |
| `MCP_TIMEOUT`                              | MCPサーバー起動のタイムアウト（ミリ秒）                                                                                 |
| `MCP_TOOL_TIMEOUT`                         | MCPツール実行のタイムアウト（ミリ秒）                                                                                  |

## 設定オプション

グローバル設定を`settings.json`に移行する過程にあります。

`claude config`は[settings.json](#settings-files)に置き換えられる予定です

設定を管理するには、次のコマンドを使用します：

* 設定の一覧表示：`claude config list`
* 設定の表示：`claude config get <key>`
* 設定の変更：`claude config set <key> <value>`
* 設定への追加（リスト用）：`claude config add <key> <value>`
* 設定からの削除（リスト用）：`claude config remove <key> <value>`

デフォルトでは、`config`はプロジェクト設定を変更します。グローバル設定を管理するには、`--global`（または`-g`）フラグを使用します。

### グローバル設定

グローバル設定を設定するには、`claude config set -g <key> <value>`を使用します：

| キー                      | 説明                                      | 例                                                                       |
| :---------------------- | :-------------------------------------- | :---------------------------------------------------------------------- |
| `autoUpdaterStatus`     | 自動更新プログラムを有効または無効にする（デフォルト：`enabled`）   | `disabled`                                                              |
| `preferredNotifChannel` | 通知を受け取りたい場所（デフォルト：`iterm2`）             | `iterm2`、`iterm2_with_bell`、`terminal_bell`、または`notifications_disabled` |
| `theme`                 | カラーテーマ                                  | `dark`、`light`、`light-daltonized`、または`dark-daltonized`                  |
| `verbose`               | bashとコマンドの出力を完全に表示するかどうか（デフォルト：`false`） | `true`                                                                  |
