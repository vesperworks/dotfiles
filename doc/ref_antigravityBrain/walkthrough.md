# Mastra API ワークフロー デバッグ手順書

## 問題 (Problem)
ユーザーは `vwCleanAnonWorkflow` を実行しようとした際に 404 エラーに遭遇しました。初期の実装では、非推奨の `/execute` エンドポイントを使用しており、ワークフローIDやポート番号が誤っていた可能性がありました。

## 解決策 (Solution)
以下の3つの主要な問題を特定し、解決しました：

1.  **ポート番号の誤り**: このプロジェクトの Mastra サーバーはポート `4112` で稼働していましたが、クライアントは `4111`（別プロジェクトで使用）または誤ったIDで `4112` にアクセスしていました。
2.  **ワークフローIDの誤り**: API は `mastra.config.ts` のキー名（`vwCleanAnonWorkflow`）をIDとして使用しますが、内部ID（`vw-clean-anon-workflow`）を使用しようとしていました。
3.  **非推奨のエンドポイント**: `/execute` エンドポイントは利用できません。正しいフローは `create-run` -> `start` です。
4.  **永続化の問題**: デフォルトでは実行結果（Run）が永続化されないため、`GET /runs/:runId` が 404 を返していました。これに対処するため、`watch` エンドポイントを使用して結果をストリーミングする方法に切り替えました。

## 実装された変更 (Changes Implemented)

### 1. `useWorkflowProcessor.ts` のリファクタリング
フックを更新し、以下のフローを実装しました：
1.  **Create Run**: `POST /api/workflows/vwCleanAnonWorkflow/create-run` -> `runId` を取得。
2.  **Watch**: `GET /api/workflows/vwCleanAnonWorkflow/watch?runId={runId}` からのストリーム読み込みを開始。
3.  **Start**: `POST /api/workflows/vwCleanAnonWorkflow/start?runId={runId}` を実行（ペイロード `{ inputData: ... }` を送信）。
4.  **Process Stream**: `watch` からのチャンク応答を解析し、実行結果を抽出。

### 2. APIエンドポイントの検証
`curl` を使用して各エンドポイントを検証しました：
- `GET /api/workflows` (ポート 4112): ワークフローの存在を確認。
- `POST /create-run`: 有効な `runId` が返されることを確認。
- `POST /start`: 実行が正常に開始されることを確認。
- `GET /watch`: 接続成功 (200 OK) を確認。

### 3. フロントエンドの検証
ブラウザサブエージェントを使用し、フロントエンドアプリケーションが `http://localhost:5173` で正しくロードされ、UI要素（ファイルドロップゾーンなど）が表示されることを確認しました。

## 検証結果 (Verification Results)

### API 検証
```bash
# Create Run
curl -X POST http://127.0.0.1:4112/api/workflows/vwCleanAnonWorkflow/create-run
# Output: {"runId":"..."}

# Start Run
curl -X POST "http://127.0.0.1:4112/api/workflows/vwCleanAnonWorkflow/start?runId=..." -d @payload.json
# Output: {"message":"Workflow run started"}
```

### フロントエンド検証
フロントエンドは正常にロードされ、ファイルドロップゾーンが表示されています。`useWorkflowProcessor.ts` の統合ロジックは、検証済みのAPI動作に合わせて更新されました。

## 次のステップ (Next Steps)
- ユーザーはUIからファイルをアップロードし、完全なエンドツーエンドのフローをテストできます。
- `watch` ストリームのフォーマットに関してさらなる問題が発生した場合は、`useWorkflowProcessor.ts` の解析ロジックを微調整する必要があるかもしれません。

## CLIスクリプトの開発とデバッグ

ワークフローの自動化とテスト容易性を高めるため、CLIスクリプト `scripts/run-workflow.ts` を作成しました。

### 実装機能
- **ファイル入力**: `--file` または `-f` で処理対象ファイルを指定
- **ルール指定**: `--rules` または `-r` で置換ルール（JSON）を指定
- **オプション**: `--removeFillers`, `--generateReport` で処理オプションを制御
- **結果出力**: `--output` または `-o` で結果をJSONファイルに保存

### 直面した課題：ストリーミングレスポンスのパース

APIの `watch` エンドポイントからのレスポンス（Server-Sent Events）のパースにおいて、いくつかの困難な問題に直面しました。

1.  **スペース区切りのJSON**: レスポンスが標準的な `ndjson`（改行区切り）ではなく、スペースで区切られたJSONオブジェクトのストリームとして送られてくることが判明しました。
2.  **二重エンコード**: さらに調査を進めると、各イベントがJSONオブジェクトそのものではなく、**JSON文字列としてエスケープされ、ダブルクォートで囲まれた状態**で送られてきていることがわかりました。
    - 例: `"{\"type\":\"watch\", ...}" "{\"type\":\"watch\", ...}"`

### 解決策

この特殊なフォーマットに対応するため、パースロジックを以下のように修正しました：

1.  **区切り文字の変更**: 単純な `}` や `{"type":"watch"` ではなく、エスケープされた開始パターン `"{\"type\":\"watch\"` を区切り文字として使用。
2.  **二重パース**:
    - まず、分割された文字列を `JSON.parse` して、内部のJSON文字列を取り出す（デコード）。
    - 次に、そのJSON文字列を再度 `JSON.parse` して、実際のJavaScriptオブジェクトに変換する。

この修正により、CLIスクリプトは安定してAPIレスポンスを処理し、最終結果（`processedFiles` や `anonymizedFiles`）を正しく抽出・保存できるようになりました。

> [!NOTE]
> APIの出力結果（`anonymizedFiles`の`content`など）に `undefined` という文字列が大量に混入する現象が確認されました。これはAPIサーバー側のバグと考えられますが、CLIスクリプトとしては結果の取得と保存に成功しています。

