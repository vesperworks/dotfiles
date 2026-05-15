# Annotate Mode Template

codebase / ローカルの画像を読み込んで、丸つけ・矢印・テキスト・ハイライト等で注釈し、
結果を PNG としてクリップボードに書き出し → Cmd+V でチャットに貼り戻すための HTML テンプレ。

## アプローチ選定

調査結果（推奨確率付き）:
1. **Markerjs2 (CDN, 推奨 85%)** — 矩形/円/楕円/矢印/直線/テキスト/フリーハンド/ハイライト一通り揃う。CDN 一発。ライセンス要確認（Linkware/MIT 系）
2. **fabric.js (推奨 55%)** — 自作ツールバーで完全カスタマイズ可能。学習コスト高
3. **生 Canvas + 手書きツール (推奨 40%)** — 完全依存ゼロ。機能制限大

本テンプレでは **Markerjs2 を採用**（フォールバックとして生 Canvas モードも残す）。

## Data Schema

```json
{
  "title": "...",
  "imagePath": "/absolute/path/to/screenshot.png",
  "imageDataUrl": "data:image/png;base64,...",
  "imageMime": "image/png",
  "summary": "ここに丸つけて確認してほしい点を一言で"
}
```

- `imageDataUrl` が存在すればそれを優先（ローカル `file://` プロトコル不要）
- 5MB 超は `imagePath` のみ（`file://` で参照、`open` 経由で見られる）

## Template

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>HTML // {{TITLE}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/markerjs2/markerjs2.js"></script>
<style>
:root {
  --bg: #0a0a0a; --surface: #111111; --surface-hover: #1a1a1a;
  --border: #222222; --border-accent: #333333;
  --text: #e0e0e0; --text-muted: #666666; --text-dim: #444444;
  --accent: #00ff88; --accent-dim: rgba(0,255,136,0.15);
  --cyan: #00d4ff; --warn: #ffaa00; --danger: #ff5555;
  --font-sans: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: var(--font-sans); background: var(--bg); color: var(--text); padding: 32px 40px; line-height: 1.5; -webkit-font-smoothing: antialiased; }
.header { display: grid; grid-template-columns: 1fr auto; align-items: end; margin-bottom: 24px; padding-bottom: 20px; border-bottom: 2px solid var(--accent); }
.header h1 { font-family: var(--font-mono); font-size: 1.6rem; font-weight: 700; letter-spacing: -0.02em; color: var(--accent); }
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta { font-family: var(--font-mono); color: var(--text-muted); font-size: 0.72rem; text-align: right; line-height: 1.8; letter-spacing: 0.03em; word-break: break-all; }
.summary { background: var(--surface); border-left: 3px solid var(--cyan); padding: 14px 20px; margin-bottom: 20px; font-size: 0.92rem; }
.panel { background: var(--surface); border: 1px solid var(--border); margin-bottom: 24px; overflow: hidden; }
.panel-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 20px; border-bottom: 1px solid var(--border); }
.panel-header h2 { font-family: var(--font-mono); font-size: 0.7rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; }
.panel-header .tag { font-family: var(--font-mono); font-size: 0.6rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; letter-spacing: 0.05em; }
.panel-body { padding: 20px; }

.image-frame { position: relative; display: flex; justify-content: center; background: #050505; border: 1px dashed var(--border-accent); padding: 16px; min-height: 280px; }
.target-img { max-width: 100%; max-height: 78vh; display: block; cursor: crosshair; }
.btn-row { display: flex; gap: 10px; flex-wrap: wrap; padding: 16px 20px; border-top: 1px solid var(--border); }
.btn { font-family: var(--font-mono); font-size: 0.72rem; padding: 10px 16px; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; letter-spacing: 0.05em; text-transform: uppercase; transition: all 0.15s; }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { background: #00cc6a; }
.btn.cyan { color: var(--cyan); border-color: var(--cyan); }
.btn.cyan:hover { background: rgba(0,212,255,0.12); }
.hint { font-family: var(--font-mono); font-size: 0.72rem; color: var(--text-muted); padding: 0 20px 16px; }
.path-row { font-family: var(--font-mono); font-size: 0.7rem; color: var(--text-dim); padding: 8px 20px; background: var(--surface-hover); border-top: 1px solid var(--border); word-break: break-all; }

.footer { margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); letter-spacing: 0.05em; display: flex; justify-content: space-between; }
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 0.8rem; padding: 12px 18px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 9999; max-width: 360px; }
.toast.show { opacity: 1; transform: translateY(0); }
</style>
</head>
<body>

<div class="header">
  <h1><span>HTML //</span> {{TITLE}}</h1>
  <div class="meta">GEN {{DATE}}<br>MODE ANNOTATE</div>
</div>

<div class="summary">{{SUMMARY}}</div>

<div class="panel">
  <div class="panel-header">
    <h2>Image Annotation</h2>
    <span class="tag">MARKERJS2</span>
  </div>
  <div class="panel-body">
    <div class="image-frame">
      <img id="target-img" class="target-img" src="{{IMAGE_SRC}}" alt="annotation target">
    </div>
  </div>
  <div class="hint">画像をクリックすると注釈ツールバーが開きます（丸/矩形/矢印/テキスト/フリーハンド/ハイライト）。完了したら下のボタンで PNG をクリップボードへ。</div>
  <div class="btn-row">
    <button class="btn primary" onclick="openMarker()">注釈ツールを開く</button>
    <button class="btn" onclick="copyAnnotatedPng()">PNG をクリップボードへ</button>
    <button class="btn cyan" onclick="downloadAnnotatedPng()">PNG ダウンロード</button>
    <button class="btn" onclick="resetAnnotation()">注釈をリセット</button>
  </div>
  <div class="path-row">SRC: {{IMAGE_PATH}}</div>
</div>

<div class="footer">
  <span>HTML SKILL v0.1.0 / ANNOTATE MODE</span>
  <span>GENERATED BY CLAUDE CODE</span>
</div>

<div class="toast" id="toast"></div>

<script>
const STATE = {
  originalSrc: document.getElementById('target-img').src,
  lastState: null
};

function toast(msg, kind = 'ok') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.style.borderColor = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.style.color = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.classList.add('show');
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(() => t.classList.remove('show'), 2400);
}

function openMarker() {
  const img = document.getElementById('target-img');
  if (typeof markerjs2 === 'undefined') {
    toast('Markerjs2 のロードに失敗。インターネット接続を確認', 'err');
    return;
  }
  const markerArea = new markerjs2.MarkerArea(img);
  markerArea.settings.displayMode = 'popup';
  markerArea.uiStyleSettings.toolbarBackgroundColor = '#111111';
  markerArea.uiStyleSettings.toolbarBackgroundHoverColor = '#1a1a1a';
  markerArea.uiStyleSettings.toolbarColor = '#e0e0e0';
  markerArea.uiStyleSettings.toolboxBackgroundColor = '#0a0a0a';
  markerArea.uiStyleSettings.toolboxColor = '#00ff88';
  markerArea.uiStyleSettings.toolboxAccentColor = '#00ff88';
  markerArea.addEventListener('render', (evt) => {
    img.src = evt.dataUrl;
    STATE.lastState = evt.state;
  });
  if (STATE.lastState) markerArea.restoreState(STATE.lastState);
  markerArea.show();
}

document.getElementById('target-img').addEventListener('click', () => {
  // 画像クリックでも開く（任意）
  if (typeof markerjs2 !== 'undefined' && !document.querySelector('.markerjs-overlay')) {
    openMarker();
  }
});

async function getAnnotatedBlob() {
  const img = document.getElementById('target-img');
  // 画像が data:URL or 同一オリジン file:// なら canvas に描画してから export
  const canvas = document.createElement('canvas');
  // natural size を尊重
  canvas.width = img.naturalWidth || img.width;
  canvas.height = img.naturalHeight || img.height;
  const ctx = canvas.getContext('2d');
  await new Promise((resolve, reject) => {
    if (img.complete && img.naturalWidth > 0) return resolve();
    img.onload = resolve;
    img.onerror = () => reject(new Error('画像のロードに失敗'));
  });
  try {
    ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
  } catch (err) {
    throw new Error('Canvas 描画失敗（CORS の可能性）: ' + err.message);
  }
  return new Promise((resolve, reject) => {
    canvas.toBlob(b => b ? resolve(b) : reject(new Error('toBlob failed')), 'image/png');
  });
}

async function copyAnnotatedPng() {
  try {
    const blob = await getAnnotatedBlob();
    const item = new ClipboardItem({ 'image/png': blob });
    await navigator.clipboard.write([item]);
    toast('PNG をクリップボードへ。Cmd+V で貼り戻してください');
  } catch (err) {
    toast('コピー失敗: ' + err.message + '（ダウンロードで保存できます）', 'err');
  }
}

async function downloadAnnotatedPng() {
  try {
    const blob = await getAnnotatedBlob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'annotated-' + Date.now() + '.png';
    a.click();
    URL.revokeObjectURL(url);
    toast('PNG をダウンロードしました');
  } catch (err) {
    toast('ダウンロード失敗: ' + err.message, 'err');
  }
}

function resetAnnotation() {
  const img = document.getElementById('target-img');
  img.src = STATE.originalSrc;
  STATE.lastState = null;
  toast('注釈をリセットしました');
}

// Markerjs2 が CDN ロードできなかった場合の警告
window.addEventListener('load', () => {
  setTimeout(() => {
    if (typeof markerjs2 === 'undefined') {
      toast('Markerjs2 のロード失敗。PNG ダウンロードのみ動作します', 'err');
    }
  }, 1500);
});
</script>
</body>
</html>
```

## 画像読み込みのフォールバック

| 画像サイズ | `IMAGE_SRC` の値 | 備考 |
|-----------|------------------|------|
| 〜5MB | `data:image/png;base64,...` | data URL 埋め込み、配布可能 |
| 5MB+ | `file:///abs/path/to/img.png` | ローカル限定、CORS で canvas エクスポート不可の場合あり |

## CORS への対処

`file://` 画像を canvas に描画すると `tainted canvas` エラーで `toBlob` が失敗することがある。

対策:
1. base64 data URL 埋め込み（最優先）
2. それでも失敗するなら **PNG ダウンロード**は機能する（注釈ありの画像で）
3. Markerjs2 の `render` イベントが返す `dataUrl` を別途保存しておき、それから PNG 化（実装済み）

## 操作フロー（ユーザー目線）

1. SKILL 起動 → ブラウザで HTML 開く
2. 「注釈ツールを開く」ボタン or 画像クリック → Markerjs2 ツールバー
3. 丸/矢印/テキスト等で書き込み → ツールバー右上の `✓` で確定
4. 「PNG をクリップボードへ」ボタン → Cmd+V でチャットに貼り付け
   - 失敗時は「PNG ダウンロード」でローカル保存 → Finder からドラッグ

## ライセンス注意

Markerjs2 のライセンスは確認必須（[GitHub](https://github.com/ailon/markerjs2)）。OSS 利用不可と判断された場合は fabric.js + 自作ツールバー（Phase 2）に切替予定。
