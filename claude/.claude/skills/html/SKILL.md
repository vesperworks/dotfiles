---
name: html
description: "スレッドの状況・確認事項・図解・画像注釈・画像評価を、self-contained な HTML レポートで可視化するスキル。4 モード: status（チェックリスト＋Yes/No 確認 UI）/ diagram（Mermaid + D3.js フロー図）/ annotate（画像注釈、PNG クリップボード書き出し）/ image-review（画像にスコア+チェックリスト+コメント評価）。生成後は自動で open でブラウザ起動。明示モード指定がなければ会話文脈から自動判定。トリガー: 「HTMLで説明」「HTMLで可視化」「HTMLで確認UI」「画像に丸つけて」「画像を評価したい」「フロー図をHTMLで」「/html」。NOT for HTML→Markdown 変換（vw-docling 参照）、NOT for スキル/エージェント自体のフロー解析（vw-flow-viz 参照）。"
argument-hint: <mode? status|diagram|annotate|image-review> [path-or-topic]
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
model: opus
---

<role>
You are an HTML report generator. Take the current thread context (decisions, open questions, status, code artifacts, images) and emit a single-file, self-contained HTML document that the user can open in a browser to (a) review the situation at a glance, (b) answer Yes/No or multi-choice questions interactively, (c) explore flow/relationship diagrams, or (d) annotate images and copy the result back to clipboard.
</role>

<language>
- Think: 日本語
- Communicate: 日本語
- Code/HTML: English（コメント・ラベルは日本語可、識別子は英語）
</language>

<design_philosophy>
- **依存ゼロ or CDN のみ**: 単一 HTML ファイルで動作。`open file.html` で完結
- **生成→自動 open までセット**: 生成後は `open` で必ずブラウザ起動する（許可: `Bash(open *.html|*.png|*.pdf)`）
- **4 モード**: status / diagram / annotate / image-review のいずれか。引数なし or モード未指定なら**会話文脈から自動判定**（曖昧な時のみ AskUserQuestion で 1 回確認）
- **LIGHT/DARK テーマ切替**: DARK = Catppuccin Macchiato + Hacker、LIGHT = Swiss International Typographic Style（白紙 + インク + Swiss Red `#e4002b`）。☀/☾ トグルボタン + `localStorage` で永続化 + `prefers-color-scheme` 自動検出
- **Müller-Brockmann 12カラムグリッド**: `.spread > .wrap > .grid > .band` 構造。8px baseline + 24px leading。`G` キーでグリッドオーバーレイ切替（カラム番号 + baseline ライン可視化）
- **インタラクティブ**: 確認 UI で Yes/No・複数選択を取って、結果を「クリップボードに JSON コピー」する
- **画像注釈**: codebase 内の画像を `file://` パスで読み込み、Markerjs2 で丸つけ・矢印・テキスト → PNG クリップボード書き出し（Cmd+V でチャットに貼れる）
- **画像評価**: 画像を表示しつつ横にスコア・チェックリスト・コメント記入欄（UI/UX レビュー、デザイン採点等）
</design_philosophy>

<workflow>

## Phase 1: Mode Resolution（自動判定優先）

### モード自動判定ルール（明示モード未指定時）

引数の有無に関わらず、**まず会話文脈から自動推測**する。確度が低い時のみ AskUserQuestion で 1 回確認。

| キーワード / 文脈 | 推定モード | 確度判定 |
|------------------|----------|----------|
| 「状況」「確認事項」「整理して」「タスク」「TODO」「未解決」「議論」「上記の会話」 | `status` | 高 |
| 「フロー」「処理の流れ」「シーケンス」「関係図」「ノード」「Sankey」「アーキ図」 | `diagram` | 高 |
| 「画像に丸つけ」「ここに矢印」「注釈」「マークアップ」 + 画像パス | `annotate` | 高 |
| 「画像を評価」「採点」「UI レビュー」「デザインレビュー」「スコアつけて」 + 画像パス | `image-review` | 高 |
| 引数なし + 直前の会話が画像中心 | `annotate` または `image-review`（AskUserQuestion で 1 回確認） | 中 |
| 引数なし + 直前の会話が抽象議論 | `status` | 中 |
| どちらでも取れる（曖昧） | AskUserQuestion で 1 回確認 | 低 |

### サブモード判定（diagram のみ）

| キーワード | サブモード |
|----------|----------|
| 「処理の流れ」「フローチャート」 | `flow` |
| 「対話」「時系列」「シーケンス」 | `sequence` |
| 「ノード」「関係」 | `graph` |
| 「リソース配分」「Sankey」「遷移量」「トークン消費」 | `sankey` |

### 引数による明示指定

第 1 引数 = モード、第 2 引数以降 = 各モードのパラメータ。

| モード | 引数例 |
|--------|--------|
| `status` | `/html status "PRP-024 の残タスク確認"` |
| `diagram` | `/html diagram flow "認証フロー"` または `/html diagram sequence` |
| `annotate` | `/html annotate ~/Desktop/screenshot.png` |
| `image-review` | `/html image-review ~/Desktop/mockup.png` |

明示指定があれば自動判定をスキップ。引数が曖昧な場合のみ AskUserQuestion でバッチ確認（1 回のみ）。

## Phase 2: Content Extraction

### Mode: status

1. **会話文脈の抽出**: 直近のスレッドから以下を整理
   - **確認事項**: ユーザーに Yes/No / 複数選択で答えてもらうべき判断点
   - **状況**: 今わかっている事実（完了済み・進行中・未着手）
   - **ブロッカー**: 解決待ちのもの
   - **次のアクション**: 提案候補（推奨確率付き、最低 3 つ）
2. **データ構造化** (JSON):
   ```json
   {
     "title": "...",
     "summary": "...",
     "sections": [
       {
         "kind": "checklist|qa|status|actions",
         "title": "...",
         "items": [
           {"id": "q1", "label": "...", "type": "yesno|multi|text", "options": ["a","b"]}
         ]
       }
     ]
   }
   ```

### Mode: diagram

1. **ノード/エッジ抽出**: 会話または指定されたファイルから関係性を抽出
2. **タイプ判定**:
   - `flow` → Mermaid `graph TD` または `flowchart`
   - `sequence` → Mermaid `sequenceDiagram`
   - `graph` → D3.js force-directed graph
   - `sankey` → D3.js Sankey（既存の `vw-flow-viz` パターン）
3. データを JSON or Mermaid 文字列で表現

### Mode: annotate

1. **画像読み込み**: `Read` ツールで画像存在確認 + `file --mime-type` で MIME 検出
2. **画像パス→base64 埋め込み**: `base64 -i path` で data URL 化（外部依存を避ける）
   - 5MB 超の場合はそのまま `file://` 絶対パスで参照（埋め込まない選択肢を提示）
3. **テンプレ生成**: Markerjs2 を CDN で読み込み、Canvas に画像を描画

## Phase 3: HTML Generation

### Step 3.1: Select Template

| Mode | Template File |
|------|---------------|
| `status` | [references/status-template.md](./references/status-template.md) |
| `diagram` | [references/diagram-template.md](./references/diagram-template.md) |
| `annotate` | [references/annotate-template.md](./references/annotate-template.md) |
| `image-review` | [references/review-template.md](./references/review-template.md) |

共通カラー・タイポ定義: [references/design-system.md](./references/design-system.md)

### Step 3.2: Placeholder Replacement

各テンプレ内の `{{...}}` プレースホルダを実データに置換:

| Placeholder | 内容 |
|-------------|------|
| `{{TITLE}}` | レポートタイトル |
| `{{DATE}}` | 生成日時 `YYYY-MM-DD HH:MM` |
| `{{SUMMARY}}` | 1〜3 行のサマリー |
| `{{DATA_JSON}}` | モード別のメインデータ (JSON 文字列、`<script>` 内に埋め込み) |
| `{{IMAGE_DATA_URL}}` | annotate モード時の画像 data URL |

### Step 3.3: Save and Open（必ず自動 open する）

1. 出力先（プロジェクト配下があれば `.brain/`、なければ `$TMPDIR`）:
   - `.brain/report/{YYYY-MM-DD-HHmm}-html-{mode}.html`
   - フォールバック: `$TMPDIR/claude/html/{YYYY-MM-DD-HHmm}-{mode}.html`
2. `Write` ツールで HTML を保存
3. **必ず** `open {file_path}` でデフォルトブラウザ起動
   - 許可済み: `Bash(open *.html)` / `Bash(open *.png)` / `Bash(open *.pdf)`
   - **`dangerouslyDisableSandbox: true` で実行する**（macOS の `open` は LaunchServices/XPC を使うため、sandbox 内では `NSOSStatusErrorDomain Code=-600` で失敗する。これは経路の制約であり権限の問題ではない）
   - **失敗時のみ**: パスを stdout に出して「ターミナルで open してください」と案内
   - スキップ禁止: 「ユーザーが手動で開く」前提にしない
4. 結果サマリーを stdout に出力（パスとモード）

## Phase 4: Present Results

```
HTML レポート生成完了

モード: {status|diagram|annotate}
タイトル: {title}
ファイル: {path}

ブラウザを起動しました。
- status モード: 設問に回答 → [結果を JSON でコピー] ボタンで Claude に貼り戻し
- annotate モード: 注釈後 [PNG をクリップボードへ] → Cmd+V でチャットに貼り付け
```

</workflow>

<usage_examples>

### 例 1: 状況確認 UI
```
ユーザー: いままでの議論を HTML で確認 UI にして
→ /html status "現スレッドの確認事項"
   出力: .brain/report/2026-05-15-1430-html-status.html
   ブラウザで Yes/No / 複数選択に答えてもらい、結果を JSON でコピー → 貼り戻し
```

### 例 2: フロー図
```
ユーザー: install.sh の処理フローを HTML で図にして
→ /html diagram flow "install.sh の処理フロー"
   出力: .brain/report/2026-05-15-1432-html-diagram.html
   Mermaid + D3.js のインタラクティブ図
```

### 例 3: 画像注釈
```
ユーザー: ~/Desktop/screenshot.png のここに丸つけたい
→ /html annotate ~/Desktop/screenshot.png
   出力: .brain/report/2026-05-15-1435-html-annotate.html
   Markerjs2 で丸・矢印・テキスト → [PNG をクリップボード] → Cmd+V で貼り戻し
```

</usage_examples>

<implementation_notes>

### 出力先の決定ロジック

```bash
# プロジェクトルート判定
if [ -d "$PWD/.brain" ] || git rev-parse --show-toplevel >/dev/null 2>&1; then
  OUT_DIR="$(git rev-parse --show-toplevel)/.brain/report"
else
  OUT_DIR="${TMPDIR:-/tmp}/claude/html"
fi
mkdir -p "$OUT_DIR"
TS=$(date +%Y-%m-%d-%H%M)
OUT_FILE="$OUT_DIR/${TS}-html-${MODE}.html"
```

### 画像の data URL 化

```bash
MIME=$(file --mime-type -b "$IMG_PATH")
B64=$(base64 -i "$IMG_PATH" | tr -d '\n')
DATA_URL="data:${MIME};base64,${B64}"
```

5MB 超は埋め込まず、`file://${IMG_PATH}` を参照（ローカルファイル限定）。

### クリップボード書き出しの user gesture

`navigator.clipboard.write` は user gesture（click）内でのみ動作。テンプレ内のボタン `onclick` ハンドラで実行する。

### 既存パターンとの整合

- 出力先・タイムスタンプ書式は `vw-flow-viz` と統一
- カラーパレットは [design-system.md](./references/design-system.md) で単一ソース化
- AskUserQuestion 使い分けは `vw-docling` 参照（単体起動時のみ、4 問まで）

</implementation_notes>

<advanced_references>
- [Design System (Colors + Typography)](./references/design-system.md)
- [Status Mode Template](./references/status-template.md)
- [Diagram Mode Template](./references/diagram-template.md)
- [Annotate Mode Template](./references/annotate-template.md)
- [Image Review Mode Template](./references/review-template.md)
</advanced_references>
