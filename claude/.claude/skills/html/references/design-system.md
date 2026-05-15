# Design System for `/html` SKILL

3 つのテンプレ（status / diagram / annotate）が共通して使う色・タイポ・コンポーネント定義。
`vw-flow-viz` の `html-template.md` と統一されたトークンを採用する（後方互換性のため）。

## 1. Color Tokens

### Base (Hacker + Catppuccin Macchiato 融合)

| Variable | Hex | 用途 |
|----------|-----|------|
| `--bg` | `#0a0a0a` | ページ背景 |
| `--surface` | `#111111` | パネル背景 |
| `--surface-hover` | `#1a1a1a` | hover 時 |
| `--border` | `#222222` | 通常 border |
| `--border-accent` | `#333333` | 強調 border |
| `--text` | `#e0e0e0` | 通常テキスト |
| `--text-muted` | `#666666` | 補助テキスト |
| `--text-dim` | `#444444` | 非アクティブ |

### Accent

| Variable | Hex | 用途 |
|----------|-----|------|
| `--accent` | `#00ff88` | 主要アクション・成功 |
| `--accent-dim` | `rgba(0,255,136,0.15)` | accent の薄色背景 |
| `--cyan` | `#00d4ff` | 情報・選択中 |
| `--cyan-dim` | `rgba(0,212,255,0.15)` | cyan の薄色背景 |
| `--warn` | `#ffaa00` | 注意・進行中 |
| `--danger` | `#ff5555` | エラー・ブロッカー |
| `--purple` | `#cc44ff` | ツール・補助情報 |

### Type-specific（Sankey/関係図と統一）

| Type | Color |
|------|-------|
| user | `#00d4ff` |
| skill | `#00ff88` |
| agent | `#ffaa00` |
| subagent | `#ff7700` |
| tool | `#cc44ff` |
| output | `#00ffcc` |

## 2. Typography

| Variable | Font | 用途 |
|----------|------|------|
| `--font-sans` | `'Inter', -apple-system, sans-serif` | 見出し・本文 |
| `--font-mono` | `'JetBrains Mono', 'SF Mono', monospace` | データ・ラベル・バッジ |

CDN: Google Fonts `Inter:wght@300;400;600;700` + `JetBrains+Mono:wght@400;500;700`

## 3. Common CSS Snippet (paste into every template)

```css
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
  --warn: #ffaa00;
  --danger: #ff5555;
  --purple: #cc44ff;
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
.header h1 {
  font-family: var(--font-mono);
  font-size: 1.6rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: var(--accent);
}
.header h1 span { color: var(--text-muted); font-weight: 400; }
.header .meta {
  font-family: var(--font-mono);
  color: var(--text-muted);
  font-size: 0.72rem;
  text-align: right;
  line-height: 1.8;
  letter-spacing: 0.03em;
}
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
.btn {
  font-family: var(--font-mono);
  font-size: 0.72rem;
  padding: 8px 14px;
  background: var(--surface-hover);
  color: var(--accent);
  border: 1px solid var(--border-accent);
  cursor: pointer;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  transition: background 0.15s, border-color 0.15s;
}
.btn:hover { background: var(--accent-dim); border-color: var(--accent); }
.btn.primary { background: var(--accent); color: var(--bg); border-color: var(--accent); }
.btn.primary:hover { background: #00cc6a; }
.btn.danger { color: var(--danger); }
.btn.danger:hover { background: rgba(255,85,85,0.1); border-color: var(--danger); }
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
.toast {
  position: fixed;
  bottom: 24px;
  right: 24px;
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
}
.toast.show { opacity: 1; transform: translateY(0); }
```

## 4. Common JS Utilities (paste into every template)

```js
// Toast notification
function toast(msg, kind = 'ok') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.style.borderColor = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.style.color = kind === 'err' ? 'var(--danger)' : 'var(--accent)';
  t.classList.add('show');
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(() => t.classList.remove('show'), 2400);
}

// Copy text to clipboard
async function copyText(text, label = 'クリップボードにコピーしました') {
  try {
    await navigator.clipboard.writeText(text);
    toast(label);
  } catch (err) {
    toast('コピー失敗: ' + err.message, 'err');
  }
}

// Copy canvas as PNG to clipboard (image/png)
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
```

## 5. HTML Shell（共通ヘッダー・フッター）

各テンプレの先頭/末尾は次の構造を持つ:

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
<!-- mode 固有の CDN をここに -->
<style>
/* 共通 CSS Snippet を貼る */
/* + モード固有 CSS */
</style>
</head>
<body>

<div class="header">
  <h1><span>HTML //</span> {{TITLE}}</h1>
  <div class="meta">GEN {{DATE}}<br>MODE {{MODE}}</div>
</div>

<!-- モード固有のコンテンツ -->

<div class="footer">
  <span>HTML SKILL v0.1.0</span>
  <span>GENERATED BY CLAUDE CODE // html skill</span>
</div>

<div class="toast" id="toast"></div>

<script>
/* 共通 JS Utilities を貼る */
/* + モード固有 JS */
</script>
</body>
</html>
```

## 6. アクセシビリティ・操作性ガイド

- すべてのインタラクティブ要素は `tabindex` で キーボード操作可能に
- `aria-label` をボタンに付与（とくにアイコンのみのボタン）
- 配色コントラスト: `--text` (#e0e0e0) / `--bg` (#0a0a0a) で AAA 達成
- フォントサイズは最小 0.65rem まで（バッジ・ラベル限定）。本文は 0.85rem 以上
