---
name: vw-wiki
description: karpathy llm-wiki + gBrain パターンの LLM 育成型ナレッジベース（オントロジー層）を任意のディレクトリに構築・運用するスキル。操作は init（wiki/ ブートストラップ）/ ingest（ソース取り込み）/ query（wiki で回答 + file-back）/ lint（健全性検査）/ sync（git 監視パスの更新を一括取り込み）の 5 つ。ソースは git 参照（コミット SHA + ログ 1 行で出所記録）と raw/（git 外ソース）の 2 種。ルールの正規ソースは生成される wiki/SCHEMA.md に自包され、Cursor (Sonnet) など他エージェントでも同一ワークフローが動く。Use when the user says 「wiki を作って/育てて」「ingest して」「wiki に取り込んで」「ナレッジベース化して」「オントロジー作って」「wiki で答えて」「wiki を lint して」「sync して」「/vw-wiki」等。NOT for Claude Code の auto-memory（MEMORY.md）の管理、NOT for .brain/thoughts/ の Atomic Notes（vw-notetaker 参照）、NOT for 単発の Web リサーチ（deep-research / vw:websearch 参照）。
---

# vw-wiki — LLM 育成型ナレッジベース

## Core Purpose

LLM が Markdown の wiki（オントロジー層）を ingest / query / lint / sync の 4 操作で育てる
karpathy llm-wiki パターンを、Claude Code と Cursor の両方で同一ルールで運用する。
ソースは 2 種: **git 参照ソース**（リポジトリ管理下の原本。コピーせず、取り込み版のコミット SHA +
コミットログ 1 行を記録。不変性は git が保証）と **raw/ ソース**（git の不変性が使えないもの）。
**ロジックの正規ソースはこの SKILL ではなく、各 wiki に同梱される `wiki/SCHEMA.md`**。
この SKILL はブートストラップ（init）と、SCHEMA.md への確実な誘導だけを担う。

## Quick Checklist (初期応答で必ず確認)

- [ ] 対象ディレクトリはどこか（明示がなければ cwd。曖昧なら AskUserQuestion で確認）
- [ ] 対象に `wiki/SCHEMA.md` が存在するか → **存在する: Step I は飛ばす / 存在しない: init から**
- [ ] ユーザーの意図はどの操作か（init / ingest / query / lint / sync）

## Basic Workflow

### Step I: init（wiki/SCHEMA.md が存在しない場合のみ）

1. AskUserQuestion でトピック名（例: "LLM エージェント設計"）と配置ディレクトリ、
   sync で監視したい既存パス（任意）を確認する。
2. [schema-template.md](./references/schema-template.md) の TEMPLATE START〜END を
   `{topic}` 置換のうえ `wiki/SCHEMA.md` として書き出す。**テンプレの改変は置換のみ**。
3. [bootstrap-templates.md](./references/bootstrap-templates.md) に従い以下を生成する:
   - `wiki/INDEX.md` / `wiki/LOG.md` / `wiki/SOURCES.md`
   - ディレクトリ: `raw/` と `wiki/{inbox,concepts,entities,sources,queries}/`
   - `.cursor/rules/wiki.mdc`（Cursor 用ラッパー）
   - `AGENTS.md` への追記（CLAUDE.md が既存ならそちらへ。Claude Code / Codex 用ラッパー）
4. 生成結果をツリーで報告し、「raw/ にソースを置く（または SOURCES.md に監視パスを登録する）→
   『ingest して』『sync して』で取り込みが始まる」と案内する。

### Step O: 操作実行（ingest / query / lint / sync）

1. **`wiki/SCHEMA.md` を全文読む**。この SKILL の記憶ではなく、必ず実ファイルを読む
   （wiki ごとにユーザーがルールを育てている可能性があるため）。
2. SCHEMA.md の「操作手順」セクションの該当手順を、番号を飛ばさず順番に実行する。
3. SCHEMA.md とこの SKILL が矛盾したら **SCHEMA.md を優先**する。

## 設計原則（この SKILL を編集するときの制約）

- ロジックを SKILL.md に書かない。ルール追加は schema-template.md（新規 wiki 向け）か、
  各 wiki の SCHEMA.md（既存 wiki 向け）に行う。
- ラッパー（.mdc / AGENTS.md 追記）は「SCHEMA.md を読め」以上のことを言わない。
  二重管理になった瞬間に Cursor と Claude Code の挙動が割れる。
- SCHEMA.md は 150 行以内を維持する（Sonnet の遵守率確保のため）。

## Rollback / Recovery

- init の生成物が不要になった: 生成したファイル/ディレクトリを `trash` で削除
  （`trash wiki/ raw/ .cursor/rules/wiki.mdc` + AGENTS.md の追記セクションを手動除去）。
- ingest / sync が壊した: git 管理下なら `git restore wiki/`（jj なら `jj restore wiki/`）。
  非管理下のため復旧不能な場合に備え、大規模 ingest（5 ページ超の更新）の前には
  LOG.md に更新予定ページの一覧を先に追記しておく。
- SKILL 自体の破損: `git restore claude/.claude/skills/vw-wiki/`（dotfiles リポジトリ）。

## Advanced References

- [SCHEMA.md テンプレート（正規ソース）](./references/schema-template.md)
- [Bootstrap テンプレート集（INDEX/LOG/SOURCES/.mdc/AGENTS.md）](./references/bootstrap-templates.md)
- 設計の経緯・出典: dotfiles リポジトリ `.brain/dotfiles/research/2026-06-10-ontology-wiki-skill-design.md`
