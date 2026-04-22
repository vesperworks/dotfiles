---
name: vw-docling
description: Convert PDF/DOCX/PPTX/HTML/images/URLs to Markdown (or JSON/HTML/Text) using the docling CLI. Use when the user asks to "convert to MD", "Markdown化", "PDFをMDに", "テキスト化", "doclingで変換", "ファイルをMarkdownに", or similar. Automatically selects options based on input characteristics (Japanese OCR, scanned PDFs, tables, formulas, images). When invoked standalone without input arguments (e.g. `/vw-docling` alone), MUST use the AskUserQuestion tool to collect input path, characteristics, and output directory before executing. NOT for audio/ASR transcription (whisper等) — do not invoke for audio input.
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

## 対象外

- **音声 / ASR（whisper系）には触れない**。音声ファイルが入力として渡された場合はこのスキルは適用しない
