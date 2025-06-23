---
created: 2025-06-06T10:29
updated: 2025-06-12T18:40
---
# IDE統合

> Claude Codeをお気に入りの開発環境に統合する

Claude Codeは人気のある統合開発環境（IDE）とシームレスに統合され、コーディングワークフローを強化します。この統合により、お好みの開発環境内で直接Claudeの機能を活用できます。

## サポートされているIDE

Claude Codeは現在、2つの主要なIDEファミリーをサポートしています：

* **Visual Studio Code**（CursorやWindsurfなどの人気のあるフォークを含む）
* **JetBrains IDE**（PyCharm、WebStorm、IntelliJ、GoLandなどを含む）

## 機能

* **クイック起動**：`Cmd+Esc`（Mac）または`Ctrl+Esc`（Windows/Linux）を使用してエディタから直接Claude Codeを開くか、UI内のClaude Codeボタンをクリックします
* **差分表示**：コードの変更はターミナルではなくIDE差分ビューアに直接表示できます。これは`/config`で設定できます
* **選択コンテキスト**：IDE内の現在の選択/タブは自動的にClaude Codeと共有されます
* **診断共有**：IDEからの診断エラー（リント、構文など）は作業中に自動的にClaudeと共有されます
* **ファイル参照ショートカット**：`Cmd+Option+K`（Mac）または`Alt+Ctrl+K`（Linux/Windows）を使用してファイル参照（例：@File#L1-99）を挿入します

## インストール

### VS Code

1. VSCodeを開く
2. 統合ターミナルを開く
3. `claude`を実行する - 拡張機能が自動インストールされます

今後は、外部ターミナルで`/ide`コマンドを使用してIDEに接続することもできます。

<Note>
  これらのインストール手順は、CursorやWindsurfなどのVS Codeフォークにも適用されます。
</Note>

### JetBrains IDE

マーケットプレイスから[Claude Codeプラグイン](https://docs.anthropic.com/s/claude-code-jetbrains)をインストールし、IDEを再起動します。

<Note>
  統合ターミナルで`claude`を実行すると、プラグインが自動インストールされる場合もあります。有効にするにはIDEを完全に再起動する必要があります。
</Note>

<Warning>
  **リモート開発の制限**：JetBrains Remote Developmentを使用する場合、プラグインをインストールし、リモートホストで`claude`を実行する必要があります。
</Warning>

## 設定

両方の統合はClaude Codeの設定システムで動作します。IDE固有の機能を有効にするには：

1. Claude Codeで`/config`を実行します
2. 差分ツールを自動IDE検出のために`auto`に設定します
3. Claude CodeはIDEに基づいて適切なビューアを自動的に使用します

外部ターミナル（IDEの組み込みターミナルではない）を使用している場合でも、Claude Code起動後に`/ide`コマンドを使用してIDEに接続できます。これにより、別のターミナルアプリケーションからClaudeを実行している場合でも、IDE統合機能の恩恵を受けることができます。これはVS CodeとJetBrains IDEの両方で機能します。

<Note>
  外部ターミナルを使用する場合、ClaudeがIDEと同じファイルにデフォルトでアクセスできるようにするには、IDEプロジェクトルートと同じディレクトリからClaudeを起動してください。
</Note>

## トラブルシューティング

### VS Code拡張機能がインストールされない

* VS Codeの統合ターミナルからClaude Codeを実行していることを確認してください
* IDEに対応するCLIがインストールされていることを確認してください：
  * VS Codeの場合：`code`コマンドが利用可能であること
  * Cursorの場合：`cursor`コマンドが利用可能であること
  * Windsurfの場合：`windsurf`コマンドが利用可能であること
  * インストールされていない場合は、`Cmd+Shift+P`（Mac）または`Ctrl+Shift+P`（Windows/Linux）を使用して「Shell Command: Install 'code' command in PATH」（またはIDEに応じた同等のもの）を検索してください
* VS Codeに拡張機能をインストールする権限があることを確認してください

### JetBrains プラグインが機能しない

* プロジェクトのルートディレクトリからClaude Codeを実行していることを確認してください
* JetBrains プラグインがIDE設定で有効になっていることを確認してください
* IDEを完全に再起動してください。複数回行う必要がある場合があります
* JetBrains Remote Developmentの場合、Claude Codeプラグインがクライアントのローカルではなくリモートホストにインストールされていることを確認してください

追加のヘルプについては、[トラブルシューティングガイド](/ja/docs/claude-code/troubleshooting)を参照するか、サポートにお問い合わせください。
