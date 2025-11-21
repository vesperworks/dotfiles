---
created: 2025-06-06T10:29
updated: 2025-06-12T18:40
---
# チームセットアップ

> ユーザー管理、セキュリティ、ベストプラクティスなど、チームをClaude Codeに導入する方法を学びましょう。

## ユーザー管理

Claude Codeをセットアップするには、Anthropicモデルへのアクセスが必要です。チームの場合、Claude Codeへのアクセスを以下の3つの方法でセットアップできます：

* Anthropic ConsoleからのAnthropic API
* Amazon Bedrock
* Google Vertex AI

**Anthropic APIを通じてチームのClaude Codeアクセスをセットアップするには：**

1. 既存のAnthropic Consoleアカウントを使用するか、新しいAnthropic Consoleアカウントを作成します
2. 以下のいずれかの方法でユーザーを追加できます：
   * Console内から一括でユーザーを招待する（Console -> Settings -> Members -> Invite）
   * [SSOをセットアップする](https://support.anthropic.com/en/articles/10280258-setting-up-single-sign-on-on-the-api-console)
3. ユーザーを招待する際、以下のいずれかの役割が必要です：
   * 「Claude Code」の役割は、ユーザーがClaude Code APIキーのみを作成できることを意味します
   * 「Developer」の役割は、ユーザーがあらゆる種類のAPIキーを作成できることを意味します
4. 招待された各ユーザーは以下の手順を完了する必要があります：
   * Consoleの招待を受け入れる
   * [システム要件を確認する](getting-started#check-system-requirements)
   * [Claude Codeをインストールする](overview#install-and-authenticate)
   * Consoleアカウントの認証情報でログインする

**BedrockまたはVertexを通じてチームのClaude Codeアクセスをセットアップするには：**

1. [Bedrockのドキュメント](bedrock-vertex-proxies#connect-to-amazon-bedrock)または[Vertexのドキュメント](bedrock-vertex-proxies#connect-to-google-vertex-ai)に従います
2. 環境変数とクラウド認証情報を生成するための手順をユーザーに配布します。[設定の管理方法についてはこちら](settings#configuration-hierarchy)をご覧ください。
3. ユーザーは[Claude Codeをインストール](overview#install-and-authenticate)できます

# セキュリティへの取り組み

あなたのコードのセキュリティは最も重要です。Claude Codeはセキュリティを核として構築されています。私たちは、Anthropicの包括的なセキュリティプログラムの要件に従って、すべてのアプリケーションやサービスと同様に、Claude Codeを開発しました。プログラムの詳細や各種リソース（SOC 2 Type 2レポート、ISO 27001証明書など）へのアクセスリクエストについては、[Anthropic Trust Center](https://trust.anthropic.com)をご覧ください。

Claude Codeは、デフォルトで現在の作業ディレクトリ内のファイルの読み取りや、`date`、`pwd`、`whoami`などの特定のbashコマンドなど、厳格な読み取り専用の権限を持つように設計されています。Claude Codeが追加のアクション（ファイルの編集、テストの実行、bashコマンドの実行など）を実行しようとする場合、ユーザーに許可を求めます。Claude Codeが許可を求める際、ユーザーはその特定のインスタンスだけに承認するか、今後そのコマンドを自動的に実行できるようにするかを選択できます。私たちは細かい権限をサポートしているため、エージェントが何を許可されるか（例：テストの実行、リンターの実行）と何が許可されないか（例：クラウドインフラストラクチャの更新）を正確に指定できます。これらの権限設定はバージョン管理にチェックインして組織内のすべての開発者に配布できるほか、個々の開発者によってカスタマイズすることもできます。

Claude Codeのエンタープライズデプロイメントでは、エンタープライズ管理ポリシー設定もサポートしています。これらはユーザーとプロジェクトの設定よりも優先され、システム管理者がユーザーが上書きできないセキュリティポリシーを適用できるようにします。[エンタープライズ管理ポリシー設定の構成方法を学ぶ](settings#configuration-hierarchy)。

Claude Codeは透明性とセキュリティを念頭に設計されています。例えば、モデルが実行する前に`git`コマンドを提案することを許可し、ユーザーに許可または拒否する権限を与えます。これにより、ユーザーや組織はすべての可能な回避策を監視しようとするのではなく、直接自分の権限を設定できます。

エージェントシステムは、エージェントが現実世界と対話するツールを呼び出し、より長い期間にわたって行動できるため、AIチャット体験とは根本的に異なります。エージェントシステムは非決定論的であり、ユーザーのリスクを軽減するための多くの組み込み保護機能があります。

1. **プロンプトインジェクション**は、モデル入力が望ましくない方法でモデルの動作を変更する場合です。これが発生するリスクを軽減するために、いくつかの製品内緩和策を追加しました：
   * ネットワークリクエストを行うツールは、デフォルトでユーザーの承認が必要です
   * Webフェッチは別のコンテキストウィンドウを使用し、潜在的に悪意のあるプロンプトがメインのコンテキストウィンドウに注入されるのを防ぎます
   * 新しいコードベースでClaude Codeを初めて実行する際、コードを信頼するかどうかの確認を求められます
   * 新しいMCPサーバー（`.mcp.json`で設定）を初めて見る場合、サーバーを信頼するかどうかの確認を求められます
   * プロンプトインジェクションの結果として潜在的なコマンドインジェクションを持つbashコマンドを検出した場合、許可リストに登録されていても、ユーザーに手動での承認を求めます
   * bashコマンドを許可リストに登録された権限に確実に一致させることができない場合、閉じた状態で失敗し、ユーザーに手動での承認を求めます
   * モデルが複雑なbashコマンドを生成する場合、ユーザーがコマンドの内容を理解できるように、自然言語での説明を生成します
2. **プロンプト疲れ**。頻繁に使用される安全なコマンドをユーザーごと、コードベースごと、または組織ごとに許可リストに登録することをサポートしています。また、編集受け入れモードに切り替えて、一度に多くの編集を受け入れ、副作用を持つ可能性のあるツール（例：bash）に権限プロンプトを集中させることもできます

最終的に、Claude Codeはそれを指示するユーザーと同じ数の権限しか持たず、提案されたコードとコマンドが安全であることを確認する責任はユーザーにあります。

**MCPセキュリティ**

Claude Codeでは、ユーザーがModel Context Protocol（MCP）サーバーを設定できます。許可されたMCPサーバーのリストは、エンジニアがソース管理にチェックインするClaude Code設定の一部として、ソースコードで設定されます。

独自のMCPサーバーを作成するか、信頼できるプロバイダーからのMCPサーバーを使用することをお勧めします。MCPサーバーのClaude Code権限を設定することができます。AnthropicはMCPサーバーを管理または監査しません。

# データフローと依存関係

![Claude Codeデータフロー図](https://mintlify.s3.us-west-1.amazonaws.com/anthropic/images/claude-code-data-flow.png)

Claude Codeは[NPM](https://www.npmjs.com/package/@anthropic-ai/claude-code)からインストールされます。Claude Codeはローカルで実行されます。LLMと対話するために、Claude Codeはネットワーク経由でデータを送信します。このデータには、すべてのユーザープロンプトとモデル出力が含まれます。データはTLSを介して転送中に暗号化され、保存時には暗号化されません。Claude Codeは、ほとんどの一般的なVPNやLLMプロキシと互換性があります。

Claude CodeはAnthropicのAPIに基づいて構築されています。APIのセキュリティ管理（APIログ記録手順を含む）の詳細については、[Anthropic Trust Center](https://trust.anthropic.com)で提供されているコンプライアンス資料を参照してください。

Claude Codeは、Claude.ai認証情報、Anthropic API認証情報、Bedrock認証、およびVertex認証を介した認証をサポートしています。MacOSでは、APIキー、OAuthトークン、およびその他の認証情報は暗号化されたmacOS Keychainに保存されます。また、代替キーチェーンから読み取るための`apiKeyHelper`もサポートしています。デフォルトでは、このヘルパーは5分後またはHTTP 401レスポンス時に呼び出されます。`CLAUDE_CODE_API_KEY_HELPER_TTL_MS`を指定することで、カスタムリフレッシュ間隔を設定できます。

Claude Codeは、ユーザーのマシンからStatsigサービスに接続し、レイテンシー、信頼性、使用パターンなどの運用メトリクスを記録します。このログ記録には、コードやファイルパスは含まれません。データはTLSを使用して転送中に暗号化され、256ビットAES暗号化を使用して保存時に暗号化されます。詳細は[Statsigセキュリティドキュメント](https://www.statsig.com/trust/security)をご覧ください。Statsigテレメトリをオプトアウトするには、`DISABLE_TELEMETRY`環境変数を設定します。

Claude Codeは、ユーザーのマシンからSentryに接続して運用エラーログを記録します。データはTLSを使用して転送中に暗号化され、256ビットAES暗号化を使用して保存時に暗号化されます。詳細は[Sentryセキュリティドキュメント](https://sentry.io/security/)をご覧ください。エラーログ記録をオプトアウトするには、`DISABLE_ERROR_REPORTING`環境変数を設定します。

ユーザーが`/bug`コマンドを実行すると、コードを含む完全な会話履歴のコピーがAnthropicに送信されます。データは転送中および保存時に暗号化されます。オプションで、公開リポジトリにGithub issueが作成されます。バグレポートをオプトアウトするには、`DISABLE_BUG_COMMAND`環境変数を設定します。

デフォルトでは、BedrockまたはVertexを使用する場合、エラーレポート、テレメトリ、バグレポート機能を含むすべての非必須トラフィックを無効にします。`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`環境変数を設定することで、これらすべてを一度にオプトアウトすることもできます。以下が完全なデフォルト動作です：

| サービス                          | Anthropic API                                   | Vertex API                                           | Bedrock API                                           |
| ----------------------------- | ----------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------- |
| **Statsig（メトリクス）**            | デフォルトでオン。<br />`DISABLE_TELEMETRY=1`で無効化。       | デフォルトでオフ。<br />`CLAUDE_CODE_USE_VERTEX`は1である必要があります。 | デフォルトでオフ。<br />`CLAUDE_CODE_USE_BEDROCK`は1である必要があります。 |
| **Sentry（エラー）**               | デフォルトでオン。<br />`DISABLE_ERROR_REPORTING=1`で無効化。 | デフォルトでオフ。<br />`CLAUDE_CODE_USE_VERTEX`は1である必要があります。 | デフォルトでオフ。<br />`CLAUDE_CODE_USE_BEDROCK`は1である必要があります。 |
| **Anthropic API（`/bug`レポート）** | デフォルトでオン。<br />`DISABLE_BUG_COMMAND=1`で無効化。     | デフォルトでオフ。<br />`CLAUDE_CODE_USE_VERTEX`は1である必要があります。 | デフォルトでオフ。<br />`CLAUDE_CODE_USE_BEDROCK`は1である必要があります。 |

すべての環境変数は`settings.json`にチェックインできます（[詳細はこちら](settings#configuration-hierarchy)）。

Claude Codeは会話履歴をローカルに平文で保存し、ユーザーが以前の会話を再開できるようにします。会話は30日間保持され、`rm -r ~/.claude/projects/*/`を実行することで早期に削除できます。保持期間は`cleanupPeriodDays`設定を使用してカスタマイズできます。他の設定と同様に、この設定をリポジトリにチェックインしたり、すべてのリポジトリに適用されるようにグローバルに設定したり、エンタープライズポリシーを使用してすべての従業員に対して管理したりできます。`claude`をアンインストールしても履歴は削除されません。

# コスト管理

Anthropic APIを使用する場合、Claude Codeワークスペースの総支出を制限できます。設定するには、[これらの手順に従ってください](https://support.anthropic.com/en/articles/9796807-creating-and-managing-workspaces)。管理者は[これらの手順に従って](https://support.anthropic.com/en/articles/9534590-cost-and-usage-reporting-in-console)コストと使用状況のレポートを表示できます。

BedrockとVertexでは、Claude Codeはクラウドからメトリクスを送信しません。コストメトリクスを取得するために、多くの大企業が[LiteLLM](https://github.com/BerriAI/litellm)を使用していると報告しています。これは、企業が[キーごとの支出を追跡する](https://docs.litellm.ai/docs/proxy/virtual_keys#tracking-spend)のに役立つオープンソースツールです。このプロジェクトはAnthropicと提携しておらず、そのセキュリティを監査していません。

チームでの使用では、Claude CodeはAPIトークンの消費に応じて課金されます。平均して、Claude Codeは開発者1人あたり月額約\$50-60のコストがかかりますが、ユーザーが実行しているインスタンスの数や自動化で使用しているかどうかによって大きく異なります。

# 組織のためのベストプラクティス

1. Claude Codeがコードベースを理解できるようにドキュメントに投資することを強くお勧めします。多くの組織は、システムアーキテクチャ、テストの実行方法やその他の一般的なコマンド、コードベースに貢献するためのベストプラクティスを含む`CLAUDE.md`ファイル（メモリとも呼ばれます）をリポジトリのルートに作成します。このファイルは通常、すべてのユーザーが恩恵を受けられるようにソース管理にチェックインされます。[詳細はこちら](memory)。
2. カスタム開発環境がある場合、Claude Codeをインストールするための「ワンクリック」方法を作成することが、組織全体での採用を拡大するための鍵であることがわかっています。
3. 新しいユーザーには、コードベースのQ\&A、または小さなバグ修正や機能リクエストでClaude Codeを試すことをお勧めします。Claude Codeに計画を立てるよう依頼してください。Claudeの提案をチェックし、軌道から外れている場合はフィードバックを与えてください。時間が経つにつれて、ユーザーがこの新しいパラダイムをよりよく理解するようになると、Claude Codeをよりエージェント的に実行させることがより効果的になります。
4. セキュリティチームは、ローカル設定で上書きできないClaude Codeが許可されることと許可されないことに関する管理権限を設定できます。[詳細はこちら](overview#permission-rules)。
5. MCPは、チケット管理システムやエラーログへの接続など、Claude Codeにより多くの情報を提供する優れた方法です。1つの中央チームがMCPサーバーを設定し、すべてのユーザーが恩恵を受けられるように`.mcp.json`設定をコードベースにチェックインすることをお勧めします。[詳細はこちら](tutorials#set-up-model-context-protocol-mcp)。

Anthropicでは、すべてのAnthropicコードベースの開発を強化するためにClaude Codeを信頼しています。私たちと同じくらいClaude Codeを楽しんでいただければ幸いです！

# よくある質問

**Q: 既存の商業契約は適用されますか？**

AnthropicのAPIを直接使用している場合（1P）でも、AWS BedrockやGoogle Vertex（3P）を通じてアクセスしている場合でも、相互に別途合意しない限り、既存の商業契約がClaude Codeの使用に適用されます。

**Q: Claude Codeはユーザーコンテンツでトレーニングしますか？**

デフォルトでは、AnthropicはClaude Codeに送信されるコードやプロンプトを使用して生成モデルをトレーニングしません。

[Development Partner Program](https://support.anthropic.com/en/articles/11174108-about-the-development-partner-program)などを通じて、トレーニングする素材を提供する方法に明示的にオプトインした場合、提供された素材を使用してモデルをトレーニングする場合があります。組織の管理者は、組織のDevelopment Partner Programに明示的にオプトインできます。このプログラムはAnthropic一次APIのみで利用可能であり、BedrockまたはVertexユーザーには利用できないことに注意してください。

詳細は[商業利用規約](https://www.anthropic.com/legal/commercial-terms)および[プライバシーポリシー](https://www.anthropic.com/legal/privacy)をご覧ください。

**Q: ゼロデータ保持キーを使用できますか？**

はい、ゼロデータ保持組織からのAPIキーを使用できます。その場合、Claude Codeはチャットトランスクリプトをサーバーに保持しません。ユーザーのローカルClaude Codeクライアントは、ユーザーが再開できるように、セッションをローカルに最大30日間保存する場合があります。この動作は設定可能です。

**Q: Anthropicの信頼性と安全性についての詳細はどこで確認できますか？**

[Anthropic Trust Center](https://trust.anthropic.com)および[Transparency Hub](https://www.anthropic.com/transparency)で詳細情報を確認できます。

**Q: セキュリティの脆弱性はどのように報告できますか？**

AnthropicはHackerOneを通じてセキュリティプログラムを管理しています。[このフォームを使用して脆弱性を報告してください](https://hackerone.com/anthropic-vdp/reports/new?type=team\&report_type=vulnerability)。[security@anthropic.com](mailto:security@anthropic.com)にメールを送ることもできます。
