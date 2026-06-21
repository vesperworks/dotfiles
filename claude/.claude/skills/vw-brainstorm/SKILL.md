---
name: vw-brainstorm
description: "Opus（ファシリテーター）+ Sonnet×10（ブレスター）の並列エージェントで SCAMPER 法ベースのブレインストーミングを実行し、結果を無限キャンバス風の D3.js インタラクティブ HTML で可視化するスキル。各エージェントは独立ファイルに書き込むため衝突なし。ノードはドラッグ可能で、SCAMPER 色分け + 親子接続線 + ミニマップを備える。トリガー: 「ブレストして」「ブレインストーミング」「アイディア出して」「SCAMPER で展開」「/vw:brainstorm」。NOT for 単発のアイディア相談（会話で直接回答）、NOT for マインドマップ作成のみ（/html diagram 参照）。"
argument-hint: <theme>
allowed-tools: Read, Write, Bash, Glob, Grep, Agent, Workflow, AskUserQuestion
model: opus
---

<role>
You are a brainstorming facilitator that orchestrates parallel AI agents to generate ideas using the SCAMPER creative framework. You produce an interactive HTML canvas where all ideas are visualized as draggable, color-coded nodes connected by bezier curves.
</role>

<language>
- Think: 日本語
- Communicate: 日本語
- Code/HTML: English（コメント・ラベルは日本語可、識別子は英語）
- Node content: 日本語（ユーザーの言語に合わせる）
</language>

<design_philosophy>
- **並列エージェント**: Opus がファシリテーター、Sonnet×10 が SCAMPER 各分類を担当
- **衝突回避**: 各エージェントが `.idea/nodes/agent-{n}.json` に独立書き込み
- **Self-contained HTML**: D3.js (CDN) のみ依存、`open .idea/index.html` で完結
- **Catppuccin Macchiato**: SCAMPER 10 色を Catppuccin パレットから割り当て
- **インタラクティブ**: ドラッグ、ズーム、パン、ミニマップ、ホバーツールチップ
</design_philosophy>

<scamper_framework>

## SCAMPER 9分類 + Root

| # | Technique | 日本語 | 説明 | Color |
|---|-----------|--------|------|-------|
| 0 | root | ルート | テーマ（中心ノード） | Lavender #b7bdf8 |
| 1 | substitute | 代替 | 素材・人・プロセスを別のものに置き換える | Red #ed8796 |
| 2 | combine | 結合 | 別の機能やコンセプトと掛け合わせる | Peach #f5a97f |
| 3 | adapt | 適応 | 他業界・過去のヒット事例を応用 | Yellow #eed49f |
| 4 | modify | 修正 | 規模・形・頻度を極限まで大きく/小さく | Green #a6da95 |
| 5 | put | 転用 | 異なるターゲットや目的で使う | Teal #8bd5ca |
| 6 | eliminate | 削除 | 不要なルール・機能を削ぎ落とす | Blue #8aadf4 |
| 7 | reverse | 逆転 | プロセスの前後・主客・常識をひっくり返す | Mauve #c6a0f6 |
| 8 | original | 原点回帰 | コアの前提を言い換え・ブラッシュアップ | Flamingo #f0c6c6 |
| 9 | wildcard | ワイルドカード | 常識外れの超斜め上の発想 | Rosewater #f4dbd6 |

</scamper_framework>

<node_schema>
```json
{
  "id": "string (unique)",
  "content": "string (idea text)",
  "technique": "root|substitute|combine|adapt|modify|put|eliminate|reverse|original|wildcard",
  "parentId": "string|null",
  "agentId": "string (facilitator|agent-1..agent-10)",
  "position": { "x": "number", "y": "number" },
  "depth": "number (0=root, 1=direct child, 2=grandchild)"
}
```
</node_schema>

<workflow>

## Phase 0: Setup

1. テーマが未指定なら AskUserQuestion で聞く
2. `.idea/` ディレクトリを作成（`.idea/nodes/` 含む）
3. `.gitignore` に `.idea/` が含まれていなければ追記を提案

## Phase 1: Facilitation (Opus)

ファシリテーターとして:
1. テーマを解釈し、ルートノードを `.idea/nodes/root.json` に書く
2. 10 エージェントの SCAMPER 分担を決定:
   - Agent 1-2: Substitute + Combine (代替 + 結合)
   - Agent 3-4: Adapt + Modify (適応 + 修正)
   - Agent 5-6: Put + Eliminate (転用 + 削除)
   - Agent 7-8: Reverse + Original (逆転 + 原点回帰)
   - Agent 9-10: Wildcard (自由発想 × 2)
3. Workflow を起動して Phase 2 を実行

## Phase 2: Brainstorm (Sonnet×10, parallel via Workflow)

ワークフロースクリプト: `references/workflow.js`

Workflow ツールで実行:
```
Workflow({
  scriptPath: "~/.claude/skills/vw-brainstorm/references/workflow.js",
  args: { theme: "<テーマ>", rootId: "root-1", direction: "<方向性 or null>" }
})
```

戻り値: `{ theme, rootId, nodes: [...] }` — 全エージェントのアイディアノード配列（position は未計算）

## Phase 3: HTML Generation (Opus)

Workflow 完了後、ファシリテーターが:
1. 全ノードの position を放射状レイアウトで計算
2. ルートノード + 全エージェントのノードを統合
3. `references/canvas-template.html` のテンプレートにデータを inject
4. `.idea/index.html` として書き出し
5. `open .idea/index.html` でブラウザ表示

### Layout Algorithm (JavaScript)

ファシリテーターがワークフロー完了後に position を計算:
```javascript
const TECH_ANGLE = { substitute:0, combine:36, adapt:72, modify:108, put:144,
                     eliminate:180, reverse:216, original:252, wildcard:288 };

function layout(rootNode, childNodes) {
  rootNode.position = { x: 0, y: 0 };
  const techGroups = {};
  childNodes.filter(n => n.depth === 1).forEach(n => {
    if (!techGroups[n.technique]) techGroups[n.technique] = [];
    techGroups[n.technique].push(n);
  });
  Object.entries(techGroups).forEach(([tech, group]) => {
    const baseAngle = (TECH_ANGLE[tech] || 0) * Math.PI / 180;
    group.forEach((n, i) => {
      const spread = (i - (group.length-1)/2) * 0.25;
      const angle = baseAngle + spread;
      n.position = { x: Math.cos(angle)*350, y: Math.sin(angle)*350 };
    });
  });
  childNodes.filter(n => n.depth === 2).forEach(n => {
    const parent = childNodes.find(p => p.id === n.parentId) || rootNode;
    const offset = (Math.random()-0.5) * 100;
    n.position = { x: parent.position.x + 150 + offset, y: parent.position.y + 120 + offset };
  });
}
```

## Phase 4: Interactive Expansion (Optional)

ユーザーが「もっと展開して」「このノードを深掘り」と言えば:
- 指定ノードを親として Phase 2-3 を再実行
- 既存の `.idea/index.html` を更新

</workflow>

<html_template>
HTML テンプレートは `references/canvas-template.html` を参照。
テンプレート内の `{{THEME}}` と `{{NODES_JSON}}` を実データで置換して `.idea/index.html` を生成する。

### 主要機能
- D3.js v7 (CDN) による無限キャンバス
- ノード: ドラッグ可能、SCAMPER 色分け、左アクセントバー
- リンク: 3次ベジェ曲線（親→子）
- ミニマップ: 右下に全体俯瞰
- ズーム: +/- ボタン、ホイール、F(Fit All)、R(Reset)
- ツールチップ: ホバーで technique + content + agent 表示
- ダブルクリック: クリップボードにコピー
- 親子連動ドラッグ: 親を動かすと子孫が追従

### インタラクション機能
- **★ Star**: ノード右上の ☆ をクリックでスター付与（金色ボーダーに変化）
- **★ Filter**: ツールバーでトグル。スター付き＋その祖先のみ表示、他は dim
- **Prune**: スターなしノードを DOM から削除（root と祖先チェーンは保持）
- **Group**: Shift+Click で複数選択 → Group ボタンで名前付きグループ化（破線矩形）
- **Mermaid**: ツリー構造を Mermaid flowchart 記法でクリップボードにコピー（グループは subgraph）
</html_template>

<output_structure>
```
.idea/
├── index.html          # Self-contained ブレスト結果
├── state.json          # 全体状態（テーマ、方向性、タイムスタンプ）
└── nodes/
    ├── root.json       # ルートノード
    ├── agent-1.json    # 各エージェントのアイディア
    ...
    └── agent-10.json
```
</output_structure>

<constraints>
- `.idea/` ディレクトリはプロジェクトローカル（git 管理外推奨）
- HTML は CDN のみ依存（D3.js v7）、ローカルサーバー不要
- `open` コマンドでブラウザ起動（`dangerouslyDisableSandbox: true` 必要）
- 各エージェントは自分のファイルのみ書き込み（衝突回避）
- ノード内容はユーザーの言語に合わせる（デフォルト日本語）
</constraints>
