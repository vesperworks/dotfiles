export const meta = {
  name: 'vw-repo-audit',
  description: 'OSS 公開前ゲート監査: Sonnet×6 がカテゴリ別に並列監査する',
  whenToUse: 'vw-repo-audit SKILL の Step 2 から起動される',
  phases: [{ title: 'Audit', detail: '6 カテゴリ並列監査 (Sonnet)' }],
}

// args: { projectRoot, reviewDir, skillDir, date, vcs, truncatedCount }
// 大きな入力は {reviewDir}/inputs/ のファイルで受け取る（args には載せない）:
//   commitlog.txt   — 未公開コミット一覧
//   diff-files.txt  — 精読対象の変更ファイル（1 行 1 ファイル）
//   surface.txt     — 表層ファイル（1 行 1 ファイル）
const A = typeof args === 'string' ? JSON.parse(args) : args

const CATEGORIES = [
  { n: 1, key: 'first-impression', title: 'First Impression', section: '§1' },
  { n: 2, key: 'hygiene',          title: 'Hygiene',          section: '§2' },
  { n: 3, key: 'history',          title: 'History',          section: '§3' },
  { n: 4, key: 'structure',        title: 'Structure',        section: '§4' },
  { n: 5, key: 'docs-freshness',   title: 'Docs Freshness',   section: '§5' },
  { n: 6, key: 'taste',            title: 'Taste',            section: '§6' },
]

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['category', 'summary', 'findings', 'unverified'],
  properties: {
    category: { type: 'string' },
    summary: { type: 'string', description: '監査の要約 2-3 文。指摘ゼロなら何をどう確認したか' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'file', 'summary', 'evidence'],
        properties: {
          severity: { enum: ['critical', 'serious', 'nitpick'] },
          file: { type: 'string', description: 'repo ルートからの相対パス' },
          line: { type: 'integer' },
          summary: { type: 'string', description: '指摘 1 文（機密値は絶対に含めない）' },
          evidence: { type: 'string', description: '根拠。file:line と確認方法。機密値はマスク' },
          fix_hint: { type: 'string', description: '修正の方向性 1 行（任意）' },
          related: { type: 'array', items: { type: 'string' }, description: '同一原因の影響箇所 file:line' },
        },
      },
    },
    unverified: {
      type: 'array',
      items: {
        type: 'object',
        required: ['hypothesis', 'verify_command'],
        properties: {
          hypothesis: { type: 'string' },
          verify_command: { type: 'string', description: '白黒つける検証コマンド 1 行' },
        },
      },
      description: '実行検証できなかった仮説（減点対象外）',
    },
  },
}

const results = await parallel(CATEGORIES.map(cat => () => agent(
  `あなたは OSS 公開前監査の「${cat.title}」カテゴリ担当です。

## 手順
1. まず ${A.skillDir}/references/categories.md を Read し、「全カテゴリ共通の規約」と「${cat.section} ${cat.title}」の節に厳密に従う
2. 監査対象の入力 3 ファイルを Read する:
   - ${A.reviewDir}/inputs/commitlog.txt — 未公開コミット一覧
   - ${A.reviewDir}/inputs/diff-files.txt — 精読対象の変更ファイル${A.truncatedCount ? `（他 ${A.truncatedCount} 件は絞り込みで名前のみ審査に落ちている）` : ''}
   - ${A.reviewDir}/inputs/surface.txt — 表層ファイル（常時審査対象）
3. リポジトリルート ${A.projectRoot}（VCS: ${A.vcs}）で、担当カテゴリの観点のみで監査する（他カテゴリの指摘はしない）
4. 所見を ${A.reviewDir}/cat-${cat.n}-${cat.key}.md に Markdown で書き出す（見出し・指摘一覧・根拠）
5. 構造化出力（findings）を返す

## 厳守事項
- 指摘には file:line 証拠を必ず付ける。読まずに推測で指摘しない
- 機密らしき値は**値そのものをどこにも書かない**（file:line + 種別のみ）
- コマンドで検証できる仮説は実行してから指摘に昇格。できなければ unverified に分離
- 監査日: ${A.date}`,
  {
    label: `audit:${cat.key}`,
    phase: 'Audit',
    model: 'sonnet',
    schema: FINDINGS_SCHEMA,
  }
)))

const reports = results.filter(Boolean)
log(`${reports.length}/6 カテゴリの監査が完了`)
return { date: A.date, reports }
