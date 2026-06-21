export const meta = {
  name: 'vw-brainstorm',
  description: 'SCAMPER brainstorming with 10 parallel Sonnet agents + live file save',
  phases: [
    { title: 'Brainstorm', detail: 'Generate ideas and save to files as each agent completes', model: 'sonnet' }
  ]
}

const IDEA_SCHEMA = {
  type: 'object',
  properties: {
    nodes: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          content: { type: 'string' },
          technique: { type: 'string', enum: ['substitute','combine','adapt','modify','put','eliminate','reverse','original','wildcard'] },
          parentId: { type: 'string' },
          depth: { type: 'number' }
        },
        required: ['id', 'content', 'technique', 'parentId', 'depth']
      }
    }
  },
  required: ['nodes']
}

const parsed = typeof args === 'string' ? JSON.parse(args) : (args || {})
const theme = parsed.theme || 'テーマ未設定'
const direction = parsed.direction || ''
const ideaDir = parsed.ideaDir || '.idea'
const round = parsed.round || 'r1'

// parentIds: starred nodes to branch from (re-brainstorm)
// If not provided, use rootId as single parent (initial brainstorm)
const parentIds = parsed.parentIds || [parsed.rootId || 'root-1']

log('round=' + round + ' parents=' + parentIds.join(',') + ' theme=' + theme)

phase('Brainstorm')

const SCAMPER_DEFS = `- substitute: 素材・人・プロセスを別のものに置き換える
- combine: 別の機能やコンセプト・他分野と掛け合わせる
- adapt: 他業界・過去のヒット事例の構造を応用する
- modify: 規模・形・頻度を極限まで大きく or 小さくする
- put: まったく異なるターゲットや目的で使ってみる
- eliminate: 不要なルール・中間業者・基本機能を削ぎ落とす
- reverse: プロセスの前後・主客・常識をひっくり返す
- original: コアの前提を言い換え・ブラッシュアップ
- wildcard: 常識外れの超斜め上の発想・コペルニクス的転回`

const ASSIGNMENTS = [
  { id: 1, techniques: ['substitute', 'combine'] },
  { id: 2, techniques: ['substitute', 'combine'] },
  { id: 3, techniques: ['adapt', 'modify'] },
  { id: 4, techniques: ['adapt', 'modify'] },
  { id: 5, techniques: ['put', 'eliminate'] },
  { id: 6, techniques: ['put', 'eliminate'] },
  { id: 7, techniques: ['reverse', 'original'] },
  { id: 8, techniques: ['reverse', 'original'] },
  { id: 9, techniques: ['wildcard'] },
  { id: 10, techniques: ['wildcard'] },
]

// Distribute agents across parent nodes
const parentList = parentIds.length ? parentIds : ['root-1']

const results = await pipeline(
  ASSIGNMENTS,
  a => {
    const parentId = parentList[(a.id - 1) % parentList.length]
    return agent(
      `あなたは SCAMPER ブレインストーミングの agent-${a.id} です。

テーマ: "${theme}"
${direction ? '方向性: ' + direction : ''}
親ノード ID: "${parentId}"

以下の SCAMPER テクニックでアイディアを 3〜5 個生成してください: ${a.techniques.join(', ')}

各テクニックの意味:
${SCAMPER_DEFS}

ルール:
- まず depth-1 ノードを 3〜4 個生成（parentId = "${parentId}"）
- 次に、各 depth-1 ノードに対して depth-2 の子ノードを 3 個ずつ生成（parentId = 親 depth-1 の id）
- content は日本語、35 文字以内で具体的に
- id format: "${round}-a${a.id}-{連番}"（depth-2 は "${round}-a${a.id}-{親番号}-{子番号}"）
- 創造的で、驚きがあり、具体的なアイディアを出すこと

JSON の "nodes" 配列で返してください。`,
      {
        label: `brainstorm:${round}-a${a.id}`,
        phase: 'Brainstorm',
        model: 'sonnet',
        schema: IDEA_SCHEMA,
        effort: 'medium'
      }
    )
  },
  (result, assignment) => {
    if (!result || !result.nodes) return null
    const agentLabel = round + '-a' + assignment.id
    const layoutNodes = result.nodes.map(n => ({
      ...n,
      agentId: agentLabel,
      position: { x: 0, y: 0 },
      isStarred: false
    }))

    const jsonStr = JSON.stringify(layoutNodes, null, 0)
    return agent(
      `Write the following JSON to the file ${ideaDir}/nodes/${agentLabel}.json using the Write tool. Write EXACTLY this content:\n${jsonStr}`,
      { label: `save:${agentLabel}`, phase: 'Brainstorm', model: 'haiku', effort: 'low' }
    ).then(() => layoutNodes)
  }
)

const allNodes = results.filter(Boolean).flat()
log(allNodes.length + ' nodes saved (' + round + ')')

return { theme, round, nodeCount: allNodes.length }
