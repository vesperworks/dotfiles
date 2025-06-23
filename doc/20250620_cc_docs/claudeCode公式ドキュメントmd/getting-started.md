---
created: 2025-06-06T10:29
updated: 2025-06-12T18:40
---
# Claude Codeを使い始める

> Claude Codeのインストール、認証、使用開始方法について学びます。

## システム要件を確認する

* **オペレーティングシステム**: macOS 10.15+、Ubuntu 20.04+/Debian 10+、またはWSL経由のWindows
* **ハードウェア**: 最低4GB RAM
* **ソフトウェア**:
  * Node.js 18+
  * [git](https://git-scm.com/downloads) 2.23+ (オプション)
  * PRワークフロー用の[GitHub](https://cli.github.com/)または[GitLab](https://gitlab.com/gitlab-org/cli) CLI (オプション)
  * 拡張ファイル検索用の[ripgrep](https://github.com/BurntSushi/ripgrep?tab=readme-ov-file#installation) (rg) (オプション)
* **ネットワーク**: 認証とAI処理にはインターネット接続が必要
* **地域**: [対応国](https://www.anthropic.com/supported-countries)でのみ利用可能

<Note>
  **WSLインストールのトラブルシューティング**

  現在、Claude CodeはWindows上で直接実行できず、WSLが必要です。WSLで問題が発生した場合：

  1. **OS/プラットフォーム検出の問題**: インストール中にエラーが発生した場合、WSLがWindows `npm`を使用している可能性があります。以下を試してください：

     * インストール前に`npm config set os linux`を実行する
     * `npm install -g @anthropic-ai/claude-code --force --no-os-check`でインストールする（`sudo`は使用しないでください）

  2. **Nodeが見つからないエラー**: `claude`実行時に`exec: node: not found`が表示される場合、WSL環境がWindowsのNode.jsインストールを使用している可能性があります。`which npm`と`which node`で確認できます。これらは`/mnt/c/`ではなく`/usr/`で始まるLinuxパスを指すはずです。修正するには、Linuxディストリビューションのパッケージマネージャーまたは[`nvm`](https://github.com/nvm-sh/nvm)を使用してNodeをインストールしてみてください。
</Note>

## インストールと認証

<Steps>
  <Step title="Claude Codeをインストールする">
    Install [NodeJS 18+](https://nodejs.org/en/download), then run:

    ```sh
    npm install -g @anthropic-ai/claude-code
    ```

    <Warning>
      Do NOT use `sudo npm install -g` as this can lead to permission issues and
      security risks. If you encounter permission errors, see [configure Claude
      Code](/en/docs/claude-code/troubleshooting#linux-permission-issues) for recommended solutions.
    </Warning>
  </Step>

  <Step title="プロジェクトに移動する">
    ```bash
    cd your-project-directory 
    ```
  </Step>

  <Step title="Claude Codeを起動する">
    ```bash
    claude
    ```
  </Step>

  <Step title="認証を完了する">
    Claude Codeは複数の認証オプションを提供しています：

    1. **Anthropic Console**: デフォルトのオプションです。Anthropic Consoleを通じて接続し、
       OAuth処理を完了します。[console.anthropic.com](https://console.anthropic.com)でアクティブな課金が必要です。
    2. **Claude App（ProまたはMaxプラン）**: Claudeの[ProまたはMaxプラン](https://www.anthropic.com/pricing)に登録すると、Claude CodeとWebインターフェースの両方を含む統合サブスクリプションが利用できます。同じ価格帯でより多くの価値を得ながら、一か所でアカウントを管理できます。Claude.aiアカウントでログインしてください。起動時に、サブスクリプションタイプに合ったオプションを選択してください。
    3. **エンタープライズプラットフォーム**: 既存のクラウドインフラストラクチャを持つエンタープライズデプロイメント向けに、
       [Amazon BedrockまたはGoogle Vertex AI](/ja/docs/claude-code/bedrock-vertex-proxies)
       を使用するようにClaude Codeを設定します。
  </Step>
</Steps>

## プロジェクトを初期化する

初めてのユーザーには、以下をお勧めします：

<Steps>
  <Step title="Claude Codeを起動する">
    ```bash
    claude
    ```
  </Step>

  <Step title="簡単なコマンドを実行する">
    ```bash
    summarize this project
    ```
  </Step>

  <Step title="CLAUDE.mdプロジェクトガイドを生成する">
    ```bash
    /init 
    ```
  </Step>

  <Step title="生成されたCLAUDE.mdファイルをコミットする">
    生成されたCLAUDE.mdファイルをリポジトリにコミットするようClaudeに依頼します。
  </Step>
</Steps>
