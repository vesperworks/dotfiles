# プラグインマーケットプレイス

> Claude Code拡張機能をチーム全体およびコミュニティ全体に配布するためのプラグインマーケットプレイスを作成および管理します。

プラグインマーケットプレイスは、利用可能なプラグインのカタログであり、Claude Code拡張機能の発見、インストール、管理を簡単にします。このガイドでは、既存のマーケットプレイスを使用する方法と、チーム配布用に独自のマーケットプレイスを作成する方法を説明します。

## 概要

マーケットプレイスはJSONファイルであり、利用可能なプラグインをリストし、それらを見つける場所を説明します。マーケットプレイスは以下を提供します：

* **一元化された発見**: 複数のソースからのプラグインを1か所で参照
* **バージョン管理**: プラグインバージョンを自動的に追跡および更新
* **チーム配布**: 組織全体で必要なプラグインを共有
* **柔軟なソース**: gitリポジトリ、GitHubリポジトリ、ローカルパス、パッケージマネージャーのサポート

### 前提条件

* Claude Codeがインストールされて実行中
* JSONファイル形式の基本的な理解
* マーケットプレイスの作成: Gitリポジトリまたはローカル開発環境

## マーケットプレイスの追加と使用

`/plugin marketplace`コマンドを使用してマーケットプレイスを追加し、異なるソースからプラグインにアクセスします：

### GitHubマーケットプレイスの追加

```shell .claude-plugin/marketplace.jsonを含むGitHubリポジトリを追加 theme={null}
/plugin marketplace add owner/repo
```

### Gitリポジトリの追加

```shell 任意のgitリポジトリを追加 theme={null}
/plugin marketplace add https://gitlab.com/company/plugins.git
```

### 開発用のローカルマーケットプレイスの追加

```shell .claude-plugin/marketplace.jsonを含むローカルディレクトリを追加 theme={null}
/plugin marketplace add ./my-marketplace
```

```shell marketplace.jsonファイルへの直接パスを追加 theme={null}
/plugin marketplace add ./path/to/marketplace.json
```

```shell URLを介してリモートmarketplace.jsonを追加 theme={null}
/plugin marketplace add https://url.of/marketplace.json
```

### マーケットプレイスからプラグインをインストール

マーケットプレイスを追加したら、プラグインを直接インストールします：

```shell 既知のマーケットプレイスからインストール theme={null}
/plugin install plugin-name@marketplace-name
```

```shell 利用可能なプラグインを対話的に参照 theme={null}
/plugin
```

### マーケットプレイスのインストール確認

マーケットプレイスを追加した後：

1. **マーケットプレイスをリスト**: `/plugin marketplace list`を実行して追加されたことを確認
2. **プラグインを参照**: `/plugin`を使用してマーケットプレイスから利用可能なプラグインを表示
3. **インストールをテスト**: プラグインをインストールしてマーケットプレイスが正しく機能することを確認

## チームマーケットプレイスの設定

`.claude/settings.json`で必要なマーケットプレイスを指定して、チームプロジェクトの自動マーケットプレイスインストールを設定します：

```json  theme={null}
{
  "extraKnownMarketplaces": {
    "team-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    },
    "project-specific": {
      "source": {
        "source": "git",
        "url": "https://git.company.com/project-plugins.git"
      }
    }
  }
}
```

チームメンバーがリポジトリフォルダを信頼すると、Claude Codeはこれらのマーケットプレイスと`enabledPlugins`フィールドで指定されたプラグインを自動的にインストールします。

***

## 独自のマーケットプレイスを作成

チームまたはコミュニティ向けのカスタムプラグインコレクションを構築および配布します。

### マーケットプレイス作成の前提条件

* Gitリポジトリ（GitHub、GitLab、またはその他のgitホスティング）
* JSONファイル形式の理解
* 配布する1つ以上のプラグイン

### マーケットプレイスファイルの作成

リポジトリルートに`.claude-plugin/marketplace.json`を作成します：

```json  theme={null}
{
  "name": "company-tools",
  "owner": {
    "name": "DevTools Team",
    "email": "devtools@company.com"
  },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "./plugins/formatter",
      "description": "Automatic code formatting on save",
      "version": "2.1.0",
      "author": {
        "name": "DevTools Team"
      }
    },
    {
      "name": "deployment-tools",
      "source": {
        "source": "github",
        "repo": "company/deploy-plugin"
      },
      "description": "Deployment automation tools"
    }
  ]
}
```

### マーケットプレイススキーマ

#### 必須フィールド

| フィールド     | 型      | 説明                          |
| :-------- | :----- | :-------------------------- |
| `name`    | string | マーケットプレイス識別子（ケバブケース、スペースなし） |
| `owner`   | object | マーケットプレイス保守者情報              |
| `plugins` | array  | 利用可能なプラグインのリスト              |

#### オプションのメタデータ

| フィールド                  | 型      | 説明              |
| :--------------------- | :----- | :-------------- |
| `metadata.description` | string | マーケットプレイスの簡潔な説明 |
| `metadata.version`     | string | マーケットプレイスバージョン  |
| `metadata.pluginRoot`  | string | 相対プラグインソースの基本パス |

### プラグインエントリ

<Note>
  プラグインエントリは*プラグインマニフェストスキーマ*（すべてのフィールドがオプション）に基づいており、マーケットプレイス固有のフィールド（`source`、`category`、`tags`、`strict`）が追加されます。`name`は必須です。
</Note>

**必須フィールド：**

| フィールド    | 型              | 説明                      |
| :------- | :------------- | :---------------------- |
| `name`   | string         | プラグイン識別子（ケバブケース、スペースなし） |
| `source` | string\|object | プラグインを取得する場所            |

#### オプションのプラグインフィールド

**標準メタデータフィールド：**

| フィールド         | 型       | 説明                                                 |
| :------------ | :------ | :------------------------------------------------- |
| `description` | string  | プラグインの簡潔な説明                                        |
| `version`     | string  | プラグインバージョン                                         |
| `author`      | object  | プラグイン作成者情報                                         |
| `homepage`    | string  | プラグインホームページまたはドキュメンテーションURL                        |
| `repository`  | string  | ソースコードリポジトリURL                                     |
| `license`     | string  | SPDXライセンス識別子（例：MIT、Apache-2.0）                     |
| `keywords`    | array   | プラグイン発見とカテゴリ化用のタグ                                  |
| `category`    | string  | 整理用のプラグインカテゴリ                                      |
| `tags`        | array   | 検索性用のタグ                                            |
| `strict`      | boolean | プラグインフォルダ内のplugin.jsonを要求（デフォルト：true） <sup>1</sup> |

**コンポーネント設定フィールド：**

| フィールド        | 型              | 説明                        |
| :----------- | :------------- | :------------------------ |
| `commands`   | string\|array  | コマンドファイルまたはディレクトリへのカスタムパス |
| `agents`     | string\|array  | エージェントファイルへのカスタムパス        |
| `hooks`      | string\|object | カスタムフック設定またはフックファイルへのパス   |
| `mcpServers` | string\|object | MCPサーバー設定またはMCP設定へのパス     |

*<sup>1 - `strict: true`（デフォルト）の場合、プラグインは`plugin.json`マニフェストファイルを含む必要があり、マーケットプレイスフィールドはこれらの値を補足します。`strict: false`の場合、plugin.jsonはオプションです。存在しない場合、マーケットプレイスエントリは完全なプラグインマニフェストとして機能します。</sup>*

### プラグインソース

#### 相対パス

同じリポジトリ内のプラグイン：

```json  theme={null}
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin"
}
```

#### GitHubリポジトリ

```json  theme={null}
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo"
  }
}
```

#### Gitリポジトリ

```json  theme={null}
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git"
  }
}
```

#### 高度なプラグインエントリ

プラグインエントリはデフォルトのコンポーネント位置をオーバーライドし、追加のメタデータを提供できます。`${CLAUDE_PLUGIN_ROOT}`は環境変数であり、プラグインのインストールディレクトリに解決されることに注意してください（詳細については[環境変数](/ja/plugins-reference#environment-variables)を参照）：

```json  theme={null}
{
  "name": "enterprise-tools",
  "source": {
    "source": "github",
    "repo": "company/enterprise-plugin"
  },
  "description": "Enterprise workflow automation tools",
  "version": "2.1.0",
  "author": {
    "name": "Enterprise Team",
    "email": "enterprise@company.com"
  },
  "homepage": "https://docs.company.com/plugins/enterprise-tools",
  "repository": "https://github.com/company/enterprise-plugin",
  "license": "MIT",
  "keywords": ["enterprise", "workflow", "automation"],
  "category": "productivity",
  "commands": [
    "./commands/core/",
    "./commands/enterprise/",
    "./commands/experimental/preview.md"
  ],
  "agents": [
    "./agents/security-reviewer.md",
    "./agents/compliance-checker.md"
  ],
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"}]
      }
    ]
  },
  "mcpServers": {
    "enterprise-db": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  },
  "strict": false
}
```

<Note>
  **スキーマ関係**: プラグインエントリはプラグインマニフェストスキーマを使用し、すべてのフィールドがオプションであり、マーケットプレイス固有のフィールド（`source`、`strict`、`category`、`tags`）が追加されます。これは、`plugin.json`ファイルで有効なフィールドはマーケットプレイスエントリでも使用できることを意味します。`strict: false`の場合、`plugin.json`が存在しなければ、マーケットプレイスエントリは完全なプラグインマニフェストとして機能します。`strict: true`（デフォルト）の場合、マーケットプレイスフィールドはプラグイン独自のマニフェストファイルを補足します。
</Note>

***

## マーケットプレイスのホストと配布

プラグイン配布ニーズに最適なホスティング戦略を選択します。

### GitHubでホスト（推奨）

GitHubは最も簡単な配布方法を提供します：

1. **リポジトリを作成**: マーケットプレイス用の新しいリポジトリを設定
2. **マーケットプレイスファイルを追加**: プラグイン定義を含む`.claude-plugin/marketplace.json`を作成
3. **チームと共有**: チームメンバーは`/plugin marketplace add owner/repo`で追加

**利点**: 組み込みバージョン管理、問題追跡、チームコラボレーション機能。

### 他のgitサービスでホスト

任意のgitホスティングサービスは、任意のgitリポジトリへのURLを使用してマーケットプレイス配布に機能します。

例えば、GitLabを使用する場合：

```shell  theme={null}
/plugin marketplace add https://gitlab.com/company/plugins.git
```

### 開発用のローカルマーケットプレイスを使用

配布前にローカルでマーケットプレイスをテストします：

```shell テスト用のローカルマーケットプレイスを追加 theme={null}
/plugin marketplace add ./my-local-marketplace
```

```shell プラグインインストールをテスト theme={null}
/plugin install test-plugin@my-local-marketplace
```

## マーケットプレイス操作の管理

### 既知のマーケットプレイスをリスト

```shell 設定されたすべてのマーケットプレイスをリスト theme={null}
/plugin marketplace list
```

設定されたすべてのマーケットプレイスをソースとステータスとともに表示します。

### マーケットプレイスメタデータの更新

```shell マーケットプレイスメタデータをリフレッシュ theme={null}
/plugin marketplace update marketplace-name
```

マーケットプレイスソースからプラグインリストとメタデータをリフレッシュします。

### マーケットプレイスを削除

```shell マーケットプレイスを削除 theme={null}
/plugin marketplace remove marketplace-name
```

設定からマーケットプレイスを削除します。

<Warning>
  マーケットプレイスを削除すると、そこからインストールしたプラグインがアンインストールされます。
</Warning>

***

## マーケットプレイスのトラブルシューティング

### 一般的なマーケットプレイスの問題

#### マーケットプレイスが読み込まれない

**症状**: マーケットプレイスを追加できない、またはそこからプラグインが表示されない

**解決策**:

* マーケットプレイスURLがアクセス可能であることを確認
* `.claude-plugin/marketplace.json`が指定されたパスに存在することを確認
* `claude plugin validate`を使用してJSON構文が有効であることを確認
* プライベートリポジトリの場合、アクセス権限があることを確認

#### プラグインインストール失敗

**症状**: マーケットプレイスは表示されるがプラグインインストールが失敗

**解決策**:

* プラグインソースURLがアクセス可能であることを確認
* プラグインディレクトリに必要なファイルが含まれていることを確認
* GitHubソースの場合、リポジトリがパブリックであるか、アクセス権限があることを確認
* プラグインソースを手動でクローン/ダウンロードしてテスト

### 検証とテスト

共有する前にマーケットプレイスをテストします：

```bash マーケットプレイスJSON構文を検証 theme={null}
claude plugin validate .
```

```shell テスト用のマーケットプレイスを追加 theme={null}
/plugin marketplace add ./path/to/marketplace
```

```shell テストプラグインをインストール theme={null}
/plugin install test-plugin@marketplace-name
```

完全なプラグインテストワークフローについては、[プラグインをローカルでテスト](/ja/plugins#test-your-plugins-locally)を参照してください。技術的なトラブルシューティングについては、[プラグインリファレンス](/ja/plugins-reference)を参照してください。

***

## 次のステップ

### マーケットプレイスユーザー向け

* **コミュニティマーケットプレイスを発見**: Claude CodeプラグインコレクションについてgitHubを検索
* **フィードバックを提供**: マーケットプレイス保守者に問題を報告し、改善を提案
* **有用なマーケットプレイスを共有**: チームが価値のあるプラグインコレクションを発見するのを支援

### マーケットプレイス作成者向け

* **プラグインコレクションを構築**: 特定のユースケース周辺のテーマ別マーケットプレイスを作成
* **バージョン管理を確立**: 明確なバージョン管理と更新ポリシーを実装
* **コミュニティエンゲージメント**: フィードバックを収集し、アクティブなマーケットプレイスコミュニティを維持
* **ドキュメンテーション**: マーケットプレイスコンテンツを説明する明確なREADMEファイルを提供

### 組織向け

* **プライベートマーケットプレイス**: 独自ツール用の内部マーケットプレイスを設定
* **ガバナンスポリシー**: プラグイン承認とセキュリティレビューのガイドラインを確立
* **トレーニングリソース**: チームが有用なプラグインを効果的に発見および採用するのを支援

## 関連項目

* [プラグイン](/ja/plugins) - プラグインのインストールと使用
* [プラグインリファレンス](/ja/plugins-reference) - 完全な技術仕様とスキーマ
* [プラグイン開発](/ja/plugins#develop-more-complex-plugins) - 独自のプラグインの作成
* [設定](/ja/settings#plugin-configuration) - プラグイン設定オプション
