# mcp-setup.md — claude.ai コネクタ設定（Gmail / Google Calendar）

vw-agent は Gmail / Google Calendar へのアクセスに **claude.ai コネクタ**
（`claude_ai_Gmail` / `claude_ai_Google_Calendar`）を使う。
ローカル MCP サーバー・GCP OAuth セットアップ・プロジェクト直下の `.mcp.json` は**不要**。

## 前提と制約（設計上の重要事項）

- コネクタは claude.ai アカウントに紐づく **1 つの Google アカウント接続**。
  プロジェクトごとの接続先切替はできない。接続先アカウントは USER.md に記録し、
  操作の承認提示時に必ず併記する（誤アカウント操作防止）。
- 利用可能ツール（2026-07 時点、実接続で確認済み）:
  - Gmail: スレッド検索・取得 / 下書き作成・一覧 / ラベル作成・付与・除去。
    **送信ツールと添付ダウンロードツールはない**
    （送信はユーザーが Gmail 上で行う。添付の取得はブラウザ経由 — CLAUDE.md §5 参照）。
  - Calendar: カレンダー一覧 / イベント一覧・取得・作成・更新・削除 / 出欠応答 / 時間候補提案。
- ヘッドレス実行（cron / 自動化）ではコネクタが使えない場合がある。

## 接続確認手順（init 時と、ツールがエラーを返した時）

1. `/mcp` を実行し、`claude.ai Gmail` と `claude.ai Google Calendar` が接続済みか確認する。
2. 一覧にない場合は claude.ai（Web）の「設定 → コネクタ」で Gmail / Google Calendar を接続する。
3. 「requires re-authorization (token expired)」エラーが出る場合は `/mcp` から再認証する
   （Claude Desktop 側で接続済みでも、Claude Code 側のトークンは別管理で失効することがある）。
4. 動作確認: 「今日の予定を教えて」「未読メールを 3 件教えて」の 2 つで疎通を見る。

## .gitignore テンプレート

生成先: `<秘書プロジェクトルート>/.gitignore`

置換変数なし（固定内容）。

---TEMPLATE START---
```gitignore
downloads/
.claude/
```
---TEMPLATE END---
