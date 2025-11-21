# プラグイン

> カスタムコマンド、エージェント、フック、スキル、MCPサーバーを通じてClaude Codeを拡張するプラグインシステム。

<Tip>
  完全な技術仕様とスキーマについては、[プラグインリファレンス](/ja/plugins-reference)を参照してください。マーケットプレイス管理については、[プラグインマーケットプレイス](/ja/plugin-marketplaces)を参照してください。
</Tip>

プラグインを使用すると、プロジェクトとチーム全体で共有できるカスタム機能でClaude Codeを拡張できます。[マーケットプレイス](/ja/plugin-marketplaces)からプラグインをインストールして、事前構築されたコマンド、エージェント、フック、スキル、MCPサーバーを追加するか、独自のプラグインを作成してワークフローを自動化します。

## クイックスタート

シンプルなグリーティングプラグインを作成して、プラグインシステムに慣れましょう。カスタムコマンドを追加する動作するプラグインを構築し、ローカルでテストして、コアコンセプトを理解します。

### 前提条件

* マシンにインストールされたClaude Code
* コマンドラインツールの基本的な知識

### 最初のプラグインを作成する

<Steps>
  <Step title="マーケットプレイス構造を作成する">
    ```bash  theme={null}
    mkdir test-marketplace
    cd test-marketplace
    ```
  </Step>

  <Step title="プラグインディレクトリを作成する">
    ```bash  theme={null}
    mkdir my-first-plugin
    cd my-first-plugin
    ```
  </Step>

  <Step title="プラグインマニフェストを作成する">
    ```bash Create .claude-plugin/plugin.json theme={null}
    mkdir .claude-plugin
    cat > .claude-plugin/plugin.json << 'EOF'
    {
    "name": "my-first-plugin",
    "description": "A simple greeting plugin to learn the basics",
    "version": "1.0.0",
    "author": {
    "name": "Your Name"
    }
    }
    EOF
    ```
  </Step>

  <Step title="カスタムコマンドを追加する">
    ```bash Create commands/hello.md theme={null}
    mkdir commands
    cat > commands/hello.md << 'EOF'
    ---
    description: Greet the user with a personalized message
    ---

    # Hello Command

    Greet the user warmly and ask how you can help them today. Make the greeting personal and encouraging.
    EOF
    ```
  </Step>

  <Step title="マーケットプレイスマニフェストを作成する">
    ```bash Create marketplace.json theme={null}
    cd ..
    mkdir .claude-plugin
    cat > .claude-plugin/marketplace.json << 'EOF'
    {
    "name": "test-marketplace",
    "owner": {
    "name": "Test User"
    },
    "plugins": [
    {
      "name": "my-first-plugin",
      "source": "./my-first-plugin",
      "description": "My first test plugin"
    }
    ]
    }
    EOF
    ```
  </Step>

  <Step title="プラグインをインストールしてテストする">
    ```bash Start Claude Code from parent directory theme={null}
    cd ..
    claude
    ```

    ```shell テストマーケットプレイスを追加する theme={null}
    /plugin marketplace add ./test-marketplace
    ```

    ```shell プラグインをインストールする theme={null}
    /plugin install my-first-plugin@test-marketplace
    ```

    「今すぐインストール」を選択します。その後、新しいプラグインを使用するためにClaude Codeを再起動する必要があります。

    ```shell 新しいコマンドを試す theme={null}
    /hello
    ```

    Claude がグリーティングコマンドを使用しているのが見えます！`/help`をチェックして、新しいコマンドがリストされているのを確認してください。
  </Step>
</Steps>

これらのキーコンポーネントでプラグインを正常に作成およびテストしました：

* **プラグインマニフェスト** (`.claude-plugin/plugin.json`) - プラグインのメタデータを説明します
* **コマンドディレクトリ** (`commands/`) - カスタムスラッシュコマンドを含みます
* **テストマーケットプレイス** - ローカルでプラグインをテストできます

### プラグイン構造の概要

プラグインは以下の基本構造に従います：

```
my-first-plugin/
├── .claude-plugin/
│   └── plugin.json          # プラグインメタデータ
├── commands/                 # カスタムスラッシュコマンド（オプション）
│   └── hello.md
├── agents/                   # カスタムエージェント（オプション）
│   └── helper.md
├── skills/                   # エージェントスキル（オプション）
│   └── my-skill/
│       └── SKILL.md
└── hooks/                    # イベントハンドラー（オプション）
    └── hooks.json
```

**追加できるコンポーネント：**

* **コマンド**: `commands/`ディレクトリにマークダウンファイルを作成します
* **エージェント**: `agents/`ディレクトリにエージェント定義を作成します
* **スキル**: `skills/`ディレクトリに`SKILL.md`ファイルを作成します
* **フック**: イベント処理用に`hooks/hooks.json`を作成します
* **MCPサーバー**: 外部ツール統合用に`.mcp.json`を作成します

<Note>
  **次のステップ**: より多くの機能を追加する準備ができましたか？[より複雑なプラグインを開発する](#develop-more-complex-plugins)にジャンプして、エージェント、フック、MCPサーバーを追加します。すべてのプラグインコンポーネントの完全な技術仕様については、[プラグインリファレンス](/ja/plugins-reference)を参照してください。
</Note>

***

## プラグインをインストールして管理する

プラグインを発見、インストール、管理してClaude Code機能を拡張する方法を学びます。

### 前提条件

* Claude Codeがインストールされて実行中
* コマンドラインインターフェイスの基本的な知識

### マーケットプレイスを追加する

マーケットプレイスは利用可能なプラグインのカタログです。プラグインを発見してインストールするために追加します：

```shell マーケットプレイスを追加する theme={null}
/plugin marketplace add your-org/claude-plugins
```

```shell 利用可能なプラグインを参照する theme={null}
/plugin
```

Gitリポジトリ、ローカル開発、チーム配布を含む詳細なマーケットプレイス管理については、[プラグインマーケットプレイス](/ja/plugin-marketplaces)を参照してください。

### プラグインをインストールする

#### インタラクティブメニュー経由（発見に推奨）

```shell プラグイン管理インターフェイスを開く theme={null}
/plugin
```

「プラグインを参照」を選択して、説明、機能、インストールオプション付きの利用可能なオプションを表示します。

#### 直接コマンド経由（クイックインストール用）

```shell 特定のプラグインをインストールする theme={null}
/plugin install formatter@your-org
```

```shell 無効化されたプラグインを有効にする theme={null}
/plugin enable plugin-name@marketplace-name
```

```shell アンインストールせずに無効化する theme={null}
/plugin disable plugin-name@marketplace-name
```

```shell プラグインを完全に削除する theme={null}
/plugin uninstall plugin-name@marketplace-name
```

### インストールを確認する

プラグインをインストールした後：

1. **利用可能なコマンドを確認する**: `/help`を実行して新しいコマンドを表示します
2. **プラグイン機能をテストする**: プラグインのコマンドと機能を試します
3. **プラグイン詳細を確認する**: `/plugin` → 「プラグインを管理」を使用して、プラグインが提供するものを確認します

## チームプラグインワークフローを設定する

リポジトリレベルでプラグインを構成して、チーム全体で一貫したツールを確保します。チームメンバーがリポジトリフォルダを信頼すると、Claude Codeは指定されたマーケットプレイスとプラグインを自動的にインストールします。

**チームプラグインを設定するには：**

1. リポジトリの`.claude/settings.json`にマーケットプレイスとプラグイン構成を追加します
2. チームメンバーがリポジトリフォルダを信頼します
3. すべてのチームメンバーのプラグインが自動的にインストールされます

構成例、マーケットプレイスセットアップ、ロールアウトベストプラクティスを含む完全な手順については、[チームマーケットプレイスを構成する](/ja/plugin-marketplaces#how-to-configure-team-marketplaces)を参照してください。

***

## より複雑なプラグインを開発する

基本的なプラグインに慣れたら、より高度な拡張機能を作成できます。

### プラグインにスキルを追加する

プラグインには、Claudeの機能を拡張する[エージェントスキル](/ja/skills)を含めることができます。スキルはモデルが呼び出すもので、Claude はタスクコンテキストに基づいて自律的に使用します。

プラグインにスキルを追加するには、プラグインルートに`skills/`ディレクトリを作成し、`SKILL.md`ファイルを含むスキルフォルダを追加します。プラグインスキルはプラグインがインストールされると自動的に利用可能になります。

完全なスキル作成ガイダンスについては、[エージェントスキル](/ja/skills)を参照してください。

### 複雑なプラグインを整理する

多くのコンポーネントを持つプラグインの場合、機能別にディレクトリ構造を整理します。完全なディレクトリレイアウトと整理パターンについては、[プラグインディレクトリ構造](/ja/plugins-reference#plugin-directory-structure)を参照してください。

### プラグインをローカルでテストする

プラグインを開発する場合、ローカルマーケットプレイスを使用して変更を反復的にテストします。このワークフローはクイックスタートパターンに基づいており、任意の複雑さのプラグインで機能します。

<Steps>
  <Step title="開発構造を設定する">
    テスト用にプラグインとマーケットプレイスを整理します：

    ```bash ディレクトリ構造を作成する theme={null}
    mkdir dev-marketplace
    cd dev-marketplace
    mkdir my-plugin
    ```

    これにより以下が作成されます：

    ```
    dev-marketplace/
    ├── .claude-plugin/marketplace.json  (作成します)
    └── my-plugin/                        (開発中のプラグイン)
        ├── .claude-plugin/plugin.json
        ├── commands/
        ├── agents/
        └── hooks/
    ```
  </Step>

  <Step title="マーケットプレイスマニフェストを作成する">
    ```bash marketplace.jsonを作成する theme={null}
    mkdir .claude-plugin
    cat > .claude-plugin/marketplace.json << 'EOF'
    {
    "name": "dev-marketplace",
    "owner": {
    "name": "Developer"
    },
    "plugins": [
    {
      "name": "my-plugin",
      "source": "./my-plugin",
      "description": "Plugin under development"
    }
    ]
    }
    EOF
    ```
  </Step>

  <Step title="インストールしてテストする">
    ```bash 親ディレクトリからClaude Codeを開始する theme={null}
    cd ..
    claude
    ```

    ```shell 開発マーケットプレイスを追加する theme={null}
    /plugin marketplace add ./dev-marketplace
    ```

    ```shell プラグインをインストールする theme={null}
    /plugin install my-plugin@dev-marketplace
    ```

    プラグインコンポーネントをテストします：

    * `/command-name`でコマンドを試します
    * エージェントが`/agents`に表示されることを確認します
    * フックが期待通りに機能することを確認します
  </Step>

  <Step title="プラグインを反復する">
    プラグインコードに変更を加えた後：

    ```shell 現在のバージョンをアンインストールする theme={null}
    /plugin uninstall my-plugin@dev-marketplace
    ```

    ```shell 変更をテストするために再インストールする theme={null}
    /plugin install my-plugin@dev-marketplace
    ```

    プラグインを開発および改善する際にこのサイクルを繰り返します。
  </Step>
</Steps>

<Note>
  **複数のプラグイン用**: `./plugins/plugin-name`のようなサブディレクトリにプラグインを整理し、それに応じてmarketplace.jsonを更新します。整理パターンについては、[プラグインソース](/ja/plugin-marketplaces#plugin-sources)を参照してください。
</Note>

### プラグインの問題をデバッグする

プラグインが期待通りに機能していない場合：

1. **構造を確認する**: ディレクトリが`.claude-plugin/`内ではなくプラグインルートにあることを確認します
2. **コンポーネントを個別にテストする**: 各コマンド、エージェント、フックを個別に確認します
3. **検証とデバッグツールを使用する**: CLIコマンドとトラブルシューティング技術については、[デバッグと開発ツール](/ja/plugins-reference#debugging-and-development-tools)を参照してください

### プラグインを共有する

プラグインを共有する準備ができたら：

1. **ドキュメントを追加する**: インストールと使用方法の指示を含むREADME.mdを含めます
2. **プラグインをバージョン管理する**: `plugin.json`でセマンティックバージョニングを使用します
3. **マーケットプレイスを作成または使用する**: 簡単なインストールのためにプラグインマーケットプレイスを通じて配布します
4. **他の人でテストする**: より広い配布前にチームメンバーにプラグインをテストしてもらいます

<Note>
  完全な技術仕様、デバッグ技術、配布戦略については、[プラグインリファレンス](/ja/plugins-reference)を参照してください。
</Note>

***

## 次のステップ

Claude Codeのプラグインシステムを理解したので、異なる目標のための推奨パスを以下に示します：

### プラグインユーザー向け

* **プラグインを発見する**: コミュニティマーケットプレイスで有用なツールを参照します
* **チーム採用**: プロジェクトのリポジトリレベルプラグインを設定します
* **マーケットプレイス管理**: 複数のプラグインソースを管理する方法を学びます
* **高度な使用**: プラグインの組み合わせとワークフローを探索します

### プラグイン開発者向け

* **最初のマーケットプレイスを作成する**: [プラグインマーケットプレイスガイド](/ja/plugin-marketplaces)
* **高度なコンポーネント**: 特定のプラグインコンポーネントをさらに詳しく調べます：
  * [スラッシュコマンド](/ja/slash-commands) - コマンド開発の詳細
  * [サブエージェント](/ja/sub-agents) - エージェント構成と機能
  * [エージェントスキル](/ja/skills) - Claudeの機能を拡張する
  * [フック](/ja/hooks) - イベント処理と自動化
  * [MCP](/ja/mcp) - 外部ツール統合
* **配布戦略**: プラグインを効果的にパッケージ化して共有します
* **コミュニティ貢献**: コミュニティプラグインコレクションへの貢献を検討します

### チームリードと管理者向け

* **リポジトリ構成**: チームプロジェクトの自動プラグインインストールを設定します
* **プラグインガバナンス**: プラグイン承認とセキュリティレビューのガイドラインを確立します
* **マーケットプレイス保守**: 組織固有のプラグインカタログを作成および保守します
* **トレーニングとドキュメント**: チームメンバーがプラグインワークフローを効果的に採用するのを支援します

## 関連項目

* [プラグインマーケットプレイス](/ja/plugin-marketplaces) - プラグインカタログの作成と管理
* [スラッシュコマンド](/ja/slash-commands) - カスタムコマンドの理解
* [サブエージェント](/ja/sub-agents) - 特化したエージェントの作成と使用
* [エージェントスキル](/ja/skills) - Claudeの機能を拡張する
* [フック](/ja/hooks) - イベントハンドラーでワークフローを自動化する
* [MCP](/ja/mcp) - 外部ツールとサービスに接続する
* [設定](/ja/settings) - プラグインの構成オプション
