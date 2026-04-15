# HTML Template for Flow Visualization

## Design System

**Theme**: Hacker + Swiss Design
- **Sans font**: Inter (headings, body)
- **Mono font**: JetBrains Mono (data, labels, badges)
- **Colors**: Dark BG (#0a0a0a) + Neon accents
- **Layout**: Strict grid, minimal decoration, sharp edges

### Color Palette

| Type | Color | Hex |
|------|-------|-----|
| User | Cyan | #00d4ff |
| Skill | Neon Green | #00ff88 |
| Agent | Amber | #ffaa00 |
| Sub-agent | Orange | #ff7700 |
| Tool | Purple | #cc44ff |
| Output | Teal | #00ffcc |

## Placeholders

Replace these before output:
- `{{SANKEY_DATA}}` — JSON object with nodes and links (see Data Format below)
- `{{PIPELINE_DATA}}` — JSON array of phases with stages and jobs (see Pipeline Format below)
- `{{TITLE}}` — target name
- `{{DATE}}` — generation date (YYYY-MM-DD HH:MM)
- `{{TOTAL_TOKENS}}` — estimated total tokens

## Template

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>FLOW_VIZ // {{TITLE}}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">
<script src="https://d3js.org/d3.v7.min.js"></script>
<script src="https://unpkg.com/d3-sankey@0.12.3/dist/d3-sankey.min.js"></script>
<style>
  :root {
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
    --user: #00d4ff;
    --skill: #00ff88;
    --agent: #ffaa00;
    --subagent: #ff7700;
    --tool: #cc44ff;
    --output: #00ffcc;
    --font-sans: 'Inter', -apple-system, sans-serif;
    --font-mono: 'JetBrains Mono', 'SF Mono', monospace;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: var(--font-sans);
    background: var(--bg);
    color: var(--text);
    padding: 32px 40px;
    line-height: 1.5;
    -webkit-font-smoothing: antialiased;
  }
  .header {
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: end;
    margin-bottom: 32px;
    padding-bottom: 20px;
    border-bottom: 2px solid var(--accent);
  }
  .header h1 { font-family: var(--font-mono); font-size: 1.6rem; font-weight: 700; letter-spacing: -0.02em; color: var(--accent); }
  .header h1 span { color: var(--text-muted); font-weight: 400; }
  .header .meta { font-family: var(--font-mono); color: var(--text-muted); font-size: 0.72rem; text-align: right; line-height: 1.8; letter-spacing: 0.03em; }
  .stats { display: grid; grid-template-columns: repeat(5, 1fr); gap: 1px; background: var(--border); margin-bottom: 32px; border: 1px solid var(--border); }
  .stat-card { background: var(--surface); padding: 20px 16px; }
  .stat-card .label { font-family: var(--font-mono); font-size: 0.65rem; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.12em; margin-bottom: 4px; }
  .stat-card .value { font-family: var(--font-mono); font-size: 2rem; font-weight: 700; color: var(--accent); line-height: 1; }
  .stat-card:nth-child(3) .value { color: var(--cyan); }
  .panel { background: var(--surface); border: 1px solid var(--border); margin-bottom: 24px; overflow: hidden; }
  .panel-header { display: flex; justify-content: space-between; align-items: center; padding: 14px 20px; border-bottom: 1px solid var(--border); }
  .panel-header h2 { font-family: var(--font-mono); font-size: 0.7rem; font-weight: 500; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.1em; }
  .panel-header .tag { font-family: var(--font-mono); font-size: 0.6rem; color: var(--accent); background: var(--accent-dim); padding: 2px 8px; letter-spacing: 0.05em; }
  .panel-body { padding: 20px; }
  table { width: 100%; border-collapse: collapse; }
  th { font-family: var(--font-mono); text-align: left; padding: 8px 12px; font-size: 0.6rem; font-weight: 500; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.1em; border-bottom: 1px solid var(--border-accent); }
  td { font-family: var(--font-mono); text-align: left; padding: 7px 12px; font-size: 0.78rem; color: var(--text); border-bottom: 1px solid var(--border); }
  tr:hover td { background: var(--surface-hover); }
  .type-badge { display: inline-block; padding: 1px 6px; font-family: var(--font-mono); font-size: 0.6rem; font-weight: 500; letter-spacing: 0.05em; text-transform: uppercase; }
  .type-user { background: rgba(0,212,255,0.15); color: var(--user); }
  .type-skill { background: rgba(0,255,136,0.15); color: var(--skill); }
  .type-agent { background: rgba(255,170,0,0.15); color: var(--agent); }
  .type-subagent { background: rgba(255,119,0,0.15); color: var(--subagent); }
  .type-tool { background: rgba(204,68,255,0.15); color: var(--tool); }
  .type-output { background: rgba(0,255,204,0.15); color: var(--output); }
  .token-bar-container { margin-top: 8px; }
  .token-bar { display: flex; height: 6px; overflow: hidden; margin-bottom: 16px; }
  .token-bar div { transition: width 0.3s; }
  .legend { display: flex; flex-wrap: wrap; gap: 20px; font-family: var(--font-mono); font-size: 0.7rem; color: var(--text-muted); }
  .legend-item { display: flex; align-items: center; gap: 6px; }
  .legend-dot { width: 6px; height: 6px; }

  /* --- Pipeline --- */
  .pl-phase { margin-bottom: 28px; }
  .pl-phase-title { font-family: var(--font-mono); font-size: 0.75rem; font-weight: 700; color: var(--accent); margin-bottom: 10px; letter-spacing: 0.03em; }
  .pl-row { display: flex; gap: 2px; align-items: flex-start; }
  .pl-stage { flex: 1; min-width: 130px; background: var(--surface-hover); border: 1px solid var(--border); }
  .pl-stage-header { font-family: var(--font-mono); font-size: 0.58rem; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.08em; padding: 6px 10px; background: rgba(255,255,255,0.03); border-bottom: 1px solid var(--border); text-align: center; }
  .pl-job { padding: 8px 10px; border-bottom: 1px solid var(--border); position: relative; transition: opacity 0.2s; }
  .pl-job.maybe { opacity: 0.35; }
  .pl-job:hover { opacity: 1 !important; }
  .pl-job .name { font-family: var(--font-mono); font-size: 0.68rem; font-weight: 500; }
  .pl-job .meta { font-family: var(--font-mono); font-size: 0.55rem; color: var(--text-muted); margin-top: 2px; }
  .pl-job .prob-dot { position: absolute; right: 8px; top: 8px; width: 7px; height: 7px; border-radius: 50%; }
  .pl-conn { display: flex; align-items: center; padding: 0 3px; color: var(--border-accent); font-size: 1rem; min-width: 20px; justify-content: center; margin-top: 22px; }

  /* --- Waterfall --- */
  .wf-phase { margin-bottom: 24px; }
  .wf-phase-title { font-family: var(--font-mono); font-size: 0.75rem; font-weight: 700; color: var(--accent); margin-bottom: 8px; }
  .wf-row { display: grid; grid-template-columns: 140px 1fr 55px; align-items: center; height: 32px; gap: 8px; }
  .wf-label { font-family: var(--font-mono); font-size: 0.63rem; color: var(--text-muted); text-align: right; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  .wf-track { height: 18px; position: relative; background: rgba(255,255,255,0.02); }
  .wf-bar { position: absolute; top: 0; height: 100%; display: flex; align-items: center; padding-left: 6px; font-family: var(--font-mono); font-size: 0.5rem; font-weight: 600; color: rgba(0,0,0,0.7); }
  .wf-bar.ghost { opacity: 0.12; }
  .wf-prob { font-family: var(--font-mono); font-size: 0.65rem; font-weight: 700; text-align: right; }

  /* --- Sankey SVG --- */
  .node-label { fill: var(--text-muted); font-family: var(--font-mono); font-size: 9px; font-weight: 400; }
  .node-pct { font-family: var(--font-mono); font-size: 13px; font-weight: 700; }
  .link { fill: none; stroke-opacity: 0.18; }
  .link:hover { stroke-opacity: 0.45; }

  /* --- Tooltip --- */
  .tooltip { position: absolute; background: #111; border: 1px solid var(--border-accent); padding: 12px 16px; font-family: var(--font-mono); font-size: 0.72rem; color: var(--text); pointer-events: none; opacity: 0; transition: opacity 0.1s; z-index: 100; line-height: 1.7; max-width: 380px; white-space: pre-line; }
  .tooltip strong { color: var(--accent); }
  .tooltip .tt-header { border-bottom: 1px solid var(--border); padding-bottom: 6px; margin-bottom: 6px; }
  .tooltip .tt-type { font-size: 0.6rem; text-transform: uppercase; letter-spacing: 0.08em; opacity: 0.6; }
  .tooltip .tt-tokens { color: var(--cyan); font-weight: 700; }
  .tooltip .tt-detail { font-size: 0.65rem; color: var(--text-muted); line-height: 1.6; }

  .footer { margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border); font-family: var(--font-mono); font-size: 0.6rem; color: var(--text-dim); letter-spacing: 0.05em; display: flex; justify-content: space-between; }
</style>
</head>
<body>

<div class="header">
  <h1><span>FLOW_VIZ //</span> {{TITLE}}</h1>
  <div class="meta">GEN {{DATE}}<br>EST ~{{TOTAL_TOKENS}} TOKENS</div>
</div>

<div class="stats" id="stats"></div>

<div class="panel">
  <div class="panel-header"><h2>Execution Flow</h2><span class="tag">SANKEY</span></div>
  <div class="panel-body" id="sankey"></div>
</div>

<div class="panel">
  <div class="panel-header"><h2>Execution Pipeline</h2><span class="tag">STAGE + JOB</span></div>
  <div class="panel-body" id="pipeline-flow" style="overflow-x:auto;"></div>
</div>

<div class="panel">
  <div class="panel-header"><h2>Token Waterfall</h2><span class="tag">TIMELINE + WIDTH</span></div>
  <div class="panel-body" id="waterfall-flow"></div>
</div>

<div class="panel">
  <div class="panel-header"><h2>Node Breakdown</h2><span class="tag">TABLE</span></div>
  <div class="panel-body" style="padding: 0;">
    <table id="node-table">
      <thead><tr><th>Type</th><th>Name</th><th>Est. Tokens</th><th>Probability</th></tr></thead>
      <tbody></tbody>
    </table>
  </div>
</div>

<div class="panel">
  <div class="panel-header"><h2>Token Distribution</h2><span class="tag">BREAKDOWN</span></div>
  <div class="panel-body">
    <div class="token-bar-container">
      <div class="token-bar" id="token-bar"></div>
      <div class="legend" id="legend"></div>
    </div>
  </div>
</div>

<div class="footer">
  <span>FLOW_VIZ v0.1.0</span>
  <span>GENERATED BY CLAUDE CODE // vw-flow-viz skill</span>
</div>

<div class="tooltip" id="tooltip"></div>

<script>
const DATA = {{SANKEY_DATA}};
const COLORS = { user: '#00d4ff', skill: '#00ff88', agent: '#ffaa00', subagent: '#ff7700', tool: '#cc44ff', output: '#00ffcc' };

// --- Stats ---
const typeGroups = {};
DATA.nodes.forEach(n => {
  if (!typeGroups[n.type]) typeGroups[n.type] = { count: 0, tokens: 0 };
  typeGroups[n.type].count += 1;
  typeGroups[n.type].tokens += n.tokens || 0;
});
const totalTokens = DATA.nodes.find(n => n.id === 'session')?.tokens || DATA.nodes.reduce((s, n) => s + (n.tokens || 0), 0);
const statsEl = document.getElementById('stats');
[
  { label: 'Nodes', value: DATA.nodes.length },
  { label: 'Links', value: DATA.links.length },
  { label: 'Tokens', value: totalTokens.toLocaleString() },
  { label: 'Agents', value: (typeGroups.agent?.count || 0) + (typeGroups.subagent?.count || 0) },
  { label: 'Tools', value: typeGroups.tool?.count || 0 }
].forEach(s => {
  const card = document.createElement('div');
  card.className = 'stat-card';
  card.innerHTML = `<div class="label">${s.label}</div><div class="value">${s.value}</div>`;
  statsEl.appendChild(card);
});

// --- Sankey ---
const margin = { top: 40, right: 100, bottom: 60, left: 100 };
const containerWidth = document.getElementById('sankey').clientWidth || 1100;
const width = containerWidth;
const height = Math.max(950, DATA.nodes.length * 55);

const svg = d3.select('#sankey').append('svg')
  .attr('width', '100%').attr('height', height).attr('viewBox', `0 0 ${width} ${height}`);

const nodeMap = {};
DATA.nodes.forEach((n, i) => { nodeMap[n.id] = i; });

const sankeyData = {
  nodes: DATA.nodes.map(n => ({ ...n })),
  links: DATA.links.map(l => ({ source: nodeMap[l.source], target: nodeMap[l.target], value: Math.max(l.value, 1), probability: l.probability }))
};

const sankey = d3.sankey().nodeId(d => d.index).nodeWidth(24).nodePadding(30)
  .nodeAlign(d3.sankeyJustify).extent([[margin.left, margin.top], [width - margin.right, height - margin.bottom]]);

const { nodes, links } = sankey(sankeyData);
const tooltip = document.getElementById('tooltip');
const totalTok = totalTokens;

// Links
svg.append('g').selectAll('.link').data(links).join('path')
  .attr('class', 'link').attr('d', d3.sankeyLinkHorizontal())
  .attr('stroke', d => COLORS[d.source.type] || '#444')
  .attr('stroke-width', d => Math.max(1, d.width))
  .on('mouseover', (e, d) => {
    const prob = d.probability != null ? `<br>発火確率: ~${(d.probability * 100).toFixed(0)}%` : '';
    const srcDetail = d.source.detail ? `<div class="tt-detail">${d.source.detail.split('\n')[0]}</div>` : '';
    tooltip.innerHTML = `<div class="tt-header"><strong>${d.source.name}</strong> → ${d.target.name}</div><span class="tt-tokens">${d.value.toLocaleString()} tokens</span>${prob}${srcDetail}`;
    tooltip.style.opacity = 1;
  })
  .on('mousemove', e => { tooltip.style.left = (e.pageX + 14) + 'px'; tooltip.style.top = (e.pageY - 24) + 'px'; })
  .on('mouseout', () => { tooltip.style.opacity = 0; });

// Nodes
const nodeG = svg.append('g').selectAll('.node').data(nodes).join('g').attr('class', 'node');
nodeG.append('rect').attr('x', d => d.x0).attr('y', d => d.y0)
  .attr('height', d => Math.max(2, d.y1 - d.y0)).attr('width', d => d.x1 - d.x0)
  .attr('fill', d => COLORS[d.type] || '#444');

nodeG.style('cursor', 'pointer')
  .on('mouseover', (e, d) => {
    const pct = ((d.tokens || 0) / totalTok * 100).toFixed(1);
    const detail = d.detail ? `<div class="tt-detail">${d.detail}</div>` : '';
    tooltip.innerHTML = `<div class="tt-header"><strong>${d.name}</strong> <span class="tt-type">${d.type}</span></div><span class="tt-tokens">${(d.tokens || 0).toLocaleString()} tokens</span> (${pct}%)${detail ? '<br>' + detail : ''}`;
    tooltip.style.opacity = 1;
  })
  .on('mousemove', e => { tooltip.style.left = (e.pageX + 14) + 'px'; tooltip.style.top = (e.pageY - 24) + 'px'; })
  .on('mouseout', () => { tooltip.style.opacity = 0; });

// Percentage labels (above node)
nodeG.append('text').attr('class', 'node-pct')
  .attr('x', d => (d.x0 + d.x1) / 2).attr('y', d => d.y0 - 4).attr('text-anchor', 'middle')
  .attr('fill', d => COLORS[d.type] || '#888')
  .text(d => { const pct = ((d.tokens || 0) / totalTok * 100); return pct < 1 ? '<1%' : Math.round(pct) + '%'; });

// Name labels (below node)
nodeG.append('text').attr('class', 'node-label')
  .attr('x', d => (d.x0 + d.x1) / 2).attr('y', d => d.y1 + 12).attr('text-anchor', 'middle')
  .text(d => d.name);

// Total tokens label
svg.append('text').attr('x', width / 2).attr('y', height - 20).attr('text-anchor', 'middle')
  .attr('fill', '#666').attr('font-family', 'var(--font-mono)').attr('font-size', '13px')
  .attr('font-weight', '600').attr('letter-spacing', '0.05em')
  .text(`${totalTok.toLocaleString()} TOKENS`);

// --- Node Table ---
const tbody = document.querySelector('#node-table tbody');
DATA.nodes.forEach(n => {
  const prob = DATA.links.filter(l => l.target === n.id).map(l => l.probability).filter(p => p != null);
  const avgProb = prob.length > 0 ? prob.reduce((a, b) => a + b, 0) / prob.length : 1.0;
  const tr = document.createElement('tr');
  tr.innerHTML = `<td><span class="type-badge type-${n.type}">${n.type}</span></td><td>${n.name}</td><td>${(n.tokens || 0).toLocaleString()}</td><td>~${(avgProb * 100).toFixed(0)}%</td>`;
  tbody.appendChild(tr);
});

// --- Token Bar ---
const bar = document.getElementById('token-bar');
const legendEl = document.getElementById('legend');
const nodesWithOutgoing = new Set(DATA.links.map(l => l.source));
const typeTokens = {};
DATA.nodes.forEach(n => { if (!nodesWithOutgoing.has(n.id)) typeTokens[n.type] = (typeTokens[n.type] || 0) + (n.tokens || 0); });
const total = Object.values(typeTokens).reduce((a, b) => a + b, 0) || 1;
const typeLabels = { user: 'User', skill: 'Skill', agent: 'Agent', subagent: 'Sub-agent', tool: 'Tool', output: 'Output' };
Object.entries(typeTokens).forEach(([type, tokens]) => {
  const pct = (tokens / total * 100);
  if (pct < 0.5) return;
  const div = document.createElement('div');
  div.style.width = pct + '%'; div.style.background = COLORS[type] || '#444';
  bar.appendChild(div);
  const item = document.createElement('div');
  item.className = 'legend-item';
  item.innerHTML = `<span class="legend-dot" style="background:${COLORS[type]}"></span>${typeLabels[type] || type}: ${tokens.toLocaleString()} (${pct.toFixed(1)}%)`;
  legendEl.appendChild(item);
});

// === Probability color ===
const probColor = p => p >= 0.8 ? '#00ff88' : p >= 0.5 ? '#ffaa00' : '#ff4466';
const typeColor = t => t === 'llm' ? '#00ff88' : t === 'tool' ? '#cc44ff' : '#00ffcc';

// === Pipeline + Waterfall data ===
const phases = {{PIPELINE_DATA}};

// === Pipeline ===
(() => {
  const container = document.getElementById('pipeline-flow');
  phases.forEach(phase => {
    const phaseEl = document.createElement('div'); phaseEl.className = 'pl-phase';
    const title = document.createElement('div'); title.className = 'pl-phase-title'; title.textContent = phase.name;
    phaseEl.appendChild(title);
    const row = document.createElement('div'); row.className = 'pl-row';
    phase.stages.forEach((stage, si) => {
      if (si > 0) { const conn = document.createElement('div'); conn.className = 'pl-conn'; conn.textContent = '→'; row.appendChild(conn); }
      const stageEl = document.createElement('div'); stageEl.className = 'pl-stage';
      const header = document.createElement('div'); header.className = 'pl-stage-header'; header.textContent = stage.stage;
      stageEl.appendChild(header);
      stage.jobs.forEach(job => {
        const jobEl = document.createElement('div'); jobEl.className = 'pl-job' + (job.prob < 0.5 ? ' maybe' : '');
        const dot = document.createElement('div'); dot.className = 'prob-dot'; dot.style.background = probColor(job.prob);
        jobEl.innerHTML = `<div class="name">${job.name}</div><div class="meta"><span style="color:${probColor(job.prob)}">${Math.round(job.prob*100)}%</span> · ${job.tokens} tok</div>`;
        jobEl.appendChild(dot); stageEl.appendChild(jobEl);
      });
      row.appendChild(stageEl);
    });
    phaseEl.appendChild(row); container.appendChild(phaseEl);
  });
})();

// === Waterfall ===
(() => {
  const container = document.getElementById('waterfall-flow');
  phases.forEach(phase => {
    const phaseEl = document.createElement('div'); phaseEl.className = 'wf-phase';
    const title = document.createElement('div'); title.className = 'wf-phase-title'; title.textContent = phase.name;
    phaseEl.appendChild(title);
    const allJobs = phase.stages.flatMap(s => s.jobs);
    let cumLeft = 0;
    const scale = 5500;
    allJobs.forEach(job => {
      const row = document.createElement('div'); row.className = 'wf-row';
      const label = document.createElement('div'); label.className = 'wf-label'; label.textContent = job.name;
      const track = document.createElement('div'); track.className = 'wf-track';
      const barW = (job.tokens / scale) * 100;
      if (job.prob < 1) {
        const ghost = document.createElement('div'); ghost.className = 'wf-bar ghost';
        ghost.style.left = cumLeft + '%'; ghost.style.width = barW + '%'; ghost.style.background = typeColor(job.type);
        track.appendChild(ghost);
      }
      const b = document.createElement('div'); b.className = 'wf-bar';
      b.style.left = cumLeft + '%'; b.style.width = (barW * job.prob) + '%';
      b.style.background = typeColor(job.type); b.style.opacity = job.prob < 1 ? '0.7' : '1';
      if (barW > 8) b.textContent = job.tokens;
      track.appendChild(b);
      cumLeft += barW + 0.5;
      const prob = document.createElement('div'); prob.className = 'wf-prob';
      prob.style.color = probColor(job.prob); prob.textContent = Math.round(job.prob * 100) + '%';
      row.appendChild(label); row.appendChild(track); row.appendChild(prob);
      phaseEl.appendChild(row);
    });
    container.appendChild(phaseEl);
  });
})();
</script>
</body>
</html>
```

## Data Format

### Sankey Data (`{{SANKEY_DATA}}`)

Flow-conserving model: parent output = sum of children.

```json
{
  "nodes": [
    {"id": "session", "name": "Total Session", "type": "skill", "tokens": 12500, "detail": "..."},
    {"id": "user-input", "name": "User Input", "type": "user", "tokens": 150, "detail": "..."},
    {"id": "phase1", "name": "Phase 1", "type": "skill", "tokens": 2100, "detail": "..."},
    {"id": "p1-read", "name": "Read", "type": "tool", "tokens": 800, "detail": "..."}
  ],
  "links": [
    {"source": "session", "target": "user-input", "value": 150, "probability": 1.0},
    {"source": "session", "target": "phase1", "value": 2100, "probability": 1.0},
    {"source": "phase1", "target": "p1-read", "value": 800, "probability": 1.0}
  ]
}
```

### Pipeline Data (`{{PIPELINE_DATA}}`)

Phases with stages and jobs for Pipeline + Waterfall views.

```json
[
  {
    "name": "Phase 1: Resolve",
    "stages": [
      {
        "stage": "Prompt",
        "jobs": [{"name": "Skill Prompt", "type": "llm", "prob": 1.0, "tokens": 5400}]
      },
      {
        "stage": "Read",
        "jobs": [{"name": "Read", "type": "tool", "prob": 1.0, "tokens": 800}]
      }
    ]
  }
]
```

### Important Notes

- **Flow conservation**: For Sankey, parent output = sum of children. `session.tokens = sum(direct children tokens)`.
- **No circular links**: D3 Sankey requires DAG. If same tool is called from multiple phases, create separate nodes per phase.
- **Node `detail`**: Multi-line string shown in tooltip. Include source location in SKILL.md and token breakdown.
- **Pipeline `type`**: `"llm"` for LLM reasoning steps, `"tool"` for tool calls, `"output"` for deliverables.
- **Ghost bars**: Waterfall shows ghost bars for `prob < 1.0` to visualize potential but uncertain execution.
