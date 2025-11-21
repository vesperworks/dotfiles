# 実装計画 - プロジェクト初期化

## 目標
Bun, Vite, React, TypeScript を使用して `vwCleanAnon` Webアプリケーションを初期化します。Mastra は Playground ベースでセットアップします。

## ユーザー確認事項
> [!IMPORTANT]
> プロジェクトを現在のディレクトリ (`~/Works/vwAnnon-antigravity`) で初期化します。
> **変更点**: npm の代わりに **Bun** を使用します。Mastra は **Playground** を有効にしてセットアップします。

## 技術的決定: ワークフロー実行戦略
以下のAPI詳細を確認しました:
- **ポート**: 4112 (このプロジェクト用Mastraサーバー)
- **ワークフローID**: `vwCleanAnonWorkflow` (`mastra.config.ts`のキーと一致)
- **実行フロー**:
    1. `POST /api/workflows/vwCleanAnonWorkflow/create-run` -> `{ runId: "..." }` を返す
    2. `POST /api/workflows/vwCleanAnonWorkflow/start?runId=...` ボディ: `{ inputData: { ... } }`
- **ステータス監視**:
    - 現在、`GET /runs/{runId}` は 404 を返し、デフォルトでは実行が永続化されないことを示しています。
    - そのため、`watch` エンドポイント (`GET /api/workflows/vwCleanAnonWorkflow/watch?runId=...`) を使用して結果をストリーミングします。

このパターンは、廃止された `/execute` エンドポイントを置き換えます。

### プロジェクト構造
- 現在のディレクトリで Bun + Vite プロジェクトを初期化します。
- Tailwind CSS を設定します。
- ディレクトリ構造を作成します:
    - `src/components`
    - `src/hooks`
    - `src/utils`
    - `src/types`
    - `src/mastra`

### 依存関係
- `bun` (パッケージマネージャー)
- `vite`
- `react`, `react-dom`
- `typescript`
- `tailwindcss`, `postcss`, `autoprefixer`
- `@mastra/core` (および関連する Mastra パッケージ)
- `zod`
- `lucide-react` (アイコン用)
- `clsx`, `tailwind-merge` (スタイリングユーティリティ)

## 検証計画

### 自動テスト
- `npm run dev` を実行し、開発サーバーが起動することを確認します。
- Tailwind のスタイルが適用されているか確認します。

### 手動検証
- ディレクトリ構造が計画通りであることを確認します。

## CLI Script Implementation (Completed)

### CLI Script `scripts/run-workflow.ts`
- [x] Implemented file reading and API interaction
- [x] Implemented robust JSON stream parsing (handling space-separated and double-encoded JSON)
- [x] Added support for custom rules and output options
- [x] Verified functionality with sample file and rules
- [x] Confirmed `result.json` generation

## Verification Plan (Completed)

### Automated Tests
- [x] CLI script execution: `bun run scripts/run-workflow.ts --file sample.txt --rules rules.json --output result.json` -> **Success**
- [x] Result validation: `result.json` contains valid `processedFiles` and `anonymizedFiles`.

### Manual Verification
- [x] Frontend UI loading check -> **Success**
- [x] API endpoint verification via curl -> **Success**

