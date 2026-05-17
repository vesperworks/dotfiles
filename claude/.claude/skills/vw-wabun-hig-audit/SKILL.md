---
name: vw-wabun-hig-audit
description: 既存の CSS / Tailwind config / DTCG JSON を Apple HIG（Human Interface Guidelines）と W3C JLREQ 由来の和文タイポルーブリックで監査し、20カテゴリ × 4段階重み付け（Critical×12 / Serious×8 / Moderate×4 / Tip×1）の100点満点で採点。Critical / Serious 違反には refactor diff を提案する。詳細レポートを `.brain/thoughts/shared/research/{date}-wabun-hig-audit-{target}.md` に保存。Use when the user says 「デザイン監査」「HIG準拠チェック」「和文組版チェック」「CSS採点」「デザイントークン監査」「palt 効いてる？」「行間チェック」等。NOT for 0→1 のデザイン生成（design system 起票は別タスク）and NOT for 画像ベースのビジュアル評価（html image-review 参照）。
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# vw-wabun-hig-audit — 和文 HIG デザイン監査

CSS / Tailwind config / DTCG JSON を対象に、Apple HIG と W3C JLREQ の規範に照らして **100点満点で採点**し、違反箇所には **before/after の refactor diff** を提示する。

審美眼は自前ではなく、HIG（外部の権威ある規範）を借りる。ゼロから生成せず、既存資産を refactor する。

詳細ルーブリックは `references/` を参照（情報は最小に圧縮済み、必要時のみ展開）:

| ファイル | 内容 |
|----------|------|
| [`references/hig-foundations.md`](references/hig-foundations.md) | HIG Typography / Color / Layout / Components 圧縮ルーブリック |
| [`references/wabun-typography.md`](references/wabun-typography.md) | 和文組版（JLREQ + kiso.css 由来）の期待値 |
| [`references/scoring-rubric.md`](references/scoring-rubric.md) | 採点式 + 20 カテゴリ表 + 信頼度マッピング |
| [`references/diff-templates.md`](references/diff-templates.md) | refactor diff の出力雛形（Vanilla CSS / Tailwind / React inline） |
| [`references/CREDITS.md`](references/CREDITS.md) | フォーク元（MIT）と出典 |

---

## Step 0: 入力受付

ユーザが何を渡してきたかを判定する。

| 入力タイプ | 扱い |
|-----------|------|
| 単一 CSS / SCSS ファイル（パス） | Read で全文取得、`Step 1.5: 🟢 High` |
| Tailwind config（`tailwind.config.{js,ts}`） | Read、`Step 1.5: 🟢 High` |
| DTCG JSON（`*.tokens.json` / `*.dtcg.json`） | Read、`Step 1.5: 🟢 High` |
| ディレクトリ（複数 CSS） | Glob で `*.css` 全件、各ファイルの行数合計が多ければ scope 選択 |
| スクリーンショット | `Step 1.5: 🟡 Medium`、視覚評価のみ。Token / 厳密 size は採点除外 |
| URL（公開サイト） | このスキルでは fetch しない。ローカルにダウンロードしてから渡してもらう（`html image-review` へ誘導してもよい）|
| 説明文のみ | `Step 1.5: 🔴 Low`、採点せず観察と質問返し |

**入力が指定されていない場合**、AskUserQuestion で 1 回だけ確認する（既定で full audit）:

```
質問: 監査対象は？
オプション:
  - CSS / SCSS ファイル
  - Tailwind config
  - DTCG JSON
  - ディレクトリ全体（複数ファイル）
  - スクリーンショット（画像）
```

---

## Step 1: 自動推論 (Smart Defaults)

質問する前に、可能な限り推論する。

### 1.1 Scope（quick / full / custom）

- ユーザ発話に「ざっと」「軽く」「クイック」 → **Quick audit (5 カテゴリ)**
- 「全部」「フル」「徹底的に」 → **Full audit (20 カテゴリ)**
- 「タイポだけ」「コントラストだけ」 → **Custom (該当カテゴリのみ)**
- 何も言われていない → **Full audit** を既定

Quick audit のカテゴリ自動選択は `references/scoring-rubric.md` §「Quick audit の自動マップ」を参照。

### 1.2 和文適用判定（第 20 カテゴリのオン / オフ）

以下のいずれかに該当 → **第 20 カテゴリを ON**:

- `lang="ja"` がコード中に出現
- `font-family` に `Hiragino` / `YuGothic` / `Yu Gothic` / `Noto Sans JP` / `BIZ UDPGothic` / `Meiryo` が含まれる
- 監査対象ファイルに U+3040–U+30FF（ひらがな・カタカナ）または U+4E00–U+9FFF（CJK 漢字）の文字列リテラルが含まれる

該当なし → 第 20 カテゴリは自動 OFF（採点から除外、レポートに「Wabun: N/A」と表示）。

### 1.3 WCAG レベル

既定 **AA**。ユーザが「AAA」「アクセシビリティ最優先」「政府系」と言った場合のみ AAA。

---

## Step 1.5: 信頼度宣言（必須・1 行）

`references/scoring-rubric.md` §「信頼度」を参照。

レポート冒頭に必ず:

```
**Input:** [path or filename]
**Type:** [CSS / Tailwind config / DTCG / Screenshot]
**Confidence:** 🟢 High（または 🟡 Medium / 🔴 Low）
**Wabun:** ON（または OFF）
**Scope:** Full audit（20 カテゴリ）
```

- 🟡 Medium のときは「Critical 以外は ×0.5 修正を適用」と明記
- 🔴 Low のときは採点せず、観察と質問返しで終わる

---

## Step 2: 監査の実行

`references/hig-foundations.md` と `references/wabun-typography.md` の判定基準をカテゴリ順に適用。

### 2.1 検出ヒント（コード入力時に自動で走る）

各カテゴリの検出スクリプトは `hig-foundations.md` の各セクション末尾と `wabun-typography.md` §「検出ヒント」に書かれている。代表例:

```bash
# 8pt grid 違反（spacing 値で 4 の倍数でないもの）
grep -nE '(padding|margin|gap|width|height)\s*:\s*[0-9]+px' input.css \
  | awk -F: '{ split($3, a, /[: ]+/); for (i in a) if (a[i] ~ /[0-9]+px$/) { v = a[i]; sub("px","",v); if (v % 4 != 0) print $1":"$2": off-grid "v"px" } }'

# 和文 line-height
grep -nE 'line-height\s*:\s*1\.[0-4]' input.css

# palt の有無
grep -nE 'font-feature-settings.*"palt"' input.css

# focus outline 削除
grep -nE 'outline\s*:\s*(none|0)' input.css
```

実際の検出は Bash で grep / awk を使うか、Read してから Claude が目視評価する。**正規表現で取りこぼした項目は Claude の目視で補完する**（HIG / JLREQ への適合は最終的に意味的判断が要る）。

### 2.2 重み付け

```
Score = 100
  − (Critical × 12)
  − (Serious  × 8)
  − (Moderate × 4)
  − (Tip      × 1)
```

🟡 Medium のときは Serious / Moderate / Tip に ×0.5。Critical は満額。

---

## Step 3: レポートの出力

### 3.1 標準出力（チャット）

以下の構造で出力:

```markdown
# 監査結果

**Input:** path/to/style.css
**Type:** Vanilla CSS
**Confidence:** 🟢 High
**Wabun:** ON
**Scope:** Full audit（20 カテゴリ）

## サマリ

Score: 100 − (3×12) − (2×8) − (4×4) − (5×1) = **27/100**
Critical: 3 / Serious: 2 / Moderate: 4 / Tip: 5

## Critical（必修）

### C1. Touch target 不足 — Category #4
- File: `style.css:42-44`
- 違反: アイコンボタンの実体ヒット領域が 32×32px、HIG 要件 44×44pt 未達
- Diff:
  ```diff
  - .icon-button { width: 32px; height: 32px; }
  + .icon-button { min-width: 44px; min-height: 44px; }
  ```
- Why: `hig-foundations.md` §3.2

### C2. ...

## Serious

（以下同様）

## Moderate（サマリのみ）

- M1. padding 13px が 7 箇所に複製（line 12, 45, ...） — Category #3
- M2. ...

## Tip（サマリのみ）

- T1. color-scheme 未指定 — Category #11
- T2. ...

## 信頼度に基づく修正

🟢 High なので満額採点。

## レポート保存先

→ `.brain/thoughts/shared/research/2026-05-19-wabun-hig-audit-style-css.md`
```

### 3.2 レポート保存（必須）

`Write` ツールで以下のパスに同内容を保存する:

```
.brain/thoughts/shared/research/{YYYY-MM-DD}-wabun-hig-audit-{target-slug}.md
```

- `{YYYY-MM-DD}` は今日の日付（`date +%Y-%m-%d`）
- `{target-slug}` は監査対象のファイル名・ディレクトリ名をケバブケース化（例: `style-css`, `tailwind-config`, `tokens-json`）

レポート内容はチャット出力と同じ + 末尾に以下のメタ情報を追加:

```yaml
---
audited_at: 2026-05-19T16:42:00+09:00
target: path/to/style.css
target_type: Vanilla CSS
confidence: high
wabun: on
scope: full
score: 27
critical: 3
serious: 2
moderate: 4
tip: 5
---
```

### 3.3 次の一手（任意）

採点末尾に 1 行で「次の一手」を提案:

- スコア < 50 → 「Critical を優先順に直すと +12〜36 点。順に手伝う？」
- 50 ≤ スコア < 80 → 「Serious を 1 つずつ直すと +8 点。どれから？」
- スコア ≥ 80 → 「Tip 中心。ここまでで実用ラインは満たしている」

---

## 設計の固定事項

- **0→1 生成しない**: 渡されていない要素について「こうあるべき」と新規生成しない。観察と diff だけ
- **多言語自動検出はしない**: ユーザの会話言語に合わせるが、HIG と JLREQ の二系統に固定
- **Figma MCP を使わない**: 入力は CSS / Tailwind / DTCG / 画像に限る
- **採点式は固定**: Critical×12 / Serious×8 / Moderate×4 / Tip×1（Phase 4 試運転後に再調整余地あり、変更時は CHANGELOG）
- **第 20 カテゴリ「Japanese Typography」は和文判定が ON のときだけ採点に含める**

---

## ステータス

| Phase | 状態 |
|-------|------|
| 0. 雛形 | ✅ |
| 1. HIG ルーブリック | ✅ |
| 2. 和文ルーブリック | ✅ |
| 3. 採点式 + diff テンプレ + SKILL 本体 | ✅ |
| 4. 試運転 | 進行中 |
| 5. HTML レポート連携 | 未着手 |
