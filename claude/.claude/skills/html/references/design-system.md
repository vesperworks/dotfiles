# Design System for `/html` SKILL

4 つのテンプレ（status / diagram / annotate / image-review）が共通して使う色・タイポ・グリッド・コンポーネント・プリセットシステム定義。
`vw-flow-viz` の `html-template.md` と統一されたトークンを採用する（後方互換性のため）。

> **§5（Common CSS）と §6（Common JS）が正規ソース。**
> 各テンプレートファイルにインライン展開された旧コードよりも、本ファイルの §5/§6 を優先すること。

## 1. プリセットシステム

vw-grid-systems と同じ操作体系を採用したインタラクティブプリセット切り替え。

### キーボードショートカット

| Key | 機能 |
|-----|------|
| `J` / `K` | カラープリセット prev / next |
| `N` / `P` | フォントプリセット prev / next |
| `G` | グリッドオーバーレイ切替 |
| `E` | 静的HTMLエクスポート（JS/HUD除去、スタイル焼き込み） |

- input / textarea / select / contenteditable にフォーカス中はショートカット無効
- Cmd / Ctrl / Alt との組み合わせは無視（ブラウザ標準動作を阻害しない）

### HUD（Heads-Up Display）

画面下部に固定表示。常にダーク背景（カラープリセットに非依存）。

```
COLOR: Hacker  │  FONT: Inter (Geometric Sans)  │  J K color  N P font  G grid  E export
```

- JS で動的生成（`data-removable` 属性付き）→ テンプレート HTML の変更不要
- エクスポート時に自動除去

### 永続化

| Key | Storage |
|-----|---------|
| `html-preset-color` | カラープリセット index (0–4) |
| `html-preset-font` | フォントプリセット index (0–7) |

### 既存テンプレートとの互換性

- `<button id="themeToggle">` が存在する場合、クリック動作を「次のカラープリセット」に再割当
- `[data-theme]` 属性は引き続き設定（Swiss = `light`、他 = `dark`）→ テンプレートの `data-theme` 参照コードが壊れない
- Google Fonts `<link>` を JS で全フォント一括 URL に動的更新 → テンプレートの `<head>` 変更不要

## 2. Color Presets

5 プリセット。各プリセットは CSS 変数を `root.style.setProperty()` で一括上書き。

| idx | Name | Concept | `--bg` | `--accent` | `--text` | theme |
|-----|------|---------|--------|------------|----------|-------|
| 0 | **Hacker** | Catppuccin Macchiato + 端末グリーン | `#0a0a0a` | `#00ff88` | `#e0e0e0` | dark |
| 1 | **Swiss** | Swiss International Typographic Style | `#ffffff` | `#e4002b` | `#111315` | light |
| 2 | **Warm** | 暖色ダーク（アンバー） | `#1a120b` | `#ff9f43` | `#e8ddd0` | dark |
| 3 | **Cool** | 寒色ダーク（スカイブルー） | `#0a1628` | `#48dbfb` | `#d0dce8` | dark |
| 4 | **Mono** | モノクローム | `#111111` | `#ffffff` | `#e0e0e0` | dark |

全変数（surface / border / text-muted / cyan / warn / danger / purple / grid overlay）は §6 Common JS の `COLOR_PRESETS` オブジェクトに定義。

### Type-specific Colors（Sankey/関係図と統一、テーマ共通）

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

## 4. Font Presets

8 プリセット。`--font-sans` を切り替え。`--font-mono`（JetBrains Mono）は全プリセット共通。

| idx | Name | Category | CSS `font-family` |
|-----|------|----------|--------------------|
| 0 | **Inter** | Geometric Sans | `'Inter', -apple-system, sans-serif` |
| 1 | **Noto Sans JP** | 汎用ゴシック | `'Noto Sans JP', sans-serif` |
| 2 | **BIZ UDPGothic** | UD ゴシック | `'BIZ UDPGothic', sans-serif` |
| 3 | **IBM Plex Sans JP** | テック | `'IBM Plex Sans JP', sans-serif` |
| 4 | **Zen Kaku Gothic New** | 丸ゴシック | `'Zen Kaku Gothic New', sans-serif` |
| 5 | **M PLUS 1** | モダン | `'M PLUS 1', sans-serif` |
| 6 | **Sawarabi Mincho** | 明朝 | `'Sawarabi Mincho', serif` |
| 7 | **Dela Gothic One** | デコラティブ | `'Dela Gothic One', sans-serif` |

行高は必ず `--bl` (8px) の倍数に固定:
- 本文: `line-height: var(--lh)` (24px = 3×8)
- 小テキスト（バッジ・ラベル）: `line-height: 16px` (2×8)
- 大見出し: `line-height: 48px` (6×8) or `32px` (4×8)

### Google Fonts 一括ロード URL

JS が既存の `<link>` を以下 URL に動的更新する:

```
https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500;700&family=Noto+Sans+JP:wght@300;400;500;700&family=BIZ+UDPGothic:wght@400;700&family=IBM+Plex+Sans+JP:wght@300;400;500;700&family=Zen+Kaku+Gothic+New:wght@300;400;500;700&family=M+PLUS+1:wght@300;400;500;700&family=Sawarabi+Mincho&family=Dela+Gothic+One&display=swap
```

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

  /* DARK palette (Hacker default) */
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

/* ===== Toolbar (legacy — repurposed by preset system) ===== */
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
  bottom: 56px; right: 24px;
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

/* ===== HUD (preset indicator — always dark) ===== */
.hud {
  position: fixed;
  bottom: 0; left: 0; right: 0;
  z-index: 300;
  background: rgba(10,10,10,0.92);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  border-top: 1px solid #333;
  padding: 6px 16px;
  display: flex;
  align-items: center;
  gap: 16px;
  font-family: 'JetBrains Mono', 'SF Mono', monospace;
  font-size: 0.65rem;
  letter-spacing: 0.06em;
  color: #888;
  user-select: none;
}
.hud .sep { color: #333; }
.hud .val { color: #00ff88; }
.hud .cat { color: #666; }
.hud .key {
  display: inline-block;
  padding: 1px 5px;
  border: 1px solid #444;
  border-radius: 2px;
  font-size: 0.6rem;
  color: #666;
  margin: 0 1px;
}
.hud .hint { margin-left: auto; display: flex; gap: 10px; }
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

/* ===== Preset System (color + font + grid + export) ===== */
(function initPresets() {
  var COLOR_PRESETS = [
    { name: 'Hacker', theme: 'dark', vars: {
      '--bg':'#0a0a0a', '--surface':'#111111', '--surface-hover':'#1a1a1a',
      '--border':'#222222', '--border-accent':'#333333',
      '--text':'#e0e0e0', '--text-muted':'#666666', '--text-dim':'#444444',
      '--accent':'#00ff88', '--accent-dim':'rgba(0,255,136,0.15)',
      '--cyan':'#00d4ff', '--cyan-dim':'rgba(0,212,255,0.15)',
      '--warn':'#ffaa00', '--danger':'#ff5555', '--purple':'#cc44ff',
      '--g-col':'rgba(0,255,136,0.05)', '--g-edge':'rgba(0,255,136,0.25)',
      '--g-base':'rgba(0,212,255,0.18)', '--g-base-min':'rgba(0,212,255,0.06)'
    }},
    { name: 'Swiss', theme: 'light', vars: {
      '--bg':'#ffffff', '--surface':'#f4f4f4', '--surface-hover':'#eaeaea',
      '--border':'#d4d4d4', '--border-accent':'#bbbbbb',
      '--text':'#111315', '--text-muted':'#5b6066', '--text-dim':'#999999',
      '--accent':'#e4002b', '--accent-dim':'rgba(228,0,43,0.08)',
      '--cyan':'#0055aa', '--cyan-dim':'rgba(0,85,170,0.08)',
      '--warn':'#b86e00', '--danger':'#cc0000', '--purple':'#6622aa',
      '--g-col':'rgba(228,0,43,0.06)', '--g-edge':'rgba(228,0,43,0.35)',
      '--g-base':'rgba(0,150,140,0.25)', '--g-base-min':'rgba(0,150,140,0.10)'
    }},
    { name: 'Warm', theme: 'dark', vars: {
      '--bg':'#1a120b', '--surface':'#231a11', '--surface-hover':'#2c2118',
      '--border':'#3a2d1f', '--border-accent':'#4d3d2a',
      '--text':'#e8ddd0', '--text-muted':'#8a7a6a', '--text-dim':'#5a4a3a',
      '--accent':'#ff9f43', '--accent-dim':'rgba(255,159,67,0.15)',
      '--cyan':'#feca57', '--cyan-dim':'rgba(254,202,87,0.15)',
      '--warn':'#ff6b6b', '--danger':'#ee5a24', '--purple':'#e056a0',
      '--g-col':'rgba(255,159,67,0.05)', '--g-edge':'rgba(255,159,67,0.25)',
      '--g-base':'rgba(254,202,87,0.18)', '--g-base-min':'rgba(254,202,87,0.06)'
    }},
    { name: 'Cool', theme: 'dark', vars: {
      '--bg':'#0a1628', '--surface':'#0f1d33', '--surface-hover':'#152540',
      '--border':'#1e3050', '--border-accent':'#2a4066',
      '--text':'#d0dce8', '--text-muted':'#5a7a9a', '--text-dim':'#354a60',
      '--accent':'#48dbfb', '--accent-dim':'rgba(72,219,251,0.15)',
      '--cyan':'#0abde3', '--cyan-dim':'rgba(10,189,227,0.15)',
      '--warn':'#feca57', '--danger':'#ff6b6b', '--purple':'#a29bfe',
      '--g-col':'rgba(72,219,251,0.05)', '--g-edge':'rgba(72,219,251,0.25)',
      '--g-base':'rgba(10,189,227,0.18)', '--g-base-min':'rgba(10,189,227,0.06)'
    }},
    { name: 'Mono', theme: 'dark', vars: {
      '--bg':'#111111', '--surface':'#1a1a1a', '--surface-hover':'#222222',
      '--border':'#333333', '--border-accent':'#444444',
      '--text':'#e0e0e0', '--text-muted':'#777777', '--text-dim':'#444444',
      '--accent':'#ffffff', '--accent-dim':'rgba(255,255,255,0.1)',
      '--cyan':'#aaaaaa', '--cyan-dim':'rgba(170,170,170,0.1)',
      '--warn':'#cccccc', '--danger':'#999999', '--purple':'#bbbbbb',
      '--g-col':'rgba(255,255,255,0.04)', '--g-edge':'rgba(255,255,255,0.2)',
      '--g-base':'rgba(170,170,170,0.15)', '--g-base-min':'rgba(170,170,170,0.05)'
    }}
  ];

  var FONT_PRESETS = [
    { name:'Inter', cat:'Geometric Sans', family:"'Inter',-apple-system,sans-serif",
      gf:'Inter:wght@300;400;600;700' },
    { name:'Noto Sans JP', cat:'汎用ゴシック', family:"'Noto Sans JP',sans-serif",
      gf:'Noto+Sans+JP:wght@300;400;500;700' },
    { name:'BIZ UDPGothic', cat:'UD ゴシック', family:"'BIZ UDPGothic',sans-serif",
      gf:'BIZ+UDPGothic:wght@400;700' },
    { name:'IBM Plex Sans JP', cat:'テック', family:"'IBM Plex Sans JP',sans-serif",
      gf:'IBM+Plex+Sans+JP:wght@300;400;500;700' },
    { name:'Zen Kaku Gothic New', cat:'丸ゴシック', family:"'Zen Kaku Gothic New',sans-serif",
      gf:'Zen+Kaku+Gothic+New:wght@300;400;500;700' },
    { name:'M PLUS 1', cat:'モダン', family:"'M PLUS 1',sans-serif",
      gf:'M+PLUS+1:wght@300;400;500;700' },
    { name:'Sawarabi Mincho', cat:'明朝', family:"'Sawarabi Mincho',serif",
      gf:'Sawarabi+Mincho' },
    { name:'Dela Gothic One', cat:'デコラティブ', family:"'Dela Gothic One',sans-serif",
      gf:'Dela+Gothic+One' }
  ];

  var ALL_FONTS_URL = 'https://fonts.googleapis.com/css2?'
    + FONT_PRESETS.map(function(f){ return 'family=' + f.gf; }).join('&')
    + '&family=JetBrains+Mono:wght@400;500;700&display=swap';

  var state = {
    color: parseInt(localStorage.getItem('html-preset-color') || '0', 10) % COLOR_PRESETS.length,
    font: parseInt(localStorage.getItem('html-preset-font') || '0', 10) % FONT_PRESETS.length
  };

  var root = document.documentElement;

  function applyColor(idx) {
    var p = COLOR_PRESETS[idx];
    root.setAttribute('data-theme', p.theme);
    for (var k in p.vars) root.style.setProperty(k, p.vars[k]);
    state.color = idx;
    localStorage.setItem('html-preset-color', String(idx));
    updateHUD();
    updateThemeToggle();
  }

  function applyFont(idx) {
    var p = FONT_PRESETS[idx];
    root.style.setProperty('--font-sans', p.family);
    state.font = idx;
    localStorage.setItem('html-preset-font', String(idx));
    updateHUD();
  }

  function cycle(type, dir) {
    var presets = type === 'color' ? COLOR_PRESETS : FONT_PRESETS;
    var cur = state[type];
    var next = (cur + dir + presets.length) % presets.length;
    if (type === 'color') applyColor(next);
    else applyFont(next);
    toast((type === 'color' ? 'COLOR' : 'FONT') + ': ' + presets[next].name);
  }

  function updateHUD() {
    var hud = document.getElementById('hud');
    if (!hud) return;
    var cp = COLOR_PRESETS[state.color];
    var fp = FONT_PRESETS[state.font];
    hud.innerHTML =
      'COLOR: <span class="val">' + cp.name + '</span>' +
      ' <span class="sep">│</span> ' +
      'FONT: <span class="val">' + fp.name + '</span> ' +
      '<span class="cat">(' + fp.cat + ')</span>' +
      '<span class="hint">' +
        '<span><span class="key">J</span><span class="key">K</span> color</span>' +
        '<span><span class="key">N</span><span class="key">P</span> font</span>' +
        '<span><span class="key">G</span> grid</span>' +
        '<span><span class="key">E</span> export</span>' +
      '</span>';
  }

  function updateThemeToggle() {
    var btn = document.getElementById('themeToggle');
    if (!btn) return;
    btn.textContent = COLOR_PRESETS[state.color].name;
    btn.setAttribute('aria-label', 'Cycle color preset (current: ' + COLOR_PRESETS[state.color].name + ')');
  }

  function exportStatic() {
    var clone = document.documentElement.cloneNode(true);
    clone.querySelectorAll('[data-removable], script').forEach(function(el) { el.remove(); });
    var fp = FONT_PRESETS[state.font];
    var fontLink = clone.querySelector('link[href*="fonts.googleapis.com"]');
    if (fontLink) {
      fontLink.href = 'https://fonts.googleapis.com/css2?family='
        + fp.gf + '&family=JetBrains+Mono:wght@400;500;700&display=swap';
    }
    var html = '<!DOCTYPE html>\n' + clone.outerHTML;
    var blob = new Blob([html], { type: 'text/html' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = (document.title || 'report').replace(/[^a-zA-Z0-9_　-鿿-]/g, '_') + '_export.html';
    a.click();
    URL.revokeObjectURL(a.href);
    toast('Static HTML exported');
  }

  // Upgrade Google Fonts link to include all presets
  var fontLink = document.querySelector('link[href*="fonts.googleapis.com"]');
  if (fontLink) { fontLink.href = ALL_FONTS_URL; }
  else {
    var l = document.createElement('link');
    l.rel = 'stylesheet'; l.href = ALL_FONTS_URL;
    document.head.appendChild(l);
  }

  document.addEventListener('DOMContentLoaded', function() {
    // Create HUD
    var hud = document.createElement('div');
    hud.id = 'hud'; hud.className = 'hud';
    hud.setAttribute('data-removable', '');
    document.body.appendChild(hud);

    // Apply stored presets
    applyColor(state.color);
    applyFont(state.font);

    // Populate grid overlay columns
    document.querySelectorAll('.guides .cols').forEach(function(h) {
      var n = parseInt(getComputedStyle(root).getPropertyValue('--cols').trim() || '12', 10);
      for (var i = 1; i <= n; i++) {
        var c = document.createElement('div');
        c.className = 'col';
        var s = document.createElement('span');
        s.textContent = i;
        c.appendChild(s);
        h.appendChild(c);
      }
    });

    // Repurpose themeToggle button (remove old listener, attach preset cycle)
    var oldBtn = document.getElementById('themeToggle');
    if (oldBtn) {
      var newBtn = oldBtn.cloneNode(true);
      oldBtn.parentNode.replaceChild(newBtn, oldBtn);
      newBtn.addEventListener('click', function() { cycle('color', 1); });
      updateThemeToggle();
    }

    // Keyboard shortcuts
    document.addEventListener('keydown', function(e) {
      if (e.target.matches('input,textarea,select,[contenteditable]')) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      switch (e.key) {
        case 'j': case 'J': cycle('color', -1); break;
        case 'k': case 'K': cycle('color', 1); break;
        case 'n': case 'N': cycle('font', -1); break;
        case 'p': case 'P': cycle('font', 1); break;
        case 'g': case 'G':
          document.body.classList.toggle('grid-on');
          toast(document.body.classList.contains('grid-on') ? 'Grid ON' : 'Grid OFF');
          break;
        case 'e': case 'E': exportStatic(); break;
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
<!-- ↑ Preset system upgrades this link at runtime to include all font presets -->
<!-- mode-specific CDN here -->
<style>
/* Common CSS Snippet (§5) */
/* + mode-specific CSS */
</style>
</head>
<body>

<div class="toolbar">
  <button id="themeToggle" aria-label="Cycle color preset">Hacker</button>
</div>
<!-- ↑ Preset system repurposes this button to cycle color presets -->
<!-- HUD is dynamically injected by preset system (§6) — no manual HTML needed -->

<section class="spread">
  <div class="wrap">
    <div class="grid">

      <div class="header">
        <h1><span>HTML //</span> {{TITLE}}</h1>
        <div class="meta">GEN {{DATE}}<br>MODE {{MODE}}</div>
      </div>

      <!-- mode-specific content (as .band / grid-column elements) -->

      <div class="footer">
        <span class="left">HTML SKILL v2.0.0 / {{MODE}} MODE</span>
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
- DARK 系テーマ: `--text` / `--bg` コントラスト比 AAA 達成
- LIGHT（Swiss）: `--text` (#111315) / `--bg` (#ffffff) で AAA 達成
- フォントサイズは最小 0.6rem まで（バッジ・ラベル限定）。本文は 0.85rem 以上
- テーマ切替は `localStorage` で永続化、初回は Hacker（dark）
- **キーボードショートカット**: `J/K` カラー切替、`N/P` フォント切替、`G` グリッド、`E` エクスポート
- HUD は `data-removable` 属性付き → エクスポート時に自動除去
- `themeToggle` ボタンはカラープリセット送りとして動作（旧テーマトグルの上位互換）
