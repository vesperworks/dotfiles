const dir = process.argv[2] || '.idea';
const port = parseInt(process.argv[3] || '8888');

Bun.serve({
  port,
  async fetch(req) {
    const url = new URL(req.url);
    const headers = { 'Access-Control-Allow-Origin': '*', 'Cache-Control': 'no-store' };

    if (req.method === 'OPTIONS') {
      return new Response(null, { headers: { ...headers, 'Access-Control-Allow-Methods': 'GET,POST', 'Access-Control-Allow-Headers': 'Content-Type' } });
    }

    // POST /save-state → write state.json
    if (req.method === 'POST' && url.pathname === '/save-state') {
      const body = await req.json();
      await Bun.write(`${dir}/state.json`, JSON.stringify(body, null, 2));
      return new Response(JSON.stringify({ ok: true, nodes: body.nodes?.length || 0 }), { headers: { ...headers, 'Content-Type': 'application/json' } });
    }

    // POST /prune-nodes → remove pruned node IDs from all JSON files
    if (req.method === 'POST' && url.pathname === '/prune-nodes') {
      const { pruneIds } = await req.json();
      const pruneSet = new Set(pruneIds);
      const glob = new Bun.Glob('*.json');
      let removed = 0;
      for await (const fname of glob.scan(`${dir}/nodes`)) {
        if (fname === 'root.json') continue;
        const fpath = `${dir}/nodes/${fname}`;
        const raw = await Bun.file(fpath).text();
        const data = JSON.parse(raw);
        if (Array.isArray(data)) {
          const filtered = data.filter(n => !pruneSet.has(n.id));
          removed += data.length - filtered.length;
          if (filtered.length === 0) {
            const fs = require('fs'); fs.unlinkSync(fpath);
          } else if (filtered.length < data.length) {
            await Bun.write(fpath, JSON.stringify(filtered));
          }
        }
      }
      return new Response(JSON.stringify({ ok: true, removed }), { headers: { ...headers, 'Content-Type': 'application/json' } });
    }

    // GET /nodes/ → JSON array of filenames
    if (url.pathname === '/nodes/' || url.pathname === '/nodes') {
      const glob = new Bun.Glob('*.json');
      const files = [];
      for await (const file of glob.scan(`${dir}/nodes`)) files.push(file);
      return new Response(JSON.stringify(files.sort()), { headers: { ...headers, 'Content-Type': 'application/json' } });
    }

    // Static file serving
    let path = `${dir}${url.pathname}`;
    if (url.pathname === '/') path = `${dir}/live.html`;
    const file = Bun.file(path);
    if (await file.exists()) return new Response(file, { headers });
    return new Response('Not found', { status: 404 });
  }
});

console.log(`vw:brainstorm server → http://127.0.0.1:${port}  (serving ${dir}/)`);
