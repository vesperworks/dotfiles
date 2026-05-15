# Image Review Mode Template

画像（スクリーンショット・モックアップ・デザイン）を表示しつつ、
横に **スコア（5 段階）+ チェックリスト + 評価コメント記入欄** を並べる「採点シート」UI。

UI/UX レビュー、デザインレビュー、コーディング画面の点検、PR スクショ評価などに使う。
annotate モードが「描き込み」中心なのに対し、image-review は「**判定と記録**」が中心。

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
<html lang="ja">
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
:root {
  --bg: #0a0a0a; --surface: #111111; --surface-hover: #1a1a1a;
  --border: #222222; --border-accent: #333333;
  --text: #e0e0e0; --text-muted: #666666; --text-dim: #444444;
  --accent: #00ff88; --accent-dim: rgba(0,255,136,0.15);
  --cyan: #00d4ff; --warn: #ffaa00; --danger: #ff5555; --purple: #cc44ff;
  --font-sans: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: var(--font-sans); background: var(--bg); color: var(--text); padding: 28px 36px; line-height: 1.5; -webkit-font-smoothing: antialiased; }
.header { display: grid; grid-template-columns: 1fr auto; align-items: end; margin-bottom: 20px; padding-bottom: 16px; border-bottom: 2px solid var(--accent); }
.header h1 { font-family: var(--font-mono); font-size: 1.5rem; font-weight: 700; letter-spacing: -0.02em; color: var(--accent); }
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta { font-family: var(--font-mono); color: var(--text-muted); font-size: 0.72rem; text-align: right; line-height: 1.7; }
.summary { background: var(--surface); border-left: 3px solid var(--cyan); padding: 12px 18px; margin-bottom: 20px; font-size: 0.9rem; }

/* ===== 2 カラムレイアウト ===== */
.layout { display: grid; grid-template-columns: minmax(0, 1fr) 460px; gap: 20px; align-items: start; }
@media (max-width: 1100px) { .layout { grid-template-columns: 1fr; } }

.image-pane { background: var(--surface); border: 1px solid var(--border); padding: 12px; position: sticky; top: 12px; display: flex; flex-direction: column; gap: 10px; }
.image-frame { background: #050505; border: 1px dashed var(--border-accent); padding: 16px; display: flex; align-items: center; justify-content: center; min-height: 280px; }
.image-pane img { display: block; max-width: 100%; max-height: 78vh; height: auto; width: auto; object-fit: contain; margin: 0 auto; cursor: crosshair; }
.image-meta { font-family: var(--font-mono); font-size: 0.65rem; color: var(--text-dim); word-break: break-all; }
.image-toolbar { display: flex; gap: 8px; flex-wrap: wrap; }
.image-hint { font-family: var(--font-mono); font-size: 0.65rem; color: var(--text-muted); }

.review-pane { display: flex; flex-direction: column; gap: 16px; }
.panel { background: var(--surface); border: 1px solid var(--border); overflow: hidden; }
.panel-header { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; border-bottom: 1px solid var(--border); }
.panel-header h2 { font-family: var(--font-mono); font-size: 0.68rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; }
.panel-header .tag { font-family: var(--font-mono); font-size: 0.58rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; }
.panel-body { padding: 14px 16px; }

/* === Score ringgauge === */
.gauge { display: grid; grid-template-columns: 1fr auto; gap: 16px; align-items: center; padding: 4px 0; }
.gauge-label { font-size: 0.85rem; }
.gauge-rubric { font-family: var(--font-mono); font-size: 0.62rem; color: var(--text-dim); margin-top: 2px; }
.score-buttons { display: flex; gap: 4px; }
.score-btn { font-family: var(--font-mono); width: 32px; height: 32px; font-size: 0.78rem; font-weight: 700; background: var(--surface-hover); color: var(--text-muted); border: 1px solid var(--border-accent); cursor: pointer; transition: all 0.12s; }
.score-btn:hover { color: var(--text); border-color: var(--accent); }
.score-btn.s1.selected { background: rgba(255,85,85,0.2); color: var(--danger); border-color: var(--danger); }
.score-btn.s2.selected { background: rgba(255,119,0,0.2); color: #ff7700; border-color: #ff7700; }
.score-btn.s3.selected { background: rgba(255,170,0,0.18); color: var(--warn); border-color: var(--warn); }
.score-btn.s4.selected { background: rgba(0,212,255,0.2); color: var(--cyan); border-color: var(--cyan); }
.score-btn.s5.selected { background: var(--accent-dim); color: var(--accent); border-color: var(--accent); }
.criterion-row { padding: 10px 0; border-bottom: 1px solid var(--border); }
.criterion-row:last-child { border-bottom: none; }

/* === Total === */
.total-row { display: grid; grid-template-columns: 1fr auto; gap: 12px; padding: 10px 14px; background: var(--surface-hover); border-top: 1px solid var(--accent); }
.total-label { font-family: var(--font-mono); font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; }
.total-value { font-family: var(--font-mono); font-size: 1.6rem; font-weight: 700; color: var(--accent); line-height: 1; }
.total-stars { font-family: var(--font-mono); font-size: 0.9rem; color: var(--warn); margin-top: 2px; }

/* === Checklist === */
.check-row { display: grid; grid-template-columns: 32px 1fr; gap: 10px; align-items: center; padding: 6px 0; cursor: pointer; }
.check-box { width: 22px; height: 22px; border: 1px solid var(--border-accent); background: var(--surface-hover); display: flex; align-items: center; justify-content: center; font-family: var(--font-mono); font-size: 0.85rem; transition: all 0.12s; }
.check-box.on { background: var(--accent-dim); color: var(--accent); border-color: var(--accent); }
.check-box.off { color: transparent; }
.check-label { font-size: 0.88rem; user-select: none; }
.check-label.done { color: var(--text-muted); text-decoration: line-through; }

/* === Comment === */
.comment-area { width: 100%; min-height: 90px; background: var(--surface-hover); color: var(--text); border: 1px solid var(--border-accent); padding: 10px 12px; font-family: var(--font-mono); font-size: 0.82rem; resize: vertical; }
.comment-area:focus { outline: none; border-color: var(--accent); }

/* === Buttons === */
.btn-row { display: flex; gap: 10px; flex-wrap: wrap; padding: 12px 16px; border-top: 1px solid var(--border); }
.btn { font-family: var(--font-mono); font-size: 0.7rem; padding: 9px 16px; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; letter-spacing: 0.05em; text-transform: uppercase; transition: all 0.15s; }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { background: #00cc6a; }

.footer { margin-top: 16px; padding-top: 14px; border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.58rem; color: var(--text-dim); display: flex; justify-content: space-between; }
.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 0.8rem; padding: 12px 18px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 1000; max-width: 360px; }
.toast.show { opacity: 1; transform: translateY(0); }
</style>
</head>
<body>

<div class="header">
  <h1><span>HTML //</span> {{TITLE}}</h1>
  <div class="meta">GEN {{DATE}}<br>MODE IMAGE-REVIEW</div>
</div>

<div class="summary">{{SUMMARY}}</div>

<div class="layout">
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
  <span>HTML SKILL v0.2.0 / IMAGE-REVIEW MODE</span>
  <span>GENERATED BY CLAUDE CODE</span>
</div>

<div class="toast" id="toast"></div>

<script>
const DATA = {{DATA_JSON}};
const STATE = {
  scores: {},        // {criterionId: 1..5}
  perComments: {},   // {criterionId: string}
  checks: {},        // {checkId: boolean}
  overall: '',
  originalImgSrc: null,  // 注釈リセット用
  markerState: null      // Markerjs2 の state（再編集用）
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
async function copyText(text, label) {
  try { await navigator.clipboard.writeText(text); toast(label || 'コピーしました'); }
  catch (err) { toast('コピー失敗: ' + err.message, 'err'); }
}

function escapeHtml(s) {
  if (s == null) return '';
  return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

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
      <textarea class="comment-area" placeholder="この項目のコメント..." style="min-height:50px;font-size:0.76rem;margin-top:6px;" data-cmt="${escapeHtml(c.id)}"></textarea>
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

function recalcTotal() {
  const criteria = DATA.criteria || [];
  let sumWeight = 0;
  let sumWeighted = 0;
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
  const stars = '★'.repeat(filled) + '☆'.repeat(5 - filled);
  document.getElementById('total-stars').textContent = stars;
}

document.getElementById('overall-comment').addEventListener('input', e => { STATE.overall = e.target.value; });

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

/* ===== 注釈ツール（Markerjs2 統合） ===== */
function openMarker() {
  const img = document.getElementById('target-img');
  if (typeof markerjs2 === 'undefined') {
    toast('Markerjs2 のロード失敗（ネット接続/CDN を確認）', 'err');
    return;
  }
  if (STATE.originalImgSrc == null) STATE.originalImgSrc = img.src;
  const ma = new markerjs2.MarkerArea(img);
  ma.settings.displayMode = 'popup';
  ma.uiStyleSettings.toolbarBackgroundColor = '#111111';
  ma.uiStyleSettings.toolbarBackgroundHoverColor = '#1a1a1a';
  ma.uiStyleSettings.toolbarColor = '#e0e0e0';
  ma.uiStyleSettings.toolboxBackgroundColor = '#0a0a0a';
  ma.uiStyleSettings.toolboxColor = '#00ff88';
  ma.uiStyleSettings.toolboxAccentColor = '#00ff88';
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

/* ===== 結果スクショ書き出し（html2canvas） ===== */
async function captureScreenshot() {
  if (typeof html2canvas === 'undefined') throw new Error('html2canvas のロードに失敗');
  // クリップボード書き込み時に user gesture を保つため await の前後に注意
  const canvas = await html2canvas(document.body, {
    backgroundColor: '#0a0a0a',
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

このテンプレは依存ゼロ（vanilla JS）。CDN 一切不要、ローカルでも企業ネットワーク下でも動作。
