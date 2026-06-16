# Design System for `/html` SKILL

3 つのテンプレ（status / diagram / annotate / image-review）が共通して使う色・タイポ・グリッド・コンポーネント定義。
`vw-flow-viz` の `html-template.md` と統一されたトークンを採用する（後方互換性のため）。

## 1. テーマ設計

| テーマ | コンセプト | デフォルト条件 |
|--------|-----------|---------------|
| **DARK** | Catppuccin Macchiato + Hacker | `prefers-color-scheme: dark` or 初回訪問時 |
| **LIGHT** | Swiss International Typographic Style | `prefers-color-scheme: light` |

- `<html data-theme="dark|light">` で切替
- ヘッダー右上にトグルボタン（☀ / ☾）
- `localStorage('html-skill-theme')` で永続化
- `G` キーでグリッドオーバーレイ切替（Müller-Brockmann 12カラム + baseline 可視化）

## 2. Color Tokens

### DARK テーマ (Hacker + Catppuccin Macchiato)

| Variable | Hex | 用途 |
|----------|-----|------|
| `--bg` | `#0a0a0a` | ページ背景 |
| `--surface` | `#111111` | パネル背景 |
| `--surface-hover` | `#1a1a1a` | hover 時 |
| `--border` | `#222222` | 通常 border |
| `--border-accent` | `#333333` | 強調 border |
| `--text` | `#e0e0e0` | 通常テキスト |
| `--text-muted` | `#666666` | 補助テキスト |
| `--text-dim` | `#444444` | 非アクティブ |
| `--accent` | `#00ff88` | 主要アクション・成功 |
| `--accent-dim` | `rgba(0,255,136,0.15)` | accent の薄色背景 |
| `--cyan` | `#00d4ff` | 情報・選択中 |
| `--cyan-dim` | `rgba(0,212,255,0.15)` | cyan の薄色背景 |
| `--warn` | `#ffaa00` | 注意・進行中 |
| `--danger` | `#ff5555` | エラー・ブロッカー |
| `--purple` | `#cc44ff` | ツール・補助情報 |

### LIGHT テーマ (Swiss International Typographic Style)

| Variable | Hex | 用途 |
|----------|-----|------|
| `--bg` | `#ffffff` | ページ背景（白紙） |
| `--surface` | `#f4f4f4` | パネル背景 |
| `--surface-hover` | `#eaeaea` | hover 時 |
| `--border` | `#d4d4d4` | 通常 border |
| `--border-accent` | `#bbbbbb` | 強調 border |
| `--text` | `#111315` | 通常テキスト（インク） |
| `--text-muted` | `#5b6066` | 補助テキスト |
| `--text-dim` | `#999999` | 非アクティブ |
| `--accent` | `#e4002b` | Swiss Red（Müller-Brockmann 正統色） |
| `--accent-dim` | `rgba(228,0,43,0.08)` | accent の薄色背景 |
| `--cyan` | `#0055aa` | 情報・選択中 |
| `--cyan-dim` | `rgba(0,85,170,0.08)` | cyan の薄色背景 |
| `--warn` | `#b86e00` | 注意・進行中 |
| `--danger` | `#cc0000` | エラー・ブロッカー |
| `--purple` | `#6622aa` | ツール・補助情報 |

### Grid Overlay Colors（テーマ別）

| Variable | DARK | LIGHT | 用途 |
|----------|------|-------|------|
| `--g-col` | `rgba(0,255,136,0.05)` | `rgba(228,0,43,0.06)` | カラム塗り |
| `--g-edge` | `rgba(0,255,136,0.25)` | `rgba(228,0,43,0.35)` | カラム端線 |
| `--g-base` | `rgba(0,212,255,0.18)` | `rgba(0,150,140,0.25)` | メジャー baseline |
| `--g-base-min` | `rgba(0,212,255,0.06)` | `rgba(0,150,140,0.10)` | マイナー baseline |

### Type-specific（Sankey/関係図と統一、テーマ共通）

| Type | Color |
|------|-------|
| user | `#00d4ff` |
| skill | `#00ff88` |
| agent | `#ffaa00` |
| subagent | `#ff7700` |
| tool | `#cc44ff` |
| output | `#00ffcc` |

## 3. Grid Tokens（テーマ非依存）

Müller-Brockmann 12カラムモジュラーグリッド + 8px baseline。

| Variable | Value | 用途 |
|----------|-------|------|
| `--cols` | `12` | カラム数 |
| `--bl` | `8px` | ベースラインユニット |
| `--lh` | `24px` | リーディング（3 × baseline） |
| `--gutter` | `24px` | カラム間ガター |
| `--margin` | `48px` | 左右マージン |
| `--maxw` | `1200px` | コンテンツ最大幅 |
| `--pad` | `48px` | spread 上下パディング |

## 4. Typography

| Variable | Font | 用途 |
|----------|------|------|
| `--font-sans` | `'Inter', -apple-system, sans-serif` | 見出し・本文 |
| `--font-mono` | `'JetBrains Mono', 'SF Mono', monospace` | データ・ラベル・バッジ |

CDN: Google Fonts `Inter:wght@300;400;600;700` + `JetBrains+Mono:wght@400;500;700`

行高は必ず `--bl` (8px) の倍数に固定:
- 本文: `line-height: var(--lh)` (24px = 3×8)
- 小テキスト（バッジ・ラベル）: `line-height: 16px` (2×8)
- 大見出し: `line-height: 48px` (6×8) or `32px` (4×8)

## 5. Common CSS Snippet (paste into every template)

```css
/* ===== Theme + Grid tokens (ONE source of truth) ===== */
:root, [data-theme="dark"] {
  /* Grid (theme-independent) */
  --cols: 12;
  --bl: 8px;
  --lh: 24px;
  --gutter: 24px;
  --margin: 48px;
  --maxw: 1200px;
  --pad: 48px;

  /* Typography */
  --font-sans: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;

  /* DARK palette */
  --bg: #0a0a0a;
  --surface: #111111;
  --surface-hover: #1a1a1a;
  --border: #222222;
  --border-accent: #333333;
  --text: #e0e0e0;
  --text-muted: #666666;
  --text-dim: #444444;
  --accent: #00ff88;
  --accent-dim: rgba(0,255,136,0.15);
  --cyan: #00d4ff;
  --cyan-dim: rgba(0,212,255,0.15);
  --warn: #ffaa00;
  --danger: #ff5555;
  --purple: #cc44ff;

  /* Grid overlay */
  --g-col: rgba(0,255,136,0.05);
  --g-edge: rgba(0,255,136,0.25);
  --g-base: rgba(0,212,255,0.18);
  --g-base-min: rgba(0,212,255,0.06);
}

[data-theme="light"] {
  --bg: #ffffff;
  --surface: #f4f4f4;
  --surface-hover: #eaeaea;
  --border: #d4d4d4;
  --border-accent: #bbbbbb;
  --text: #111315;
  --text-muted: #5b6066;
  --text-dim: #999999;
  --accent: #e4002b;
  --accent-dim: rgba(228,0,43,0.08);
  --cyan: #0055aa;
  --cyan-dim: rgba(0,85,170,0.08);
  --warn: #b86e00;
  --danger: #cc0000;
  --purple: #6622aa;

  --g-col: rgba(228,0,43,0.06);
  --g-edge: rgba(228,0,43,0.35);
  --g-base: rgba(0,150,140,0.25);
  --g-base-min: rgba(0,150,140,0.10);
}

/* ===== Reset + base ===== */
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: var(--font-sans);
  background: var(--bg);
  color: var(--text);
  font-size: 16px;
  line-height: var(--lh);
  -webkit-font-smoothing: antialiased;
}

/* ===== Grid scaffold (Müller-Brockmann 12-col) ===== */
.spread { position: relative; width: 100%; }
.wrap {
  position: relative;
  max-width: var(--maxw);
  margin: 0 auto;
  padding: var(--pad) var(--margin);
}
.grid {
  display: grid;
  grid-template-columns: repeat(var(--cols), 1fr);
  column-gap: var(--gutter);
  row-gap: var(--lh);
}
.band {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: subgrid;
  column-gap: var(--gutter);
  align-items: start;
}
@supports not (grid-template-columns: subgrid) {
  .band { grid-template-columns: repeat(var(--cols), 1fr); }
}

/* ===== Grid overlay (INSIDE .wrap — same content box) ===== */
.guides {
  position: absolute; inset: 0;
  pointer-events: none; z-index: 60;
  opacity: 0; transition: opacity .26s ease;
}
body.grid-on .guides { opacity: 1; }
.guides .cols {
  position: absolute; top: 0; bottom: 0;
  left: var(--margin); right: var(--margin);
  display: grid;
  grid-template-columns: repeat(var(--cols), 1fr);
  column-gap: var(--gutter);
}
.guides .col {
  background: var(--g-col);
  box-shadow: inset 1px 0 0 var(--g-edge), inset -1px 0 0 var(--g-edge);
  position: relative;
}
.guides .col span {
  position: absolute; top: 32px; left: 0; right: 0;
  text-align: center;
  font-family: var(--font-mono); font-size: 10px; line-height: 1;
  color: var(--accent); opacity: 0.6;
}
.guides .rows {
  position: absolute;
  left: var(--margin); right: var(--margin);
  top: var(--pad); bottom: 0;
  background-image:
    repeating-linear-gradient(to bottom, var(--g-base) 0 1px, transparent 1px var(--lh)),
    repeating-linear-gradient(to bottom, var(--g-base-min) 0 1px, transparent 1px var(--bl));
}
.guides .mline { position: absolute; top: 0; bottom: 0; width: 1px; background: var(--g-edge); }
.guides .mline.l { left: var(--margin); }
.guides .mline.r { right: var(--margin); }

/* ===== Header (folio-style) ===== */
.header {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: subgrid;
  column-gap: var(--gutter);
  align-items: end;
  padding-bottom: var(--lh);
  border-bottom: 2px solid var(--accent);
  margin-bottom: var(--lh);
}
@supports not (grid-template-columns: subgrid) {
  .header { grid-template-columns: repeat(var(--cols), 1fr); }
}
.header h1 {
  grid-column: 1 / 9;
  font-family: var(--font-mono);
  font-size: 1.5rem;
  font-weight: 700;
  line-height: 32px;
  letter-spacing: -0.02em;
  color: var(--accent);
}
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta {
  grid-column: 9 / 13;
  font-family: var(--font-mono);
  color: var(--text-muted);
  font-size: 0.72rem;
  text-align: right;
  line-height: var(--lh);
  letter-spacing: 0.03em;
}

/* ===== Toolbar (theme + grid toggles) ===== */
.toolbar {
  position: fixed; top: 16px; right: 16px; z-index: 200;
  display: flex; align-items: center; gap: 8px;
}
.toolbar button {
  font-family: var(--font-mono);
  font-size: 0.68rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  padding: 8px 12px;
  border: 1px solid var(--border-accent);
  background: var(--surface);
  color: var(--text-muted);
  cursor: pointer;
  transition: all 0.15s;
  line-height: 16px;
}
.toolbar button:hover {
  border-color: var(--accent);
  color: var(--accent);
}
.toolbar button.active {
  background: var(--accent);
  color: var(--bg);
  border-color: var(--accent);
}

/* ===== Summary callout ===== */
.summary {
  grid-column: 1 / -1;
  background: var(--surface);
  border-left: 3px solid var(--cyan);
  padding: 16px var(--gutter);
  font-size: 0.92rem;
  line-height: var(--lh);
}

/* ===== Panel ===== */
.panel {
  background: var(--surface);
  border: 1px solid var(--border);
  overflow: hidden;
}
.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px var(--gutter);
  border-bottom: 1px solid var(--border);
}
.panel-header h2 {
  font-family: var(--font-mono);
  font-size: 0.7rem;
  font-weight: 500;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  line-height: var(--lh);
}
.panel-header .tag {
  font-family: var(--font-mono);
  font-size: 0.6rem;
  color: var(--accent);
  background: var(--accent-dim);
  padding: 2px 8px;
  letter-spacing: 0.05em;
  line-height: 16px;
}
.panel-body { padding: 16px var(--gutter); }

/* ===== Buttons ===== */
.btn {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  padding: 8px 16px;
  background: var(--surface-hover);
  color: var(--accent);
  border: 1px solid var(--border-accent);
  cursor: pointer;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  transition: background 0.15s, border-color 0.15s, color 0.15s;
  line-height: var(--lh);
}
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { filter: brightness(0.85); }
.btn.danger { color: var(--danger); }
.btn.danger:hover { background: rgba(255,85,85,0.1); border-color: var(--danger); }

/* ===== Footer ===== */
.footer {
  grid-column: 1 / -1;
  padding-top: var(--lh);
  border-top: 1px solid var(--border);
  font-family: var(--font-mono);
  font-size: 0.6rem;
  color: var(--text-dim);
  letter-spacing: 0.05em;
  display: grid;
  grid-template-columns: subgrid;
  column-gap: var(--gutter);
  line-height: var(--lh);
}
@supports not (grid-template-columns: subgrid) {
  .footer { grid-template-columns: repeat(var(--cols), 1fr); }
}
.footer .left { grid-column: 1 / 7; }
.footer .right { grid-column: 7 / 13; text-align: right; }

/* ===== Toast ===== */
.toast {
  position: fixed;
  bottom: 24px; right: 24px;
  background: var(--surface);
  border: 1px solid var(--accent);
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 0.8rem;
  padding: 12px 18px;
  opacity: 0;
  transform: translateY(8px);
  transition: opacity 0.2s, transform 0.2s;
  pointer-events: none;
  z-index: 1000;
  max-width: 360px;
  line-height: var(--lh);
}
.toast.show { opacity: 1; transform: translateY(0); }
```

## 6. Common JS Utilities (paste into every template)

```js
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

/* ===== Clipboard ===== */
async function copyText(text, label = 'クリップボードにコピーしました') {
  try {
    await navigator.clipboard.writeText(text);
    toast(label);
  } catch (err) {
    toast('コピー失敗: ' + err.message, 'err');
  }
}

async function copyCanvasPng(canvas, label = 'PNG をクリップボードにコピー') {
  return new Promise((resolve, reject) => {
    canvas.toBlob(async (blob) => {
      if (!blob) return reject(new Error('toBlob failed'));
      try {
        const item = new ClipboardItem({ 'image/png': blob });
        await navigator.clipboard.write([item]);
        toast(label);
        resolve();
      } catch (err) {
        toast('コピー失敗: ' + err.message, 'err');
        reject(err);
      }
    }, 'image/png');
  });
}

/* ===== Theme toggle (LIGHT / DARK) ===== */
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
      btn.setAttribute('aria-label', cur === 'dark' ? 'Switch to light' : 'Switch to dark');
    }
    updateLabel();
    btn.addEventListener('click', () => {
      const cur = document.documentElement.getAttribute('data-theme');
      const next = cur === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      localStorage.setItem('html-skill-theme', next);
      updateLabel();
    });
  });
})();

/* ===== Grid overlay toggle (G key only, no button) ===== */
(function initGridToggle() {
  document.addEventListener('DOMContentLoaded', () => {
    function setGrid(on) {
      document.body.classList.toggle('grid-on', on);
    }
    document.addEventListener('keydown', (e) => {
      if ((e.key === 'g' || e.key === 'G') && !e.metaKey && !e.ctrlKey && !e.altKey) {
        setGrid(!document.body.classList.contains('grid-on'));
      }
    });

    // populate overlay columns (numbered)
    document.querySelectorAll('.guides .cols').forEach((h) => {
      const n = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--cols').trim() || '12', 10);
      for (let i = 1; i <= n; i++) {
        const c = document.createElement('div');
        c.className = 'col';
        const s = document.createElement('span');
        s.textContent = i;
        c.appendChild(s);
        h.appendChild(c);
      }
    });
  });
})();
```

## 7. HTML Shell（共通ヘッダー・フッター）

各テンプレの先頭/末尾は次の構造を持つ:

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
<!-- mode-specific CDN here -->
<style>
/* Common CSS Snippet (§5) */
/* + mode-specific CSS */
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
        <div class="meta">GEN {{DATE}}<br>MODE {{MODE}}</div>
      </div>

      <!-- mode-specific content (as .band / grid-column elements) -->

      <div class="footer">
        <span class="left">HTML SKILL v1.0.0 / {{MODE}} MODE</span>
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
/* Common JS Utilities (§6) */
/* + mode-specific JS */
</script>
</body>
</html>
```

## 8. アクセシビリティ・操作性ガイド

- すべてのインタラクティブ要素は `tabindex` で キーボード操作可能に
- `aria-label` をボタンに付与（とくにアイコンのみのボタン）
- DARK: `--text` (#e0e0e0) / `--bg` (#0a0a0a) で AAA 達成
- LIGHT: `--text` (#111315) / `--bg` (#ffffff) で AAA 達成
- フォントサイズは最小 0.6rem まで（バッジ・ラベル限定）。本文は 0.85rem 以上
- `G` キーでグリッドオーバーレイ切替（開発・検証用）
- テーマ切替は `localStorage` で永続化、`prefers-color-scheme` を初期デフォルトに
