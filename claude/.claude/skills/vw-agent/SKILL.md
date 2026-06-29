---
name: vw-agent
description: Gmail / Google Calendar MCP を駆使する秘書エージェントのセットアップ（init）と呼び出し。claude を起動したディレクトリ（cwd）がそのまま秘書プロジェクトになる。秘書ごとに Google アカウント・MCP 認証（.mcp.json + ~/.google-mcp/<name>/）・人格（SOUL/USER/MEMORY）・学習 wiki（vw-wiki）が分離される。ロジックの正規ソースは各プロジェクトの CLAUDE.md に自包。Use when the user says 「秘書を作って」「秘書をセットアップ」「vw-agent init」「/vw-agent」、または秘書プロジェクト内で「メール確認」「予定入れて」「/downloads」「学んで」「lint」等。NOT for 汎用ナレッジベース構築（vw-wiki 参照）、NOT for claude.ai コネクタでの単発 Gmail/Calendar 操作（プロジェクト分離が不要なら直接 MCP ツールを使う）。
argument-hint: "[init <name> | <秘書への指示>]"
---

# vw-agent — Gmail/Calendar MCP 秘書エージェント

## Core Purpose

claude を起動したディレクトリ（cwd）を秘書ごとの独立プロジェクトとして初期化し、Gmail / Google Calendar の
ローカル MCP・人格ファイル（SOUL/USER/MEMORY）・学習 wiki（vw-wiki）をアカウント単位で分離して運用する。
**ロジックの正規ソースはこの SKILL ではなく、各プロジェクトに生成される `CLAUDE.md`（秘書ルールブック）**。
この SKILL はブートストラップ（init）と、ルールブックへの確実な誘導だけを担う。

## Quick Checklist (初期応答で必ず確認)

- [ ] cwd は秘書プロジェクトか（`SOUL.md` と `.mcp.json` が同時に存在するか）
- [ ] 秘書プロジェクト外で init 以外の秘書依頼を受けた →
      対象の秘書プロジェクトの場所を確認し `cd <秘書プロジェクト> && claude` を案内して**停止**
      （プロジェクト直下の `.mcp.json` はそのディレクトリで Claude Code を起動した時のみ有効なため）
- [ ] ユーザーの意図はどちらか（init / 秘書実行）

## Basic Workflow

### Step I: init（新しい秘書のセットアップ — cwd が秘書プロジェクトになる）

1. cwd を確認する。`CLAUDE.md` `SOUL.md` `.mcp.json` のいずれかが既に存在する場合は、
   秘書専用の空ディレクトリで claude を起動し直すよう案内して**停止**（上書き init しない）。
2. AskUserQuestion で 1 回にまとめて確認する:
   秘書名（kebab-case、例 `hermes`。`~/.google-mcp/<name>/` の認証分離キーになる）/
   繋ぎ先 Google アカウント（Gmail アドレス）/
   秘書の役割・人格の一言 / ユーザーの呼び名とタイムゾーン。
3. ディレクトリを作成する: `mkdir -p downloads ~/.google-mcp/<name>`
   （`~/.google-mcp` はサンドボックス書込許可外のため許可プロンプトが出る。恒久許可は追加しない）。
4. [persona-templates.md](./references/persona-templates.md) から `SOUL.md` / `USER.md` / `MEMORY.md` を
   cwd に生成する。**テンプレの改変は変数置換のみ**
   （`{agent-name}` `{user-name}` `{google-account}` `{persona}` `{date}` `{timezone}`）。
5. [project-claude-template.md](./references/project-claude-template.md) から `CLAUDE.md` を生成する。
6. [mcp-setup.md](./references/mcp-setup.md) から `.mcp.json` / `.gitignore` / `SETUP-OAUTH.md` を生成する。
7. Gmail MCP サーバー準備（初回のみ・全秘書共有）:
   `~/.google-mcp/servers/Gmail-MCP-Server/dist/index.js` が無ければ mcp-setup.md の手順で clone + build。
8. Skill ツールで `vw-wiki` を init 起動する（対象 = cwd、トピック「<name> 秘書業務知識」）。
   wiki/ + raw/ が生成され、CLAUDE.md には同一文言セクションが既にあるため二重追記されない。
   秘書プロジェクトは **git 管理しない**（`git init` しない。.gitkeep も不要）。
   生成する .gitignore は将来ユーザーが自分で git 管理を始めた場合の事故防止の保険。
9. 生成結果をツリーで報告し、次を案内する:
   「SETUP-OAUTH.md に従って OAuth を設定 → このディレクトリで claude を**再起動**
   （.mcp.json を読み込むため）→ 初回起動時に .mcp.json の承認 →
   `/mcp` で gmail / google-calendar の接続を確認」。

### Step O: 秘書実行（プロジェクト内での依頼すべて）

1. **プロジェクトの `CLAUDE.md` `SOUL.md` `USER.md` `MEMORY.md` を全文読む**。
   この SKILL の記憶ではなく、必ず実ファイルを読む（秘書ごとにルールが育っているため）。
2. CLAUDE.md のキーワード表と手順（§1〜§8）に厳密に従う。SOUL.md の安全ルール S1〜S5 が最優先。
3. CLAUDE.md とこの SKILL が矛盾したら **CLAUDE.md を優先**する。

## 設計原則（この SKILL を編集するときの制約）

- ロジックを SKILL.md に書かない。ルール追加は project-claude-template.md（新規秘書向け）か、
  各プロジェクトの CLAUDE.md（既存秘書向け）に行う。
- 安全ルール（承認ゲート）は SOUL.md に集約し「CLAUDE.md より優先」を崩さない
  （学習ループが CLAUDE.md を書き換えても安全ルールが浸食されないため）。
- 生成される CLAUDE.md は 150 行以内、SOUL.md は 60 行以内を維持する（Sonnet の遵守率確保のため）。
- 認証情報（credentials / token）は `~/.google-mcp/<name>/` の外に置かない。
  dotfiles・プロジェクトに入ってよいのはパス文字列だけ。

## Rollback / Recovery

- 秘書が不要になった: 秘書プロジェクトのディレクトリを `trash` + `trash ~/.google-mcp/<name>`
  （認証情報も一緒に破棄。Google 側の OAuth クライアントは GCP Console から手動削除）。
- init が途中で失敗した: 生成済みファイルを `trash` してから init をやり直す（上書き再実行はしない）。
- OAuth の再認証が必要（token 失効等）: プロジェクトの `SETUP-OAUTH.md`（削除済みなら
  [mcp-setup.md](./references/mcp-setup.md)）の認証コマンドを再実行する。
- SKILL 自体の破損: dotfiles リポジトリで `jj restore claude/.claude/skills/vw-agent/`。

## Advanced References

- [persona-templates.md](./references/persona-templates.md) — SOUL / USER / MEMORY テンプレート
- [project-claude-template.md](./references/project-claude-template.md) — 秘書ルールブック（正規ソース）のテンプレート
- [mcp-setup.md](./references/mcp-setup.md) — .mcp.json / .gitignore / SETUP-OAUTH.md テンプレートと Gmail MCP の clone/build 手順
