---
description: ディレクトリ内のファイルパスのみから qmd collection 設計を推論し、既存 index.yml を破壊しない適用コマンド列を生成（本文は読まない、500超は階層サンプリング）
argument-hint: <directory path>
---

ユーザーから対象ディレクトリ `$ARGUMENTS` の qmd 分類を依頼されました。

`vw-qmd-classifier` subagent に委譲してください。

委譲時の指示：

- 対象: `$ARGUMENTS` 配下の `*.md` / `*.markdown` ファイル
- **本文は絶対に読まない**
- まず `qmd collection list` で既存 collection を確認（名前衝突チェック）
- 次に `fd ... | wc -l` でファイル数を測り、ファイル数に応じて
  階層サンプリングに切り替える（agent definition の WORKFLOW に従う）
- 出力: **YAML ではなく、`qmd collection add` + `qmd context add` の実行可能コマンド列**
- 各コマンド行に `# files: N` などのコメントで根拠を付ける
- サンプリング使用時は出力冒頭に NOTE コメントを入れる
- ロールバック用 `qmd collection remove ...` を末尾に必ず添える

agent からのコマンド列を受け取ったら、ユーザーに以下を提示し、適用前に確認してもらってください：

1. 集計サマリー（規模・ディレクトリ別カウント・命名統計）
2. 既存 collection との衝突チェック結果
3. 適用コマンド列（コピペ実行可能な bash ブロック）
4. 不明・要レビュー箇所（TODO）
5. サンプリング適用の有無

**重要**: agent が `~/.config/qmd/index.yml` を直接編集する提案を返してきた場合は拒否し、
CLI コマンド列に書き換えるよう再依頼してください。
