# Annotate Mode Template

codebase / ローカルの画像を読み込んで、丸つけ・矢印・テキスト・ハイライト等で注釈し、
結果を PNG としてクリップボードに書き出し → Cmd+V でチャットに貼り戻すための HTML テンプレ。

Müller-Brockmann 12カラムグリッド + LIGHT/DARK テーマ切替対応。

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
<html lang="ja" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>HTML // {{TITLE}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
<script src="https://cdn.jsdelivr.net/npm/markerjs2/markerjs2.js"></script>
<style>
/* ===== Theme + Grid tokens ===== */
:root, [data-theme="dark"] {
  --cols: 12; --bl: 8px; --lh: 24px; --gutter: 24px; --margin: 48px; --maxw: 1200px; --pad: 48px;
  --font-sans: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
  --bg: #0a0a0a; --surface: #111111; --surface-hover: #1a1a1a;
  --border: #222222; --border-accent: #333333;
  --text: #e0e0e0; --text-muted: #666666; --text-dim: #444444;
  --accent: #00ff88; --accent-dim: rgba(0,255,136,0.15);
  --cyan: #00d4ff; --cyan-dim: rgba(0,212,255,0.15);
  --warn: #ffaa00; --danger: #ff5555; --purple: #cc44ff;
  --g-col: rgba(0,255,136,0.05); --g-edge: rgba(0,255,136,0.25);
  --g-base: rgba(0,212,255,0.18); --g-base-min: rgba(0,212,255,0.06);
}
[data-theme="light"] {
  --bg: #ffffff; --surface: #f4f4f4; --surface-hover: #eaeaea;
  --border: #d4d4d4; --border-accent: #bbbbbb;
  --text: #111315; --text-muted: #5b6066; --text-dim: #999999;
  --accent: #e4002b; --accent-dim: rgba(228,0,43,0.08);
  --cyan: #0055aa; --cyan-dim: rgba(0,85,170,0.08);
  --warn: #b86e00; --danger: #cc0000; --purple: #6622aa;
  --g-col: rgba(228,0,43,0.06); --g-edge: rgba(228,0,43,0.35);
  --g-base: rgba(0,150,140,0.25); --g-base-min: rgba(0,150,140,0.10);
}

/* ===== Reset + base ===== */
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: var(--font-sans); background: var(--bg); color: var(--text); font-size: 16px; line-height: var(--lh); -webkit-font-smoothing: antialiased; }

/* ===== Grid scaffold ===== */
.spread { position: relative; width: 100%; }
.wrap { position: relative; max-width: var(--maxw); margin: 0 auto; padding: var(--pad) var(--margin); }
.grid { display: grid; grid-template-columns: repeat(var(--cols), 1fr); column-gap: var(--gutter); row-gap: var(--lh); }
.band { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: start; }
@supports not (grid-template-columns: subgrid) { .band { grid-template-columns: repeat(var(--cols), 1fr); } }

/* ===== Grid overlay ===== */
.guides { position: absolute; inset: 0; pointer-events: none; z-index: 60; opacity: 0; transition: opacity .26s ease; }
body.grid-on .guides { opacity: 1; }
.guides .cols { position: absolute; top: 0; bottom: 0; left: var(--margin); right: var(--margin); display: grid; grid-template-columns: repeat(var(--cols), 1fr); column-gap: var(--gutter); }
.guides .col { background: var(--g-col); box-shadow: inset 1px 0 0 var(--g-edge), inset -1px 0 0 var(--g-edge); position: relative; }
.guides .col span { position: absolute; top: 32px; left: 0; right: 0; text-align: center; font-family: var(--font-mono); font-size: 10px; line-height: 1; color: var(--accent); opacity: 0.6; }
.guides .rows { position: absolute; left: var(--margin); right: var(--margin); top: var(--pad); bottom: 0; background-image: repeating-linear-gradient(to bottom, var(--g-base) 0 1px, transparent 1px var(--lh)), repeating-linear-gradient(to bottom, var(--g-base-min) 0 1px, transparent 1px var(--bl)); }
.guides .mline { position: absolute; top: 0; bottom: 0; width: 1px; background: var(--g-edge); }
.guides .mline.l { left: var(--margin); } .guides .mline.r { right: var(--margin); }

/* ===== Toolbar ===== */
.toolbar { position: fixed; top: 16px; right: 16px; z-index: 200; display: flex; align-items: center; gap: 8px; }
.toolbar button { font-family: var(--font-mono); font-size: 0.68rem; letter-spacing: 0.08em; text-transform: uppercase; padding: 8px 12px; border: 1px solid var(--border-accent); background: var(--surface); color: var(--text-muted); cursor: pointer; transition: all 0.15s; line-height: 16px; }
.toolbar button:hover { border-color: var(--accent); color: var(--accent); }
.toolbar button.active { background: var(--accent); color: var(--bg); border-color: var(--accent); }

/* ===== Header ===== */
.header { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: end; padding-bottom: var(--lh); border-bottom: 2px solid var(--accent); margin-bottom: 0; }
@supports not (grid-template-columns: subgrid) { .header { grid-template-columns: repeat(var(--cols), 1fr); } }
.header h1 { grid-column: 1 / 9; font-family: var(--font-mono); font-size: 1.5rem; font-weight: 700; line-height: 32px; letter-spacing: -0.02em; color: var(--accent); }
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta { grid-column: 9 / 13; font-family: var(--font-mono); color: var(--text-muted); font-size: 0.72rem; text-align: right; line-height: var(--lh); letter-spacing: 0.03em; word-break: break-all; }

/* ===== Summary ===== */
.summary { grid-column: 1 / -1; background: var(--surface); border-left: 3px solid var(--cyan); padding: 16px var(--gutter); font-size: 0.92rem; line-height: var(--lh); }

/* ===== Panel ===== */
.panel { background: var(--surface); border: 1px solid var(--border); overflow: hidden; }
.panel-header { display: flex; justify-content: space-between; align-items: center; padding: 12px var(--gutter); border-bottom: 1px solid var(--border); }
.panel-header h2 { font-family: var(--font-mono); font-size: 0.7rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; line-height: var(--lh); }
.panel-header .tag { font-family: var(--font-mono); font-size: 0.6rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; letter-spacing: 0.05em; line-height: 16px; }
.panel-body { padding: 16px var(--gutter); }

/* ===== Image annotation ===== */
.image-frame { position: relative; display: flex; justify-content: center; align-items: center; background: var(--bg); border: 1px dashed var(--border-accent); padding: 16px; min-height: 280px; }
.target-img { max-width: 100%; max-height: 78vh; display: block; cursor: crosshair; }
.hint { font-family: var(--font-mono); font-size: 0.72rem; color: var(--text-muted); padding: 12px var(--gutter); line-height: var(--lh); }
.path-row { font-family: var(--font-mono); font-size: 0.7rem; color: var(--text-dim); padding: 8px var(--gutter); background: var(--surface-hover); border-top: 1px solid var(--border); word-break: break-all; line-height: var(--lh); }

/* ===== Buttons ===== */
.btn-row { display: flex; gap: 12px; flex-wrap: wrap; padding: 16px var(--gutter); border-top: 1px solid var(--border); }
.btn { font-family: var(--font-mono); font-size: 0.72rem; padding: 10px 18px; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; letter-spacing: 0.05em; text-transform: uppercase; transition: all 0.15s; line-height: var(--lh); }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { filter: brightness(0.85); }
.btn.cyan { color: var(--cyan); border-color: var(--cyan); }
.btn.cyan:hover { background: var(--cyan-dim); border-color: var(--cyan); }

/* ===== Footer ===== */
.footer { grid-column: 1 / -1; padding-top: var(--lh); border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); letter-spacing: 0.05em; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); line-height: var(--lh); }
@supports not (grid-template-columns: subgrid) { .footer { grid-template-columns: repeat(var(--cols), 1fr); } }
.footer .left { grid-column: 1 / 7; } .footer .right { grid-column: 7 / 13; text-align: right; }

.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 0.8rem; padding: 12px 18px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 9999; max-width: 360px; line-height: var(--lh); }
.toast.show { opacity: 1; transform: translateY(0); }
</style>
</head>
<body>

<div class="toolbar">
  <button id="themeToggle" aria-label="Toggle theme">☀</button>

</div>

<section class="spread">
  <div class="wrap">
    <div class="grid">

      <div class="header">
        <h1><span>HTML //</span> {{TITLE}}</h1>
        <div class="meta">GEN {{DATE}}<br>MODE ANNOTATE</div>
      </div>

      <div class="summary">{{SUMMARY}}</div>

      <!-- Annotation panel — full width -->
      <div class="band">
        <div class="panel" style="grid-column: 1 / -1;">
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
      </div>

      <div class="footer">
        <span class="left">HTML SKILL v1.0.0 / ANNOTATE MODE</span>
        <span class="right">GENERATED BY CLAUDE CODE</span>
      </div>

    </div>

    <div class="guides" aria-hidden="true">
      <div class="cols"></div><div class="rows"></div>
      <div class="mline l"></div><div class="mline r"></div>
    </div>
  </div>
</section>

<div class="toast" id="toast"></div>

<script>
const STATE = {
  originalSrc: document.getElementById('target-img').src,
  lastState: null
};

/* ===== Theme toggle ===== */
(function initTheme() {
  const stored = localStorage.getItem('html-skill-theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const theme = stored || (prefersDark ? 'dark' : 'light');
  document.documentElement.setAttribute('data-theme', theme);
  document.addEventListener('DOMContentLoaded', () => {
    const btn = document.getElementById('themeToggle');
    if (!btn) return;
    function updateLabel() {
      const cur = document.documentElement.getAttribute('data-theme');
      btn.textContent = cur === 'dark' ? '☀' : '☾';
    }
    updateLabel();
    btn.addEventListener('click', () => {
      const cur = document.documentElement.getAttribute('data-theme');
      const next = cur === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('html-skill-theme', next);
      updateLabel();
      updateMarkerTheme();
    });
  });
})();

/* ===== Grid overlay toggle ===== */
(function initGrid() {
  document.addEventListener('DOMContentLoaded', () => {
    function setGrid(on) {
      document.body.classList.toggle('grid-on', on);
    }
    document.addEventListener('keydown', (e) => {
      if ((e.key === 'g' || e.key === 'G') && !e.metaKey && !e.ctrlKey && !e.altKey)
        setGrid(!document.body.classList.contains('grid-on'));
    });
    document.querySelectorAll('.guides .cols').forEach((h) => {
      const n = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--cols').trim() || '12', 10);
      for (let i = 1; i <= n; i++) {
        const c = document.createElement('div'); c.className = 'col';
        const s = document.createElement('span'); s.textContent = i;
        c.appendChild(s); h.appendChild(c);
      }
    });
  });
})();

/* ===== Toast ===== */
function toast(msg, kind = 'ok') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.style.borderColor = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.style.color = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.classList.add('show');
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(() => t.classList.remove('show'), 2400);
}

/* ===== Markerjs2 theme-aware colors ===== */
function getMarkerColors() {
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
  return isDark
    ? { toolbar: '#111111', toolbarHover: '#1a1a1a', toolbarColor: '#e0e0e0', toolbox: '#0a0a0a', toolboxColor: '#00ff88', toolboxAccent: '#00ff88' }
    : { toolbar: '#f4f4f4', toolbarHover: '#eaeaea', toolbarColor: '#111315', toolbox: '#ffffff', toolboxColor: '#e4002b', toolboxAccent: '#e4002b' };
}

function updateMarkerTheme() {
  // Markerjs2 does not support live re-theming; the next openMarker() call will use current theme colors
}

function openMarker() {
  const img = document.getElementById('target-img');
  if (typeof markerjs2 === 'undefined') {
    toast('Markerjs2 のロードに失敗。インターネット接続を確認', 'err');
    return;
  }
  const mc = getMarkerColors();
  const markerArea = new markerjs2.MarkerArea(img);
  markerArea.settings.displayMode = 'popup';
  markerArea.uiStyleSettings.toolbarBackgroundColor = mc.toolbar;
  markerArea.uiStyleSettings.toolbarBackgroundHoverColor = mc.toolbarHover;
  markerArea.uiStyleSettings.toolbarColor = mc.toolbarColor;
  markerArea.uiStyleSettings.toolboxBackgroundColor = mc.toolbox;
  markerArea.uiStyleSettings.toolboxColor = mc.toolboxColor;
  markerArea.uiStyleSettings.toolboxAccentColor = mc.toolboxAccent;
  markerArea.addEventListener('render', (evt) => {
    img.src = evt.dataUrl;
    STATE.lastState = evt.state;
  });
  if (STATE.lastState) markerArea.restoreState(STATE.lastState);
  markerArea.show();
}

document.getElementById('target-img').addEventListener('click', () => {
  if (typeof markerjs2 !== 'undefined' && !document.querySelector('.markerjs-overlay')) {
    openMarker();
  }
});

async function getAnnotatedBlob() {
  const img = document.getElementById('target-img');
  const canvas = document.createElement('canvas');
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
- **`G` キー** でグリッドオーバーレイ表示 — レイアウト確認用
- **テーマトグル（☀/☾）** で LIGHT/DARK 切替、`localStorage` で永続化

## ライセンス注意

Markerjs2 のライセンスは確認必須（[GitHub](https://github.com/ailon/markerjs2)）。OSS 利用不可と判断された場合は fabric.js + 自作ツールバー（Phase 2）に切替予定。
