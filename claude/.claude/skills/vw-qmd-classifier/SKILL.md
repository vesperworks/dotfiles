---
name: vw-qmd-classifier
description: |
  ディレクトリ内のファイルパスとファイル名のみから qmd collection 設計を推論し、
  既存 `~/.config/qmd/index.yml` を破壊しない `qmd collection add` / `qmd context add` の
  適用コマンド列を生成するスキル。本文は一切読まないためトークン消費が小さい。
  ファイル数に応じて階層サンプリングを自動適用するため大規模ディレクトリ（500+/5000+）でも
  精度を保つ。Use when the user says 「qmd 分類して」「qmd で検索可能にして」「qmd collection 作って」
  「/vw-qmd-classifier」等。NOT for ファイル本文の意味解析（読まない設計）and NOT for
  qmd CLI を自動実行すること（CLI コマンド列の出力までで止める）。
disable-model-invocation: true
argument-hint: <directory path>
allowed-tools: Bash, Glob, TodoWrite
model: sonnet
---

<role>
You design qmd collections from filenames and paths only — never reading file bodies.
Output: ready-to-run `qmd collection add` + `qmd context add` commands. Never YAML to be pasted.
</role>

<language>
- Think: 日本語
- Communicate: 日本語（ナレーション・コメント）
- CLI commands / arguments: English
- context strings (qmd context add の引数): English（LLM が検索結果を解釈しやすい）
</language>

# vw-qmd-classifier — qmd 自動分類スキル

ローカル Markdown 検索ツール `qmd` の collection 設計を、ファイル本文を読まずに推論する。出力は `qmd collection add` / `qmd context add` の実行可能 CLI コマンド列で、既存 `index.yml` を破壊せず、必要なら `qmd collection remove` でロールバック可能。

## 背景（なぜこのスキルが必要か）

- qmd は path / pattern ベースで collection を定義し、context（人間記述のサマリー）を付けて検索品質を上げる
- 数千ファイル規模の Vault を手作業で classify するのは非現実的
- 一方で、ファイル本文を全部 LLM に読ませると context window もコストも破綻する
- **解決**: ディレクトリ階層 + ファイル名 + 命名統計だけで semantic クラスタリングは 90% 以上達成できる
- 出力を **YAML 直編集ではなく CLI コマンド列**にすることで、既存 collection を破壊せず、ロールバック容易

## トリガー

ユーザーの発話例:

- 「qmd 分類して」「qmd で検索可能にして」
- 「qmd の collection 作って」「qmd collection 設計して」
- 「`/vw-qmd-classifier ~/path`」「`/vw-qmd-classifier`」（引数なし → AskUserQuestion で対象収集）
- 「このディレクトリを qmd に登録したい」

## ABSOLUTE RULES

1. **Never read file contents**. No `Read` on `.md` files. Use Bash with `fd`, `gfind`, `tree`,
   `awk`, `sed`, `sort`, `uniq` to obtain paths, sizes, and dates only.
2. **Never auto-run** `qmd collection add` / `qmd collection remove` / `qmd context add` /
   `qmd update` / `qmd embed`. Output a command list — let the user paste/execute manually.
3. **Never propose direct edits to `~/.config/qmd/index.yml`**. Always use the `qmd collection`
   and `qmd context` CLI subcommands (they preserve existing collections, support rollback).
4. **Always check existing collections first** with `qmd collection list` before proposing.
   Warn on name collision and suggest a different name (or ask the user to remove first).
5. Files larger than 100 KB are flagged in the proposal as comments, not opened.
6. macOS 環境のため、列挙系は `fd`（高速・並列）、メタ情報付き出力は `gfind -printf`
   （1 プロセスで stat 取得できるため大規模ディレクトリで効率的）を使い分ける。
   標準 `find` の `-printf` は非対応のため使わない。

## WORKFLOW (file-count-aware)

### Step 0: Inspect existing qmd state

```bash
qmd collection list
```

既存 collection 名と path を控える。提案する collection 名がこれらと衝突しないこと、
あるいは衝突する場合はユーザーに `qmd collection remove <name>` 後の再実行を促す。

### Step 1: Count first

```bash
COUNT=$(fd -e md -e markdown --type f . <dir> | wc -l | tr -d ' ')
echo "Total markdown files: $COUNT"
```

### Step 2: Branch by count

#### When COUNT ≤ 50 — list everything

メタ情報（サイズ・更新日）を 1 プロセスで取るため `gfind -printf` を使用。

```bash
gfind <dir> -type f \( -name "*.md" -o -name "*.markdown" \) \
  -printf "%P\t%s\t%TY-%Tm-%Td\n" | sort
```

#### When 51 ≤ COUNT ≤ 500 — list paths + show tree

```bash
gfind <dir> -type f \( -name "*.md" -o -name "*.markdown" \) \
  -printf "%P\t%s\t%TY-%Tm-%Td\n" | sort
tree -L 3 -P "*.md" --noreport <dir> 2>/dev/null | head -200
```

#### When COUNT > 500 — hierarchical sampling (do NOT list every path)

列挙系は `fd` で高速化。ディレクトリスケルトンは `tree`。

```bash
# (a) Directory skeleton — most important
tree -L 3 -d --noreport <dir> | head -100

# (b) File counts per directory
fd -e md --type f . <dir> \
  | awk -F/ '{NF--; print}' OFS=/ \
  | sort | uniq -c | sort -rn | head -50

# (c) Representative samples (head/tail per dir)
fd --type d . <dir> | while read -r d; do
  n=$(fd -e md --type f --max-depth 1 . "$d" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] || continue
  echo "## $d  ($n files)"
  fd -e md --type f --max-depth 1 . "$d" -x basename 2>/dev/null | sort | head -3
  [ "$n" -gt 6 ] && echo "  ..."
  [ "$n" -gt 6 ] && fd -e md --type f --max-depth 1 . "$d" -x basename 2>/dev/null | sort | tail -3
done | head -200

# (d) Naming-pattern statistics (regex-collapsed)
fd -e md --type f . <dir> -x basename \
  | sed -E 's/[0-9]{4}-[0-9]{2}-[0-9]{2}/YYYY-MM-DD/g; s/[0-9]+/N/g' \
  | sort | uniq -c | sort -rn | head -20
```

#### When COUNT > 5,000 — recursive

Suggest the user run `/vw-qmd-classifier` separately for each top-level subdirectory
returned by `tree -L 1 -d --noreport <dir>`.

### Step 3: Analyze patterns from observations

Look for:
- Date-prefix patterns (`YYYY-MM-DD-...md`)
- Subdirectory naming as semantic unit (`meetings/`, `people/`, `journals/`)
- Filename prefixes/suffixes (`meeting-`, `-spec`, `-adr`)
- Per-entity grouping (slug-style names like `first-last.md`)
- Index/README files at directory boundaries

### Step 4: Cluster into 3–8 candidate collections

- Avoid singletons (1-2 files)
- Prefer broad scope over hyper-specific splits
- Use folder boundaries as default cluster lines
- Collection name は **小文字 + アンダースコア区切り**（`agents`, `vercel_react_rules` 等）。
  既存 collection と衝突する場合は別名を提案（例: `agents` が衝突するなら `claude_agents`）

### Step 5: Draft contexts

For each collection, one-line context:
`<role> + <trust level> + <usage caveat>`

例: `"Meeting transcripts, raw, verify decisions before citing."`

スコープ別 context を貼りたい場合は `qmd://<collection>/<subpath>` virtual path を使う：
- `qmd://agents/` — collection 全体
- `qmd://skills_core/SKILL.md` — `SKILL.md` ファイル群（glob 風）に対する補足
- `qmd://eval/test-cases/` — サブディレクトリスコープ

### Step 6: Output applicable command list

YAML ではなく**実行可能な qmd CLI コマンド列**を出力する。ユーザーがそのままコピペで実行できる形。

```bash
# === qmd-classify proposal for: <target dir> ===
# Generated: <date>
# Files: <count> (sampling: yes/no)
# Existing collections (from `qmd collection list`): <list> [or: none]
# Name collision check: <ok / WARNING ...>

# --- 1. Add collections ---
qmd collection add <name1> <abs-path1> --pattern '**/*.md'
qmd collection add <name2> <abs-path2> --pattern '**/*.md'
# ...

# --- 2. Attach contexts (one liner per collection / scope) ---
qmd context add 'qmd://<name1>/' '<role + trust + caveat>'
qmd context add 'qmd://<name2>/' '<role + trust + caveat>'
# scope-specific (optional):
qmd context add 'qmd://<name3>/SKILL.md' '<scope-specific note>'

# --- 3. Re-index and embed ---
qmd update
qmd embed --all

# --- 4. (optional) Verify coverage ---
qmd collection list
qmd ls <name1>
```

When sampling was used (>500 files), prepend a NOTE comment block:

```bash
# NOTE: Based on hierarchical sampling of N files (full enumeration skipped).
#       File-body inspection NOT performed. Run `qmd collection list` and
#       `qmd ls <name>` after `qmd update` to validate that all paths got classified.
```

### Step 7: Rollback hint

末尾に必ずロールバック方法を 1 行で添える：

```bash
# Rollback: qmd collection remove <name1> <name2> ... && qmd update
```

## OUTPUT STRUCTURE (required)

最終出力は以下 4 セクション構成：

1. **集計サマリー** — 規模・ディレクトリ別カウント・命名統計（日本語）
2. **既存 collection との衝突チェック結果**（日本語）
3. **適用コマンド列**（上記 Step 6 の bash 形式）
4. **要レビュー箇所**（日本語、TODO 形式）

## OUTPUT STYLE

- ナレーションは日本語、CLI コマンドは英語のまま。
- Be conservative: prefer fewer collections with broad scope.
- 「unclassified」「misc」コレクションは**作らない**（`qmd collection add` で空集合に近いものを作っても意味が薄い）。
  代わりに「ルート直下の N ファイルは collection 化を見送り、`qmd context add /` で global context のみ付与」を提案する形でよい。
- Show file counts in CLI comments for sanity-check (`# files: N`).
- If a directory has < 20 files, suggest a single collection (don't over-engineer).
- For sampling-based runs, explicitly say "based on N samples of M total files".

## 標準起動フロー

引数なしで起動された場合（例: `/vw-qmd-classifier` のみ）、`AskUserQuestion` で対象ディレクトリを収集する：

1. 「対象ディレクトリのパスを教えてください」（自由入力）
2. （任意）「既存 collection を破棄して再構築しますか？」（破棄なし / collection_X だけ削除 / 既存維持で追加）

引数ありで起動された場合（例: `/vw-qmd-classifier ~/Documents/notes`）、即座に Step 0 から実行。
