---
created: 2025-06-06T10:30
updated: 2025-06-12T18:40
---
# Bedrock、Vertex、およびプロキシ

> Claude CodeをAmazon BedrockやGoogle Vertex AIと連携させ、プロキシを通じて接続するように設定します。

## モデル設定

デフォルトでは、Claude Codeは`claude-opus-4-20250514`を使用します。以下の環境変数を使用してこれをオーバーライドできます：

```bash
# Anthropic API
ANTHROPIC_MODEL='claude-opus-4-20250514'
ANTHROPIC_SMALL_FAST_MODEL='claude-3-5-haiku-20241022'

# Amazon Bedrock (モデルIDを使用)
ANTHROPIC_MODEL='us.anthropic.claude-opus-4-20250514-v1:0'
ANTHROPIC_SMALL_FAST_MODEL='us.anthropic.claude-3-5-haiku-20241022-v1:0'

# Amazon Bedrock (推論プロファイルARNを使用)
ANTHROPIC_MODEL='arn:aws:bedrock:us-east-2:your-account-id:application-inference-profile/your-model-id'
ANTHROPIC_SMALL_FAST_MODEL='arn:aws:bedrock:us-east-2:your-account-id:application-inference-profile/your-small-model-id'

# Google Vertex AI
ANTHROPIC_MODEL='claude-3-7-sonnet@20250219'
ANTHROPIC_SMALL_FAST_MODEL='claude-3-5-haiku@20241022'
```

グローバル設定を使用してこれらの変数を設定することもできます：

```bash
# Anthropic API用に設定
claude config set --global env '{"ANTHROPIC_MODEL": "claude-opus-4-20250514"}'

# Bedrock用に設定 (モデルIDを使用)
claude config set --global env '{"CLAUDE_CODE_USE_BEDROCK": "true", "ANTHROPIC_MODEL": "us.anthropic.claude-opus-4-20250514-v1:0"}'

# Bedrock用に設定 (推論プロファイルARNを使用)
claude config set --global env '{"CLAUDE_CODE_USE_BEDROCK": "true", "ANTHROPIC_MODEL": "arn:aws:bedrock:us-east-2:your-account-id:application-inference-profile/your-model-id"}'

# Vertex AI用に設定
claude config set --global env '{"CLAUDE_CODE_USE_VERTEX": "true", "ANTHROPIC_MODEL": "claude-3-7-sonnet@20250219"}'
```

<Note>
  異なるプロバイダー間で利用可能なすべてのモデルについては、[モデル名
  リファレンス](/ja/docs/about-claude/models/all-models#model-names)をご覧ください。
</Note>

## サードパーティAPIとの使用

<Note>
  Claude Codeは、使用するAPIプロバイダーに関係なく、Claude Sonnet 3.7とClaude Haiku 3.5の
  両方のモデルへのアクセスが必要です。
</Note>

### Amazon Bedrockへの接続

```bash
CLAUDE_CODE_USE_BEDROCK=1
```

プロンプトキャッシングを有効にしていない場合は、以下も設定してください：

```bash
DISABLE_PROMPT_CACHING=1
```

コスト削減と高いレート制限のためのプロンプトキャッシングについては、Amazon Bedrockにお問い合わせください。

標準のAWS SDK認証情報（例：`~/.aws/credentials`または`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`などの関連環境変数）が必要です。AWS認証情報を設定するには、次のコマンドを実行します：

```bash
aws configure
```

プロキシを通じてClaude Codeにアクセスしたい場合は、`ANTHROPIC_BEDROCK_BASE_URL`環境変数を使用できます：

```bash
ANTHROPIC_BEDROCK_BASE_URL='https://your-proxy-url'
```

プロキシが独自のAWS認証情報を維持している場合は、`CLAUDE_CODE_SKIP_BEDROCK_AUTH`環境変数を使用して、Claude CodeのAWS認証情報要件を削除できます。

```bash
CLAUDE_CODE_SKIP_BEDROCK_AUTH=1
```

<Note>
  ユーザーはAWSアカウントでClaude Sonnet 3.7とClaude Haiku 3.5の両方のモデルにアクセスする必要があります。
  モデルアクセスロールがある場合、これらのモデルがまだ利用できない場合は、アクセスをリクエストする必要があるかもしれません。
  推論プロファイルはクロスリージョン機能を必要とするため、各リージョンでのBedrockへのアクセスが必要です。
</Note>

### Google Vertex AIへの接続

```bash
CLAUDE_CODE_USE_VERTEX=1
CLOUD_ML_REGION=us-east5
ANTHROPIC_VERTEX_PROJECT_ID=your-project-id
```

プロンプトキャッシングを有効にしていない場合は、以下も設定してください：

```bash
DISABLE_PROMPT_CACHING=1
```

<Note>
  Vertex AI上のClaude Codeは現在、`us-east5`リージョンのみをサポートしています。
  プロジェクトにこの特定のリージョンで割り当てられたクォータがあることを確認してください。
</Note>

<Note>
  ユーザーはVertex AIプロジェクトでClaude Sonnet 3.7とClaude Haiku 3.5の
  両方のモデルにアクセスする必要があります。
</Note>

google-auth-libraryを通じて設定された標準のGCP認証情報が必要です。GCP認証情報を設定するには、次のコマンドを実行します：

```bash
gcloud auth application-default login
```

プロキシを通じてClaude Codeにアクセスしたい場合は、`ANTHROPIC_VERTEX_BASE_URL`環境変数を使用できます：

```bash
ANTHROPIC_VERTEX_BASE_URL='https://your-proxy-url'
```

プロキシが独自のGCP認証情報を維持している場合は、`CLAUDE_CODE_SKIP_VERTEX_AUTH`環境変数を使用して、Claude CodeのGCP認証情報要件を削除できます。

```bash
CLAUDE_CODE_SKIP_VERTEX_AUTH=1
```

最良の体験を得るには、レート制限の引き上げについてGoogleにお問い合わせください。

## プロキシを通じた接続

Claude CodeをLLMプロキシで使用する場合、以下の環境変数と設定を使用して認証動作を制御できます。これらの設定はBedrockおよびVertex固有の設定と組み合わせることができます。

### 設定

Claude CodeはBedrockおよびVertexでの使用を設定するために、環境変数によって制御される多くの設定をサポートしています。完全なリファレンスについては、[環境変数](/ja/docs/claude-code/settings#environment-variables)をご覧ください。

環境変数ではなくファイルで設定したい場合は、[Claude Code設定](/ja/docs/claude-code/settings#available-settings)ファイルの`env`オブジェクトにこれらの設定を追加できます。

また、`apiKeyHelper`設定を構成して、APIキーを取得するためのカスタムシェルスクリプトを設定することもできます（起動時に一度呼び出され、各セッションの期間中、または`CLAUDE_CODE_API_KEY_HELPER_TTL_MS`が経過するまでキャッシュされます）。

### LiteLLM

<Note>
  LiteLLMはサードパーティのプロキシサービスです。Anthropicは、LiteLLMのセキュリティや機能を
  推奨、維持、または監査していません。このガイドは情報提供のみを目的としており、
  古くなる可能性があります。自己責任で使用してください。
</Note>

このセクションでは、使用状況と支出の追跡、一元化された認証、ユーザーごとの予算設定などを提供するサードパーティのLLMプロキシであるLiteLLM Proxy ServerでのClaude Codeの設定について説明します。

#### ステップ1：前提条件

* 最新バージョンに更新されたClaude Code
* 実行中でClaude Codeからネットワークアクセス可能なLiteLLM Proxy Server
* LiteLLMプロキシキー

#### ステップ2：プロキシ認証の設定

以下の認証方法のいずれかを選択してください：

**オプションA：静的プロキシキー**
プロキシキーを環境変数として設定します：

```bash
ANTHROPIC_AUTH_TOKEN=your-proxy-key
```

**オプションB：動的プロキシキー**
組織がローテーションキーまたは動的認証を使用している場合：

1. `ANTHROPIC_AUTH_TOKEN`環境変数を設定しないでください
2. 認証トークンを提供するキーヘルパースクリプトを作成します
3. Claude Code設定の`apiKeyHelper`設定の下にスクリプトを登録します
4. 自動更新を有効にするためにトークンの有効期間を設定します：
   ```bash
   CLAUDE_CODE_API_KEY_HELPER_TTL_MS=3600000
   ```
   これを`apiKeyHelper`から返されるトークンの有効期間（ミリ秒単位）に設定します。

#### ステップ3：デプロイメントの設定

LiteLLMを通じて使用したいClaudeデプロイメントを選択します：

* **Anthropic API**：Anthropic APIへの直接接続
* **Bedrock**：Claudeモデルを搭載したAmazon Bedrock
* **Vertex AI**：Claudeモデルを搭載したGoogle Cloud Vertex AI

##### オプションA：LiteLLMを通じたAnthropic API

1. LiteLLMエンドポイントを設定します：
   ```bash
   ANTHROPIC_BASE_URL=https://litellm-url:4000/anthropic
   ```

##### オプションB：LiteLLMを通じたBedrock

1. Bedrock設定を構成します：
   ```bash
   ANTHROPIC_BEDROCK_BASE_URL=https://litellm-url:4000/bedrock
   CLAUDE_CODE_SKIP_BEDROCK_AUTH=1
   CLAUDE_CODE_USE_BEDROCK=1
   ```

##### オプションC：LiteLLMを通じたVertex AI

**推奨：プロキシ指定の認証情報**

1. Vertex設定を構成します：
   ```bash
   ANTHROPIC_VERTEX_BASE_URL=https://litellm-url:4000/vertex_ai/v1
   CLAUDE_CODE_SKIP_VERTEX_AUTH=1
   CLAUDE_CODE_USE_VERTEX=1
   ```

**代替：クライアント指定の認証情報**

ローカルのGCP認証情報を使用したい場合：

1. ローカルでGCPに認証します：

   ```bash
   gcloud auth application-default login
   ```

2. Vertex設定を構成します：

   ```bash
   ANTHROPIC_VERTEX_BASE_URL=https://litellm-url:4000/vertex_ai/v1
   ANTHROPIC_VERTEX_PROJECT_ID=your-gcp-project-id
   CLAUDE_CODE_USE_VERTEX=1
   CLOUD_ML_REGION=your-gcp-region
   ```

3. LiteLLMヘッダー設定を更新します：

   パススルーGCPトークンは`Authorization`ヘッダーに配置されるため、LiteLLM設定の`general_settings.litellm_key_header_name`が`Proxy-Authorization`に設定されていることを確認してください。

#### ステップ4. モデルの選択

デフォルトでは、モデルは[モデル設定](#モデル設定)で指定されたものを使用します。

LiteLLMでカスタムモデル名を設定している場合は、前述の環境変数をそれらのカスタム名に設定してください。

詳細については、[LiteLLMドキュメント](https://docs.litellm.ai/)を参照してください。
