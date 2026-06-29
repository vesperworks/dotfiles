# 12ヶ月カレンダーテンプレート（設計解説）

> **正規ソースは [calendar-template.html](./calendar-template.html)。** 通常の生成ではそちらをコピーしてプレースホルダ置換するだけでよく、本ファイルはテンプレート改修時の設計解説として読む。本ファイル内のコード断片と calendar-template.html に差異がある場合は **calendar-template.html を優先**する（本ファイルのコードはブラウザテスト前の初版であり、detail 描画の座標系修正等が反映されていない）。

`html` スキルの [design-system.md](../../html/references/design-system.md) の §5 Common CSS / §6 Common JS / §7 HTML Shell をベースとして継承し、財務諸表カレンダー固有の CSS/JS/SVG 生成を追加する。カラープリセット（J/K）・フォントプリセット（N/P）・グリッドオーバーレイ（G）・静的エクスポート（E）はそのまま流用する。

## 1. レイアウト構造

```html
<div class="fin-calendar">
  <div class="fin-year-nav">
    <button id="yearPrev">‹</button>
    <span id="yearLabel">{{FISCAL_YEAR}}年度</span>
    <button id="yearNext">›</button>
    <span class="fin-unit">単位: {{UNIT}}</span>
  </div>

  <div class="fin-grid">
    <!-- 12 枚の月カード。データが無い月は .fin-card--empty -->
    <div class="fin-card" data-month="2026-01" tabindex="0">
      <div class="fin-card__head">
        <span class="fin-card__month">1月</span>
        <span class="fin-card__badge {{yoy_class}}">{{yoy_label}}</span>
      </div>
      <div class="fin-card__mini">
        <svg class="fin-mini-pl" viewBox="0 0 100 60"></svg>
        <svg class="fin-mini-bs" viewBox="0 0 100 60"></svg>
        <svg class="fin-mini-cf" viewBox="0 0 100 60"></svg>
      </div>
    </div>
    <!-- ... 12 個分 ... -->
  </div>
</div>

<div class="fin-modal" id="finModal" aria-hidden="true">
  <div class="fin-modal__body">
    <button class="fin-modal__close" aria-label="閉じる">×</button>
    <div class="fin-modal__content"><!-- 詳細図解を JS で描画 --></div>
  </div>
</div>
```

- `.fin-grid` は縦スクロールコンテナ（`overflow-y: auto; max-height: calc(100vh - {ヘッダー+HUD高さ})`）
- カード枚数は常に12（データ欠損月は `.fin-card--empty` でグレーアウト＋「データなし」表示、レイアウト崩れを防ぐ）
- カードクリック / Enter キーでモーダル展開

## 2. CSS 追加分（design-system.md §5 の後に追記）

```css
.fin-calendar { grid-column: 1 / -1; }

.fin-year-nav {
  display: flex; align-items: center; gap: 12px;
  font-family: var(--font-mono);
  margin-bottom: var(--lh);
}
.fin-year-nav button {
  background: var(--surface); border: 1px solid var(--border-accent);
  color: var(--text); cursor: pointer; padding: 4px 10px;
}
.fin-unit { margin-left: auto; color: var(--text-muted); font-size: 0.75rem; }

.fin-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--gutter);
  max-height: 78vh;
  overflow-y: auto;
  padding-right: 8px;
  scroll-behavior: smooth;
}
@media (max-width: 900px) {
  .fin-grid { grid-template-columns: repeat(2, 1fr); }
}

.fin-card {
  background: var(--surface);
  border: 1px solid var(--border);
  padding: 12px;
  cursor: pointer;
  transition: border-color 0.15s, transform 0.15s;
}
.fin-card:hover, .fin-card:focus-visible {
  border-color: var(--accent);
  transform: translateY(-2px);
  outline: none;
}
.fin-card--empty { opacity: 0.35; cursor: default; }
.fin-card--empty:hover { transform: none; border-color: var(--border); }

.fin-card__head {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 8px;
}
.fin-card__month {
  font-family: var(--font-mono); font-weight: 700; font-size: 0.9rem;
}
.fin-card__badge {
  font-family: var(--font-mono); font-size: 0.6rem;
  padding: 1px 6px; letter-spacing: 0.04em;
}
.fin-card__badge.up { color: var(--pl-plus, var(--accent)); }
.fin-card__badge.down { color: var(--pl-minus, var(--danger)); }
.fin-card__badge.flat { color: var(--text-muted); }

.fin-card__mini {
  display: grid; grid-template-columns: repeat(3, 1fr); gap: 4px;
}
.fin-card__mini svg { width: 100%; height: 56px; display: block; }

.fin-modal {
  position: fixed; inset: 0; z-index: 500;
  display: flex; align-items: center; justify-content: center;
  background: rgba(0,0,0,0.6);
  opacity: 0; pointer-events: none;
  transition: opacity 0.15s;
}
.fin-modal[aria-hidden="false"] { opacity: 1; pointer-events: auto; }
.fin-modal__body {
  background: var(--bg); border: 1px solid var(--border-accent);
  max-width: 900px; width: 92vw; max-height: 88vh; overflow-y: auto;
  padding: var(--pad); position: relative;
}
.fin-modal__close {
  position: absolute; top: 12px; right: 12px;
  background: none; border: none; color: var(--text-muted);
  font-size: 1.4rem; cursor: pointer; line-height: 1;
}

/* 詳細図解内の数値ラベル */
.fin-detail-label {
  font-family: var(--font-mono); font-size: 0.68rem; fill: var(--text-muted);
}
.fin-detail-value {
  font-family: var(--font-mono); font-size: 0.72rem; font-weight: 700; fill: var(--text);
}
```

## 3. JS 追加分（design-system.md §6 の後に追記）

以下は素の SVG 生成関数。D3.js 等の外部ライブラリを使わず、`document.createElementNS` で完結させる（単一ファイル・CDN最小化のため）。

```js
const NS = 'http://www.w3.org/2000/svg';
function svgEl(tag, attrs) {
  const el = document.createElementNS(NS, tag);
  for (const k in attrs) el.setAttribute(k, attrs[k]);
  return el;
}

/* ---- PL waterfall (mini: 5 blocks, detail: full) ---- */
function drawPLWaterfall(svg, pl, { mini = true } = {}) {
  svg.innerHTML = '';
  const steps = mini
    ? [
        ['売上', pl.revenue, 'base'],
        ['原価', -pl.cogs, 'minus'],
        ['粗利', pl.grossProfit, 'sub'],
        ['販管費', -pl.sga, 'minus'],
        ['純利益', pl.netIncome, 'final'],
      ]
    : [
        ['売上', pl.revenue, 'base'],
        ['原価', -pl.cogs, 'minus'],
        ['粗利', pl.grossProfit, 'sub'],
        ['販管費', -pl.sga, 'minus'],
        ['営業利益', pl.operatingIncome, 'sub'],
        ['営業外', pl.nonOperating, pl.nonOperating >= 0 ? 'plus' : 'minus'],
        ['経常利益', pl.ordinaryIncome, 'sub'],
        ['特別損益等', pl.extraordinary, pl.extraordinary >= 0 ? 'plus' : 'minus'],
        ['純利益', pl.netIncome, 'final'],
      ];
  const maxAbs = Math.max(...steps.map(s => Math.abs(s[1])), 1);
  const w = 100 / steps.length;
  let cursor = 0;
  steps.forEach((s, i) => {
    const [label, val, kind] = s;
    const isAbsolute = kind === 'base' || kind === 'sub' || kind === 'final';
    const h = (Math.abs(val) / maxAbs) * 50;
    const y = isAbsolute ? 55 - h : (val >= 0 ? 55 - cursor - h : 55 - cursor);
    const fill = kind === 'minus' ? 'var(--pl-minus, var(--danger))'
      : kind === 'plus' ? 'var(--pl-plus, var(--accent))'
      : kind === 'final' ? 'var(--accent)'
      : 'var(--text-muted)';
    svg.appendChild(svgEl('rect', {
      x: i * w + 2, y, width: w - 4, height: Math.max(h, 1),
      fill,
    }));
    if (!mini) {
      svg.appendChild(svgEl('text', { x: i * w + w / 2, y: 59, 'text-anchor': 'middle', class: 'fin-detail-label' })).textContent = label;
    }
    if (isAbsolute) cursor = 55 - y >= 0 ? 55 - y : cursor;
    else cursor += val >= 0 ? h : -h;
  });
}

/* ---- BS block (mini: 2 blocks, detail: current/fixed/equity breakdown) ---- */
function drawBSBlock(svg, bs, { mini = true } = {}) {
  svg.innerHTML = '';
  const total = Math.max(bs.totalAssets, bs.totalLiabilities + bs.equity, 1);
  const scale = 55 / total;
  if (mini) {
    svg.appendChild(svgEl('rect', { x: 2, y: 55 - bs.totalAssets * scale, width: 45, height: bs.totalAssets * scale, fill: 'var(--bs-current, var(--cyan))' }));
    svg.appendChild(svgEl('rect', { x: 53, y: 55 - (bs.totalLiabilities + bs.equity) * scale, width: 45, height: (bs.totalLiabilities + bs.equity) * scale, fill: 'var(--accent)' }));
    return;
  }
  const left = [['流動資産', bs.currentAssets], ['固定資産', bs.fixedAssets]];
  const right = [['流動負債', bs.currentLiabilities], ['固定負債', bs.fixedLiabilities], ['純資産', bs.equity]];
  let ly = 55;
  left.forEach(([label, val]) => {
    const h = val * scale;
    ly -= h;
    svg.appendChild(svgEl('rect', { x: 4, y: ly, width: 40, height: h, fill: 'var(--bs-current, var(--cyan))' }));
  });
  let ry = 55;
  right.forEach(([label, val], i) => {
    const h = val * scale;
    ry -= h;
    const fill = label === '純資産' ? 'var(--accent)' : 'var(--bs-fixed, var(--text-muted))';
    svg.appendChild(svgEl('rect', { x: 56, y: ry, width: 40, height: h, fill }));
  });
}

/* ---- CF bridge (start -> operating -> investing -> financing -> end) ---- */
function drawCFBridge(svg, cf, { mini = true } = {}) {
  svg.innerHTML = '';
  const steps = [
    ['期首', cf.cashBegin, 'base'],
    ['営業', cf.operating, cf.operating >= 0 ? 'plus' : 'minus'],
    ['投資', cf.investing, 'neutral'],
    ['財務', cf.financing, 'neutral'],
    ['期末', cf.cashEnd, 'base'],
  ];
  const maxAbs = Math.max(...steps.map(s => Math.abs(s[1])), 1);
  const w = 100 / steps.length;
  let cursor = 0;
  steps.forEach((s, i) => {
    const [label, val, kind] = s;
    const isAbsolute = kind === 'base';
    const h = (Math.abs(val) / maxAbs) * 50;
    const y = isAbsolute ? 55 - h : (val >= 0 ? 55 - cursor - h : 55 - cursor);
    const fill = kind === 'minus' ? 'var(--pl-minus, var(--danger))'
      : kind === 'plus' ? 'var(--pl-plus, var(--accent))'
      : kind === 'base' ? 'var(--text)'
      : 'var(--bs-fixed, var(--text-muted))';
    svg.appendChild(svgEl('rect', { x: i * w + 2, y, width: w - 4, height: Math.max(h, 1), fill }));
    if (isAbsolute) cursor = 55 - y;
    else cursor += val >= 0 ? h : -h;
  });
}

/* ---- Card / Modal wiring ---- */
function renderCalendar(data) {
  const grid = document.querySelector('.fin-grid');
  data.months.forEach(m => {
    const card = grid.querySelector(`[data-month="${m.month}"]`);
    if (!card || m.empty) return;
    drawPLWaterfall(card.querySelector('.fin-mini-pl'), m.pl, { mini: true });
    drawBSBlock(card.querySelector('.fin-mini-bs'), m.bs, { mini: true });
    drawCFBridge(card.querySelector('.fin-mini-cf'), m.cf, { mini: true });
    card.addEventListener('click', () => openModal(m));
    card.addEventListener('keydown', e => { if (e.key === 'Enter') openModal(m); });
  });
}

function openModal(m) {
  const modal = document.getElementById('finModal');
  const content = modal.querySelector('.fin-modal__content');
  content.innerHTML = `
    <h2>${m.month}</h2>
    <svg class="fin-detail-pl" viewBox="0 0 300 70" style="width:100%;height:140px"></svg>
    <svg class="fin-detail-bs" viewBox="0 0 100 60" style="width:100%;height:200px"></svg>
    <svg class="fin-detail-cf" viewBox="0 0 300 70" style="width:100%;height:140px"></svg>
  `;
  drawPLWaterfall(content.querySelector('.fin-detail-pl'), m.pl, { mini: false });
  drawBSBlock(content.querySelector('.fin-detail-bs'), m.bs, { mini: false });
  drawCFBridge(content.querySelector('.fin-detail-cf'), m.cf, { mini: false });
  modal.setAttribute('aria-hidden', 'false');
}
document.getElementById('finModal')?.addEventListener('click', e => {
  if (e.target.id === 'finModal' || e.target.closest('.fin-modal__close')) {
    document.getElementById('finModal').setAttribute('aria-hidden', 'true');
  }
});
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') document.getElementById('finModal')?.setAttribute('aria-hidden', 'true');
});
```

## 4. データ欠損月の扱い

`data.months` は必ず12要素。データが無い月は `{ month, empty: true }` のみを持たせ、カード側は `.fin-card--empty` クラスで灰色表示（クリック無効）。**12枚固定でレイアウトを崩さない**のが原則（YAGNI で「ある月だけ表示」にすると年間比較ができなくなる）。

## 5. YoY バッジ（前年同月比）

`m.yoy`（前年同月の売上比、%）があればカード右上に表示:
- `yoy >= 105` → `up`（緑）「+{n}%」
- `yoy <= 95` → `down`（赤）「{n}%」
- それ以外 → `flat`（グレー）「±0%」
- 前年データが無い場合はバッジ非表示

## Common Pitfalls

- SVG の `viewBox` とコンテナサイズの比率がずれるとブロックが潰れて見える → `preserveAspectRatio` はデフォルト（`xMidYMid meet`）のままでよいが、mini 用 viewBox は必ず `0 0 100 60` に統一しモーダル用と別スケールにする
- モーダルを開いた状態でカレンダー側をスクロールできてしまう → `body.classList.add('fin-modal-open')` で `overflow: hidden` を付与するのを忘れない
- 12ヶ月グリッドを `overflow-y: auto` にせず全部展開すると「スクロールできる」という要件を満たさない
