---
name: vw-fin-calendar
description: "財務諸表（PL/BS/CF）のデータを入力すると、「会計の地図」/図解総研スタイルの視覚的な図解（PLウォーターフォール・BS左右対照ブロック・CFブリッジチャート）を使い、12ヶ月分を月次カレンダーグリッドでレイアウトした、スクロール可能な self-contained HTML レポートを生成するスキル。カードクリックで月次詳細図解にズームイン。複数期間（四半期・年度等）分の期末BSデータがあれば、資産・負債の膨らみ方を横並びの積み上げ棒グラフ＋テーブルで比較する「推移タイムラインビュー」にトグル切替できる。トリガー: 「財務諸表を可視化して」「決算書をカレンダー形式で見せて」「PL/BS/CFをグラフィカルに」「月次の経営数字をHTMLで」「BS推移を比較して」「複数期間を並べて見せて」「/vw-fin-calendar」。NOT for 単なる表形式の集計・関数計算（document-skills:xlsx 参照）、NOT for PDF/画像からのテキスト抽出のみが目的の場合（vw-docling 参照。本スキルは抽出後の可視化を担当）、NOT for 会話の状況整理やフロー図（html スキル参照）。"
argument-hint: [財務データ or ファイルパス]
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
model: sonnet
---

# 財務諸表マンスリーカレンダー可視化

## Core Purpose

財務諸表（損益計算書 PL / 貸借対照表 BS / キャッシュフロー計算書 CF）の月次データを解析し、12ヶ月分を1枚のカレンダーグリッド（Q1〜Q4の四半期ごとにグルーピング表示）に並べ、各月をクリックすると詳細な図解にズームインできる、単一 HTML ファイルのレポートを生成する。数値の羅列ではなく「面積・長さで増減と健全性を直感的に伝える」ことを目的とする。複数期間分の期末BSデータがあれば、推移タイムラインビューにトグル切替でき、こちらもホバーで費目説明・関連ブロックのハイライトが効く。

## Quick Checklist（初期応答で必ず確認）

- [ ] 入力データの形式（テキスト貼り付け / CSV / JSON / PDF / 画像 / スプレッドシート）
- [ ] 対象年度・何月始まりか（1月始まり or 会計年度4月始まり等）
- [ ] 単位（円 / 千円 / 百万円）
- [ ] 前年同月データの有無（YoY バッジ表示に使う。無ければ省略）
- [ ] 複数期間（四半期・年度等）のBS推移比較を含めるか。含める場合、過去何期分の期末BSデータがあるか・どの形式か（ユーザーが別途添付する想定。本スキル単体では過去データを遡って収集しない）
- [ ] 出力先（プロジェクト内なら `.brain/report/`、無ければ `$TMPDIR`）

## Basic Workflow

### Step 1: 入力データの受け取りと解析

1. ユーザー入力を確認:
   - **テキスト貼り付け/CSV/JSON**: そのまま解析
   - **PDF/画像（決算書スキャン等）**: 先に `vw-docling` スキルまたは `Read` ツール（画像は Claude Vision で直接読み取り可）でテキスト化してから本スキルに渡す。本スキル単体では OCR は行わない
   - **xlsx**: `document-skills:xlsx` で該当シートを読み取ってから渡す
2. 勘定科目を以下の標準スキーマにマッピングする。科目名の表記ゆれ（例:「売上高」「営業収益」「純売上」等）は文脈で判断し、不明な場合は AskUserQuestion で確認
3. 12ヶ月に満たないデータの場合、欠損月は `{ month, empty: true }` として保持する（**12枚固定でレイアウトする。ある月だけ表示しない** — 年間比較ができなくなるため）
4. `months` 配列は必ず「会計年度の開始月から始まる12ヶ月」の順で並べる。カレンダーグリッドは表示時にこの配列順を3ヶ月ずつ Q1〜Q4 にグルーピングする（実際の月番号や決算月からは計算しない）ため、並び順が崩れるとQ区切りもずれる

### Step 2: 月次データの構造化（JSON）

```json
{
  "company": "string",
  "unit": "円 | 千円 | 百万円",
  "fiscalYear": "2026",
  "months": [
    {
      "month": "2026-01",
      "yoy": 108,
      "pl": { "revenue": 0, "cogs": 0, "grossProfit": 0, "sga": 0, "operatingIncome": 0, "nonOperating": 0, "ordinaryIncome": 0, "extraordinary": 0, "netIncome": 0 },
      "bs": { "currentAssets": 0, "fixedAssets": 0, "totalAssets": 0, "currentLiabilities": 0, "fixedLiabilities": 0, "totalLiabilities": 0, "equity": 0 },
      "cf": { "operating": 0, "investing": 0, "financing": 0, "cashBegin": 0, "cashEnd": 0 }
    }
  ],
  "periods": [
    {
      "label": "2026年3月期",
      "bs": { "currentAssets": 0, "fixedAssets": 0, "totalAssets": 0, "currentLiabilities": 0, "fixedLiabilities": 0, "totalLiabilities": 0, "equity": 0 }
    }
  ],
  "timelineSummary": "string"
}
```

- `periods` / `timelineSummary` は任意（複数期間のBS推移比較を含める場合のみ）。無ければタイムラインビューのトグル自体が非表示になる
- `periods[].label` は期間の表示ラベル（例:「2026年3月期」「2026年3月期 Q1」）。会計年度の開始月は企業により異なるため、四半期の区切り計算はテンプレート側で行わず、呼び出し側が文字列としてそのまま渡す
- `periods` は `months` とは独立したデータ（複数年度にまたがる期末BSの比較用）。`months` の会計恒等式検算とは別に、`periods[].bs` 内でも `totalAssets == totalLiabilities + equity` を検算する

- 会計恒等式の検算を行う: `totalAssets == totalLiabilities + equity`、`cashBegin + operating + investing + financing == cashEnd`。ずれがある場合はユーザーに提示し、丸め誤差か入力ミスか確認する（無視して進めない）
- PL 内部整合性も検算する: `grossProfit == revenue - cogs`、`operatingIncome == grossProfit - sga`、`ordinaryIncome == operatingIncome + nonOperating`、`netIncome == ordinaryIncome + extraordinary`。元データに税金が独立科目である場合は `extraordinary` に合算してから検算する（PL 分解図は「売上 = 費用 + 純利益」の相殺を左右の帯の高さ一致で表現するため、内部整合が崩れていると図が歪む）
- PL/BS/CF いずれかのデータが月によって欠けている場合、そのブロックのみ非表示にし他は描画する

### Step 3: HTML 生成（テンプレート置換方式 — HTML/JS を書き起こさない）

**HTMLやJavaScriptを自分で書いてはならない。** 完成済み・テスト済みの [references/calendar-template.html](./references/calendar-template.html) をコピーし、プレースホルダだけを機械的に置換する。モデルの仕事は Step 1〜2 のデータマッピングのみ。

1. Step 2 の JSON を一時ファイル（例: `$TMPDIR/claude/fin-calendar/data.json`）に `Write` で保存する
2. 以下の Python ワンライナーで置換・出力する（`sed` は JSON 内のエスケープで事故るため使わない）:

```bash
python3 - "$SKILL_DIR/references/calendar-template.html" "$DATA_JSON_PATH" "$OUT_PATH" <<'EOF'
import json, sys, datetime
tpl_path, data_path, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
tpl = open(tpl_path, encoding="utf-8").read()
data = json.load(open(data_path, encoding="utf-8"))
summary = data.pop("_summary", "")  # サマリー文は data JSON の _summary キーで渡す
html = (tpl
  .replace("{{COMPANY}}", data["company"])
  .replace("{{FISCAL_YEAR}}", data["fiscalYear"])
  .replace("{{UNIT}}", data["unit"])
  .replace("{{DATE}}", datetime.datetime.now().strftime("%Y-%m-%d %H:%M"))
  .replace("{{SUMMARY}}", summary)
  .replace("{{DATA_JSON}}", json.dumps(data, ensure_ascii=False)))
open(out_path, "w", encoding="utf-8").write(html)
print("wrote", out_path)
EOF
```

3. プレースホルダは6種のみ: `{{COMPANY}}` `{{FISCAL_YEAR}}` `{{UNIT}}` `{{DATE}}` `{{SUMMARY}}` `{{DATA_JSON}}`。`{{SUMMARY}}` にはデータから読み取れる特徴（成長傾向・赤字月・欠損月等）を1〜3文の日本語で書く。`periods` / `timelineSummary` は（`_summary` と異なり）`data.pop()` せず `{{DATA_JSON}}` に含めたまま渡す（テンプレート側 JS が `FIN_DATA.periods` / `FIN_DATA.timelineSummary` として直接参照するため）
4. 置換後、`grep -c '{{' $OUT_PATH` が 0 であることを確認する（置換漏れ検知）
5. テンプレート自体の改修が必要な場合のみ、ビジュアル文法は [references/financial-visual-grammar.md](./references/financial-visual-grammar.md)、実装解説は [references/calendar-template.md](./references/calendar-template.md) を参照する（通常の生成では読む必要はない）

### Step 4: 保存と自動 open（`html` スキルと同じロジック）

1. 出力先: プロジェクト配下なら `.brain/report/{YYYY-MM-DD-HHmm}-fin-calendar-{company}.html`、無ければ `$TMPDIR/claude/fin-calendar/{YYYY-MM-DD-HHmm}.html`
2. `Write` で保存後、**必ず** `open {file_path}` を実行してブラウザ表示する
   - `dangerouslyDisableSandbox: true` で実行する（macOS の `open` は sandbox 内で `NSOSStatusErrorDomain Code=-600` になるため。経路上の制約であり権限の問題ではない）
   - 失敗時のみパスを stdout に出し「ターミナルで open してください」と案内
3. 結果サマリーを出力: 対象年度、月数（欠損月数含む）、ファイルパス

## Output Deliverables

- `.brain/report/{timestamp}-fin-calendar-{company}.html`（自己完結、CDN は Google Fonts のみ）
- 生成後の自動ブラウザ起動

## Rollback / Recovery（誤った財務データで生成した場合）

- 生成物は単一 HTML ファイルなので `trash {path}` で破棄すればよい（元データや他ファイルへの影響なし）
- 会計恒等式の検算エラーが出た場合は再生成前に必ずユーザーに数値を再確認する（誤った図解を「わかりやすい」まま出さない）

## Advanced References

- **[calendar-template.html](./references/calendar-template.html) — 正規ソース。完成済み・ブラウザテスト済みの単一HTMLテンプレート（プレースホルダ6種）。通常の生成ではこれをコピー置換するだけでよい**
- [Financial Visual Grammar](./references/financial-visual-grammar.md) — PL/BS/CF の図解ルール、カラートークン（テンプレート改修時のみ参照）
- [Calendar Template 解説](./references/calendar-template.md) — グリッド・モーダル・SVG生成ロジックの設計解説（テンプレート改修時のみ参照）
- [html スキル design-system.md](../html/references/design-system.md) — 共通カラープリセット・グリッド・CSS/JS基盤（本スキルのテンプレートはこれを焼き込み済み）
