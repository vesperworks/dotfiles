# Bootstrap テンプレート集（init 時に生成するファイル）

init 時に schema-template.md（SCHEMA.md 本体）と合わせて以下を生成する。
`{topic}` はユーザーのトピック名、`{date}` は当日（YYYY-MM-DD）に置換。

## 1. wiki/INDEX.md

```markdown
# INDEX — {topic}

全ページのカタログ。ページを作成・改名・削除したら必ずこのファイルを更新する（SCHEMA.md R10）。

## concepts/

（なし）

## entities/

（なし）

## sources/

（なし）

## queries/

（なし）

## inbox/

（なし）

## 昇格候補

（なし）
```

ページのエントリ形式: `- [[concepts/foo]] — 1 行要約`
昇格候補の形式: `- <slug>: 登場箇所1, 登場箇所2`（3 ページ目の登場でページに昇格し、この行を消す。SCHEMA.md R7）

## 2. wiki/LOG.md

```markdown
# LOG — 追記専用

形式: `## YYYY-MM-DD <operation> | <対象>`（operation = init / ingest / query / lint / sync）

## {date} init | wiki 初期化
```

## 3. wiki/SOURCES.md

```markdown
# SOURCES — 監視ソース登録簿

sync の対象となる git 管理下のパス（リポジトリ相対）。1 行 1 パス、ディレクトリ指定可。
raw/ は登録不要（sync が常に対象に含める）。人間が編集してよい唯一の wiki ファイル（SCHEMA.md R1）。

## 監視パス

（なし）
```

init 時の AskUserQuestion で「sync で監視したい既存ディレクトリ・ファイルはあるか」を確認し、
あれば「## 監視パス」に `- <リポジトリ相対パス>` 形式で初期登録する。

## 4. .cursor/rules/wiki.mdc（wiki の親ディレクトリ＝プロジェクトルートに配置）

Cursor (Sonnet) 用ラッパー。ロジックは一切書かない — SCHEMA.md へ誘導するだけ。

```markdown
---
description: このプロジェクトの wiki/（ナレッジベース）への取り込み・質問・検査・同期。「ingest」「wiki に取り込んで」「wiki で答えて」「lint して」「sync して」等で適用する
alwaysApply: false
---

このプロジェクトには `wiki/`（エージェントが育てるナレッジベース）と `raw/`（不変ソース）がある。

wiki に関する操作（ingest / query / lint / sync）を行うときは:

1. 最初に `wiki/SCHEMA.md` を全文読む。
2. SCHEMA.md に書かれた 10 か条と操作手順に厳密に従う。手順の番号を飛ばさない。
3. SCHEMA.md とこのルールが矛盾したら SCHEMA.md を優先する。
```

## 5. AGENTS.md への追記（Claude Code / Codex 等用ラッパー）

プロジェクトルートの `AGENTS.md`（CLAUDE.md が既にあるプロジェクトでは CLAUDE.md）に以下のセクションを追記する。
ファイルがなければ AGENTS.md を新規作成する（その場合、以下のセクションのみをファイル内容としてよい）。既に同セクションがあれば何もしない。

```markdown
## wiki/ ナレッジベース

このプロジェクトには `wiki/`（エージェントが育てるナレッジベース）と `raw/`（不変ソース）がある。
wiki への取り込み（ingest）・質問への回答（query）・検査（lint）・監視ソースの同期（sync）を行う前に、
必ず `wiki/SCHEMA.md` を全文読み、その規則に厳密に従うこと。
```

## 6. ディレクトリ

```
raw/
wiki/inbox/  wiki/concepts/  wiki/entities/  wiki/sources/  wiki/queries/
```

- 既に存在するディレクトリ・ファイルには何もしない（上書き禁止。`mkdir -p` 相当の no-op）。
- git 管理下の場合のみ、各空ディレクトリに `.gitkeep` を置く（管理外なら不要）。
