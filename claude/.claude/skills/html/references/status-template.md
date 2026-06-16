# Status Mode Template

スレッドの状況・確認事項を整理した対話 UI 用 HTML。
ユーザーが Yes/No・複数選択・自由記述で回答 → 「結果を JSON でコピー」ボタンで Claude に貼り戻せる。

Müller-Brockmann 12カラムグリッド + LIGHT/DARK テーマ切替対応。
パネル box を廃止し、全要素を直接グリッドカラムに配置（セクション区切りはルール線）。

## Type Scale — 3 sizes only

| 段階 | サイズ | line-height | 用途 |
|------|--------|-------------|------|
| Display | 32px | 32px (4×8) | ページタイトル h1 のみ |
| Body | 16px | 24px (3×8) | 本文、質問、ステータスラベル、アクション |
| Caption | 11px | 24px (3×8) | バッジ、ボタン、タグ、メタ、フッター、スコア（全て mono） |

## Data Schema

```json
{
  "title": "...",
  "summary": "概要を 1〜3 行で",
  "sections": [
    {
      "kind": "status",
      "title": "現状",
      "items": [
        {"label": "Phase 7 完了", "state": "done"},
        {"label": "main を push", "state": "wip"},
        {"label": "浮遊コミット整理", "state": "todo"},
        {"label": "tailscale alias 復旧", "state": "blocked"}
      ]
    },
    {
      "kind": "qa",
      "title": "確認事項",
      "items": [
        {"id": "q1", "label": "main を origin に push しますか？", "type": "yesno"},
        {"id": "q2", "label": "浮遊コミットの扱いは？", "type": "multi", "options": ["全て abandon", "個別に確認", "後回し"]},
        {"id": "q3", "label": "補足コメント", "type": "text"}
      ]
    },
    {
      "kind": "actions",
      "title": "次のアクション候補（推奨確率付き）",
      "items": [
        {"label": "main を push（jj git push --bookmark main）", "score": 0.7},
        {"label": "浮遊コミット 10 件を jj show で精査", "score": 0.2},
        {"label": "tailscale alias を .zshrc に再追加", "score": 0.1}
      ]
    }
  ]
}
```

### state 値（status 用）

| state | 表示 | 色 |
|-------|------|-----|
| `done` | ✓ DONE | `--accent` |
| `wip` | ◐ WIP | `--warn` |
| `todo` | ○ TODO | `--text-dim` |
| `blocked` | ✗ BLOCKED | `--danger` |

### type 値（qa 用）

| type | UI |
|------|-----|
| `yesno` | Yes / No / Skip の 3 ボタン |
| `multi` | 単一選択ラジオ + Skip |
| `multiSelect` | 複数選択チェックボックス |
| `text` | textarea（自由記述） |

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

/* ===== Grid scaffold (Müller-Brockmann 12-col) ===== */
.spread { position: relative; width: 100%; }
.wrap { position: relative; max-width: var(--maxw); margin: 0 auto; padding: var(--pad) var(--margin); }
.grid { display: grid; grid-template-columns: repeat(var(--cols), 1fr); column-gap: var(--gutter); row-gap: var(--lh); }
.band { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: start; }
@supports not (grid-template-columns: subgrid) { .band { grid-template-columns: repeat(var(--cols), 1fr); } }

/* ===== Grid overlay (INSIDE .wrap) ===== */
.guides { position: absolute; inset: 0; pointer-events: none; z-index: 60; opacity: 0; transition: opacity .26s ease; }
body.grid-on .guides { opacity: 1; }
.guides .cols { position: absolute; top: 0; bottom: 0; left: var(--margin); right: var(--margin); display: grid; grid-template-columns: repeat(var(--cols), 1fr); column-gap: var(--gutter); }
.guides .col { background: var(--g-col); box-shadow: inset 1px 0 0 var(--g-edge), inset -1px 0 0 var(--g-edge); position: relative; }
.guides .col span { position: absolute; top: 32px; left: 0; right: 0; text-align: center; font-family: var(--font-mono); font-size: 10px; line-height: 1; color: var(--accent); opacity: 0.6; }
.guides .rows { position: absolute; left: var(--margin); right: var(--margin); top: var(--pad); bottom: 0; background-image: repeating-linear-gradient(to bottom, var(--g-base) 0 1px, transparent 1px var(--lh)), repeating-linear-gradient(to bottom, var(--g-base-min) 0 1px, transparent 1px var(--bl)); }
.guides .mline { position: absolute; top: 0; bottom: 0; width: 1px; background: var(--g-edge); }
.guides .mline.l { left: var(--margin); } .guides .mline.r { right: var(--margin); }

/* ================================================================
   TYPOGRAPHY — 3 sizes only (Müller-Brockmann)
   Display 32px / Body 16px / Caption 11px
   All line-heights = multiples of --bl (8px)
   ================================================================ */

/* ===== Toolbar ===== */
.toolbar { position: fixed; top: 16px; right: 16px; z-index: 200; display: flex; align-items: center; gap: 8px; }
.toolbar button { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.1em; text-transform: uppercase; padding: 8px 16px; border: 1px solid var(--border-accent); background: var(--surface); color: var(--text-muted); cursor: pointer; transition: all 0.15s; line-height: var(--lh); }
.toolbar button:hover { border-color: var(--accent); color: var(--accent); }
.toolbar button.active { background: var(--accent); color: var(--bg); border-color: var(--accent); }

/* ===== Header ===== */
.header { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: end; padding-bottom: var(--lh); border-bottom: 2px solid var(--accent); }
@supports not (grid-template-columns: subgrid) { .header { grid-template-columns: repeat(var(--cols), 1fr); } }
.header h1 { grid-column: 1 / 9; font-family: var(--font-mono); font-size: 32px; font-weight: 700; line-height: 32px; letter-spacing: -0.02em; color: var(--accent); }
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta { grid-column: 9 / 13; font-family: var(--font-mono); color: var(--text-muted); font-size: 11px; text-align: right; line-height: var(--lh); letter-spacing: 0.04em; }

/* ===== Summary ===== */
.summary-text { font-size: 16px; line-height: var(--lh); color: var(--text); }
.summary-accent { grid-column: 1 / 1; width: 3px; background: var(--cyan); align-self: stretch; justify-self: start; }

/* ===== Section head (folio-style) ===== */
.section-head { font-family: var(--font-mono); font-size: 11px; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.12em; line-height: var(--lh); }
.tag { font-family: var(--font-mono); font-size: 11px; color: var(--accent); background: var(--accent-dim); padding: 0 8px; letter-spacing: 0.06em; line-height: var(--lh); justify-self: end; align-self: center; }
.rule { grid-column: 1 / -1; border: none; border-top: 1px solid var(--border); margin: 0; height: 0; }

/* ===== Status rows ===== */
.status-row { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: center; }
@supports not (grid-template-columns: subgrid) { .status-row { grid-template-columns: repeat(var(--cols), 1fr); } }
.state-badge { font-family: var(--font-mono); font-size: 11px; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; line-height: var(--lh); }
.state-done { color: var(--accent); }
.state-wip  { color: var(--warn); }
.state-todo { color: var(--text-dim); }
.state-blocked { color: var(--danger); }
.status-label { font-size: 16px; line-height: var(--lh); }

/* ===== QA items ===== */
.qa-row { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: start; padding-top: 8px; padding-bottom: 8px; border-bottom: 1px solid var(--border); }
@supports not (grid-template-columns: subgrid) { .qa-row { grid-template-columns: repeat(var(--cols), 1fr); } }
.qa-row:last-of-type { border-bottom: none; }
.qa-label { font-size: 16px; color: var(--text); font-weight: 500; line-height: var(--lh); }
.qa-id { font-family: var(--font-mono); font-size: 11px; color: var(--text-dim); margin-right: 8px; }
.qa-controls { grid-column: 1 / 13; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); }
@supports not (grid-template-columns: subgrid) { .qa-controls { grid-template-columns: repeat(12, 1fr); } }
.qa-opt { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.06em; padding: 8px 0; background: var(--surface-hover); color: var(--text); border: 1px solid var(--border-accent); cursor: pointer; transition: all 0.15s; user-select: none; line-height: var(--lh); text-align: center; }
.qa-opt:hover { border-color: var(--accent); }
.qa-opt.selected { background: var(--accent-dim); border-color: var(--accent); color: var(--accent); }
.qa-opt.no.selected { background: rgba(255,85,85,0.15); border-color: var(--danger); color: var(--danger); }
.qa-opt.skip.selected { background: var(--surface); color: var(--text-muted); border-color: var(--border-accent); }
.qa-text { width: 100%; min-height: 72px; background: var(--surface-hover); color: var(--text); border: 1px solid var(--border-accent); padding: 8px 16px; font-family: var(--font-mono); font-size: 11px; resize: vertical; line-height: var(--lh); }
.qa-text:focus { outline: none; border-color: var(--accent); }

/* ===== Actions ===== */
.action-row { grid-column: 1 / -1; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); align-items: center; }
@supports not (grid-template-columns: subgrid) { .action-row { grid-template-columns: repeat(var(--cols), 1fr); } }
.action-label { font-size: 16px; line-height: var(--lh); }
.action-score { font-family: var(--font-mono); font-size: 11px; font-weight: 700; color: var(--cyan); text-align: right; line-height: var(--lh); }

/* ===== Buttons (on the grid) ===== */
.btn { font-family: var(--font-mono); font-size: 11px; letter-spacing: 0.06em; padding: 8px 0; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; text-transform: uppercase; transition: all 0.15s; line-height: var(--lh); text-align: center; }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { filter: brightness(0.85); }
.preview { background: var(--surface); border: 1px solid var(--border); padding: 16px; font-family: var(--font-mono); font-size: 11px; color: var(--text-muted); max-height: 280px; overflow: auto; white-space: pre-wrap; word-break: break-all; line-height: var(--lh); margin-top: 16px; }

/* ===== Footer ===== */
.footer { grid-column: 1 / -1; padding-top: var(--lh); border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 11px; color: var(--text-dim); letter-spacing: 0.06em; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); line-height: var(--lh); }
@supports not (grid-template-columns: subgrid) { .footer { grid-template-columns: repeat(var(--cols), 1fr); } }
.footer .left { grid-column: 1 / 7; } .footer .right { grid-column: 7 / 13; text-align: right; }

/* ===== Spacer ===== */
.spacer-2 { grid-column: 1 / -1; height: 48px; }
.spacer-1 { grid-column: 1 / -1; height: var(--lh); }

/* ===== Toast ===== */
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 11px; padding: 8px 16px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 1000; max-width: 360px; line-height: var(--lh); }
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
        <div class="meta">GEN {{DATE}}<br>MODE STATUS</div>
      </div>

      <div class="band">
        <div class="summary-accent" style="grid-column: 1 / 2;"></div>
        <p class="summary-text" style="grid-column: 2 / 11;">{{SUMMARY}}</p>
      </div>

      <div id="root" style="display: contents;"></div>

      <div class="spacer-1"></div>
      <div class="band">
        <h2 class="section-head" style="grid-column: 1 / 7;">結果のエクスポート</h2>
        <span class="tag" style="grid-column: 11 / 13;">EXPORT</span>
      </div>
      <div class="band"><hr class="rule" style="grid-column: 1 / -1;"></div>
      <div class="band" id="export-btns">
        <button class="btn primary" onclick="copyResult()">JSON コピー</button>
        <button class="btn" onclick="copyMarkdown()">MD コピー</button>
        <button class="btn" onclick="togglePreview()">プレビュー</button>
        <button class="btn" onclick="resetAll()">リセット</button>
      </div>
      <div class="band">
        <div id="preview-container" style="grid-column: 1/-1; display:none;">
          <div class="preview" id="preview">（未回答）</div>
        </div>
      </div>

      <div class="footer">
        <span class="left">HTML SKILL v1.0.0 / STATUS MODE</span>
        <span class="right">GENERATED BY CLAUDE CODE // G = grid overlay</span>
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
const DATA = {{DATA_JSON}};
const answers = {};

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

/* ===== Toast + clipboard ===== */
function toast(msg, kind = 'ok') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.style.borderColor = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.style.color = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.classList.add('show');
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(() => t.classList.remove('show'), 2400);
}
async function copyText(text, label) {
  try { await navigator.clipboard.writeText(text); toast(label || 'コピーしました'); }
  catch (err) { toast('コピー失敗: ' + err.message, 'err'); }
}
function escapeHtml(s) {
  if (s == null) return '';
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

/* ===== Content-aware column span ===== */
function setSpan(btn) {
  const text = btn.textContent;
  let w = 0;
  for (const ch of text) {
    w += /[　-鿿＀-￯]/.test(ch) ? 2 : 1;
  }
  const span = w <= 8 ? 2 : w <= 16 ? 3 : 4;
  btn.style.gridColumn = 'span ' + span;
}

/* ===== Render — all elements placed on the 12-col grid ===== */
function renderRoot() {
  const root = document.getElementById('root');
  root.innerHTML = '';

  DATA.sections.forEach((sec, si) => {
    const tagText = {status:'STATUS', qa:'Q & A', actions:'ACTIONS', checklist:'CHECK'}[sec.kind] || 'INFO';

    if (si > 0) {
      const sp = document.createElement('div');
      sp.className = 'spacer-2';
      root.appendChild(sp);
    }

    const headBand = document.createElement('div');
    headBand.className = 'band';
    headBand.innerHTML = `<h2 class="section-head" style="grid-column:1/7;">${escapeHtml(sec.title)}</h2><span class="tag" style="grid-column:11/13;">${tagText}</span>`;
    root.appendChild(headBand);

    const ruleBand = document.createElement('div');
    ruleBand.className = 'band';
    ruleBand.innerHTML = '<hr class="rule" style="grid-column:1/-1;">';
    root.appendChild(ruleBand);

    if (sec.kind === 'status') renderStatus(root, sec);
    else if (sec.kind === 'qa' || sec.kind === 'checklist') renderQA(root, sec);
    else if (sec.kind === 'actions') renderActions(root, sec);
  });
}

function renderStatus(root, sec) {
  for (const it of sec.items) {
    const row = document.createElement('div');
    row.className = 'status-row';
    const stLabel = {done:'✓ DONE', wip:'◐ WIP', todo:'○ TODO', blocked:'✗ BLOCKED'}[it.state] || '○ TODO';
    row.innerHTML = `<span class="state-badge state-${it.state||'todo'}" style="grid-column:1/3;">${stLabel}</span><span class="status-label" style="grid-column:3/13;">${escapeHtml(it.label)}</span>`;
    root.appendChild(row);
  }
}

function renderQA(root, sec) {
  for (const it of sec.items) {
    const row = document.createElement('div');
    row.className = 'qa-row';

    const label = document.createElement('div');
    label.className = 'qa-label';
    label.style.gridColumn = '1 / 13';
    label.innerHTML = `<span class="qa-id">${escapeHtml(it.id||'')}</span>${escapeHtml(it.label)}`;
    row.appendChild(label);

    const ctrls = document.createElement('div');
    ctrls.className = 'qa-controls';
    const allBtns = [];

    if (it.type === 'yesno') {
      ['yes','no','skip'].forEach(v => {
        const b = document.createElement('button');
        b.className = `qa-opt ${v}`;
        b.textContent = v.toUpperCase();
        b.dataset.value = v;
        b.onclick = () => { answers[it.id] = v; refreshSel(ctrls, v); };
        ctrls.appendChild(b); allBtns.push(b);
      });
    } else if (it.type === 'multi') {
      (it.options||[]).forEach(opt => {
        const b = document.createElement('button');
        b.className = 'qa-opt'; b.textContent = opt; b.dataset.value = opt;
        b.onclick = () => { answers[it.id] = opt; refreshSel(ctrls, opt); };
        ctrls.appendChild(b); allBtns.push(b);
      });
      const skip = document.createElement('button');
      skip.className = 'qa-opt skip'; skip.textContent = 'SKIP'; skip.dataset.value = '__skip';
      skip.onclick = () => { answers[it.id] = '__skip'; refreshSel(ctrls, '__skip'); };
      ctrls.appendChild(skip); allBtns.push(skip);
    } else if (it.type === 'multiSelect') {
      (it.options||[]).forEach(opt => {
        const b = document.createElement('button');
        b.className = 'qa-opt'; b.textContent = opt; b.dataset.value = opt;
        b.onclick = () => {
          const cur = answers[it.id] || [];
          const idx = cur.indexOf(opt);
          if (idx >= 0) cur.splice(idx,1); else cur.push(opt);
          answers[it.id] = cur;
          b.classList.toggle('selected', cur.includes(opt));
        };
        ctrls.appendChild(b); allBtns.push(b);
      });
    } else if (it.type === 'text') {
      const ta = document.createElement('textarea');
      ta.className = 'qa-text'; ta.style.gridColumn = '1 / 13';
      ta.placeholder = 'ここに入力...';
      ta.oninput = () => { answers[it.id] = ta.value; };
      ctrls.appendChild(ta);
    }

    allBtns.forEach(b => setSpan(b));
    row.appendChild(ctrls);
    root.appendChild(row);
  }
}

function refreshSel(ctrls, value) {
  ctrls.querySelectorAll('.qa-opt').forEach(b => b.classList.toggle('selected', b.dataset.value === value));
}

function renderActions(root, sec) {
  for (const it of sec.items) {
    const row = document.createElement('div');
    row.className = 'action-row';
    const score = it.score != null ? Math.round(it.score * 100) + '%' : '—';
    row.innerHTML = `<span class="action-label" style="grid-column:1/11;">${escapeHtml(it.label)}</span><span class="action-score" style="grid-column:11/13;">${score}</span>`;
    root.appendChild(row);
  }
}

/* ===== Export ===== */
function buildResult() { return {title: DATA.title, timestamp: new Date().toISOString(), answers}; }
function copyResult() {
  copyText(JSON.stringify(buildResult(), null, 2), '結果を JSON でコピーしました（Claude に貼り戻し可）');
  updatePreview();
}
function copyMarkdown() {
  const lines = [`# ${DATA.title}`,'',`_${new Date().toLocaleString('ja-JP')}_`,''];
  for (const [qid,val] of Object.entries(answers)) {
    const d = Array.isArray(val) ? val.join(', ') : (val==='__skip'?'skip':val);
    lines.push(`- **${qid}**: ${d}`);
  }
  copyText(lines.join('\n'), '結果を Markdown でコピーしました');
  updatePreview();
}
function togglePreview() {
  const c = document.getElementById('preview-container');
  c.style.display = c.style.display === 'none' ? 'block' : 'none';
  updatePreview();
}
function updatePreview() { document.getElementById('preview').textContent = JSON.stringify(buildResult(), null, 2); }
function resetAll() {
  for (const k of Object.keys(answers)) delete answers[k];
  renderRoot();
  updatePreview();
  toast('リセットしました');
}

renderRoot();
document.querySelectorAll('#export-btns .btn').forEach(b => setSpan(b));
</script>
</body>
</html>
```

## 使い方メモ

- 各設問の `id` は短いキー（`q1`, `migrate`, `push_main` 等）
- `kind: "actions"` は推奨確率サマリー用（クリック不可、0〜1 で指定）
- **`G` キー** でグリッドオーバーレイ / **☀/☾** でテーマ切替
- パネル box なし — 全要素がグリッドカラムに直接配置（セクション区切りはルール線）
- ボタン幅は内容ベースの `span 2/3/4`（`setSpan()`）、余りはホワイトスペース
- 級数は **32px / 16px / 11px** の 3段階のみ、全 line-height が 8px の倍数
