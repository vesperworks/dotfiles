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

## Usage

Replace these placeholders:
- `{{SANKEY_DATA}}` — JSON object with nodes and links
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

  /* --- Header --- */
  .header {
    display: grid;
    grid-template-columns: 1fr auto;
    align-items: end;
    margin-bottom: 32px;
    padding-bottom: 20px;
    border-bottom: 2px solid var(--accent);
  }
  .header h1 {
    font-family: var(--font-mono);
    font-size: 1.6rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    color: var(--accent);
  }
  .header h1 span {
    color: var(--text-muted);
    font-weight: 400;
  }
  .header .meta {
    font-family: var(--font-mono);
    color: var(--text-muted);
    font-size: 0.72rem;
    text-align: right;
    line-height: 1.8;
    letter-spacing: 0.03em;
  }

  /* --- Stats Grid --- */
  .stats {
    display: grid;
    grid-template-columns: repeat(5, 1fr);
    gap: 1px;
    background: var(--border);
    margin-bottom: 32px;
    border: 1px solid var(--border);
  }
  .stat-card {
    background: var(--surface);
    padding: 20px 16px;
  }
  .stat-card .label {
    font-family: var(--font-mono);
    font-size: 0.65rem;
    color: var(--text-dim);
    text-transform: uppercase;
    letter-spacing: 0.12em;
    margin-bottom: 4px;
  }
  .stat-card .value {
    font-family: var(--font-mono);
    font-size: 2rem;
    font-weight: 700;
    color: var(--accent);
    line-height: 1;
  }
  .stat-card:nth-child(3) .value { color: var(--cyan); }

  /* --- Panels --- */
  .panel {
    background: var(--surface);
    border: 1px solid var(--border);
    margin-bottom: 24px;
    overflow: hidden;
  }
  .panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 14px 20px;
    border-bottom: 1px solid var(--border);
  }
  .panel-header h2 {
    font-family: var(--font-mono);
    font-size: 0.7rem;
    font-weight: 500;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.1em;
  }
  .panel-header .tag {
    font-family: var(--font-mono);
    font-size: 0.6rem;
    color: var(--accent);
    background: var(--accent-dim);
    padding: 2px 8px;
    letter-spacing: 0.05em;
  }
  .panel-body { padding: 20px; }

  /* --- Table --- */
  table { width: 100%; border-collapse: collapse; }
  th {
    font-family: var(--font-mono);
    text-align: left;
    padding: 8px 12px;
    font-size: 0.6rem;
    font-weight: 500;
    color: var(--text-dim);
    text-transform: uppercase;
    letter-spacing: 0.1em;
    border-bottom: 1px solid var(--border-accent);
  }
  td {
    font-family: var(--font-mono);
    text-align: left;
    padding: 7px 12px;
    font-size: 0.78rem;
    color: var(--text);
    border-bottom: 1px solid var(--border);
  }
  tr:hover td { background: var(--surface-hover); }
  .type-badge {
    display: inline-block;
    padding: 1px 6px;
    font-family: var(--font-mono);
    font-size: 0.6rem;
    font-weight: 500;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }
  .type-user { background: rgba(0,212,255,0.15); color: var(--user); }
  .type-skill { background: rgba(0,255,136,0.15); color: var(--skill); }
  .type-agent { background: rgba(255,170,0,0.15); color: var(--agent); }
  .type-subagent { background: rgba(255,119,0,0.15); color: var(--subagent); }
  .type-tool { background: rgba(204,68,255,0.15); color: var(--tool); }
  .type-output { background: rgba(0,255,204,0.15); color: var(--output); }

  /* --- Token Bar --- */
  .token-bar-container { margin-top: 8px; }
  .token-bar {
    display: flex;
    height: 6px;
    overflow: hidden;
    margin-bottom: 16px;
  }
  .token-bar div { transition: width 0.3s; }
  .legend {
    display: flex;
    flex-wrap: wrap;
    gap: 20px;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    color: var(--text-muted);
  }
  .legend-item { display: flex; align-items: center; gap: 6px; }
  .legend-dot { width: 6px; height: 6px; }

  /* --- Sankey SVG --- */
  .node text {
    fill: var(--text);
    font-family: var(--font-mono);
    font-size: 10px;
    font-weight: 400;
  }
  .link { fill: none; stroke-opacity: 0.25; }
  .link:hover { stroke-opacity: 0.55; }

  /* --- Tooltip --- */
  .tooltip {
    position: absolute;
    background: var(--surface);
    border: 1px solid var(--border-accent);
    padding: 8px 12px;
    font-family: var(--font-mono);
    font-size: 0.72rem;
    color: var(--text);
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.1s;
    z-index: 100;
    line-height: 1.6;
  }
  .tooltip strong { color: var(--accent); }

  /* --- Footer --- */
  .footer {
    margin-top: 16px;
    padding-top: 16px;
    border-top: 1px solid var(--border);
    font-family: var(--font-mono);
    font-size: 0.6rem;
    color: var(--text-dim);
    letter-spacing: 0.05em;
    display: flex;
    justify-content: space-between;
  }
</style>
</head>
<body>

<div class="header">
  <h1><span>FLOW_VIZ //</span> {{TITLE}}</h1>
  <div class="meta">
    GEN {{DATE}}<br>
    EST ~{{TOTAL_TOKENS}} TOKENS
  </div>
</div>

<div class="stats" id="stats"></div>

<div class="panel">
  <div class="panel-header">
    <h2>Execution Flow</h2>
    <span class="tag">SANKEY</span>
  </div>
  <div class="panel-body" id="sankey"></div>
</div>

<div class="panel">
  <div class="panel-header">
    <h2>Node Breakdown</h2>
    <span class="tag">TABLE</span>
  </div>
  <div class="panel-body" style="padding: 0;">
    <table id="node-table">
      <thead>
        <tr><th>Type</th><th>Name</th><th>Est. Tokens</th><th>Probability</th></tr>
      </thead>
      <tbody></tbody>
    </table>
  </div>
</div>

<div class="panel">
  <div class="panel-header">
    <h2>Token Distribution</h2>
    <span class="tag">BREAKDOWN</span>
  </div>
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
const COLORS = {
  user: '#00d4ff',
  skill: '#00ff88',
  agent: '#ffaa00',
  subagent: '#ff7700',
  tool: '#cc44ff',
  output: '#00ffcc'
};

// --- Stats ---
const typeGroups = {};
DATA.nodes.forEach(n => {
  if (!typeGroups[n.type]) typeGroups[n.type] = { count: 0, tokens: 0 };
  typeGroups[n.type].count += 1;
  typeGroups[n.type].tokens += n.tokens || 0;
});
const totalTokens = DATA.nodes.reduce((s, n) => s + (n.tokens || 0), 0);
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
const margin = { top: 16, right: 180, bottom: 16, left: 160 };
const containerWidth = document.getElementById('sankey').clientWidth || 1100;
const width = containerWidth;
const height = Math.max(750, DATA.nodes.length * 55);

const svg = d3.select('#sankey')
  .append('svg')
  .attr('width', '100%')
  .attr('height', height)
  .attr('viewBox', `0 0 ${width} ${height}`);

const nodeMap = {};
DATA.nodes.forEach((n, i) => { nodeMap[n.id] = i; });

const sankeyData = {
  nodes: DATA.nodes.map(n => ({ ...n })),
  links: DATA.links.map(l => ({
    source: nodeMap[l.source],
    target: nodeMap[l.target],
    value: Math.max(l.value, 1),
    probability: l.probability
  }))
};

const sankey = d3.sankey()
  .nodeId(d => d.index)
  .nodeWidth(14)
  .nodePadding(28)
  .nodeAlign(d3.sankeyJustify)
  .extent([[margin.left, margin.top], [width - margin.right, height - margin.bottom]]);

const { nodes, links } = sankey(sankeyData);
const tooltip = document.getElementById('tooltip');

// Links
svg.append('g')
  .selectAll('.link')
  .data(links)
  .join('path')
  .attr('class', 'link')
  .attr('d', d3.sankeyLinkHorizontal())
  .attr('stroke', d => COLORS[d.source.type] || '#444')
  .attr('stroke-width', d => Math.max(1, d.width))
  .on('mouseover', (e, d) => {
    const prob = d.probability != null ? ` // ~${(d.probability * 100).toFixed(0)}%` : '';
    tooltip.innerHTML = `<strong>${d.source.name}</strong> → ${d.target.name}<br>${d.value.toLocaleString()} tokens${prob}`;
    tooltip.style.opacity = 1;
  })
  .on('mousemove', e => {
    tooltip.style.left = (e.pageX + 14) + 'px';
    tooltip.style.top = (e.pageY - 24) + 'px';
  })
  .on('mouseout', () => { tooltip.style.opacity = 0; });

// Nodes
const nodeG = svg.append('g')
  .selectAll('.node')
  .data(nodes)
  .join('g')
  .attr('class', 'node');

nodeG.append('rect')
  .attr('x', d => d.x0)
  .attr('y', d => d.y0)
  .attr('height', d => Math.max(2, d.y1 - d.y0))
  .attr('width', d => d.x1 - d.x0)
  .attr('fill', d => COLORS[d.type] || '#444')
  .on('mouseover', (e, d) => {
    tooltip.innerHTML = `<strong>${d.name}</strong><br>type: ${d.type}<br>est: ${(d.tokens || 0).toLocaleString()} tokens`;
    tooltip.style.opacity = 1;
  })
  .on('mousemove', e => {
    tooltip.style.left = (e.pageX + 14) + 'px';
    tooltip.style.top = (e.pageY - 24) + 'px';
  })
  .on('mouseout', () => { tooltip.style.opacity = 0; });

const midX = (width - margin.left - margin.right) / 2 + margin.left;
nodeG.append('text')
  .attr('x', d => {
    const cx = (d.x0 + d.x1) / 2;
    return cx < midX ? d.x0 - 8 : d.x1 + 8;
  })
  .attr('y', d => (d.y1 + d.y0) / 2)
  .attr('dy', '0.35em')
  .attr('text-anchor', d => {
    const cx = (d.x0 + d.x1) / 2;
    return cx < midX ? 'end' : 'start';
  })
  .text(d => d.name);

// --- Node Table ---
const tbody = document.querySelector('#node-table tbody');
DATA.nodes.forEach(n => {
  const prob = DATA.links
    .filter(l => l.target === n.id)
    .map(l => l.probability)
    .filter(p => p != null);
  const avgProb = prob.length > 0 ? prob.reduce((a, b) => a + b, 0) / prob.length : 1.0;
  const tr = document.createElement('tr');
  tr.innerHTML = `
    <td><span class="type-badge type-${n.type}">${n.type}</span></td>
    <td>${n.name}</td>
    <td>${(n.tokens || 0).toLocaleString()}</td>
    <td>~${(avgProb * 100).toFixed(0)}%</td>
  `;
  tbody.appendChild(tr);
});

// --- Token Bar ---
const bar = document.getElementById('token-bar');
const legendEl = document.getElementById('legend');
const typeTokens = {};
DATA.nodes.forEach(n => {
  typeTokens[n.type] = (typeTokens[n.type] || 0) + (n.tokens || 0);
});
const total = Object.values(typeTokens).reduce((a, b) => a + b, 0) || 1;
const typeLabels = { user: 'User', skill: 'Skill', agent: 'Agent', subagent: 'Sub-agent', tool: 'Tool', output: 'Output' };
Object.entries(typeTokens).forEach(([type, tokens]) => {
  const pct = (tokens / total * 100);
  if (pct < 0.5) return;
  const div = document.createElement('div');
  div.style.width = pct + '%';
  div.style.background = COLORS[type] || '#444';
  bar.appendChild(div);

  const item = document.createElement('div');
  item.className = 'legend-item';
  item.innerHTML = `<span class="legend-dot" style="background:${COLORS[type]}"></span>${typeLabels[type] || type}: ${tokens.toLocaleString()} (${pct.toFixed(1)}%)`;
  legendEl.appendChild(item);
});
</script>
</body>
</html>
```

## Data Format

The `{{SANKEY_DATA}}` placeholder must be replaced with a JSON object:

```json
{
  "nodes": [
    {
      "id": "unique-id",
      "name": "Display Name",
      "type": "user|skill|agent|subagent|tool|output",
      "tokens": 1234
    }
  ],
  "links": [
    {
      "source": "source-node-id",
      "target": "target-node-id",
      "value": 1234,
      "probability": 0.8
    }
  ]
}
```

### Important Notes

- **No circular links**: D3 Sankey requires a DAG (Directed Acyclic Graph). If the skill has loops (e.g., retry, iteration), model them as separate nodes or merge the loop into a single node.
- **Link value**: Represents estimated token flow. Use `Math.max(value, 1)` to avoid zero-width links.
- **Node deduplication**: If the same tool is called from multiple phases, create separate nodes per phase (e.g., "Read (resolve)", "Read (analysis)") to avoid circular references.
