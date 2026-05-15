# Status Mode Template

スレッドの状況・確認事項を整理した対話 UI 用 HTML。
ユーザーが Yes/No・複数選択・自由記述で回答 → 「結果を JSON でコピー」ボタンで Claude に貼り戻せる。

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
| `todo` | ○ TODO | `--text-muted` |
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
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>HTML // {{TITLE}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
<style>
/* === 共通 CSS（design-system.md より） === */
:root {
  --bg: #0a0a0a; --surface: #111111; --surface-hover: #1a1a1a;
  --border: #222222; --border-accent: #333333;
  --text: #e0e0e0; --text-muted: #666666; --text-dim: #444444;
  --accent: #00ff88; --accent-dim: rgba(0,255,136,0.15);
  --cyan: #00d4ff; --cyan-dim: rgba(0,212,255,0.15);
  --warn: #ffaa00; --danger: #ff5555; --purple: #cc44ff;
  --font-sans: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: var(--font-sans); background: var(--bg); color: var(--text); padding: 32px 40px; line-height: 1.5; -webkit-font-smoothing: antialiased; }
.header { display: grid; grid-template-columns: 1fr auto; align-items: end; margin-bottom: 24px; padding-bottom: 20px; border-bottom: 2px solid var(--accent); }
.header h1 { font-family: var(--font-mono); font-size: 1.6rem; font-weight: 700; letter-spacing: -0.02em; color: var(--accent); }
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta { font-family: var(--font-mono); color: var(--text-muted); font-size: 0.72rem; text-align: right; line-height: 1.8; letter-spacing: 0.03em; }
.summary { background: var(--surface); border-left: 3px solid var(--cyan); padding: 14px 20px; margin-bottom: 24px; font-size: 0.92rem; color: var(--text); }
.panel { background: var(--surface); border: 1px solid var(--border); margin-bottom: 24px; overflow: hidden; }
.panel-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 20px; border-bottom: 1px solid var(--border); }
.panel-header h2 { font-family: var(--font-mono); font-size: 0.7rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; }
.panel-header .tag { font-family: var(--font-mono); font-size: 0.6rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; letter-spacing: 0.05em; }
.panel-body { padding: 16px 20px; }

/* status list */
.status-list { display: grid; gap: 6px; }
.status-row { display: grid; grid-template-columns: 90px 1fr; gap: 12px; align-items: center; padding: 8px 12px; background: var(--surface-hover); border-left: 2px solid var(--border-accent); }
.state-badge { font-family: var(--font-mono); font-size: 0.65rem; font-weight: 700; letter-spacing: 0.06em; text-transform: uppercase; padding: 3px 8px; text-align: center; }
.state-done { background: var(--accent-dim); color: var(--accent); }
.state-wip  { background: rgba(255,170,0,0.15); color: var(--warn); }
.state-todo { background: rgba(255,255,255,0.04); color: var(--text-muted); }
.state-blocked { background: rgba(255,85,85,0.12); color: var(--danger); }

/* qa items */
.qa-item { padding: 14px 16px; border-bottom: 1px solid var(--border); }
.qa-item:last-child { border-bottom: none; }
.qa-label { font-size: 0.95rem; color: var(--text); margin-bottom: 10px; font-weight: 500; }
.qa-id { font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); margin-right: 8px; }
.qa-controls { display: flex; flex-wrap: wrap; gap: 8px; }
.qa-opt { font-family: var(--font-mono); font-size: 0.78rem; padding: 8px 14px; background: var(--surface-hover); color: var(--text); border: 1px solid var(--border-accent); cursor: pointer; transition: all 0.15s; user-select: none; }
.qa-opt:hover { border-color: var(--accent); }
.qa-opt.selected { background: var(--accent-dim); border-color: var(--accent); color: var(--accent); }
.qa-opt.no.selected { background: rgba(255,85,85,0.15); border-color: var(--danger); color: var(--danger); }
.qa-opt.skip.selected { background: var(--surface); color: var(--text-muted); border-color: var(--border-accent); }
.qa-text { width: 100%; min-height: 70px; background: var(--surface-hover); color: var(--text); border: 1px solid var(--border-accent); padding: 10px 12px; font-family: var(--font-mono); font-size: 0.82rem; resize: vertical; }
.qa-text:focus { outline: none; border-color: var(--accent); }

/* actions */
.action-row { display: grid; grid-template-columns: 1fr 60px; gap: 16px; align-items: center; padding: 10px 12px; border-bottom: 1px solid var(--border); }
.action-row:last-child { border-bottom: none; }
.action-label { font-size: 0.9rem; }
.action-score { font-family: var(--font-mono); font-size: 0.85rem; font-weight: 700; color: var(--cyan); text-align: right; }

/* buttons */
.btn-row { display: flex; gap: 12px; margin-top: 12px; }
.btn { font-family: var(--font-mono); font-size: 0.72rem; padding: 10px 18px; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; letter-spacing: 0.05em; text-transform: uppercase; transition: all 0.15s; }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { background: #00cc6a; }

.footer { margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); letter-spacing: 0.05em; display: flex; justify-content: space-between; }

.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 0.8rem; padding: 12px 18px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 1000; max-width: 360px; }
.toast.show { opacity: 1; transform: translateY(0); }

.preview { background: #050505; border: 1px solid var(--border); padding: 14px 16px; font-family: var(--font-mono); font-size: 0.75rem; color: var(--text-muted); max-height: 280px; overflow: auto; white-space: pre-wrap; word-break: break-all; }
</style>
</head>
<body>

<div class="header">
  <h1><span>HTML //</span> {{TITLE}}</h1>
  <div class="meta">GEN {{DATE}}<br>MODE STATUS</div>
</div>

<div class="summary">{{SUMMARY}}</div>

<div id="root"></div>

<div class="panel">
  <div class="panel-header"><h2>結果のエクスポート</h2><span class="tag">EXPORT</span></div>
  <div class="panel-body">
    <div class="btn-row">
      <button class="btn primary" onclick="copyResult()">結果を JSON でコピー</button>
      <button class="btn" onclick="copyMarkdown()">結果を Markdown でコピー</button>
      <button class="btn" onclick="togglePreview()">プレビュー表示</button>
      <button class="btn" onclick="resetAll()">リセット</button>
    </div>
    <div id="preview-container" style="display:none; margin-top: 14px;">
      <div class="preview" id="preview">（未回答）</div>
    </div>
  </div>
</div>

<div class="footer">
  <span>HTML SKILL v0.1.0 / STATUS MODE</span>
  <span>GENERATED BY CLAUDE CODE</span>
</div>

<div class="toast" id="toast"></div>

<script>
const DATA = {{DATA_JSON}};
const answers = {}; // {qid: value}

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
  try {
    await navigator.clipboard.writeText(text);
    toast(label || 'コピーしました');
  } catch (err) {
    toast('コピー失敗: ' + err.message, 'err');
  }
}

function renderRoot() {
  const root = document.getElementById('root');
  root.innerHTML = '';
  for (const sec of DATA.sections) {
    const panel = document.createElement('div');
    panel.className = 'panel';
    const tagText = { status: 'STATUS', qa: 'Q & A', actions: 'ACTIONS', checklist: 'CHECK' }[sec.kind] || 'INFO';
    panel.innerHTML = `<div class="panel-header"><h2>${escapeHtml(sec.title)}</h2><span class="tag">${tagText}</span></div><div class="panel-body" data-body></div>`;
    const body = panel.querySelector('[data-body]');
    if (sec.kind === 'status') renderStatus(body, sec);
    else if (sec.kind === 'qa' || sec.kind === 'checklist') renderQA(body, sec);
    else if (sec.kind === 'actions') renderActions(body, sec);
    root.appendChild(panel);
  }
}

function renderStatus(body, sec) {
  const list = document.createElement('div');
  list.className = 'status-list';
  for (const it of sec.items) {
    const row = document.createElement('div');
    row.className = 'status-row';
    const stateLabel = { done: '✓ DONE', wip: '◐ WIP', todo: '○ TODO', blocked: '✗ BLOCKED' }[it.state] || '○ TODO';
    row.innerHTML = `<span class="state-badge state-${it.state || 'todo'}">${stateLabel}</span><span>${escapeHtml(it.label)}</span>`;
    list.appendChild(row);
  }
  body.appendChild(list);
}

function renderQA(body, sec) {
  for (const it of sec.items) {
    const wrap = document.createElement('div');
    wrap.className = 'qa-item';
    const label = document.createElement('div');
    label.className = 'qa-label';
    label.innerHTML = `<span class="qa-id">${escapeHtml(it.id || '')}</span>${escapeHtml(it.label)}`;
    wrap.appendChild(label);
    const ctrls = document.createElement('div');
    ctrls.className = 'qa-controls';
    if (it.type === 'yesno') {
      ['yes', 'no', 'skip'].forEach(v => {
        const b = document.createElement('button');
        b.className = `qa-opt ${v}`;
        b.textContent = v.toUpperCase();
        b.onclick = () => { answers[it.id] = v; refreshSelection(it.id, ctrls, v); };
        b.dataset.value = v;
        ctrls.appendChild(b);
      });
    } else if (it.type === 'multi') {
      (it.options || []).forEach(opt => {
        const b = document.createElement('button');
        b.className = 'qa-opt';
        b.textContent = opt;
        b.onclick = () => { answers[it.id] = opt; refreshSelection(it.id, ctrls, opt); };
        b.dataset.value = opt;
        ctrls.appendChild(b);
      });
      const skip = document.createElement('button');
      skip.className = 'qa-opt skip';
      skip.textContent = 'SKIP';
      skip.onclick = () => { answers[it.id] = '__skip'; refreshSelection(it.id, ctrls, '__skip'); };
      skip.dataset.value = '__skip';
      ctrls.appendChild(skip);
    } else if (it.type === 'multiSelect') {
      (it.options || []).forEach(opt => {
        const b = document.createElement('button');
        b.className = 'qa-opt';
        b.textContent = opt;
        b.dataset.value = opt;
        b.onclick = () => {
          const cur = answers[it.id] || [];
          const idx = cur.indexOf(opt);
          if (idx >= 0) cur.splice(idx, 1); else cur.push(opt);
          answers[it.id] = cur;
          b.classList.toggle('selected', cur.includes(opt));
        };
        ctrls.appendChild(b);
      });
    } else if (it.type === 'text') {
      const ta = document.createElement('textarea');
      ta.className = 'qa-text';
      ta.placeholder = 'ここに入力...';
      ta.oninput = () => { answers[it.id] = ta.value; };
      ctrls.appendChild(ta);
    }
    wrap.appendChild(ctrls);
    body.appendChild(wrap);
  }
}

function refreshSelection(qid, ctrls, value) {
  ctrls.querySelectorAll('.qa-opt').forEach(b => {
    b.classList.toggle('selected', b.dataset.value === value);
  });
}

function renderActions(body, sec) {
  for (const it of sec.items) {
    const row = document.createElement('div');
    row.className = 'action-row';
    const score = it.score != null ? Math.round(it.score * 100) + '%' : '—';
    row.innerHTML = `<span class="action-label">${escapeHtml(it.label)}</span><span class="action-score">${score}</span>`;
    body.appendChild(row);
  }
}

function escapeHtml(s) {
  if (s == null) return '';
  return String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function buildResult() {
  return {
    title: DATA.title,
    timestamp: new Date().toISOString(),
    answers
  };
}

function copyResult() {
  const json = JSON.stringify(buildResult(), null, 2);
  copyText(json, '結果を JSON でコピーしました（Claude に貼り戻し可）');
  updatePreview();
}

function copyMarkdown() {
  const lines = [`# ${DATA.title}`, '', `_${new Date().toLocaleString('ja-JP')}_`, ''];
  for (const [qid, val] of Object.entries(answers)) {
    const display = Array.isArray(val) ? val.join(', ') : (val === '__skip' ? 'skip' : val);
    lines.push(`- **${qid}**: ${display}`);
  }
  copyText(lines.join('\n'), '結果を Markdown でコピーしました');
  updatePreview();
}

function togglePreview() {
  const c = document.getElementById('preview-container');
  c.style.display = c.style.display === 'none' ? 'block' : 'none';
  updatePreview();
}

function updatePreview() {
  document.getElementById('preview').textContent = JSON.stringify(buildResult(), null, 2);
}

function resetAll() {
  for (const k of Object.keys(answers)) delete answers[k];
  renderRoot();
  updatePreview();
  toast('リセットしました');
}

renderRoot();
</script>
</body>
</html>
```

## 使い方メモ

- 各設問の `id` は短いキー（`q1`, `migrate`, `push_main` 等）。Claude が結果を貼り戻したときに参照できる
- `kind: "actions"` セクションは提案候補のサマリー表示用（クリック不可、推奨確率を 0〜1 で）
- 設問が多くなりすぎたら `kind: "qa"` を複数セクションに分割する（〜トピック別〜）
