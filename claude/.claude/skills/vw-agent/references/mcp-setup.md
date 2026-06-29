# mcp-setup.md — vw-agent MCP セットアップテンプレート集

このファイルは vw-agent init 専用の MCP（Gmail / Google Calendar）セットアップテンプレート集。生成時は変数置換のみ行い、テンプレート本文の改変・追記は禁止。

## 検証済み情報（2026-07-02）

| 項目 | 検証結果 | 出所 |
|------|---------|------|
| Gmail MCP env: `GMAIL_OAUTH_PATH` | サポートされている（`process.env.GMAIL_OAUTH_PATH \|\| path.join(CONFIG_DIR, 'gcp-oauth.keys.json')`） | `ArtyMcLabin/Gmail-MCP-Server` main branch `src/index.ts` |
| Gmail MCP env: `GMAIL_CREDENTIALS_PATH` | サポートされている（`process.env.GMAIL_CREDENTIALS_PATH \|\| path.join(CONFIG_DIR, 'credentials.json')`） | 同上 |
| Gmail MCP デフォルトパス | `~/.gmail-mcp/`（`CONFIG_DIR = path.join(os.homedir(), '.gmail-mcp')`） | 同上 |
| Gmail MCP auth コマンド | `node dist/index.js auth`（スコープ指定は `--scopes=...`） | 同上 README + ソース `process.argv[2] === 'auth'` |
| Gmail MCP ビルド | `npm install && npm run build`（`"build": "tsc"`）。Node `>=14.0.0` | `package.json`（`name: "@gongrzhe/server-gmail-autoauth-mcp"`, `main/bin: dist/index.js`） |
| Gmail MCP フォーク状況 | `ArtyMcLabin/Gmail-MCP-Server` は `GongRzhe/Gmail-MCP-Server` のアクティブフォーク（本家は 8月以降メンテナンス停止と明記） | GitHub リポジトリ README |
| `download_attachment` 引数 | `messageId`（必須）, `attachmentId`（必須）, `savePath`（任意）, `filename`（任意） | ソース `DownloadAttachmentSchema` |
| Calendar MCP パッケージ名 | `@cocal/google-calendar-mcp`（`nspady/google-calendar-mcp`） | README |
| Calendar MCP env: `GOOGLE_OAUTH_CREDENTIALS` | サポートされている（OAuth認証情報ファイルパス） | README + `docs/authentication.md` |
| Calendar MCP env: `GOOGLE_CALENDAR_MCP_TOKEN_PATH` | サポートされている（トークン保存先カスタマイズ、任意） | `docs/authentication.md`（`export GOOGLE_CALENDAR_MCP_TOKEN_PATH=/custom/path`） |
| Calendar MCP auth コマンド | `npx @cocal/google-calendar-mcp auth`（ローカルインストール時は `npm run auth`） | 同上 |
| Google Cloud OAuth クライアント種別 | 「Desktop app」（Web application ではない） | `docs/authentication.md` |
| OAuth 同意画面テストユーザー | 追加必須。反映まで 2〜3 分待つ旨の記載あり | 同上 |

**要確認（未検証・推測を含む）**:
- `.mcp.json` の gmail サーバー `command` は本家 README のサンプルでは `npx` + 絶対パス直指定という組み合わせで記載されているが、これは `node` の誤記の可能性が高い。本テンプレートでは検証済みの `node dist/index.js auth` の実行系に合わせて `command: "node"` を採用する。
- Calendar API の有効化（APIs & Services → Library → Google Calendar API → Enable）はドキュメントに明記されているため手順に含めた。Gmail API 側の有効化手順は Gmail-MCP-Server 側 README に明記されていないため、Google Cloud Console の一般的な手順（APIs & Services → Library → Gmail API → Enable）として記載している。

---

## 1. .mcp.json テンプレート

生成先: `<秘書プロジェクトルート>/.mcp.json`（秘書プロジェクトルート = init を実行した claude の起動ディレクトリ）

置換変数は `{agent-name}` のみ。`${HOME}` は Claude Code の `.mcp.json` 環境変数展開機能でそのまま残す。

---TEMPLATE START---
```json
{
  "mcpServers": {
    "gmail": {
      "command": "node",
      "args": ["${HOME}/.google-mcp/servers/Gmail-MCP-Server/dist/index.js"],
      "env": {
        "GMAIL_OAUTH_PATH": "${HOME}/.google-mcp/{agent-name}/gcp-oauth.keys.json",
        "GMAIL_CREDENTIALS_PATH": "${HOME}/.google-mcp/{agent-name}/gmail-credentials.json"
      }
    },
    "google-calendar": {
      "command": "npx",
      "args": ["-y", "@cocal/google-calendar-mcp"],
      "env": {
        "GOOGLE_OAUTH_CREDENTIALS": "${HOME}/.google-mcp/{agent-name}/gcp-oauth.keys.json",
        "GOOGLE_CALENDAR_MCP_TOKEN_PATH": "${HOME}/.google-mcp/{agent-name}/calendar-tokens.json"
      }
    }
  }
}
```
---TEMPLATE END---

---

## 2. .gitignore テンプレート

生成先: `<秘書プロジェクトルート>/.gitignore`

置換変数なし（固定内容）。

---TEMPLATE START---
```gitignore
downloads/
*.keys.json
*credentials*.json
*tokens*.json
.claude/
```
---TEMPLATE END---

---

## 3. Gmail MCP サーバー clone/build 手順（初回のみ・全秘書共有）

生成先: なし（セットアップ時にコマンドとして実行する手順）。`~/.google-mcp/servers/Gmail-MCP-Server/dist/index.js` は複数秘書プロジェクトで共有するため、agent-name に依存しない。

判定: `~/.google-mcp/servers/Gmail-MCP-Server/dist/index.js` が既に存在すればビルド済みなのでスキップしてよい。

---TEMPLATE START---
```bash
test -f "$HOME/.google-mcp/servers/Gmail-MCP-Server/dist/index.js" || {
  git clone https://github.com/ArtyMcLabin/Gmail-MCP-Server "$HOME/.google-mcp/servers/Gmail-MCP-Server"
  cd "$HOME/.google-mcp/servers/Gmail-MCP-Server" && npm install && npm run build
}
```
---TEMPLATE END---

Node.js `>=14.0.0` が必要（`package.json` の `engines.node`）。google-calendar 側は `npx -y @cocal/google-calendar-mcp` が実行時に自動取得するため、事前 clone/build は不要。

---

## 4. SETUP-OAUTH.md テンプレート

生成先: `<秘書プロジェクトルート>/SETUP-OAUTH.md`

置換変数: `{agent-name}` `{google-account}`

---TEMPLATE START---
````markdown
# SETUP-OAUTH — {agent-name} の Google 認証セットアップ

このファイルは初回セットアップ専用の手順書。完了したら削除してよい。

## 1. Google Cloud Console でプロジェクト作成

1. https://console.cloud.google.com/ にアクセス
2. 新しいプロジェクトを作成（プロジェクト名例: `mcp-{agent-name}`）

## 2. API の有効化

「APIs & Services」→「Library」で以下を検索して有効化する:

- Gmail API
- Google Calendar API

## 3. OAuth 同意画面の設定

「APIs & Services」→「OAuth consent screen」:

1. User Type は **External** を選択
2. アプリ名・サポートメールなど必須項目を入力
3. 「Test users」に `{google-account}` を追加
4. 保存後、反映まで 2〜3 分待つ

## 4. OAuth クライアント ID の作成

「APIs & Services」→「Credentials」→「Create Credentials」→「OAuth client ID」:

1. Application type は **Desktop app** を選択（Web application ではない）
2. 作成後、JSON をダウンロード
3. ダウンロードした JSON を以下に配置する:

```bash
mkdir -p "$HOME/.google-mcp/{agent-name}"
mv ~/Downloads/client_secret_*.json "$HOME/.google-mcp/{agent-name}/gcp-oauth.keys.json"
```

## 5. Gmail 初回認証

```bash
export GMAIL_OAUTH_PATH="$HOME/.google-mcp/{agent-name}/gcp-oauth.keys.json"
export GMAIL_CREDENTIALS_PATH="$HOME/.google-mcp/{agent-name}/gmail-credentials.json"
node "$HOME/.google-mcp/servers/Gmail-MCP-Server/dist/index.js" auth
```

ブラウザが開くので `{google-account}` でログインし、権限を許可する。

## 6. Google Calendar 初回認証

```bash
export GOOGLE_OAUTH_CREDENTIALS="$HOME/.google-mcp/{agent-name}/gcp-oauth.keys.json"
export GOOGLE_CALENDAR_MCP_TOKEN_PATH="$HOME/.google-mcp/{agent-name}/calendar-tokens.json"
npx -y @cocal/google-calendar-mcp auth
```

ブラウザが開くので `{google-account}` でログインし、権限を許可する。

## 7. Claude Code での接続確認

このファイル（SETUP-OAUTH.md）のあるディレクトリ＝秘書プロジェクトで claude を起動（または再起動）する:

```bash
claude
```

初回起動時に `.mcp.json` の承認プロンプトが出るので許可する。起動後、以下で接続状態を確認する:

```
/mcp
```

`gmail` と `google-calendar` の両方が接続済みであることを確認する。

## 8. 動作確認

以下のような発話で疎通を確認する:

- 「今日の予定を教えて」（Google Calendar）
- 「未読メールを3件教えて」（Gmail）

両方正常に応答すれば完了。**このファイル（SETUP-OAUTH.md）は削除してよい。**
````
---TEMPLATE END---
