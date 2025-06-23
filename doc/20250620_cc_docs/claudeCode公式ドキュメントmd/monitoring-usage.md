---
created: 2025-06-06T10:29
updated: 2025-06-12T18:40
---
# 使用状況のモニタリング

> OpenTelemetryメトリクスを使用してClaude Codeの使用状況をモニタリングする

<Note>
  OpenTelemetryのサポートは現在ベータ版であり、詳細は変更される可能性があります。
</Note>

# Claude CodeにおけるOpenTelemetry

Claude CodeはモニタリングとオブザーバビリティのためにOpenTelemetry（OTel）メトリクスをサポートしています。このドキュメントでは、Claude CodeでOTelを有効化して設定する方法を説明します。

すべてのメトリクスは、OpenTelemetryの標準メトリクスプロトコルを介してエクスポートされる時系列データです。メトリクスバックエンドが適切に構成されていること、および集計の粒度がモニタリング要件を満たしていることを確認するのはユーザーの責任です。

## クイックスタート

環境変数を使用してOpenTelemetryを設定します：

```bash
# 1. テレメトリを有効にする
export CLAUDE_CODE_ENABLE_TELEMETRY=1

# 2. エクスポーターを選択する
export OTEL_METRICS_EXPORTER=otlp       # オプション: otlp, prometheus, console

# 3. OTLPエンドポイントを設定する（OTLPエクスポーター用）
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# 4. 認証を設定する（必要な場合）
export OTEL_EXPORTER_OTLP_HEADERS="Authorization=Bearer your-token"

# 5. デバッグ用：エクスポート間隔を短縮する（デフォルト：600000ms/10分）
export OTEL_METRIC_EXPORT_INTERVAL=10000  # 10秒

# 6. Claude Codeを実行する
claude
```

<Note>
  デフォルトのエクスポート間隔は10分です。セットアップ中は、デバッグ目的で短い間隔を使用することをお勧めします。本番環境では元に戻すことを忘れないでください。
</Note>

設定オプションの詳細については、[OpenTelemetry仕様](https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/protocol/exporter.md#configuration-options)を参照してください。

## 管理者設定

管理者は、管理設定ファイルを通じてすべてのユーザーのOpenTelemetry設定を構成できます。これにより、組織全体でテレメトリ設定を一元管理できます。設定の適用方法については、[設定階層](/ja/docs/claude-code/settings#configuration-hierarchy)を参照してください。

管理設定ファイルは以下の場所にあります：

* macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
* Linux: `/etc/claude-code/managed-settings.json`

管理設定の設定例：

```json
{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://collector.company.com:4317",
    "OTEL_EXPORTER_OTLP_HEADERS": "Authorization=Bearer company-token"
  }
}
```

<Note>
  管理設定は、MDM（モバイルデバイス管理）やその他のデバイス管理ソリューションを通じて配布できます。管理設定ファイルで定義された環境変数は優先度が高く、ユーザーによって上書きすることはできません。
</Note>

## 設定の詳細

### 一般的な設定変数

| 環境変数                                            | 説明                          | 設定例                                  |
| ----------------------------------------------- | --------------------------- | ------------------------------------ |
| `CLAUDE_CODE_ENABLE_TELEMETRY`                  | テレメトリ収集を有効にする（必須）           | `1`                                  |
| `OTEL_METRICS_EXPORTER`                         | 使用するエクスポーターの種類（カンマ区切り）      | `console`, `otlp`, `prometheus`      |
| `OTEL_EXPORTER_OTLP_PROTOCOL`                   | OTLPエクスポーターのプロトコル           | `grpc`, `http/json`, `http/protobuf` |
| `OTEL_EXPORTER_OTLP_ENDPOINT`                   | OTLPコレクターのエンドポイント           | `http://localhost:4317`              |
| `OTEL_EXPORTER_OTLP_HEADERS`                    | OTLP用の認証ヘッダー                | `Authorization=Bearer token`         |
| `OTEL_EXPORTER_OTLP_METRICS_CLIENT_KEY`         | mTLS認証用のクライアントキー            | クライアントキーファイルへのパス                     |
| `OTEL_EXPORTER_OTLP_METRICS_CLIENT_CERTIFICATE` | mTLS認証用のクライアント証明書           | クライアント証明書ファイルへのパス                    |
| `OTEL_METRIC_EXPORT_INTERVAL`                   | エクスポート間隔（ミリ秒単位、デフォルト：10000） | `5000`, `60000`                      |

### メトリクスのカーディナリティ制御

以下の環境変数は、カーディナリティを管理するためにメトリクスに含まれる属性を制御します：

| 環境変数                                | 説明                             | デフォルト値  | 無効化例    |
| ----------------------------------- | ------------------------------ | ------- | ------- |
| `OTEL_METRICS_INCLUDE_SESSION_ID`   | メトリクスにsession.id属性を含める         | `true`  | `false` |
| `OTEL_METRICS_INCLUDE_VERSION`      | メトリクスにapp.version属性を含める        | `false` | `true`  |
| `OTEL_METRICS_INCLUDE_ACCOUNT_UUID` | メトリクスにuser.account\_uuid属性を含める | `true`  | `false` |

これらの変数は、メトリクスのカーディナリティを制御するのに役立ち、メトリクスバックエンドのストレージ要件とクエリパフォーマンスに影響します。カーディナリティが低いほど、一般的にパフォーマンスが向上し、ストレージコストが低くなりますが、分析用のデータの粒度は低くなります。

### 設定例

```bash
# コンソールデバッグ（1秒間隔）
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=console
export OTEL_METRIC_EXPORT_INTERVAL=1000

# OTLP/gRPC
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# Prometheus
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=prometheus

# 複数のエクスポーター
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=console,otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/json
```

## 利用可能なメトリクス

Claude Codeは以下のメトリクスをエクスポートします：

| メトリクス名                            | 説明                   | 単位     |
| --------------------------------- | -------------------- | ------ |
| `claude_code.session.count`       | 開始されたCLIセッションの数      | count  |
| `claude_code.lines_of_code.count` | 変更されたコード行数           | count  |
| `claude_code.pull_request.count`  | 作成されたプルリクエストの数       | count  |
| `claude_code.commit.count`        | 作成されたgitコミットの数       | count  |
| `claude_code.cost.usage`          | Claude Codeセッションのコスト | USD    |
| `claude_code.token.usage`         | 使用されたトークン数           | tokens |

### メトリクスの詳細

すべてのメトリクスは以下の標準属性を共有します：

* `session.id`：一意のセッション識別子（`OTEL_METRICS_INCLUDE_SESSION_ID`で制御）
* `app.version`：現在のClaude Codeバージョン（`OTEL_METRICS_INCLUDE_VERSION`で制御）
* `organization.id`：組織UUID（認証時）
* `user.account_uuid`：アカウントUUID（認証時、`OTEL_METRICS_INCLUDE_ACCOUNT_UUID`で制御）

#### 1. セッションカウンター

各セッションの開始時に発行されます。

#### 2. コード行数カウンター

コードが追加または削除されたときに発行されます。

* 追加属性：`type`（`"added"`または`"removed"`）

#### 3. プルリクエストカウンター

Claude Codeを介してプルリクエストを作成するときに発行されます。

#### 4. コミットカウンター

Claude Codeを介してgitコミットを作成するときに発行されます。

#### 5. コストカウンター

各APIリクエスト後に発行されます。

* 追加属性：`model`

#### 6. トークンカウンター

各APIリクエスト後に発行されます。

* 追加属性：`type`（`"input"`, `"output"`, `"cacheRead"`, `"cacheCreation"`）と`model`

## メトリクスデータの解釈

これらのメトリクスは、使用パターン、生産性、コストに関する洞察を提供します：

### 使用状況のモニタリング

| メトリクス                                                         | 分析機会                              |
| ------------------------------------------------------------- | --------------------------------- |
| `claude_code.token.usage`                                     | `type`（入力/出力）、ユーザー、チーム、またはモデル別に分類 |
| `claude_code.session.count`                                   | 時間の経過に伴う採用と関与を追跡                  |
| `claude_code.lines_of_code.count`                             | コードの追加/削除を追跡して生産性を測定              |
| `claude_code.commit.count` & `claude_code.pull_request.count` | 開発ワークフローへの影響を理解                   |

### コストモニタリング

`claude_code.cost.usage`メトリクスは以下に役立ちます：

* チームや個人間の使用傾向の追跡
* 最適化のための高使用セッションの特定

<Note>
  コストメトリクスは概算です。公式の請求データについては、APIプロバイダー（Anthropic Console、AWS Bedrock、またはGoogle Cloud Vertex）を参照してください。
</Note>

### アラートとセグメンテーション

検討すべき一般的なアラート：

* コストの急増
* 異常なトークン消費
* 特定のユーザーからの高いセッション量

すべてのメトリクスは、`user.account_uuid`、`organization.id`、`session.id`、`model`、および`app.version`でセグメント化できます。

## バックエンドの考慮事項

| バックエンドタイプ                            | 最適な用途             |
| ------------------------------------ | ----------------- |
| 時系列データベース（Prometheus）                | レート計算、集計メトリクス     |
| カラムナーストア（ClickHouse）                 | 複雑なクエリ、ユニークユーザー分析 |
| オブザーバビリティプラットフォーム（Honeycomb、Datadog） | 高度なクエリ、可視化、アラート   |

DAU/WAU/MAUメトリクスには、効率的な一意値クエリをサポートするバックエンドを選択してください。

## サービス情報

すべてのメトリクスは以下とともにエクスポートされます：

* サービス名：`claude-code`
* サービスバージョン：現在のClaude Codeバージョン
* メーター名：`com.anthropic.claude_code`

## セキュリティの考慮事項

* テレメトリはオプトインであり、明示的な設定が必要です
* APIキーやファイルの内容などの機密情報がメトリクスに含まれることはありません
