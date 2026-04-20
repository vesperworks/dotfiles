---
name: vw-docling
description: Convert PDF/DOCX/PPTX/HTML/images/URLs to Markdown (or JSON/HTML/Text) using the docling CLI. Use when the user asks to "convert to MD", "Markdown化", "PDFをMDに", "テキスト化", "doclingで変換", "ファイルをMarkdownに", or similar. Automatically selects options based on input characteristics (Japanese OCR, scanned PDFs, tables, formulas, images). When invoked standalone without input arguments (e.g. `/vw-docling` alone), MUST use the AskUserQuestion tool to collect input path, characteristics, and output directory before executing. After docling finishes, MUST perform a quality check (base64-stripped head/tail sample) and, if the output is empty or filled with garbled OCR artefacts (Cyrillic/Greek junk, meaningless symbol-only lines), MUST offer AIOCR fallback ("LLMでAIOCRしますか？") via AskUserQuestion — on accept, re-process with Claude Vision (Read tool on the PDF/image) and write `-rebuild.md` then cp over. NOT for audio/ASR transcription (whisper等) — do not invoke for audio input.
---

# vw-docling 変換ツール

PDF / DOCX / PPTX / HTML / 画像 / URL を Markdown（または JSON/HTML/Text）に変換する CLI ラッパー。ユーザーから「MDに変換」「テキスト化」「doclingで変換」等の依頼を受けたら、このスキルに従って `docling` を実行する。

## 前提

- 実行コマンド: `docling`（PATH 通過済み、v2.69.1 / uv tool 管理、`~/.local/bin/docling`）
- **初回実行時はモデル自動ダウンロードで数分かかる**。実行前にユーザーへその旨を伝える
- 起動直後の `OMP: Warning #179 Can't set size of /tmp file` は無害、無視してよい
- **出力先のデフォルトはソースファイルと同じディレクトリ**（元データと一緒に動かすユースケースが多いため）。ユーザーが明示的に別の場所を指定した場合のみそちらへ出す
- 出力ファイル名は `<入力basename>.<拡張子>` 固定（docling 側でリネーム不可）

## 基本形

```bash
# 単一ファイル: ソースと同じディレクトリに MD を出す（標準）
docling --output "$(dirname <入力>)" [オプション] <入力>

# 複数ファイルを一括: 入力 basename の親ディレクトリに戻す（下記シェル例参照）
```

- 入力: ローカルファイル / ディレクトリ / URL
- 対応入力: pdf, docx, pptx, html, image, csv, xlsx, asciidoc, md, xml_uspto, xml_jats, json_docling
- 対応出力: md（default）, json, yaml, html, text, doctags

**安全デフォルト**: 判断に迷う場合は `docling --output "$(dirname <入力>)" --ocr-lang ja,en <入力>`

### 複数ファイル一括変換（異なるディレクトリにまたがる場合）

`docling` の `--output` は 1 つのディレクトリしか指定できないため、複数のソースディレクトリを一度に変換する場合は **ディレクトリごとにコマンドを分ける** か、一時出力後に `mv` で戻す:

```bash
# パターンA: ディレクトリごとに分けて実行（推奨）
docling --output /path/to/dirA --ocr-lang ja,en /path/to/dirA/*.pdf
docling --output /path/to/dirB --ocr-lang ja,en /path/to/dirB/*.pdf

# パターンB: 一時出力 → mv で各ソース横に配置
docling --output /tmp/out --ocr-lang ja,en <入力群>
# その後 MD を元ディレクトリに戻す
```

## 意思決定チャート（入力の特徴 → 付けるオプション）

入力ファイルや要件から以下を判断してオプションを付加する。

| 入力の特徴 | 推奨オプション |
| :-- | :-- |
| 日本語PDF（文字情報あり） | `--ocr-lang ja,en` |
| スキャンPDF・画像化されたPDF | `--force-ocr --ocr-lang ja,en` |
| 表が重要な論文・帳票・レポート | `--table-mode accurate`（default のため省略可） |
| 速度優先で表はざっくりでよい | `--table-mode fast` |
| 画像も別ファイルで残したい | `--image-export-mode referenced` |
| テキストのみでよい（画像不要） | `--image-export-mode placeholder` |
| 数式を含む学術文書 | `--enrich-formula` |
| コードブロックを正確に抽出したい | `--enrich-code` |
| パスワード付き PDF | `--pdf-password '<パスワード>'` |
| Apple Silicon で高速化したい | `--device mps`（default の `auto` でも可） |
| CPU 固定したい | `--device cpu` |
| 大量ファイルを並列処理 | `--num-threads 8` 等に増やす |
| JSON で欲しい | `--to json` |
| HTML で欲しい | `--to html` |

## 典型ユースケース（そのまま実行可能）

```bash
# 日本語PDF → Markdown
docling --output ./out --ocr-lang ja,en input.pdf

# スキャンされた日本語PDF（全面OCR）
docling --output ./out --force-ocr --ocr-lang ja,en scanned.pdf

# 学術論文（数式・表を正確に）
docling --output ./out --enrich-formula --table-mode accurate --ocr-lang ja,en paper.pdf

# PPTX/DOCX → Markdown（OCR不要、速い）
docling --output ./out slides.pptx
docling --output ./out document.docx

# 画像を外部PNGとして書き出す
docling --output ./out --image-export-mode referenced report.pdf

# ディレクトリ一括変換
docling --output ./out ./sources/

# URL から取得して変換
docling --output ./out https://example.com/whitepaper.pdf

# JSON 出力（構造化データとして取り込みたい場合）
docling --output ./out --to json input.pdf
```

## Basic Workflow

### Step 0: 単体起動時の対話（入力未指定時のみ）

ユーザーが `/vw-docling` を引数なしで起動した、あるいは「doclingで変換して」とだけ言って対象を示さなかった場合は、**必ず AskUserQuestion ツールで以下を収集してから実行する**（推測で進めない）。

質問テンプレート例（全て1回の AskUserQuestion 呼び出しで聞く、最大4問）:

1. **入力**（`header: "入力"`）: 入力パス / URL を聞く。選択肢にはよく使うパス例（例: `~/Downloads/`）と「Other で自由入力」を用意
2. **言語・OCR特性**（`header: "OCR/言語"`）:
   - `日本語PDF（文字情報あり）` → `--ocr-lang ja,en`
   - `スキャンPDF（画像化）` → `--force-ocr --ocr-lang ja,en`
   - `英語中心` → オプション追加なし
   - `DOCX/PPTX/HTML（OCR不要）` → オプション追加なし
3. **重要視する要素**（`header: "重点", multiSelect: true`）:
   - `表（正確）` → `--table-mode accurate`（default、省略可）
   - `数式` → `--enrich-formula`
   - `コードブロック` → `--enrich-code`
   - `画像も別ファイル` → `--image-export-mode referenced`
4. **出力先**（`header: "出力先"`）: `ソースと同じディレクトリ（標準・推奨）` / `./out/`（カレント配下） / `~/Downloads/_converted/` / 「Other で自由入力」。デフォルトは先頭の「ソースと同じディレクトリ」を Recommended として提示する

ユーザー入力をもとに意思決定チャートと突き合わせて最終コマンドを構築し、実行前にコマンドを見せて確認を取る（初回はモデルDL待ちがあることも同時に伝える）。

### Step 1: 入力の確認

1. 入力がファイルパス / ディレクトリ / URL のいずれか確認
2. 拡張子または内容から対応形式かチェック
3. PDFの場合、文字情報あり / スキャンPDF（画像化）どちらか判断
4. 日本語を含むか確認

### Step 2: オプション決定

1. 意思決定チャートを参照してオプションを組み立てる
2. 判断に迷う場合は安全デフォルト（`--ocr-lang ja,en`）を採用
3. 出力先（`--output`）をユーザー指示または推奨先から決める

### Step 3: 実行

1. 初回の場合は「初回はモデルDLで数分かかります」と伝える
2. コマンドを実行
3. 失敗時は `--verbose` を付けて再実行、エラーログを確認

### Step 4: 品質チェック & AIOCR フォールバック（重要）

docling は **テキスト層ありのデジタルPDF / DOCX / PPTX / XLSX** では高品質だが、**スキャンPDF / 画像PDF / 画像ファイル** では内部 OCR（macOS では `ocrmac`）が日本語で崩壊しやすい。変換後は**必ず品質を確認**し、怪しければユーザーに AIOCR フォールバックを提案する。

#### 4.1 品質チェックコマンド（base64 画像を除外して本文サンプル表示）

```bash
for md in <生成された MD パス...>; do
  echo "=== $(basename "$md") ($(wc -c <"$md") bytes) ==="
  grep -v 'data:image/' "$md" | head -60
  echo "--- (中略) 末尾 ---"
  grep -v 'data:image/' "$md" | tail -15
done
```

※ docling の既定は `--image-export-mode embedded` のため、PDF/画像系は **base64 文字列でファイルが肥大** する。`grep -v 'data:image/'` で本文だけ抽出するのが品質判定のコツ。

#### 4.2 文字化け / 抽出失敗の兆候

以下を見つけたら **失敗扱い** にして AIOCR フォールバックを検討:

- **0 バイト**: テキスト層も OCR も失敗（最重要シグナル）
- **キリル文字 / ギリシャ文字の混入**: `Ф Ж Б Ц Ш α β` など、日本語文脈では絶対出ない文字が頻出
- **意味不明の記号短行連続**: `12235÷` `#**ШЖН` `Ф#ХФ*` `NNAHA` のような行
- **日本語文字率が極端に低い**: 本文サンプルにひらがな・カタカナ・漢字がほぼない
- **部分的失敗も NG**: 冒頭のタイトル/QRコード部のみ化け + 本文 OK のケースは AIOCR 不要、ただし一言ユーザーに共有

#### 4.3 成功ケース（AIOCR 不要）

- **テキスト層ありのデジタル PDF**（Ghostscript / Word / PPTX 出力 PDF）: docling の抽出精度はほぼ完璧
- **DOCX / PPTX / HTML**: OCR不要、構造もきれいに出る
- **XLSX**: テーブルがそのまま Markdown テーブルになる（空セルも維持）

#### 4.4 AIOCR フォールバックの提案（AskUserQuestion）

品質不良を検出したら必ず以下を聞く（勝手に進めない）。

```
質問: 「◯◯.pdf の docling 変換結果に文字化け / 空出力を検出しました。
      Claude Vision で AIOCR し直しますか？」
選択肢:
  - はい、AIOCR で作り直す（`-opus.md` として既存と共存・Recommended）
  - はい、AIOCR で作り直して既存 MD を上書きする
  - そのままにする（部分化けだけで本文は読めるなど）
```

#### 4.5 AIOCR の実行手順（ユーザー承諾時）

##### ステップ 1: ページ数と構造の把握

- `pdfinfo <pdf>` で **物理ページ数** を確認
- ⚠️ `pdfinfo` の Pages は **物理ページ数** であり、資料内のスライド番号（ページ番号）とは必ずしも一致しない。**1 物理ページに複数スライドが縦に詰め込まれたレイアウト** もあるため、読んだ結果見えるページ番号が飛ぶことがある
- 最初の Read が終わった段階で「どのページ番号が見えたか」を把握してから次の範囲を決めると漏れを防げる

##### ステップ 2: Read tool の分割戦略（32MB 制限への対処）

- Read tool は 1 リクエストあたり **合計 base64 画像サイズが約 32MB** を超えるとエラー。これは **ファイル単体サイズではなく、内部で画像展開した後の合計**
- 画像化後は 1 物理ページあたり 2〜5MB に膨らむため、**3 ページずつ `pages: "1-3"` / `"4-6"` / … で分割** するのが堅い
- 目安:
  - 〜9 物理ページ: `pages` 未指定で一発 Read を試す。エラーなら 3 ページ刻みにフォールバック
  - 10〜30 物理ページ: 最初から **3 ページ刻み** で複数回 Read
  - 画像リッチ・高解像度スキャン: 2 ページ刻みに落とす
- ファイル単体が数 MB 程度でもエラーが出たら、画像密度が高いサイン。分割数を増やして再試行

##### ステップ 3: Read（Claude Vision）で本文・表・図を読む

- 各 Read 呼び出しで見えたページ番号を都度メモし、**未取得ページがないか** を確認
- 物理ページとスライド番号がずれるレイアウトでは、見えたスライド番号のリストを作って飛び番を確認する

##### ステップ 4: Markdown 構築ルール（標準運用）

視覚要素の扱いは以下の方針で統一する。RAG・LLM 要約用途を前提とし、「見た目の再現」ではなく「意味の再現」を優先する。

- **写真**: `(写真: 〜の様子)` 形式で **意味のみを短く記述**。色・構図などビジュアル描写は最小限に
  - 例: `(写真: 人々が屋外で集まって談笑している様子)` / `(写真: 大型施設の外観)`
- **図・ダイアグラム・フロー図**: **構造を日本語で言語化**。矢印の向き、ボックス間の関係、数値の意味まで踏み込む
  - 例: `(図: 制度フロー。A が B に申請 → B が C に承認を仰ぐ → 結果を A に通知)`
- **円グラフ・棒グラフ**: グラフの見た目ではなく **数値を正確に表で再現**。傾向は「読み取りメモ」として 1〜2 行添える
- **アイコン・装飾**: 原則省略。意味を持つ場合のみ短く触れる
- **表**: Markdown table で忠実に再現（空セルも維持、注釈行も取りこぼさない）
- **スライド番号 / ページ番号**: 資料内の元番号を尊重して見出しに反映（物理ページ番号とズレる場合があるため注意）
- **表記ゆれや誤植を見つけたら**: 原本のまま転記したうえで、注釈で「原本の表記ゆれ／誤植の可能性」と明示する

##### ステップ 5: Write 先と命名（共存 vs 上書き）

4.4 のユーザー回答に応じて以下を使い分ける。

- **共存配置（`-opus.md`・標準推奨）**:
  - 同じディレクトリに `<basename>-opus.md` として書き出す
  - 既存 docling 版と比較検討でき、RAG に両方投入しても良い。docling 版が画像 base64 で肥大している場合、LLM 用には軽量な `-opus.md` が扱いやすい
- **上書き（`-rebuild.md` 経由）**:
  - 一旦 `$TMPDIR/claude/md-rebuild/<basename>-rebuild.md` に保存 → `cp` で元ディレクトリに上書き配置
  - 既存 MD と同名で直接 Write すると hook の内容検証で拒否される場合がある（特に元が 0 バイトだと "fabrication" と判定される）
  - `~/Downloads` / `~/Desktop` などサンドボックス外に書くときは `dangerouslyDisableSandbox: true` が必要

##### ステップ 6: 末尾に「総括メモ」を添える（推奨）

MD の末尾に以下を 3〜5 行で要約しておくと、後続の RAG・LLM 要約で「この MD がどの資料か」を即座に掴める。

- 資料全体の章立て（パートごとの役割）
- 主要数値・固有名詞のハイライト
- 読み手が最初に知るべき結論

#### 4.6 AIOCR が特に効くケース

- スキャン PDF（grayscale jpeg 埋め込みなど）で docling + ocrmac が崩壊したもの
- 画像ファイル（PNG / JPG、特に新聞紙面・チラシ・手書きメモ混在）
- 図表中心の PPTX → PDF（テキストボックス化されたスライド文字が読めていない）
- 既存 OCR が日本語非対応（tesseract jpn 未導入環境など）

#### 4.7 AIOCR が不要／過剰なケース

- テキスト層ありのデジタル PDF（docling で十分、再処理はコストの無駄）
- 1枚だけごく軽微な化け（冒頭 URL が崩れる程度）で本文 OK なもの
- 音声 / 動画（このスキルの対象外）

## 出力先の推奨

**標準: ソースファイルと同じディレクトリに MD を配置する**。元データと MD を一緒に動かす（RAG 投入、要約生成、アーカイブ）ユースケースが多いため、ソース横に置いておくのが最も使いやすい。

```bash
# 単一ファイル（推奨パターン）
docling --output "$(dirname /path/to/input.pdf)" --ocr-lang ja,en /path/to/input.pdf
# → /path/to/input.md が生成される
```

ユーザーが明示的に別の場所を指定した場合の選択肢:

- **一時的な確認用** → `./drafts/` または `./out/`
- **機密含みうる素材** → `.gitignore` 済みディレクトリ（例: `inbox/_converted/`）
- **参照用に残す** → `./references/`

画像を `--image-export-mode referenced` で出した場合、画像ファイルも同じ出力ディレクトリに展開される。

## 注意事項

- **機密情報**: 社外秘 PDF 等を変換する場合、出力先が Git 管理下でないか必ず確認する
- **初回DL待ち**: ユーザーに「初回はモデルDLで数分かかります」と伝えてから実行
- **URL認証**: 認証必要な URL は `--headers '{"Authorization":"Bearer ..."}'` を使う。機密トークンはログに残さない
- **大容量PDF**: 数百ページ級は `--num-threads 8` と `--device mps`（Apple Silicon）の併用で高速化
- **失敗時**: まず `--verbose` を付けて再実行してエラーログを確認
- **品質不良を検出したら必ず Step 4 の AIOCR フォールバック（Claude Vision 再処理）をユーザーに提案**（特に日本語スキャン / 画像ファイル系）

## 対象外

- **音声 / ASR（whisper系）には触れない**。音声ファイルが入力として渡された場合はこのスキルは適用しない
