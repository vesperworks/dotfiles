# Diagram Mode Template

フロー図・シーケンス図・関係図を Mermaid + D3.js でレンダリングする HTML テンプレ。
Müller-Brockmann 12カラムグリッド + LIGHT/DARK テーマ切替対応。
`vw-flow-viz` と統一した配色。

## サブモード（`diagram` の第 2 引数）

| サブモード | 描画エンジン | 用途 |
|----------|------------|------|
| `flow` | Mermaid (`flowchart TD`) | 処理の流れ・分岐 |
| `sequence` | Mermaid (`sequenceDiagram`) | 時系列・対話 |
| `graph` | D3.js force-directed | ノード・エッジの関係 |
| `sankey` | D3.js Sankey | リソース配分（vw-flow-viz と同じ手法） |

## Data Schema

```json
{
  "title": "...",
  "subMode": "flow|sequence|graph|sankey",
  "summary": "1〜3 行",
  "mermaid": "flowchart TD\n  A[開始] --> B{分岐}\n  B -->|Yes| C[処理1]\n  B -->|No| D[処理2]",
  "graph": {
    "nodes": [{"id":"a","name":"A","group":"skill"}],
    "links": [{"source":"a","target":"b","value":1}]
  }
}
```

- `subMode = flow|sequence` → `mermaid` プロパティのみ使用
- `subMode = graph|sankey` → `graph` プロパティ（nodes/links）を使用
- 両方を含めることも可（タブで切替）

### Mermaid 配色

テーマに連動する。JS 内でテーマ判定し init ブロックを自動付与:

**DARK:**
```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'primaryColor': '#111111',
  'primaryTextColor': '#e0e0e0',
  'primaryBorderColor': '#00ff88',
  'lineColor': '#666666',
  'secondaryColor': '#1a1a1a',
  'tertiaryColor': '#0a0a0a',
  'background': '#0a0a0a',
  'mainBkg': '#111111',
  'edgeLabelBackground': '#1a1a1a',
  'fontFamily': 'JetBrains Mono'
}}}%%
```

**LIGHT:**
```mermaid
%%{init: {'theme':'base', 'themeVariables': {
  'primaryColor': '#f4f4f4',
  'primaryTextColor': '#111315',
  'primaryBorderColor': '#e4002b',
  'lineColor': '#5b6066',
  'secondaryColor': '#eaeaea',
  'tertiaryColor': '#ffffff',
  'background': '#ffffff',
  'mainBkg': '#f4f4f4',
  'edgeLabelBackground': '#eaeaea',
  'fontFamily': 'JetBrains Mono'
}}}%%
```

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
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<script src="https://d3js.org/d3.v7.min.js"></script>
<script src="https://unpkg.com/d3-sankey@0.12.3/dist/d3-sankey.min.js"></script>
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

/* ===== Panel ===== */
.panel { background: var(--surface); border: 1px solid var(--border); overflow: hidden; }
.panel-header { display: flex; justify-content: space-between; align-items: center; padding: 12px var(--gutter); border-bottom: 1px solid var(--border); }
.panel-header h2 { font-family: var(--font-mono); font-size: 0.7rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; line-height: var(--lh); }
.panel-header .tag { font-family: var(--font-mono); font-size: 0.6rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; letter-spacing: 0.05em; line-height: 16px; }
.panel-body { padding: var(--gutter); min-height: 360px; }

/* ===== Diagram ===== */
.diagram-container { display: flex; justify-content: center; overflow-x: auto; }
.mermaid { background: var(--bg); }

/* ===== D3 graph ===== */
.node circle { stroke-width: 2; cursor: pointer; }
.node text { font-family: var(--font-mono); font-size: 11px; fill: var(--text); pointer-events: none; }
.link { stroke: var(--text-dim); stroke-opacity: 0.5; }
.link-label { font-family: var(--font-mono); font-size: 9px; fill: var(--text-muted); pointer-events: none; }

/* ===== Legend ===== */
.legend { display: flex; flex-wrap: wrap; gap: 16px; padding: 12px var(--gutter); border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.7rem; color: var(--text-muted); line-height: var(--lh); }
.legend-item { display: flex; align-items: center; gap: 6px; }
.legend-dot { width: 10px; height: 10px; border-radius: 50%; }

/* ===== Buttons ===== */
.btn-row { display: flex; gap: 12px; flex-wrap: wrap; padding: 12px var(--gutter); border-top: 1px solid var(--border); }
.btn { font-family: var(--font-mono); font-size: 0.72rem; padding: 10px 18px; background: var(--surface-hover); color: var(--accent); border: 1px solid var(--border-accent); cursor: pointer; letter-spacing: 0.05em; text-transform: uppercase; transition: all 0.15s; line-height: var(--lh); }
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }

/* ===== Tooltip ===== */
.tooltip { position: absolute; background: var(--surface); border: 1px solid var(--border-accent); padding: 8px 12px; font-family: var(--font-mono); font-size: 0.72rem; color: var(--text); pointer-events: none; opacity: 0; transition: opacity 0.1s; z-index: 100; line-height: var(--lh); }

/* ===== Footer ===== */
.footer { grid-column: 1 / -1; padding-top: var(--lh); border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); letter-spacing: 0.05em; display: grid; grid-template-columns: subgrid; column-gap: var(--gutter); line-height: var(--lh); }
@supports not (grid-template-columns: subgrid) { .footer { grid-template-columns: repeat(var(--cols), 1fr); } }
.footer .left { grid-column: 1 / 7; } .footer .right { grid-column: 7 / 13; text-align: right; }

.toast { position: fixed; bottom: 24px; right: 24px; background: var(--surface); border: 1px solid var(--accent); color: var(--accent); font-family: var(--font-mono); font-size: 0.8rem; padding: 12px 18px; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; z-index: 1000; line-height: var(--lh); }
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
        <div class="meta">GEN {{DATE}}<br>MODE DIAGRAM // {{SUBMODE}}</div>
      </div>

      <div class="summary">{{SUMMARY}}</div>

      <!-- Diagram panel spans full width -->
      <div class="band">
        <div class="panel" style="grid-column: 1 / -1;">
          <div class="panel-header"><h2>Diagram</h2><span class="tag" id="sub-tag">{{SUBMODE}}</span></div>
          <div class="panel-body diagram-container" id="diagram"></div>
          <div class="legend" id="legend"></div>
          <div class="btn-row">
            <button class="btn" onclick="downloadSvg()">SVG ダウンロード</button>
            <button class="btn" onclick="copyMermaidSource()">Mermaid ソースをコピー</button>
          </div>
        </div>
      </div>

      <div class="footer">
        <span class="left">HTML SKILL v1.0.0 / DIAGRAM MODE</span>
        <span class="right">GENERATED BY CLAUDE CODE</span>
      </div>

    </div>

    <div class="guides" aria-hidden="true">
      <div class="cols"></div><div class="rows"></div>
      <div class="mline l"></div><div class="mline r"></div>
    </div>
  </div>
</section>

<div class="tooltip" id="tooltip"></div>
<div class="toast" id="toast"></div>

<script>
const DATA = {{DATA_JSON}};
const COLORS = { user: '#00d4ff', skill: '#00ff88', agent: '#ffaa00', subagent: '#ff7700', tool: '#cc44ff', output: '#00ffcc', default: '#888888' };

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
      reRenderDiagram();
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

async function copyText(text, label) {
  try { await navigator.clipboard.writeText(text); toast(label || 'コピーしました'); }
  catch (err) { toast('コピー失敗: ' + err.message, 'err'); }
}

function copyMermaidSource() {
  if (DATA.mermaid) copyText(DATA.mermaid, 'Mermaid ソースをコピーしました');
  else if (DATA.graph) copyText(JSON.stringify(DATA.graph, null, 2), 'グラフ JSON をコピーしました');
}

function downloadSvg() {
  const svg = document.querySelector('#diagram svg');
  if (!svg) { toast('SVG が見つかりません', 'err'); return; }
  const xml = new XMLSerializer().serializeToString(svg);
  const blob = new Blob([xml], { type: 'image/svg+xml' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = (DATA.title || 'diagram').replace(/[^\w-]+/g, '_') + '.svg';
  a.click();
  URL.revokeObjectURL(url);
  toast('SVG をダウンロードしました');
}

function renderLegend(types) {
  const el = document.getElementById('legend');
  el.innerHTML = '';
  types.forEach(t => {
    const item = document.createElement('div');
    item.className = 'legend-item';
    item.innerHTML = `<span class="legend-dot" style="background:${COLORS[t]||COLORS.default}"></span>${t}`;
    el.appendChild(item);
  });
}

/* ===== Mermaid theme-aware init block ===== */
function getMermaidInitBlock() {
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
  if (isDark) {
    return `%%{init: {'theme':'base', 'themeVariables': {
    'primaryColor':'#111111','primaryTextColor':'#e0e0e0','primaryBorderColor':'#00ff88',
    'lineColor':'#666666','secondaryColor':'#1a1a1a','tertiaryColor':'#0a0a0a',
    'background':'#0a0a0a','mainBkg':'#111111','edgeLabelBackground':'#1a1a1a',
    'fontFamily':'JetBrains Mono'
  }}}%%\n`;
  }
  return `%%{init: {'theme':'base', 'themeVariables': {
    'primaryColor':'#f4f4f4','primaryTextColor':'#111315','primaryBorderColor':'#e4002b',
    'lineColor':'#5b6066','secondaryColor':'#eaeaea','tertiaryColor':'#ffffff',
    'background':'#ffffff','mainBkg':'#f4f4f4','edgeLabelBackground':'#eaeaea',
    'fontFamily':'JetBrains Mono'
  }}}%%\n`;
}

let mermaidIdCounter = 0;
async function renderMermaid() {
  const initBlock = getMermaidInitBlock();
  const source = (DATA.mermaid || '').startsWith('%%{') ? DATA.mermaid : initBlock + (DATA.mermaid || '');
  mermaid.initialize({ startOnLoad: false, securityLevel: 'loose', theme: 'base' });
  try {
    const id = 'mermaid-svg-' + (mermaidIdCounter++);
    const { svg } = await mermaid.render(id, source);
    document.getElementById('diagram').innerHTML = svg;
  } catch (err) {
    document.getElementById('diagram').innerHTML = `<pre style="color: var(--danger); font-family: var(--font-mono); font-size: 0.8rem; white-space: pre-wrap; line-height: var(--lh);">Mermaid render error:\n${err.message}\n\n--- source ---\n${source}</pre>`;
  }
}

function renderForceGraph() {
  const g = DATA.graph;
  if (!g || !g.nodes || !g.links) { document.getElementById('diagram').textContent = 'no graph data'; return; }
  const container = document.getElementById('diagram');
  container.innerHTML = '';
  const w = container.clientWidth || 900;
  const h = 540;
  const isDark = document.documentElement.getAttribute('data-theme') !== 'light';
  const strokeBg = isDark ? '#0a0a0a' : '#ffffff';
  const svg = d3.select('#diagram').append('svg').attr('width', '100%').attr('height', h).attr('viewBox', `0 0 ${w} ${h}`);
  const sim = d3.forceSimulation(g.nodes)
    .force('link', d3.forceLink(g.links).id(d => d.id).distance(100))
    .force('charge', d3.forceManyBody().strength(-300))
    .force('center', d3.forceCenter(w / 2, h / 2));
  const link = svg.append('g').selectAll('line').data(g.links).join('line').attr('class', 'link').attr('stroke-width', d => Math.sqrt(d.value || 1));
  const node = svg.append('g').selectAll('g').data(g.nodes).join('g').attr('class', 'node').call(drag(sim));
  node.append('circle').attr('r', 10).attr('fill', d => COLORS[d.group] || COLORS.default).attr('stroke', strokeBg);
  node.append('text').attr('dx', 14).attr('dy', 4).text(d => d.name || d.id);
  const tooltip = document.getElementById('tooltip');
  node.on('mouseover', (e, d) => {
    tooltip.innerHTML = `<strong>${d.name || d.id}</strong><br>group: ${d.group || '—'}`;
    tooltip.style.opacity = 1;
  }).on('mousemove', e => {
    tooltip.style.left = (e.pageX + 12) + 'px';
    tooltip.style.top = (e.pageY - 24) + 'px';
  }).on('mouseout', () => { tooltip.style.opacity = 0; });
  sim.on('tick', () => {
    link.attr('x1', d => d.source.x).attr('y1', d => d.source.y).attr('x2', d => d.target.x).attr('y2', d => d.target.y);
    node.attr('transform', d => `translate(${d.x},${d.y})`);
  });
  const types = Array.from(new Set(g.nodes.map(n => n.group).filter(Boolean)));
  renderLegend(types);
}

function drag(sim) {
  return d3.drag()
    .on('start', (e, d) => { if (!e.active) sim.alphaTarget(0.3).restart(); d.fx = d.x; d.fy = d.y; })
    .on('drag', (e, d) => { d.fx = e.x; d.fy = e.y; })
    .on('end', (e, d) => { if (!e.active) sim.alphaTarget(0); d.fx = null; d.fy = null; });
}

function renderSankey() {
  const g = DATA.graph;
  if (!g || !g.nodes || !g.links) { document.getElementById('diagram').textContent = 'no sankey data'; return; }
  const container = document.getElementById('diagram');
  container.innerHTML = '';
  const w = container.clientWidth || 1000;
  const h = Math.max(540, g.nodes.length * 40);
  const svg = d3.select('#diagram').append('svg').attr('width', '100%').attr('height', h).attr('viewBox', `0 0 ${w} ${h}`);
  const nodeMap = {};
  g.nodes.forEach((n, i) => { nodeMap[n.id] = i; });
  const data = {
    nodes: g.nodes.map(n => ({ ...n })),
    links: g.links.map(l => ({ source: nodeMap[l.source], target: nodeMap[l.target], value: Math.max(l.value || 1, 1) }))
  };
  const sankey = d3.sankey().nodeId(d => d.index).nodeWidth(20).nodePadding(24).extent([[60, 40], [w - 60, h - 40]]);
  const { nodes, links } = sankey(data);
  svg.append('g').selectAll('path').data(links).join('path')
    .attr('d', d3.sankeyLinkHorizontal())
    .attr('fill', 'none')
    .attr('stroke', d => COLORS[d.source.group] || COLORS.default)
    .attr('stroke-width', d => Math.max(1, d.width))
    .attr('stroke-opacity', 0.25);
  const nG = svg.append('g').selectAll('g').data(nodes).join('g');
  nG.append('rect').attr('x', d => d.x0).attr('y', d => d.y0)
    .attr('height', d => Math.max(2, d.y1 - d.y0)).attr('width', d => d.x1 - d.x0)
    .attr('fill', d => COLORS[d.group] || COLORS.default);
  nG.append('text').attr('x', d => (d.x0 + d.x1) / 2).attr('y', d => d.y1 + 14)
    .attr('text-anchor', 'middle').attr('class', 'node-label')
    .attr('fill', 'var(--text-muted)').style('font-family', 'var(--font-mono)').style('font-size', '10px')
    .text(d => d.name || d.id);
  const types = Array.from(new Set(g.nodes.map(n => n.group).filter(Boolean)));
  renderLegend(types);
}

function reRenderDiagram() {
  const sub = DATA.subMode || 'flow';
  if (sub === 'flow' || sub === 'sequence') renderMermaid();
  else if (sub === 'graph') renderForceGraph();
  else if (sub === 'sankey') renderSankey();
  else renderMermaid();
}

(function main() {
  const sub = DATA.subMode || 'flow';
  document.getElementById('sub-tag').textContent = sub.toUpperCase();
  reRenderDiagram();
})();
</script>
</body>
</html>
```

## Mermaid 例

### flow
```
flowchart TD
  Start[起動] --> Auth{認証済?}
  Auth -->|Yes| Home[ホーム]
  Auth -->|No| Login[ログイン画面]
  Login --> Auth
```

### sequence
```
sequenceDiagram
  participant U as User
  participant C as Claude
  participant T as Tool
  U->>C: リクエスト
  C->>T: Read(file)
  T-->>C: file content
  C-->>U: レスポンス
```

## グラフ JSON 例

```json
{
  "nodes": [
    {"id": "main", "name": "main", "group": "skill"},
    {"id": "agent1", "name": "Explorer", "group": "agent"},
    {"id": "tool1", "name": "Read", "group": "tool"}
  ],
  "links": [
    {"source": "main", "target": "agent1", "value": 2},
    {"source": "agent1", "target": "tool1", "value": 5}
  ]
}
```
