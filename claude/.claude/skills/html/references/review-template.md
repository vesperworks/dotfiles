# Image Review Mode Template

画像（スクリーンショット・モックアップ・デザイン）を表示しつつ、
横に **スコア（5 段階）+ チェックリスト + 評価コメント記入欄** を並べる「採点シート」UI。

UI/UX レビュー、デザインレビュー、コーディング画面の点検、PR スクショ評価などに使う。
annotate モードが「描き込み」中心なのに対し、image-review は「**判定と記録**」が中心。

Müller-Brockmann 12カラムグリッド + LIGHT/DARK テーマ切替対応。

## Data Schema

```json
{
  "title": "ログイン画面 v3 デザインレビュー",
  "imageSrc": "data:image/png;base64,..." または "file:///abs/path",
  "imagePath": "/abs/path/to/image.png",
  "summary": "新ログイン画面の最終確認。アクセシビリティ・整合性・ブランド一貫性を評価",
  "criteria": [
    {"id": "visual",  "label": "ビジュアルデザイン",  "weight": 0.25, "rubric": ["配色", "余白", "タイポグラフィ"]},
    {"id": "ux",      "label": "ユーザビリティ",      "weight": 0.30, "rubric": ["導線", "情報密度", "迷わなさ"]},
    {"id": "a11y",    "label": "アクセシビリティ",    "weight": 0.20, "rubric": ["コントラスト", "ARIA", "キーボード操作"]},
    {"id": "consist", "label": "一貫性",              "weight": 0.15, "rubric": ["既存コンポーネントとの整合", "スタイルガイド準拠"]},
    {"id": "polish",  "label": "完成度",              "weight": 0.10, "rubric": ["細部の作り込み", "状態表現"]}
  ],
  "checklist": [
    {"id": "c1", "label": "コントラスト比 4.5:1 以上を満たしている"},
    {"id": "c2", "label": "フォーカスリングが視認できる"},
    {"id": "c3", "label": "エラー時のメッセージが具体的"},
    {"id": "c4", "label": "ロード状態の表示がある"}
  ]
}
```

- `criteria` 各項目は **5 段階スコア**（1=NG / 2=要修正 / 3=可 / 4=良 / 5=優）
- 加重平均で **総合スコア** を自動算出（重みの合計が 1.0 でなくても正規化される）
- `checklist` は単純な ✓/✗ トグル
- 自由記述コメント欄（全体 + 項目別）

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
<script src="https://html2canvas.hertzen.com/dist/html2canvas.min.js"></script>
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
.header .meta { grid-column: 9 / 13; font-family: var(--font-mono); color: var(--text-muted); font-size: 0.72rem; text-align: right; line-height: var(--lh); letter-spacing: 0.03em; }

/* ===== Summary ===== */
.summary { grid-column: 1 / -1; background: var(--surface); border-left: 3px solid var(--cyan); padding: 16px var(--gutter); font-size: 0.92rem; line-height: var(--lh); }

/* ===== 2-column layout via grid-column ===== */
.image-pane { grid-column: 1 / 8; background: var(--surface); border: 1px solid var(--border); padding: 16px; position: sticky; top: 16px; display: flex; flex-direction: column; gap: 16px; }
.image-frame { background: var(--bg); border: 1px dashed var(--border-accent); padding: 16px; display: flex; align-items: center; justify-content: center; min-height: 280px; }
.image-pane img { display: block; max-width: 100%; max-height: 72vh; height: auto; width: auto; object-fit: contain; margin: 0 auto; cursor: crosshair; }
.image-meta { font-family: var(--font-mono); font-size: 0.65rem; color: var(--text-dim); word-break: break-all; line-height: var(--lh); }
.image-toolbar { display: flex; gap: 8px; flex-wrap: wrap; }
.image-hint { font-family: var(--font-mono); font-size: 0.65rem; color: var(--text-muted); line-height: var(--lh); }

.review-pane { grid-column: 8 / 13; display: flex; flex-direction: column; gap: var(--lh); }
@media (max-width: 900px) {
  .image-pane { grid-column: 1 / -1; position: static; }
  .review-pane { grid-column: 1 / -1; }
}

/* ===== Panel ===== */
.panel { background: var(--surface); border: 1px solid var(--border); overflow: hidden; }
.panel-header { display: flex; justify-content: space-between; align-items: center; padding: 12px var(--gutter); border-bottom: 1px solid var(--border); }
.panel-header h2 { font-family: var(--font-mono); font-size: 0.7rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; line-height: var(--lh); }
.panel-header .tag { font-family: var(--font-mono); font-size: 0.6rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; letter-spacing: 0.05em; line-height: 16px; }
.panel-body { padding: 16px var(--gutter); }

/* ===== Score gauge ===== */
.gauge { display: grid; grid-template-columns: 1fr auto; gap: 16px; align-items: center; padding: 4px 0; }
.gauge-label { font-size: 0.85rem; line-height: var(--lh); }
.gauge-rubric { font-family: var(--font-mono); font-size: 0.62rem; color: var(--text-dim); margin-top: 2px; line-height: 16px; }
.score-buttons { display: flex; gap: 4px; }
.score-btn { font-family: var(--font-mono); width: 32px; height: 32px; font-size: 0.78rem; font-weight: 700; background: var(--surface-hover); color: var(--text-muted); border: 1px solid var(--border-accent); cursor: pointer; transition: all 0.12s; line-height: 32px; }
.score-btn:hover { color: var(--text); border-color: var(--accent); }
.score-btn.s1.selected { background: rgba(204,0,0,0.15); color: var(--danger); border-color: var(--danger); }
.score-btn.s2.selected { background: rgba(255,119,0,0.15); color: #ff7700; border-color: #ff7700; }
[data-theme="light"] .score-btn.s2.selected { background: rgba(180,80,0,0.12); color: #b85000; border-color: #b85000; }
.score-btn.s3.selected { background: rgba(184,110,0,0.15); color: var(--warn); border-color: var(--warn); }
.score-btn.s4.selected { background: var(--cyan-dim); color: var(--cyan); border-color: var(--cyan); }
.score-btn.s5.selected { background: var(--accent-dim); color: var(--accent); border-color: var(--accent); }
.criterion-row { padding: 12px 0; border-bottom: 1px solid var(--border); }
.criterion-row:last-child { border-bottom: none; }

/* ===== Total ===== */
.total-row { display: grid; grid-template-columns: 1fr auto; gap: 16px; padding: 12px var(--gutter); background: var(--surface-hover); border-top: 1px solid var(--accent); align-items: center; }
.total-label { font-family: var(--font-mono); font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; line-height: var(--lh); }
.total-value { font-family: var(--font-mono); font-size: 1.5rem; font-weight: 700; color: var(--accent); line-height: 32px; }
.total-stars { font-family: var(--font-mono); font-size: 0.9rem; color: var(--warn); margin-top: 2px; line-height: var(--lh); }

/* ===== Checklist ===== */
.check-row { display: grid; grid-template-columns: 32px 1fr; gap: 12px; align-items: center; padding: 8px 0; cursor: pointer; }
.check-box { width: 24px; height: 24px; border: 1px solid var(--border-accent); background: var(--surface-hover); display: flex; align-items: center; justify-content: center; font-family: var(--font-mono); font-size: 0.85rem; transition: all 0.12s; line-height: 24px; }
.check-box.on { background: var(--accent-dim); color: var(--accent); border-color: var(--accent); }
.check-box.off { color: transparent; }
.check-label { font-size: 0.88rem; user-select: none; line-height: var(--lh); }
.check-label.done { color: var(--text-muted); text-decoration: line-through; }

/* ===== Comment ===== */
.comment-area { width: 100%; min-height: 96px; background: var(--surface-hover); color: var(--text); border: 1px solid var(--border-accent); padding: 12px 16px; font-family: var(--font-mono); font-size: 0.82rem; resize: vertical; line-height: var(--lh); }
.comment-area:focus { outline: none; border-color: var(--accent); }

/* ===== Buttons ===== */
.btn-row { display: flex; gap: 10px; flex-wrap: wrap; padding: 12px var(--gutter); border-top: 1px solid var(--border); }
.btn { font-family: var(--font-mono); font-size: 0.7rem; padding: 8px 16px; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; letter-spacing: 0.05em; text-transform: uppercase; transition: all 0.15s; line-height: var(--lh); }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { filter: brightness(0.85); }

/* ===== Footer ===== */
.footer { grid-column: 1 / -1; padding-top: var(--lh); border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); letter-spacing: 0.05em; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); line-height: var(--lh); }
@supports not (grid-template-columns: subgrid) { .footer { grid-template-columns: repeat(var(--cols), 1fr); } }
.footer .left { grid-column: 1 / 7; } .footer .right { grid-column: 7 / 13; text-align: right; }

/* ===== Toast ===== */
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 0.8rem; padding: 12px 18px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 1000; max-width: 360px; line-height: var(--lh); }
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
        <div class="meta">GEN {{DATE}}<br>MODE IMAGE-REVIEW</div>
      </div>

      <div class="summary">{{SUMMARY}}</div>

      <!-- 2-column: image (col 1-7) + review (col 8-13) -->
      <div class="band">
        <div class="image-pane">
          <div class="image-frame">
            <img id="target-img" src="{{IMAGE_SRC}}" alt="review target">
          </div>
          <div class="image-toolbar">
            <button class="btn primary" onclick="openMarker()">注釈ツール（丸・矢印・テキスト）</button>
            <button class="btn" onclick="resetAnnotation()">注釈リセット</button>
          </div>
          <div class="image-hint">画像クリックでも注釈ツールが開きます。注釈完了後、下の「総評」エリアで「結果スクショ」ボタンを押すと、画像+スコア+チェック+コメント一式が PNG で出力されます。</div>
          <div class="image-meta">SRC: {{IMAGE_PATH}}</div>
        </div>

        <div class="review-pane">
          <div class="panel">
            <div class="panel-header"><h2>評価軸（5 段階スコア）</h2><span class="tag">CRITERIA</span></div>
            <div class="panel-body" id="criteria-body"></div>
            <div class="total-row">
              <div>
                <div class="total-label">総合スコア</div>
                <div class="total-stars" id="total-stars">☆☆☆☆☆</div>
              </div>
              <div class="total-value" id="total-value">—</div>
            </div>
          </div>

          <div class="panel">
            <div class="panel-header"><h2>チェックリスト</h2><span class="tag">CHECK</span></div>
            <div class="panel-body" id="check-body"></div>
          </div>

          <div class="panel">
            <div class="panel-header"><h2>総評コメント</h2><span class="tag">COMMENT</span></div>
            <div class="panel-body">
              <textarea class="comment-area" id="overall-comment" placeholder="全体所見・気づき・推奨修正など..."></textarea>
            </div>
            <div class="btn-row">
              <button class="btn primary" onclick="copyScreenshotPng()">結果スクショを PNG でコピー</button>
              <button class="btn" onclick="downloadScreenshotPng()">PNG ダウンロード</button>
              <button class="btn" onclick="copyResult()">JSON でコピー</button>
              <button class="btn" onclick="copyMarkdown()">Markdown でコピー</button>
              <button class="btn" onclick="resetAll()">リセット</button>
            </div>
          </div>
        </div>
      </div>

      <div class="footer">
        <span class="left">HTML SKILL v1.0.0 / IMAGE-REVIEW MODE</span>
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
const DATA = {{DATA_JSON}};
const STATE = {
  scores: {},
  perComments: {},
  checks: {},
  overall: '',
  originalImgSrc: null,
  markerState: null
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
  return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

/* ===== Criteria rendering ===== */
function renderCriteria() {
  const body = document.getElementById('criteria-body');
  body.innerHTML = '';
  for (const c of (DATA.criteria || [])) {
    const row = document.createElement('div');
    row.className = 'criterion-row';
    const rubric = (c.rubric || []).join(' / ');
    const weight = c.weight != null ? ` <span style="color:var(--text-dim)">(w=${c.weight})</span>` : '';
    row.innerHTML = `
      <div class="gauge">
        <div>
          <div class="gauge-label">${escapeHtml(c.label)}${weight}</div>
          ${rubric ? `<div class="gauge-rubric">${escapeHtml(rubric)}</div>` : ''}
        </div>
        <div class="score-buttons" data-cid="${escapeHtml(c.id)}"></div>
      </div>
      <textarea class="comment-area" placeholder="この項目のコメント..." style="min-height:48px;font-size:0.76rem;margin-top:8px;" data-cmt="${escapeHtml(c.id)}"></textarea>
    `;
    const btnContainer = row.querySelector('.score-buttons');
    for (let s = 1; s <= 5; s++) {
      const b = document.createElement('button');
      b.className = `score-btn s${s}`;
      b.textContent = s;
      b.onclick = () => { STATE.scores[c.id] = s; refreshScoreButtons(c.id); recalcTotal(); };
      b.dataset.score = s;
      btnContainer.appendChild(b);
    }
    const cmt = row.querySelector('textarea[data-cmt]');
    cmt.oninput = () => { STATE.perComments[c.id] = cmt.value; };
    body.appendChild(row);
  }
}

function refreshScoreButtons(cid) {
  const container = document.querySelector(`.score-buttons[data-cid="${CSS.escape(cid)}"]`);
  if (!container) return;
  container.querySelectorAll('.score-btn').forEach(b => {
    b.classList.toggle('selected', Number(b.dataset.score) === STATE.scores[cid]);
  });
}

/* ===== Checklist rendering ===== */
function renderChecklist() {
  const body = document.getElementById('check-body');
  body.innerHTML = '';
  for (const it of (DATA.checklist || [])) {
    const row = document.createElement('div');
    row.className = 'check-row';
    row.innerHTML = `<div class="check-box off">✓</div><div class="check-label">${escapeHtml(it.label)}</div>`;
    const box = row.querySelector('.check-box');
    const label = row.querySelector('.check-label');
    row.onclick = () => {
      STATE.checks[it.id] = !STATE.checks[it.id];
      const on = !!STATE.checks[it.id];
      box.classList.toggle('on', on);
      box.classList.toggle('off', !on);
      label.classList.toggle('done', on);
    };
    body.appendChild(row);
  }
}

/* ===== Total score ===== */
function recalcTotal() {
  const criteria = DATA.criteria || [];
  let sumWeight = 0, sumWeighted = 0;
  for (const c of criteria) {
    const s = STATE.scores[c.id];
    if (s == null) continue;
    const w = c.weight != null ? c.weight : 1;
    sumWeight += w;
    sumWeighted += s * w;
  }
  if (sumWeight === 0) {
    document.getElementById('total-value').textContent = '—';
    document.getElementById('total-stars').textContent = '☆☆☆☆☆';
    return;
  }
  const avg = sumWeighted / sumWeight;
  document.getElementById('total-value').textContent = avg.toFixed(2) + ' / 5';
  const filled = Math.round(avg);
  document.getElementById('total-stars').textContent = '★'.repeat(filled) + '☆'.repeat(5 - filled);
}

document.getElementById('overall-comment').addEventListener('input', e => { STATE.overall = e.target.value; });

/* ===== Build result ===== */
function buildResult() {
  const criteria = DATA.criteria || [];
  let sumWeight = 0, sumWeighted = 0;
  const scored = [];
  for (const c of criteria) {
    const s = STATE.scores[c.id];
    const w = c.weight != null ? c.weight : 1;
    if (s != null) { sumWeight += w; sumWeighted += s * w; }
    scored.push({ id: c.id, label: c.label, score: s ?? null, weight: w, comment: STATE.perComments[c.id] || null });
  }
  return {
    title: DATA.title,
    timestamp: new Date().toISOString(),
    image: DATA.imagePath,
    total: sumWeight ? +(sumWeighted / sumWeight).toFixed(2) : null,
    criteria: scored,
    checklist: (DATA.checklist || []).map(it => ({ id: it.id, label: it.label, passed: !!STATE.checks[it.id] })),
    overall_comment: STATE.overall
  };
}

function copyResult() {
  copyText(JSON.stringify(buildResult(), null, 2), 'レビュー結果を JSON でコピー（Claude に貼り戻し可）');
}

/* ===== Markerjs2 annotation ===== */
function openMarker() {
  const img = document.getElementById('target-img');
  if (typeof markerjs2 === 'undefined') {
    toast('Markerjs2 のロード失敗（ネット接続/CDN を確認）', 'err');
    return;
  }
  if (STATE.originalImgSrc == null) STATE.originalImgSrc = img.src;
  const ma = new markerjs2.MarkerArea(img);
  ma.settings.displayMode = 'popup';
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
  ma.uiStyleSettings.toolbarBackgroundColor = isDark ? '#111111' : '#f4f4f4';
  ma.uiStyleSettings.toolbarBackgroundHoverColor = isDark ? '#1a1a1a' : '#eaeaea';
  ma.uiStyleSettings.toolbarColor = isDark ? '#e0e0e0' : '#111315';
  ma.uiStyleSettings.toolboxBackgroundColor = isDark ? '#0a0a0a' : '#ffffff';
  ma.uiStyleSettings.toolboxColor = isDark ? '#00ff88' : '#e4002b';
  ma.uiStyleSettings.toolboxAccentColor = isDark ? '#00ff88' : '#e4002b';
  ma.addEventListener('render', (evt) => {
    img.src = evt.dataUrl;
    STATE.markerState = evt.state;
  });
  if (STATE.markerState) ma.restoreState(STATE.markerState);
  ma.show();
}

function resetAnnotation() {
  const img = document.getElementById('target-img');
  if (STATE.originalImgSrc) img.src = STATE.originalImgSrc;
  STATE.markerState = null;
  toast('注釈をリセットしました');
}

document.getElementById('target-img').addEventListener('click', () => {
  if (typeof markerjs2 !== 'undefined' && !document.querySelector('.markerjs-overlay')) openMarker();
});

/* ===== Screenshot export (html2canvas) ===== */
async function captureScreenshot() {
  if (typeof html2canvas === 'undefined') throw new Error('html2canvas のロードに失敗');
  const bgColor = getComputedStyle(document.documentElement).getPropertyValue('--bg').trim();
  const canvas = await html2canvas(document.body, {
    backgroundColor: bgColor || '#0a0a0a',
    scale: window.devicePixelRatio || 1,
    useCORS: true,
    logging: false
  });
  return canvas;
}

async function copyScreenshotPng() {
  toast('スクショ作成中...');
  try {
    const canvas = await captureScreenshot();
    canvas.toBlob(async (blob) => {
      if (!blob) { toast('PNG 化失敗', 'err'); return; }
      try {
        const item = new ClipboardItem({ 'image/png': blob });
        await navigator.clipboard.write([item]);
        toast('結果スクショを PNG でコピー（Cmd+V で貼り戻し）');
      } catch (err) {
        toast('クリップボード失敗: ' + err.message + '（ダウンロードしてください）', 'err');
      }
    }, 'image/png');
  } catch (err) {
    toast('スクショ失敗: ' + err.message, 'err');
  }
}

async function downloadScreenshotPng() {
  toast('スクショ作成中...');
  try {
    const canvas = await captureScreenshot();
    canvas.toBlob(blob => {
      if (!blob) { toast('PNG 化失敗', 'err'); return; }
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = 'review-' + Date.now() + '.png';
      a.click();
      URL.revokeObjectURL(url);
      toast('PNG をダウンロードしました');
    }, 'image/png');
  } catch (err) {
    toast('スクショ失敗: ' + err.message, 'err');
  }
}

function copyMarkdown() {
  const r = buildResult();
  const lines = [`# ${r.title}`, '', `_${new Date().toLocaleString('ja-JP')}_`, ''];
  lines.push(`**総合スコア**: ${r.total != null ? r.total + ' / 5' : '未評価'}`);
  lines.push('');
  lines.push('## 評価軸');
  for (const c of r.criteria) {
    const s = c.score != null ? `${c.score}/5` : '—';
    lines.push(`- **${c.label}** (w=${c.weight}): ${s}`);
    if (c.comment) lines.push(`  - ${c.comment}`);
  }
  lines.push('');
  lines.push('## チェックリスト');
  for (const it of r.checklist) lines.push(`- [${it.passed ? 'x' : ' '}] ${it.label}`);
  if (r.overall_comment) {
    lines.push('');
    lines.push('## 総評');
    lines.push(r.overall_comment);
  }
  copyText(lines.join('\n'), '結果を Markdown でコピーしました');
}

function resetAll() {
  STATE.scores = {}; STATE.perComments = {}; STATE.checks = {}; STATE.overall = '';
  document.getElementById('overall-comment').value = '';
  renderCriteria();
  renderChecklist();
  recalcTotal();
  toast('リセットしました');
}

renderCriteria();
renderChecklist();
recalcTotal();
</script>
</body>
</html>
```

## デフォルト criteria（UI/UX レビュー用、ユーザー指定なき時の推奨）

```json
[
  {"id": "visual",  "label": "ビジュアルデザイン", "weight": 0.25, "rubric": ["配色", "余白", "タイポ"]},
  {"id": "ux",      "label": "ユーザビリティ",     "weight": 0.30, "rubric": ["導線", "情報密度", "迷わなさ"]},
  {"id": "a11y",    "label": "アクセシビリティ",   "weight": 0.20, "rubric": ["コントラスト", "ARIA", "キーボード"]},
  {"id": "consist", "label": "一貫性",             "weight": 0.15, "rubric": ["既存コンポーネント整合"]},
  {"id": "polish",  "label": "完成度",             "weight": 0.10, "rubric": ["細部の作り込み"]}
]
```

## 使い分け（annotate vs image-review）

| 用途 | モード |
|------|-------|
| **画像のここに矢印・丸つけて → 貼り戻したい** | `annotate` |
| **画像を見て点数つけて記録したい / コメントを残したい** | `image-review` |
| **両方欲しい** | annotate → image-review の順で 2 ファイル生成 |

## ライセンス・依存

- Markerjs2（CDN） — 注釈ツール
- html2canvas（CDN） — 結果スクショ
- **`G` キー** でグリッドオーバーレイ表示 — レイアウト確認用
- **テーマトグル（☀/☾）** で LIGHT/DARK 切替、`localStorage` で永続化
