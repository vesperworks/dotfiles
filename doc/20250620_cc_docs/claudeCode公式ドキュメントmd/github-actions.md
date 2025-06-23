---
created: 2025-06-06T10:30
updated: 2025-06-12T18:40
---
# GitHub Actions

> Claude Codeを GitHub ワークフローに統合して、自動コードレビュー、PR管理、課題トリアージを実現します。

Claude Code GitHub Actionsは、GitHubワークフローにAIを活用した自動化をもたらします。PRや課題で簡単に`@claude`とメンションするだけで、Claudeはコードを分析し、プルリクエストを作成し、機能を実装し、バグを修正します - すべてプロジェクトの標準に従いながら行います。

<Info>
  Claude Code GitHub Actionsは現在ベータ版です。機能や性能は、体験を改善する過程で進化する可能性があります。
</Info>

<Note>
  Claude Code GitHub Actionsは[Claude Code SDK](/ja/docs/claude-code/sdk)の上に構築されており、Claude Codeをアプリケーションにプログラムで統合することができます。SDKを使用して、GitHub Actions以外のカスタム自動化ワークフローを構築できます。
</Note>

## なぜClaude Code GitHub Actionsを使用するのか？

* **即時PR作成**: 必要なものを説明すれば、Claudeが必要なすべての変更を含む完全なPRを作成します
* **自動コード実装**: 単一のコマンドで課題を動作するコードに変換します
* **標準に準拠**: Claudeは`CLAUDE.md`ガイドラインと既存のコードパターンを尊重します
* **簡単なセットアップ**: インストーラーとAPIキーで数分で始められます
* **デフォルトで安全**: コードはGithubのランナー上に留まります

## Claudeは何ができるのか？

Claude Codeは、コードの操作方法を変革する強力なGitHub Actionsを提供します：

### Claude Code Action

このGitHub Actionを使用すると、GitHubワークフロー内でClaude Codeを実行できます。これを使用して、Claude Code上にカスタムワークフローを構築できます。

[リポジトリを見る →](https://github.com/anthropics/claude-code-action)

### Claude Code Action (Base)

ClaudeでカスタムのGitHubワークフローを構築するための基盤です。この拡張可能なフレームワークにより、カスタマイズされた自動化を作成するためのClaudeの機能に完全にアクセスできます。

[リポジトリを見る →](https://github.com/anthropics/claude-code-base-action)

## クイックスタート

このアクションを設定する最も簡単な方法は、ターミナルでClaude Codeを使用することです。claudeを開いて `/install-github-app` を実行するだけです。

このコマンドは、GitHubアプリと必要なシークレットの設定をガイドします。

<Note>
  * GitHubアプリをインストールしてシークレットを追加するには、リポジトリの管理者である必要があります
  * このクイックスタート方法は、Anthropic APIの直接ユーザーのみが利用できます。AWS BedrockまたはGoogle Vertex AIを使用している場合は、[AWS BedrockおよびGoogle Vertex AIでの使用](#using-with-aws-bedrock-%26-google-vertex-ai)セクションを参照してください。
</Note>

### セットアップスクリプトが失敗した場合

`/install-github-app`コマンドが失敗した場合、または手動セットアップを好む場合は、次の手動セットアップ手順に従ってください：

1. **Claude GitHubアプリ**をリポジトリにインストールします：[https://github.com/apps/claude](https://github.com/apps/claude)
2. **ANTHROPIC\_API\_KEY**をリポジトリシークレットに追加します（[GitHub Actionsでシークレットを使用する方法を学ぶ](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)）
3. [examples/claude.yml](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml)から**ワークフローファイルをコピー**して、リポジトリの`.github/workflows/`に配置します

<Steps>
  <Step title="アクションをテストする">
    クイックスタートまたは手動セットアップのいずれかを完了した後、課題またはPRコメントで`@claude`をタグ付けしてアクションをテストしてください！
  </Step>
</Steps>

## 使用例

Claude Code GitHub Actionsはさまざまなタスクを支援できます。完全な動作例については、[examplesディレクトリ](https://github.com/anthropics/claude-code-action/tree/main/examples)を参照してください。

### 課題をPRに変換する

```yaml
# In an issue comment:
@claude implement this feature based on the issue description
```

Claudeは課題を分析し、コードを記述し、レビュー用のPRを作成します。

### 実装のヘルプを得る

```yaml
# In a PR comment:
@claude how should I implement user authentication for this endpoint?
```

Claudeはコードを分析し、具体的な実装ガイダンスを提供します。

### バグを素早く修正する

```yaml
# In an issue:
@claude fix the TypeError in the user dashboard component
```

Claudeはバグを特定し、修正を実装し、PRを作成します。

## ベストプラクティス

### CLAUDE.md設定

リポジトリのルートに`CLAUDE.md`ファイルを作成して、コードスタイルのガイドライン、レビュー基準、プロジェクト固有のルール、および好ましいパターンを定義します。このファイルは、Claudeがプロジェクト標準を理解するためのガイドとなります。

### セキュリティに関する考慮事項

**⚠️ 重要：APIキーを直接リポジトリにコミットしないでください！**

APIキーには常にGitHub Secretsを使用してください：

* APIキーを`ANTHROPIC_API_KEY`という名前のリポジトリシークレットとして追加します
* ワークフローで参照します：`anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}`
* アクションの権限を必要なものだけに制限します
* マージする前にClaudeの提案を確認します

ワークフローファイルに直接APIキーをハードコーディングするのではなく、常にGitHub Secrets（例：`${{ secrets.ANTHROPIC_API_KEY }}`）を使用してください。

### パフォーマンスの最適化

コンテキストを提供するために課題テンプレートを使用し、`CLAUDE.md`を簡潔で焦点を絞ったものにし、ワークフローに適切なタイムアウトを設定します。

### CIコスト

Claude Code GitHub Actionsを使用する際は、関連するコストに注意してください：

**GitHub Actionsのコスト：**

* Claude CodeはGitHubホストのランナーで実行され、GitHubのアクション分を消費します
* 詳細な価格設定と分数制限については、[GitHubの請求ドキュメント](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions)を参照してください

**APIコスト：**

* 各Claude対話は、プロンプトとレスポンスの長さに基づいてAPIトークンを消費します
* トークン使用量はタスクの複雑さとコードベースのサイズによって異なります
* 現在のトークンレートについては、[Claudeの価格ページ](https://www.anthropic.com/api)を参照してください

**コスト最適化のヒント：**

* 不要なAPI呼び出しを減らすために特定の`@claude`コマンドを使用する
* 過度の繰り返しを防ぐために適切な`max_turns`制限を設定する
* 暴走ワークフローを避けるために合理的な`timeout_minutes`を設定する
* 並列実行を制限するためにGitHubの同時実行制御の使用を検討する

## 設定例

さまざまなユースケースに対応した使用可能なワークフロー設定については、以下を含む：

* 課題とPRコメントの基本的なワークフロー設定
* プルリクエストの自動コードレビュー
* 特定のニーズに対するカスタム実装

Claude Code Actionリポジトリの[examplesディレクトリ](https://github.com/anthropics/claude-code-action/tree/main/examples)をご覧ください。

<Tip>
  examplesリポジトリには、`.github/workflows/`ディレクトリに直接コピーできる完全でテスト済みのワークフローが含まれています。
</Tip>

## AWS BedrockおよびGoogle Vertex AIでの使用

エンタープライズ環境では、Claude Code GitHub Actionsを独自のクラウドインフラストラクチャで使用できます。このアプローチにより、同じ機能を維持しながら、データの所在地と請求を制御できます。

### 前提条件

クラウドプロバイダーでClaude Code GitHub Actionsを設定する前に、以下が必要です：

#### Google Cloud Vertex AI用：

1. Vertex AIが有効になっているGoogle Cloudプロジェクト
2. GitHub Actions用に設定されたWorkload Identity Federation
3. 必要な権限を持つサービスアカウント
4. GitHubアプリ（推奨）またはデフォルトのGITHUB\_TOKENの使用

#### AWS Bedrock用：

1. Amazon Bedrockが有効になっているAWSアカウント
2. AWSで設定されたGitHub OIDC Identity Provider
3. Bedrock権限を持つIAMロール
4. GitHubアプリ（推奨）またはデフォルトのGITHUB\_TOKENの使用

<Steps>
  <Step title="カスタムGitHubアプリを作成する（3Pプロバイダーに推奨）">
    Vertex AIやBedrockなどの3Pプロバイダーを使用する場合、最適な制御とセキュリティのために独自のGitHubアプリを作成することをお勧めします：

    1. [https://github.com/settings/apps/new](https://github.com/settings/apps/new) にアクセスします
    2. 基本情報を入力します：
       * **GitHub App名**：一意の名前を選択します（例：「YourOrg Claude Assistant」）
       * **ホームページURL**：組織のウェブサイトまたはリポジトリのURL
    3. アプリの設定を構成します：
       * **Webhooks**：「アクティブ」のチェックを外します（この統合には不要）
    4. 必要な権限を設定します：
       * **リポジトリの権限**：
         * コンテンツ：読み取りと書き込み
         * 課題：読み取りと書き込み
         * プルリクエスト：読み取りと書き込み
    5. 「GitHub Appを作成」をクリックします
    6. 作成後、「秘密鍵を生成」をクリックし、ダウンロードした`.pem`ファイルを保存します
    7. アプリ設定ページからApp IDをメモします
    8. アプリをリポジトリにインストールします：
       * アプリの設定ページから、左サイドバーの「アプリをインストール」をクリックします
       * アカウントまたは組織を選択します
       * 「特定のリポジトリのみを選択」を選択し、特定のリポジトリを選択します
       * 「インストール」をクリックします
    9. 秘密鍵をリポジトリのシークレットとして追加します：
       * リポジトリの設定 → シークレットと変数 → アクションに移動します
       * `.pem`ファイルの内容で`APP_PRIVATE_KEY`という名前の新しいシークレットを作成します
    10. App IDをシークレットとして追加します：

    * GitHubアプリのIDで`APP_ID`という名前の新しいシークレットを作成します

    <Note>
      このアプリは、ワークフローで認証トークンを生成するために[actions/create-github-app-token](https://github.com/actions/create-github-app-token)アクションと共に使用されます。
    </Note>

    **Anthropic APIを使用する場合、または独自のGithubアプリを設定したくない場合の代替手段**：公式Anthropicアプリを使用します：

    1. [https://github.com/apps/claude](https://github.com/apps/claude) からインストールします
    2. 認証に追加の設定は必要ありません
  </Step>

  <Step title="クラウドプロバイダーの認証を設定する">
    クラウドプロバイダーを選択し、安全な認証を設定します：

    <AccordionGroup>
      <Accordion title="AWS Bedrock">
        **認証情報を保存せずにGitHub Actionsが安全に認証できるようにAWSを設定します。**

        > **セキュリティに関する注意**：リポジトリ固有の設定を使用し、必要最小限の権限のみを付与してください。

        **必要な設定**：

        1. **Amazon Bedrockを有効にする**：
           * Amazon BedrockでClaudeモデルへのアクセスをリクエストします
           * クロスリージョンモデルの場合、必要なすべてのリージョンでアクセスをリクエストします

        2. **GitHub OIDC Identity Providerを設定する**：
           * プロバイダーURL：`https://token.actions.githubusercontent.com`
           * オーディエンス：`sts.amazonaws.com`

        3. **GitHub Actions用のIAMロールを作成する**：
           * 信頼されるエンティティタイプ：Webアイデンティティ
           * アイデンティティプロバイダー：`token.actions.githubusercontent.com`
           * 権限：`AmazonBedrockFullAccess`ポリシー
           * 特定のリポジトリ用の信頼ポリシーを設定します

        **必要な値**：

        設定後、以下が必要になります：

        * **AWS\_ROLE\_TO\_ASSUME**：作成したIAMロールのARN

        <Tip>
          OIDCは静的なAWSアクセスキーを使用するよりも安全です。認証情報は一時的で自動的にローテーションされるためです。
        </Tip>

        詳細なOIDC設定手順については、[AWSドキュメント](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)を参照してください。
      </Accordion>

      <Accordion title="Google Vertex AI">
        **認証情報を保存せずにGitHub Actionsが安全に認証できるようにGoogle Cloudを設定します。**

        > **セキュリティに関する注意**：リポジトリ固有の設定を使用し、必要最小限の権限のみを付与してください。

        **必要な設定**：

        1. **Google CloudプロジェクトでのAPIの有効化**：
           * IAM認証情報API
           * セキュリティトークンサービス（STS）API
           * Vertex AI API

        2. **Workload Identity Federationリソースの作成**：
           * Workload Identity Poolを作成します
           * 以下を含むGitHub OIDCプロバイダーを追加します：
             * 発行者：`https://token.actions.githubusercontent.com`
             * リポジトリと所有者の属性マッピング
             * **セキュリティ推奨事項**：リポジトリ固有の属性条件を使用します

        3. **サービスアカウントの作成**：
           * `Vertex AI User`ロールのみを付与します
           * **セキュリティ推奨事項**：リポジトリごとに専用のサービスアカウントを作成します

        4. **IAMバインディングの設定**：
           * Workload Identity Poolがサービスアカウントを偽装できるようにします
           * **セキュリティ推奨事項**：リポジトリ固有のプリンシパルセットを使用します

        **必要な値**：

        設定後、以下が必要になります：

        * **GCP\_WORKLOAD\_IDENTITY\_PROVIDER**：完全なプロバイダーリソース名
        * **GCP\_SERVICE\_ACCOUNT**：サービスアカウントのメールアドレス

        <Tip>
          Workload Identity Federationは、ダウンロード可能なサービスアカウントキーの必要性を排除し、セキュリティを向上させます。
        </Tip>

        詳細な設定手順については、[Google Cloud Workload Identity Federationドキュメント](https://cloud.google.com/iam/docs/workload-identity-federation)を参照してください。
      </Accordion>
    </AccordionGroup>
  </Step>

  <Step title="必要なシークレットを追加する">
    以下のシークレットをリポジトリに追加します（設定 → シークレットと変数 → アクション）：

    #### Anthropic API（直接）の場合：

    1. **API認証用**：
       * `ANTHROPIC_API_KEY`：[console.anthropic.com](https://console.anthropic.com)からのAnthropic APIキー

    2. **GitHubアプリ用（独自のアプリを使用する場合）**：
       * `APP_ID`：GitHubアプリのID
       * `APP_PRIVATE_KEY`：秘密鍵（.pem）の内容

    #### Google Cloud Vertex AIの場合

    1. **GCP認証用**：
       * `GCP_WORKLOAD_IDENTITY_PROVIDER`
       * `GCP_SERVICE_ACCOUNT`

    2. **GitHubアプリ用（独自のアプリを使用する場合）**：
       * `APP_ID`：GitHubアプリのID
       * `APP_PRIVATE_KEY`：秘密鍵（.pem）の内容

    #### AWS Bedrockの場合

    1. **AWS認証用**：
       * `AWS_ROLE_TO_ASSUME`

    2. **GitHubアプリ用（独自のアプリを使用する場合）**：
       * `APP_ID`：GitHubアプリのID
       * `APP_PRIVATE_KEY`：秘密鍵（.pem）の内容
  </Step>

  <Step title="ワークフローファイルを作成する">
    クラウドプロバイダーと統合するGitHub Actionsワークフローファイルを作成します。以下の例は、AWS BedrockとGoogle Vertex AIの両方の完全な設定を示しています：

    <AccordionGroup>
      <Accordion title="AWS Bedrockワークフロー">
        **前提条件：**

        * Claudeモデルの権限を持つAWS Bedrockアクセスが有効
        * GitHubがAWSでOIDCアイデンティティプロバイダーとして設定されている
        * GitHub Actionsを信頼するBedrock権限を持つIAMロール

        **必要なGitHubシークレット：**

        | シークレット名              | 説明                      |
        | -------------------- | ----------------------- |
        | `AWS_ROLE_TO_ASSUME` | Bedrockアクセス用のIAMロールのARN |
        | `APP_ID`             | GitHubアプリID（アプリ設定から）    |
        | `APP_PRIVATE_KEY`    | GitHubアプリ用に生成した秘密鍵      |

        ```yaml

        name: Claude PR Action 

        permissions:
          contents: write
          pull-requests: write
          issues: write
          id-token: write 

        on:
          issue_comment:
            types: [created]
          pull_request_review_comment:
            types: [created]
          issues:
            types: [opened, assigned]

        jobs:
          claude-pr:
            if: |
              (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'issues' && contains(github.event.issue.body, '@claude'))
            runs-on: ubuntu-latest
            env:
              AWS_REGION: us-west-2
            steps:
              - name: Checkout repository
                uses: actions/checkout@v4

              - name: Generate GitHub App token
                id: app-token
                uses: actions/create-github-app-token@v2
                with:
                  app-id: ${{ secrets.APP_ID }}
                  private-key: ${{ secrets.APP_PRIVATE_KEY }}

              - name: Configure AWS Credentials (OIDC)
                uses: aws-actions/configure-aws-credentials@v4
                with:
                  role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
                  aws-region: us-west-2

              - uses: ./.github/actions/claude-pr-action
                with:
                  trigger_phrase: "@claude"
                  timeout_minutes: "60"
                  github_token: ${{ steps.app-token.outputs.token }}
                  use_bedrock: "true"
                  model: "us.anthropic.claude-3-7-sonnet-20250219-v1:0"
        ```

        <Tip>
          BedrockのモデルID形式には、リージョンプレフィックス（例：`us.anthropic.claude...`）とバージョンサフィックスが含まれます。
        </Tip>
      </Accordion>

      <Accordion title="Google Vertex AIワークフロー">
        **前提条件：**

        * GCPプロジェクトでVertex AI APIが有効になっている
        * GitHub用のWorkload Identity Federationが設定されている
        * Vertex AI権限を持つサービスアカウント

        **必要なGitHubシークレット：**

        | シークレット名                          | 説明                                |
        | -------------------------------- | --------------------------------- |
        | `GCP_WORKLOAD_IDENTITY_PROVIDER` | ワークロードアイデンティティプロバイダーのリソース名        |
        | `GCP_SERVICE_ACCOUNT`            | Vertex AIアクセスを持つサービスアカウントのメールアドレス |
        | `APP_ID`                         | GitHubアプリID（アプリ設定から）              |
        | `APP_PRIVATE_KEY`                | GitHubアプリ用に生成した秘密鍵                |

        ```yaml
        name: Claude PR Action

        permissions:
          contents: write
          pull-requests: write
          issues: write
          id-token: write  

        on:
          issue_comment:
            types: [created]
          pull_request_review_comment:
            types: [created]
          issues:
            types: [opened, assigned]

        jobs:
          claude-pr:
            if: |
              (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
              (github.event_name == 'issues' && contains(github.event.issue.body, '@claude'))
            runs-on: ubuntu-latest
            steps:
              - name: Checkout repository
                uses: actions/checkout@v4

              - name: Generate GitHub App token
                id: app-token
                uses: actions/create-github-app-token@v2
                with:
                  app-id: ${{ secrets.APP_ID }}
                  private-key: ${{ secrets.APP_PRIVATE_KEY }}

              - name: Authenticate to Google Cloud
                id: auth
                uses: google-github-actions/auth@v2
                with:
                  workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
                  service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
              
              - uses: ./.github/actions/claude-pr-action
                with:
                  trigger_phrase: "@claude"
                  timeout_minutes: "60"
                  github_token: ${{ steps.app-token.outputs.token }}
                  use_vertex: "true"
                  model: "claude-3-7-sonnet@20250219"
                env:
                  ANTHROPIC_VERTEX_PROJECT_ID: ${{ steps.auth.outputs.project_id }}
                  CLOUD_ML_REGION: us-east5
                  VERTEX_REGION_CLAUDE_3_7_SONNET: us-east5
        ```

        <Tip>
          プロジェクトIDはGoogle Cloud認証ステップから自動的に取得されるため、ハードコーディングする必要はありません。
        </Tip>
      </Accordion>
    </AccordionGroup>
  </Step>
</Steps>

## トラブルシューティング

### Claudeが@claudeコマンドに応答しない

GitHubアプリが正しくインストールされていることを確認し、ワークフローが有効になっていることを確認し、APIキーがリポジトリシークレットに設定されていることを確認し、コメントに`@claude`（`/claude`ではない）が含まれていることを確認します。

### ClaudeのコミットでCIが実行されない

GitHubアプリまたはカスタムアプリ（Actionsユーザーではない）を使用していることを確認し、ワークフロートリガーに必要なイベントが含まれていることを確認し、アプリの権限にCIトリガーが含まれていることを確認します。

### 認証エラー

APIキーが有効で十分な権限を持っていることを確認します。Bedrock/Vertexの場合、認証情報の設定を確認し、シークレットがワークフローで正しく名前付けされていることを確認します。

## 高度な設定

### アクションパラメータ

Claude Code Actionは以下の主要パラメータをサポートしています：

| パラメータ               | 説明               | 必須     |
| ------------------- | ---------------- | ------ |
| `prompt`            | Claudeに送信するプロンプト | はい\*   |
| `prompt_file`       | プロンプトを含むファイルへのパス | はい\*   |
| `anthropic_api_key` | Anthropic APIキー  | はい\*\* |
| `max_turns`         | 最大会話ターン数         | いいえ    |
| `timeout_minutes`   | 実行タイムアウト         | いいえ    |

\*`prompt`または`prompt_file`のいずれかが必要\
\*\*直接Anthropic APIには必要、Bedrock/Vertexには不要

### 代替統合方法

`/install-github-app`コマンドが推奨されるアプローチですが、以下の方法も可能です：

* **カスタムGitHubアプリ**：ブランド化されたユーザー名やカスタム認証フローが必要な組織向け。必要な権限（コンテンツ、課題、プルリクエスト）を持つ独自のGitHubアプリを作成し、actions/create-github-app-tokenアクションを使用してワークフローでトークンを生成します。
* **手動GitHub Actions**：最大の柔軟性のための直接ワークフロー設定
* **MCP設定**：Model Context Protocolサーバーの動的ロード

詳細なドキュメントについては、[Claude Code Actionリポジトリ](https://github.com/anthropics/claude-code-action)を参照してください。

### Claudeの動作のカスタマイズ

Claudeの動作は2つの方法で設定できます：

1. **CLAUDE.md**：リポジトリのルートに`CLAUDE.md`ファイルでコーディング標準、レビュー基準、およびプロジェクト固有のルールを定義します。Claudeは、PRを作成し、リクエストに応答する際にこれらのガイドラインに従います。詳細については、[メモリドキュメント](/ja/docs/claude-code/memory)をご覧ください。
2. **カスタムプロンプト**：ワークフローファイルの`prompt`パラメータを使用して、ワークフロー固有の指示を提供します。これにより、異なるワークフローやタスクに対してClaudeの動作をカスタマイズできます。

Claudeは、PRを作成し、リクエストに応答する際にこれらのガイドラインに従います。
