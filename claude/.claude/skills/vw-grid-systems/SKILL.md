---
name: vw-grid-systems
description: 'Build editorial, magazine, report, or slide-style webpages on 10 grid systems (Müller-Brockmann, Vignelli, Bootstrap, Material Design, Tschichold, Classical Canons, Golden Ratio, Gerstner, plus Tight/Spacious). Interactive presets: H/L layout, J/K color, N/P font (11 Japanese/Latin), A/D kerning, W/S spacing, F typo overlay, Enter slide/scroll, G grid, E export. CSS-variable --gc-* enables switching between column counts (5/6/10/12/60). Triggers: grid system, editorial layout, Swiss design, magazine spread, slide deck, bootstrap grid, material design grid, golden ratio, book layout, Vignelli, Gerstner, Tschichold. NOT for non-layout tasks.'
---

<\!--
  Ported to Claude Code SKILL format (faithful conversion only) from the
  HyperAgent skill "Muller-Brockmann Grid Systems" by alexmcdonnell-airtable
    https://github.com/alexmcdonnell-airtable/hyperagent-public-skills
  All design / code / methodology credit belongs to the original author and to
  the corpus: Josef Muller-Brockmann, *Grid Systems in Graphic Design* (1981).
  This file is a format port; grid theory, rules, and defaults are unchanged.
-->

# Müller-Brockmann Grid Systems — built real, visible, and verified

Josef Müller-Brockmann (1914–1996), Zurich; *Grid Systems in Graphic Design* (1981) is the corpus. The grid is treated as an ethic, not decoration: **"The grid system is an aid, not a guarantee. It permits a number of possible uses and each designer can look for a solution appropriate to his personal style. But one must learn how to use the grid; it is an art that requires practice."** This skill encodes that discipline AND — the part most attempts get wrong — the front-end engineering to make the grid genuinely load-bearing on the web, plus a harness that PROVES it.

> Four real review notes this skill exists to prevent:
> 1. *"the grid is just slapped on top and misaligned"* → the overlay wasn't in the same content box as the content (see §2.2).
> 2. *"the H in the headline is off the grid"* → the headline's BOX was on the grid but its INK wasn't; large glyphs carry a side-bearing (see §2.6). **Box-on-grid ≠ ink-on-grid.**
> 3. *"the pipeline cards ignore the grid entirely"* → overflow containers used flex with arbitrary widths; children must be column-width multiples (see §2.7). **Scrolling ≠ exemption from the grid.**
> 4. *"the heading row is 40px and everything below is off-grid"* → type scale transition without baseline re-entry padding (see §2.8). **Non-`--lh` line-heights silently break vertical rhythm downstream.**

---

## PART 1 — THE DISCIPLINE (decide before drawing)
- **Objective order.** The grid brings "constructive thought," legibility, and "objective and functional" design. Restraint is the point; the system, not the ego, organizes the page.
- **Modular grid.** Divide the type area into a field of **modules** — columns AND rows — separated by consistent **gutters**, inside defined **margins**. Text and images occupy whole modules. Müller-Brockmann specimens common field counts (8 / 20 / 32 fields). For the web, a **12-column grid + 8px baseline** is a robust general default; a **6×6 or 4×8 modular field grid** when you want visible rows too.
- **Baseline grid.** Vertical rhythm is sacred: **leading = a whole multiple of the baseline unit**, and every element snaps to it. This is what makes facing columns and images line up across the page.
- **Typography.** A **grotesque sans** (Akzidenz-Grotesk / Helvetica; on the web Inter, Helvetica Now, Archivo). **Flush-left, ragged-right.** Few sizes, large jumps in **scale** for hierarchy; objective, not expressive. Big **numerals/data set large** is a signature move.
- **Palette.** Pure white paper, near-black ink, **one accent — red is canonical**. Avoid the warm-cream "Claude look"; **never blue/purple gradients** (hard house rule).
- **White space + asymmetry.** Generous margins; asymmetric compositions held in tension by the grid.

---

## PART 2 — MAKE THE GRID REAL ON THE WEB (the load-bearing engineering)
`scripts/grid_tokens.py` emits this whole scaffold correctly; the rules below are why it's built the way it is.

### 2.1 One source of truth
Put every grid parameter in `:root` CSS variables — `--cols, --gutter, --margin, --bl (baseline), --lh (leading=3×bl), --maxw`. **Content and the overlay both read these same variables.** Never hand-author the overlay separately or it will drift.

### 2.2 The overlay MUST live in the SAME content box as the content  ← #1 bug
Failure mode: content sits in a centered `max-width` container while the overlay is a **full-width sibling** of the section. On any viewport wider than `--maxw`, the centered content and the full-width overlay no longer share column positions → "slapped on top / misaligned."
**Fix:** put `.guides` *inside* the same `.wrap`, and draw the column guides with `left/right = var(--margin)` and the **same** `repeat(var(--cols),1fr)` + `column-gap:var(--gutter)`. Then the overlay columns **are** the content columns at every width. Add left/right margin lines at `var(--margin)`.

### 2.3 Place every element by column LINE via subgrid bands
Don't eyeball spans. Each horizontal **band** spans all columns and re-exposes them:
```css
.band{grid-column:1 / -1; display:grid; grid-template-columns:subgrid; column-gap:var(--gutter); align-items:start;}
@supports not (grid-template-columns:subgrid){ .band{grid-template-columns:repeat(var(--cols),1fr);} }
```
Children place with `grid-column: <startline> / <endline>` (e.g. `1 / 6`, `6 / 13`). Every headline, paragraph, photo, caption now snaps to identical lines.

### 2.4 Lock vertical rhythm to the baseline
- Leading = `--lh` (e.g. 24px = 3×8). **Every line-height a multiple of the baseline, in px (not unitless) for display type** — unitless line-heights on large type push the box off the grid.
- Every margin/padding a multiple of the baseline. Spread top/bottom padding a multiple too, so content starts on a line.
- **Media heights = multiples of the leading** (e.g. 240/360/432/480px) so a photo's top AND bottom both land on lines.
- Hairline rules sit inside a baseline-height band, not free-floating.

### 2.5 The toggle (keyboard only)
The **`G` key** toggles `body.grid-on`; overlay fades 0→1. **No visible button** — the toggle is keyboard-only to keep the viewport clean. Overlay draws: translucent **numbered column fields**, the **baseline** (major line every `--lh`, faint minor every `--bl`), and **margin lines**. Showing the real grid the page is built on IS the demo.

### 2.6 OPTICAL ALIGNMENT — display ink, not its box  ← the subtle bug
A 180px headline whose layout box is exactly on line 1 still looks misaligned against body text, because the letterform's **ink** is inset by its **left side-bearing**. Cure at runtime:
```js
// after document.fonts.ready and on resize:
var cvs=document.createElement('canvas'),ctx=cvs.getContext('2d');
document.querySelectorAll('.masthead,.numeral,.shead h2,.h2b').forEach(function(el){
  el.style.marginLeft='0px';
  var cs=getComputedStyle(el),ch=(el.textContent||'').trim()[0]; if(!ch) return;
  if(cs.textTransform==='uppercase') ch=ch.toUpperCase();
  ctx.font=cs.fontStyle+' '+cs.fontWeight+' '+cs.fontSize+' '+cs.fontFamily; ctx.textAlign='left';
  var abl=ctx.measureText(ch).actualBoundingBoxLeft;     // +ve = ink overhangs left of box
  if(isFinite(abl)) el.style.marginLeft=abl.toFixed(2)+'px'; // shift box so INK lands on the line
});
```
Apply to the masthead, big numerals, and section headlines. It scales with fluid type (re-runs on resize) and uses the **actually-loaded** font, so it's correct in the user's browser.
**CRITICAL measurement caveat:** side-bearing is **font-specific**. If you measure with the wrong font you get the wrong nudge. Headless/sandbox Chrome usually lacks the webfont, so canvas falls back to a different grotesque (measured **−16px on the fallback vs −7px on real Inter** for the same `H`). To verify optics offline you must **embed the real webfont** via `@font-face` (local TTF). In production the runtime JS measures the loaded font and is correct.

### 2.7 OVERFLOW CONTAINERS ON THE GRID  ← #3 bug
Failure mode: a horizontal-scroll component (pipeline, card rail, carousel) uses `display: flex` with arbitrary `flex-basis` — its children ignore the column grid entirely. Toggle the overlay on and nothing lines up.

**Fix:** size overflow children to **column-width multiples**. Replace flex with CSS Grid `grid-auto-flow: column`, and derive item widths from the grid variables:
```css
.pipe {
  --span: 2; /* each child spans N column-widths */
  grid-column: 1 / -1;
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: calc(var(--span) * (100% + var(--gutter)) / var(--cols) - var(--gutter));
  column-gap: var(--gutter);
  overflow-x: auto;
  scroll-snap-type: x mandatory;
}
.pipe > * { scroll-snap-align: start; }
```

**Formula:** `item-width = span × (container-width + gutter) / cols − gutter`. At 12 cols / 24px gutter / 1168px content: span=1 → 75.3px (one column), span=2 → 174.7px, span=3 → 274px. Verified by the identity: `N × col-width + (N−1) × gutter`.

**Choosing `--span`:** count items and columns. 8 items in 12 cols → `--span: 2` shows 5–6 at once, scrolls for the rest. If items fit without scroll (e.g. 4 items × 3 span = 12 cols), use a subgrid `.band` instead — no scroll needed.

**Internal micro-rhythm:** children of overflow items may use the **minor baseline** (`--bl` = 8px) for internal vertical spacing — cramped cards often can't afford the full `--lh` leading. But the outer card box must still snap to `--lh` boundaries to preserve page-level rhythm. Round up with `padding-bottom`:
```css
.step {
  /* internal text at --bl rhythm (8px), card height rounded to --lh (24px) */
  padding: 24px 12px;  /* top/bottom = --lh multiples */
  min-height: calc(var(--lh) * 8); /* = 192px = 8 major baselines */
}
```

**Why scroll-snap:** snapping to grid-column increments on drag/swipe makes the grid *felt*, not just seen. The invisible structure becomes tangible.

### 2.8 TYPE SCALE TRANSITIONS — BASELINE RE-ENTRY  ← #4 bug
Failure mode: a section header row contains a kicker at `line-height: 24px` and a heading at `line-height: 40px`. The row is 40px tall; the next element starts at +40px — **off the major baseline** (40 is not a multiple of 24). Everything below drifts 16px from the grid.

**Rule:** when `line-height` changes between adjacent block-level elements, insert **re-entry padding** so the next element's top lands on a `--lh` boundary.

```
re-entry = --lh − (row-height mod --lh)       [if mod ≠ 0]
         = 24 − (40 mod 24) = 24 − 16 = 8px
```

Apply as `padding-bottom` (or `margin-bottom`) on the type-transitioning row. Total: 40 + 8 = 48px = 2 × `--lh` ✓.

**Design-time audit:** for every `line-height` value in the type scale, compute mod `--lh`:

| line-height | mod 24 | re-entry | total box |
|:-----------:|:------:|:--------:|:---------:|
| 24px        | 0      | —        | 24px      |
| 32px        | 8      | **16px** | 48px      |
| 40px        | 16     | **8px**  | 48px      |
| 48px        | 0      | —        | 48px      |
| 80px        | 8      | **16px** | 96px      |

Only `--lh`-multiple line-heights (24, 48, 72, 96…) are self-aligning. All others **silently break** vertical rhythm downstream and need explicit re-entry padding.

**Preferred approach — design line-heights to be `--lh` multiples from the start:**
```css
/* ✓ self-aligning type scale (all multiples of 24px) */
.body   { line-height: 24px; }   /* 1 × --lh */
.lead   { line-height: 48px; }   /* 2 × --lh — not 32px */
.shead h2 { line-height: 48px; } /* 2 × --lh — not 40px */
.masthead { line-height: 72px; } /* 3 × --lh — not 80px */
```
This eliminates re-entry math entirely. Larger leading may look more generous than a tightly-set heading, but that **is** the Müller-Brockmann aesthetic — white space is a feature.

**When non-`--lh` line-heights are unavoidable** (e.g. tightly-set numerals), apply re-entry on the **parent container**, not the child:
```css
.shead {
  display: flex;
  align-items: baseline;
  gap: 16px;
  /* child h2 has line-height: 40px → 40 mod 24 = 16 → re-entry = 8px */
  padding-bottom: 8px; /* row total = 48px = 2 × --lh ✓ */
}
```

**Mixed type on one line** (kicker + heading in flex row): use `align-items: baseline` so text baselines share a line. The row height equals the tallest child's `line-height`. Apply re-entry to the **flex parent**, never individual children.

---

## PART 3 — VERIFY (don't trust, measure)  → `scripts/verify_grid.js`
Render with headless Chrome (Puppeteer) and assert, at **several widths including > and < `--maxw`** (to catch centered-container drift, e.g. 1440 / 1180 / 900):
1. **Column adherence** — every placed `.band > *` left snaps to a column START and right to a column END (~0px). **Exclude the optically-aligned display elements** from this box check (their box is intentionally side-bearing-offset; they're validated in step 4). **Gotcha:** build BOTH the column-start set and the column-end set — a grid item spanning "to line N" ends at the *far* side of the gutter, so single-edge math falsely reports a one-gutter error.
2. **Overlay match** — each `.guides .col` rect equals the computed column rect (~0px).
3. **Baseline** — text tops modulo the baseline ≈ 0 (tolerance ≈ half a baseline; the box-top is a proxy — the leading does the real work).
4. **Optical ink** — each display element's ink-left (box − `actualBoundingBoxLeft`, real font) equals **its own** column line (nearest column-start to its box), not always line 1.
5. **Overflow column snap** — each child of an overflow container (`.pipe > *`, `.rail > *`) has `offsetWidth` within 1px of `span × (containerWidth + gutter) / cols − gutter`. Catches flex-basis-only items that ignore the grid.
6. **Baseline re-entry** — for every element pair where the first has `line-height mod --lh ≠ 0`, the first element's total outer box (including margin/padding) is a `--lh` multiple (tolerance ≤ 1px). Checked via: `(el.offsetTop + el.offsetHeight + parseFloat(marginBottom)) % lh ≈ 0`. Catches downstream baseline drift from type scale transitions.

Sandbox Chrome flags that work: `--headless=new --no-sandbox --disable-gpu --disable-dbus --use-gl=angle --use-angle=swiftshader`. `file://` works for non-ES-module pages; the CLI `--screenshot` can hang on tall pages — drive via Puppeteer and screenshot per viewport. Read PNGs back with the image-capable Read tool to eyeball a **zoom crop of the top-left corner** (masthead vs body vs column line) — the fastest human check.

A clean run looks like: `col=0px overlay=0px baseline≤4px ink=0px overflow≤1px reentry≤1px` → `GRID VERIFY: PASS`.

---

## PART 4 — CRAFT DEFAULTS (so it looks excellent, not just aligned)
- **Palette:** white `#fff`, ink `#111`, one accent (Swiss red `#e4002b`). No warm-cream Claude look; no blue/purple gradients.
- **Type:** a real grotesque webfont (Inter / Helvetica Now / Archivo) for display + body; a **mono** (Space Mono / IBM Plex Mono) for folios, captions, grid annotations — reinforces the technical register. Non-Latin via Noto Sans JP etc.
- **Hierarchy** through scale + weight + white space, not color. Treat key data as **large numerals**. Kicker labels in mono caps. Per-spread folios.
- **Real photography.** Ground real subjects in real photos (`SearchImages`). **Host each image via `PublishFilePublicly` and embed the `pub.hyperagent.com` URL** — a `PublishWebpage` artifact runs in a sandboxed iframe that can't authenticate thread-scoped `/api/files/...` URLs (broken-image trap).
- **Type fidelity if you ever rasterize art** (cairosvg / headless screenshots / image-gen reference): a `Helvetica`/`Arial` CSS stack silently falls back to **Noto Sans** (reads like Calibri). Render in **Liberation Sans** or an embedded Helvetica/Arimo TTF before trusting it. (Same trap as the optical-measurement caveat: wrong font in → wrong result out.)
- **Spread model:** full-width sections, each its own per-spread `.grid` + `.guides`, consistent margins/folios.

---

## PART 5 — INTERACTIVE PRESETS (the design tool layer)

Every generated page MUST include the interactive preset layer from `demo/interactive.html`. This turns the page into a live design tool: the user picks layout, color, font, and exports a clean static HTML.

### 5.1 Keybindings

| Key | Action |
|-----|--------|
| `G` | Toggle grid overlay |
| `H` / `L` | Cycle layout preset (prev / next) |
| `J` / `K` | Cycle color preset (next / prev) |
| `N` / `P` | Cycle font preset (next / prev) |
| `E` | Export static HTML (strips all JS, HUD, overlay) |
| `Escape` | Close HSB picker |

### 5.2 Layout presets (--cols + --gc-* CSS variables)

Content placement uses **semantic CSS variables** instead of hardcoded `grid-column` values. This enables switching between incompatible column counts without changing HTML.

**Placement variables** (defined in `:root`, overridden per layout):
```
--gc-hero      hero title span
--gc-sub       subtitle span
--gc-half-l    left half (folios, section heads)
--gc-meta-r    right meta (folios, captions)
--gc-col-l     left text column
--gc-col-r     right text column
--gc-q1–q4     quarter stats (4 blocks)
--gc-quote     blockquote span
--gc-gal-l     gallery left
--gc-gal-gap   gallery gutter
--gc-gal-r     gallery right
```

**Usage in HTML** — NEVER hardcode `grid-column` values; always use variables:
```html
<!-- ✓ correct -->
<h1 class="masthead" style="grid-column:var(--gc-hero);">

<!-- ✗ wrong — breaks on non-12-column grids -->
<h1 class="masthead" style="grid-column:1/10;">
```

**Exception:** `grid-column:1/-1` (full width) is safe for all column counts.

**Compatible layouts** (cols=12, only --gutter/--margin/--maxw/--pad differ):
- Müller-Brockmann, Vignelli Canon, Bootstrap, Material Design, Tight, Spacious

**Incompatible layouts** (cols ≠ 12, override --gc-* variables):
- Tschichold (10 cols, 3:7 asymmetric)
- Classical Canons (6 cols, book page ratio)
- Golden Ratio (5 cols, φ division)
- Gerstner Programme (60 cols, micro-grid)

When switching layout, `LAYOUT_BASE` resets all --gc-* to 12-column defaults, then the preset's `vars` override. Overlay columns rebuild automatically.

### 5.3 Color presets

Swiss (default), Dark, Warm, Cool, Mono, Tokyo Night, Tokyo Storm, Tokyo Day, Ayu Dark, Ayu Mirage, Ayu Light, Catppuccin Mocha, Catppuccin Macchiato, Catppuccin Latte, Dracula, Nepp, **Custom** (HSB picker).

Custom opens a canvas-based HSB color circle (hue ring + SV square) positioned above the HUD. Accent color updates `--accent`, `--g-col`, `--g-edge` in real-time.

### 5.4 Font presets

Ordered by category. All loaded via a single Google Fonts `<link>`:
1. **Inter** (Grotesque — default)
2. **Dela Gothic One** (Display)
3. **Sawarabi Mincho** (Serif)
4. **Shippori Mincho** (Serif)
5. **Zen Old Mincho** (Serif)
6. **Noto Serif JP** (Serif)
7. **Zen Maru Gothic** (Rounded)
8. **M PLUS Rounded 1c** (Rounded)
9. **M PLUS 1p** (Sans)
10. **Sawarabi Gothic** (Sans)
11. **Noto Sans JP** (Sans)

Body font is controlled by `--font-body` CSS variable. Mono font (`--font-mono: "Space Mono"`) is fixed for folios, captions, and the HUD.

### 5.5 Static export (`E` key)

Generates a self-contained HTML file with:
- Resolved `:root` values (current preset selections baked in)
- Only the selected font's Google Fonts `<link>` (not all 11)
- All interactive elements removed: `.hud`, `.picker`, `.guides`, `<script>`
- CSS between `/* ==REMOVABLE-START== */` and `/* ==REMOVABLE-END== */` stripped

### 5.6 HUD

Fixed bottom bar (`position:fixed; bottom:0`). Shows current layout/color/font names and keyboard shortcuts. Always dark background (`rgba(17,19,21,.92)`) independent of color theme. Account for it with `body { padding-bottom: 40px; }` inside the `==REMOVABLE==` block.

### 5.7 How to include

When generating a page with this skill:
1. Copy the **full `<style>` block** from `demo/interactive.html` (`:root` through `==REMOVABLE-END==`)
2. Copy the **HUD + picker HTML** (between `</head>` and the first `<section>`) — there is no toggle button; the grid overlay is `G`-key only
3. Copy the **full `<script>` block** (core JS + interactive JS + HSB picker)
4. Place content spreads between the picker and the script
5. Use `var(--gc-*)` for ALL `grid-column` placements (except `1/-1`)

### 5.8 Slide mode (re-layout, not scale)

`Enter` toggles slide mode. Each spread becomes a full-viewport slide. **The layout is CSS-reflowed, not `transform:scale`-d** — content reflows to the actual viewport width via flexbox + `margin:auto`, so grid columns match the real viewport and nothing is cut off.

```css
body.slide-mode .spread{position:fixed;top:0;left:0;width:100vw;height:calc(100vh - 40px);
  display:none;overflow-y:auto;}
body.slide-mode .spread.active{display:flex;}
body.slide-mode .wrap{margin:auto;flex-shrink:0;width:100%;}
```

- **Short slides** (content fits in viewport): vertically centered via `margin:auto`
- **Tall slides** (content exceeds viewport): top-aligned, scrollable via `overflow-y:auto`
- **No `transform:scale`** — CSS Grid reflows naturally; grids and fonts stay sharp at native resolution

### 5.9 Content rules for generated pages

**NEVER generate self-referential meta-text about the grid system.** Footers, captions, and body text must contain **subject-relevant content only**. Examples of prohibited text:
- "Designed on a Müller-Brockmann modular grid"
- "12-column, 8px baseline, 24px leading"
- "Press G to toggle grid overlay"
- "Built with CSS Grid and subgrid"

The footer spread should be minimal: a `footer-rule` + folio with the page number, optionally with a content-relevant source attribution. The HUD already shows grid metadata; duplicating it in the page body is noise.

---

## PART 6 — WORKFLOW
1. Pick the subject; gather real photos; host them publicly.
2. Generate the scaffold: `python3 scripts/grid_tokens.py` (or `--scaffold` for a full page; `--cols/--baseline/--gutter/--margin/--maxw/--accent` to taste; it warns if gutter/margin aren't baseline multiples).
3. Build spreads as **subgrid bands**; place everything by **column line** using `var(--gc-*)` variables; lock spacing/line-heights/media heights to the **baseline**.
4. **Include the interactive layer** from `demo/interactive.html` — presets, HUD, HSB picker, export, and keybindings (see §5.7).
5. Add the overlay (same content box) + optical-alignment JS (already in the scaffold; point its selector list at your display elements).
6. Open in browser for the user to preview. They cycle presets with keyboard, then press `E` to export.
7. Optionally **verify** the exported static HTML: `CHROME=… PUP=… node scripts/verify_grid.js <file-or-url> --widths=1440,1180,900`.

## SCRIPTS
- **`scripts/grid_tokens.py`** — deterministic scaffold generator. Emits the `:root` tokens, `.grid`/`.band` (subgrid) scaffold, `.guides` overlay CSS, toggle JS, and the optical-alignment JS — all wired to one source of truth. `--scaffold` emits a full minimal HTML page. No network/credentials.
- **`scripts/verify_grid.js`** — Puppeteer harness implementing all four checks above with the corrected both-edges column math, the optical-exclusion, per-element column-line ink targeting, and PASS/FAIL output at multiple widths. Env: `CHROME` (chrome binary), `PUP` (puppeteer-core module path).
- **`demo/interactive.html`** — canonical reference implementation of the interactive preset layer. All presets, keybindings, HUD, HSB picker, and export logic live here. Copy the relevant blocks when generating new pages.

---

## PART 7 — CONTENT ARCHETYPES & DESIGN PRINCIPLES

Grids are structure; these are **what you put on them**. Three complementary frameworks govern content decisions:

### 7.1 Assertion-Evidence spreads (slide-oriented content)

Source: Michael Alley, *The Craft of Scientific Presentations* (2002).

Every content spread follows the **Assertion-Evidence** pattern: a **complete-sentence headline** (the assertion) supported by **visual evidence** (image, chart, data, diagram) — never bullet points.

| Element | Grid placement | Rule |
|---------|---------------|------|
| Assertion (headline) | `var(--gc-hero)` | A full sentence that states the claim. NOT a topic label ("Sales Results") but a finding ("Q3 sales grew 140% after the pricing change"). |
| Evidence (visual) | `1/-1` (full width) or `var(--gc-col-r)` | Image, chart, diagram, or large numeral that **proves** the assertion. The audience should be able to verify the headline by looking at the evidence. |
| Source/caption | `var(--gc-meta-r)` | Data source, methodology note, or figure label. Mono font. |

**Spread structure:**
```html
<div class="band mt2">
  <h1 class="masthead" style="grid-column:var(--gc-hero);">
    Complete sentence stating the key finding
  </h1>
</div>
<div class="band mt1">
  <p class="subtitle" style="grid-column:var(--gc-sub);">
    One-line supporting context
  </p>
</div>
<div class="band mt2">
  <div style="grid-column:1/-1;height:var(--img-hero);">
    <!-- visual evidence: chart, photo, diagram -->
  </div>
</div>
```

**Logical ordering** — use SCQA (Situation → Complication → Question → Answer) to sequence multi-spread decks:

| Spread | SCQA role | Content |
|--------|-----------|---------|
| 1 (Hero) | **Situation** | Establish shared context |
| 2–3 | **Complication** | What changed, what broke, what's at stake |
| 4 (Stats) | **Question** implied | Key numbers that frame the problem |
| 5–N | **Answer** | Assertion-Evidence spreads, one claim per slide |
| Final | Synthesis | Summary assertion + next action |

### 7.2 Eye-flow placement patterns

Source: Gutenberg (1969), Nielsen/NN/g F-Pattern (2006).

Where you place elements on the grid matters as much as *which* grid lines they snap to. Four reading-gravity patterns determine where attention lands:

**Gutenberg Diagram** (default for balanced layouts):
```
┌─────────────────────────┐
│ ● Primary optical area  │  → Place: masthead, key assertion
│   (top-left)            │
│                         │
│          ╲              │  → Reading gravity flows ╲
│            ╲            │
│              ╲          │
│   (bottom-left)  ● Terminal area │  → Place: CTA, summary, folio
│                  (bottom-right)  │
└─────────────────────────┘
```

| Pattern | Best for | Grid mapping |
|---------|----------|-------------|
| **Gutenberg** | Text-heavy editorial, balanced spreads | Masthead at `--gc-hero` (top-left), CTA/summary at `--gc-meta-r` (bottom-right) |
| **F-Pattern** | Long-form body text, two-column articles | Headlines at `--gc-col-l` line 1, body text scanned left-to-right then drops |
| **Z-Pattern** | Hero + CTA pages, landing pages | Top bar → diagonal → bottom bar. Hero at `1/-1`, stats at `--gc-q1..q4`, CTA at bottom `1/-1` |
| **Layer-Cake** | Data-heavy, dashboard-style | Alternating full-width heading bands + content bands. Each `.band` is a scannable layer |

**Placement rules:**
- **Primary information** (headlines, key numerals) → top-left quadrant (`--gc-hero`, `--gc-half-l`)
- **Secondary information** (body text, details) → center and right columns (`--gc-col-l`, `--gc-col-r`)
- **Terminal action** (CTA, source, folio) → bottom-right (`--gc-meta-r`)
- **Never** place critical content in the **weak fallow areas** (top-right, bottom-left in Gutenberg) without a strong visual anchor

### 7.3 CRAP design checklist (generation-time)

Source: Robin Williams, *The Non-Designer's Design Book* (1994).

Apply these four principles **during generation** to prevent design violations before they happen:

**C — Contrast:** elements that are different must be **obviously** different.
- Font size ratio between heading and body ≥ 3:1 (e.g. `--fs-hero:96px` vs body `16px` = 6:1 ✓)
- Weight jump ≥ 2 steps (e.g. body 400 → heading 800)
- Accent color used for ≤ 2 element types (rule + numeral). More dilutes contrast
- `--ink` vs `--paper` contrast ratio ≥ 7:1 for body text (WCAG AAA)

**R — Repetition:** consistent patterns across every spread.
- Every spread has the same folio structure (`.folio` left + page number right)
- Same rule style (`.rule` or `.rule-accent`) at the same grid position per spread
- Spacing tokens repeat: only `mt1/mt2/mt3` (24/48/72px), never arbitrary values
- One mono font for all metadata (folios, captions, stat-labels, HUD)

**A — Alignment:** every element must be aligned to **something visible**.
- All elements placed by `grid-column:var(--gc-*)` — never `margin-left:20px`
- Display type optically aligned (§2.6) so ink sits on the column line
- No "centered in a sea of white space" without a grid-line anchor
- Verify with `G` toggle: if an element doesn't touch a column edge, it's misaligned

**P — Proximity:** related items close, unrelated items far.
- Related elements within 1× `--lh` (24px) of each other
- Unrelated groups separated by ≥ 2× `--lh` (48px, class `mt2`)
- Section breaks ≥ 3× `--lh` (72px, class `mt3`)
- Caption directly below its image with `mt1` (24px), never floating free

## CREED
A grid you can't toggle on and measure is a mood board, not a system. Build it from one source of truth, prove it at 0px, align the **ink**, snap every overflow child to column-width multiples, and re-enter the baseline after every type scale transition.
