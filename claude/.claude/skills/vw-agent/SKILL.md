---
name: vw-agent
description: Gmail / Google Calendar の claude.ai コネクタを駆使する秘書エージェントのセットアップ（init）と呼び出し。claude を起動したディレクトリ（cwd）がそのまま秘書プロジェクトになる。秘書ごとに人格（SOUL/USER/MEMORY）・ルールブック（CLAUDE.md）・学習 wiki（vw-wiki）が分離される。ロジックの正規ソースは各プロジェクトの CLAUDE.md に自包。Use when the user says 「秘書を作って」「秘書をセットアップ」「vw-agent init」「/vw-agent」、または秘書プロジェクト内で「メール確認」「予定入れて」「/downloads」「学んで」「lint」等。NOT for 汎用ナレッジベース構築（vw-wiki 参照）、NOT for 秘書プロジェクト外での単発 Gmail/Calendar 操作（コネクタツールを直接使えば足りる）。
argument-hint: "[init <name> | <秘書への指示>]"
---

# vw-agent — Gmail/Calendar 秘書エージェント

## Core Purpose

claude を起動したディレクトリ（cwd）を秘書ごとの独立プロジェクトとして初期化し、Gmail /
Google Calendar の claude.ai コネクタ・人格ファイル（SOUL/USER/MEMORY）・学習 wiki（vw-wiki）で
秘書業務を運用する。
**ロジックの正規ソースはこの SKILL ではなく、各プロジェクトに生成される `CLAUDE.md`（秘書ルールブック）**。
この SKILL はブートストラップ（init）と、ルールブックへの確実な誘導だけを担う。

## Quick Checklist (初期応答で必ず確認)

- [ ] cwd は秘書プロジェクトか（`SOUL.md` と `CLAUDE.md` が同時に存在するか）
- [ ] 秘書プロジェクト外で init 以外の秘書依頼を受けた →
      対象の秘書プロジェクトの場所を確認し `cd <秘書プロジェクト> && claude` を案内して**停止**
      （人格・ルール・学習 wiki はそのディレクトリにあるため）
- [ ] ユーザーの意図はどちらか（init / 秘書実行）

## Basic Workflow

### Step I: init（新しい秘書のセットアップ — cwd が秘書プロジェクトになる）

1. cwd を確認する。`CLAUDE.md` `SOUL.md` のいずれかが既に存在する場合は、
   秘書専用の空ディレクトリで claude を起動し直すよう案内して**停止**（上書き init しない）。
2. AskUserQuestion で 1 回にまとめて確認する:
   秘書名（kebab-case、例 `hermes`）/
   このプロジェクトで扱う Google アカウント（claude.ai コネクタの接続先。誤操作防止の記録用）/
   秘書の役割・人格の一言 / ユーザーの呼び名とタイムゾーン。
3. `mkdir -p downloads` を実行する。
4. [persona-templates.md](./references/persona-templates.md) から `SOUL.md` / `USER.md` / `MEMORY.md` を
   cwd に生成する。**テンプレの改変は変数置換のみ**
   （`{agent-name}` `{user-name}` `{google-account}` `{persona}` `{date}` `{timezone}`）。
5. [project-claude-template.md](./references/project-claude-template.md) から `CLAUDE.md` を生成する。
6. [mcp-setup.md](./references/mcp-setup.md) から `.gitignore` を生成し、同ファイルの
   「接続確認手順」に従って claude.ai Gmail / Google Calendar コネクタの接続を確認する
   （未接続・トークン失効ならユーザーに `/mcp` での再認証を案内する）。
7. Skill ツールで `vw-wiki` を init 起動する（対象 = cwd、トピック「<name> 秘書業務知識」）。
   wiki/ + raw/ が生成され、CLAUDE.md には同一文言セクションが既にあるため二重追記されない。
   秘書プロジェクトは **git 管理しない**（`git init` しない。.gitkeep も不要）。
   生成する .gitignore は将来ユーザーが自分で git 管理を始めた場合の事故防止の保険。
8. 生成結果をツリーで報告し、動作確認（「今日の予定を教えて」「未読メールを 3 件教えて」）を
   促す。以降はこのディレクトリで claude を起動すればいつでも秘書が有効になると案内する。

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
- コネクタの制約（送信・添付ダウンロードのツールなし、アカウント切替不可）を回避する
  実装を勝手に足さない。制約の詳細は [mcp-setup.md](./references/mcp-setup.md) が正。

## Rollback / Recovery

- 秘書が不要になった: 秘書プロジェクトのディレクトリを `trash` する
  （コネクタは claude.ai アカウント側の設定なので、プロジェクト削除の影響はない）。
- init が途中で失敗した: 生成済みファイルを `trash` してから init をやり直す（上書き再実行はしない）。
- コネクタが「requires re-authorization」を返す: `/mcp` から再認証する
  （[mcp-setup.md](./references/mcp-setup.md) の接続確認手順を参照）。
- SKILL 自体の破損: dotfiles リポジトリで `jj restore claude/.claude/skills/vw-agent/`。

## Advanced References

- [persona-templates.md](./references/persona-templates.md) — SOUL / USER / MEMORY テンプレート
- [project-claude-template.md](./references/project-claude-template.md) — 秘書ルールブック（正規ソース）のテンプレート
- [mcp-setup.md](./references/mcp-setup.md) — claude.ai コネクタの制約・接続確認手順・.gitignore テンプレート
