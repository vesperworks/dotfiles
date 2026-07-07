---
name: vw-repo-audit
description: 「OSS として公開して恥ずかしくないか」を公開前ゲートとして監査するスキル。未 push のコミット差分と公開時に見られる表層（README/LICENSE/構造/履歴メタ）を、Sonnet×6 並列監査（Workflow）+ 判定役の統合で 6 カテゴリ 100 点満点採点し、Critical/Serious には修正 diff を提案、self-contained な HTML スコアカードを生成して open する。機密らしき値は常にマスク（file:line と種別のみ記載）。Use when the user says 「公開前チェック」「repo 監査」「OSS で恥ずかしくないか」「ダサくないかチェック」「push して大丈夫か見て」「/vw-repo-audit」等。NOT for コード正しさのレビュー（/code-review 参照）、NOT for CSS/デザイントークン監査（vw-wabun-hig-audit 参照）、NOT for repo 全ファイルのフル監査（公開前ゲート専用。全量監査モードは持たない）。
argument-hint: [target-dir]
allowed-tools: Read, Write, Bash, Glob, Grep, Workflow, AskUserQuestion
model: opus
---

# vw-repo-audit — OSS 公開前ゲート監査

「これから公開される差分」が OSS として恥ずかしくないかを採点する。repo 全量は見ない —
未 push 差分 + 公開時に見られる表層だけを見る、push 直前の関所。

審美眼は自前で持たず「有名 OSS の慣習との差」で測る（vw-wabun-hig-audit が HIG を借りたのと同じ設計思想）。

| ファイル | 内容 |
|----------|------|
| [`references/categories.md`](references/categories.md) | 6 カテゴリの監査観点ルーブリック（各 Sonnet の入力） |
| [`references/scoring.md`](references/scoring.md) | 配点・severity 定義・採点式 |
| [`references/workflow.js`](references/workflow.js) | Sonnet×6 並列監査の Workflow スクリプト |

## Step 0: 対象特定（read-only）

1. **VCS 検出**: `jj root` が通れば jj、なければ `git rev-parse --show-toplevel` で git。`{project}` はリポジトリルートのディレクトリ名
2. **未公開差分の抽出**:
   - jj: `jj log -r 'main@origin..main' --no-graph` でコミット一覧、`jj diff --from main@origin --to main --summary` で変更ファイル
   - git: `git log origin/main..main --oneline` と `git diff --name-status origin/main..main`
   - **upstream が無い repo**: 差分審査をスキップし表層チェックのみに縮退（その旨を報告に明記）
3. **表層ファイルの収集**（差分の有無に関わらず常時）: README*, LICENSE*, CONTRIBUTING*, ルート直下の設定類, `ls` によるトップレベル構造, `.gitignore`
4. **絞り込み**（トークン制御）: 差分ファイルが **100 件超**なら、内容精読は重要度順（README/docs > 設定 > スクリプト > その他）に **60 件**へ絞り、残りはファイル名・パスのみの審査に落とす。絞った件数を必ず報告に残す

## Step 1: 出力ディレクトリと入力ファイルの準備

`.brain/{project}/review/{YYYY-MM-DD}-repo-audit/` を作成し、`inputs/` に監査入力を書き出す
（args に大きなデータを載せない — 文字列化事故の防止・トークン節約・証跡化のため）:

- `inputs/commitlog.txt` — 未公開コミット一覧（Step 0-2 の出力）
- `inputs/diff-files.txt` — 精読対象の変更ファイル（1 行 1 ファイル、絞り込み後）
- `inputs/surface.txt` — 表層ファイル（1 行 1 ファイル）

絞り込み時は **種別クォータ**で偏りを防ぐ（例: docs 系 20 / 設定 15 / スクリプト 20 / その他 5。
md ばかり 60 件になると Hygiene 監査が形骸化する）。

## Step 2: 並列監査（Sonnet×6 via Workflow）

```
Workflow({
  scriptPath: "~/.claude/skills/vw-repo-audit/references/workflow.js",
  args: {
    projectRoot: "<絶対パス>",
    reviewDir: "<Step 1 の絶対パス>",
    skillDir: "<このスキルの絶対パス>",
    date: "<YYYY-MM-DD>",
    vcs: "jj|git",
    truncatedCount: <絞り込みで名前のみ審査に落ちた件数>
  }
})
```

各 Sonnet は担当カテゴリのルーブリック（categories.md の該当節）に従い、file:line 証拠付きの
所見を `{reviewDir}/cat-{n}-{key}.md` に書き、構造化 findings を返す。

## Step 3: 判定・採点（このスキルを実行するモデル = 判定役）

6 カテゴリの findings を統合する。判定規約:

1. **重複統合**: 「この指摘の修正は、既出のどの指摘の修正と同じ diff になるか」を各件チェックし、
   同じなら 1 件に統合して影響箇所を file:line リストで列挙（1 根本原因 = 1 指摘）
2. **severity 最終確定**: Sonnet の申告を鵜呑みにせず scoring.md の定義で再判定。
   反証可能な指摘（コマンドで白黒つく類）は実行して確認するか「未検証」と明記する
3. **採点**: scoring.md の式で 100 点満点から減点
4. **修正 diff**: Critical / Serious には before/after diff を付ける（適用はしない）
5. **機密マスクの最終確認**: レポート・HTML のどこにも検出値そのものが載っていないこと

## Step 4: HTML スコアカード生成（必須）

`{reviewDir}/index.html` に self-contained HTML を生成し、`open` で表示する。

構成: ①総合スコア（大きく、100 点満点）②カテゴリ別バー（配点比付き）③指摘テーブル
（severity 色分け: Critical=赤 / Serious=橙 / Nitpick=灰、file:line、修正 diff は折りたたみ）
④監査メタ（対象コミット数・ファイル数・絞り込み件数・日付）。
CDN 依存なし・light/dark 両対応。あわせて md サマリを `{reviewDir}/summary.md` に保存する。

## Step 5: 報告

総合スコアと Critical/Serious の件数を先頭に、指摘一覧と「push して良いか」の判定
（90+ = そのまま可 / 70-89 = Serious 対処推奨 / 70 未満 = Critical 対処必須）を提示する。
修正の適用はユーザーの合意後のみ。

## Rollback / Recovery

- Workflow が途中で落ちた: tool 結果の runId で `Workflow({scriptPath, resumeFromRunId})` 再開（完了済み agent はキャッシュされる）
- 指摘が的外れ: 該当カテゴリの cat-*.md（生データ）を確認し、判定役の統合ミスか Sonnet の誤検出かを切り分けて該当カテゴリのみ再実行
- スコアが疑わしい: scoring.md の式で手計算検証（採点はすべて決定的な式で行う）
