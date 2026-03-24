---
name: autoloop-bootstrap
description: Codex の標準機能を優先して、半自動の改善ループを初期化・更新する skill。ユーザーが「自動ループを作りたい」「運用を改善して」「半自動で回したい」「ベストプラクティスを更新して」と言ったときに使う。まず短いインタビューを行い、その回答を元に AGENTS.md、skill、rules、automation 提案へ落とし込む。
---

# Autoloop Bootstrap

この skill は、Codex のデフォルト機能をできるだけ崩さずに、継続改善用の半自動ループを作るためのブートストラップです。

## Default-First Policy

常に次の順で検討する。

1. `AGENTS.md` に durable guidance を置く
2. `skill` に繰り返し使う手順を置く
3. `rules` で allow / prompt / forbidden を調整する
4. `automation` で定期実行にする
5. それでも UI や制御が足りないときだけ `SDK / MCP / App Server` を提案する

## Use When

- ユーザーが `自動ループを作りたい` と言ったとき
- ユーザーが `半自動で回したい` と言ったとき
- ユーザーが `運用を改善して` と言ったとき
- ユーザーが `ベストプラクティスを更新していきたい` と言ったとき
- ユーザーが `質問に答えるだけで回る setup` を求めたとき

## Trigger Phrases

次の自然文を見たら、この skill の手順を優先する。

- `自動ループを作りたい`
- `半自動で回したい`
- `運用を改善して`
- `ベストプラクティスを更新していきたい`
- `質問に答えるだけで回るようにしたい`

## Goal

ユーザーの回答だけで、次を満たす状態を作る。

- 何を自律実行してよいかが明文化されている
- どこで止まるかが明文化されている
- 改善対象と改善頻度が明文化されている
- skill と automation に落とし込める粒度まで手順化されている

## Hard Constraints

- `Research Mode` ではファイル編集しない
- `Proposal Mode` では変更候補を最大 3 件までに絞る
- 各候補に必ず `何が変わるか / 利点 / リスク / 承認要否` を付ける
- `Apply Mode` では承認された候補だけ反映する
- 承認前は `.codex/` と `.agents/` を編集しない
- `次の一手` は必ず「どのフェーズで」「何をするか」を 1 行で明示する
- `調査` と `反映` を同じ返答内で混ぜない

## Interview Contract

最初に 1 から 3 問ずつ聞く。質問は短く、各質問に 2 から 4 個の選択肢を付ける。

質問の形式は次を使う。

```text
Q1. 今回まず自動化したい対象はどれ？
1. リポジトリ運用
2. 実装レビュー
3. ベストプラクティス更新
4. skill 改善
推奨: 3
```

UI の選択肢ツールがない前提でも回るように、必ず番号付きの自然文選択肢で聞く。

## Interview Topics

最低限、次を埋める。

1. 対象
- 何を改善ループに入れたいか

2. 自律度
- 完全自動
- 承認付き半自動
- 提案のみ

3. 更新先
- `AGENTS.md`
- `.codex/rules/`
- `.agents/skills/`
- automation prompt

4. 停止条件
- テスト失敗で停止
- 破壊的変更前に停止
- 外部影響操作前に停止
- n 回失敗で停止

5. 評価方法
- diff review
- test / lint / typecheck
- representative prompts
- 再発率の観測

## Workflow

### Conversation Protocol

この skill は必ず次の順で 1 周を回す。

1. `Research Mode`
- 公式情報を確認する
- 必要なら GitHub の参照実装を確認する
- ローカル設定との差分候補を抽出する
- この時点では実装しない

2. `Proposal Mode`
- 候補を最大 3 件まで提示する
- 各候補に `何が変わるか / 利点 / リスク / 承認要否` を付ける
- 最後に `次の一手: Proposal Mode で承認待ち` のように明記する

3. `Apply Mode`
- ユーザーが承認した候補だけ実装する
- 未承認の候補には触れない
- 反映後に検証する

4. `Review Mode`
- 変更内容、検証内容、残るリスクを返す
- 次の改善候補は次周回で提案する

### Phase 1: Scope

1. 対象 repo と改善テーマを確認する
2. 既存の `AGENTS.md`、`.codex/`、`.agents/skills/` を読む
3. 既存設定を壊さない方針で差分計画を作る

### Phase 2: Interview

1. 1 から 3 問ずつ質問する
2. 各問に推奨 option を 1 つ付ける
3. 不明点が埋まるまで続ける
4. 回答内容を短く要約する

### Phase 3: Design

回答を次の 4 層にマッピングする。

1. `AGENTS.md`
- 原則
- 停止条件
- 承認基準
- レポート形式

2. `rules`
- allow
- prompt
- forbidden

3. `skill`
- 日常的に呼ぶ実行手順
- 調査 / 変更 / 検証 / 反映の流れ

4. `automation`
- 周期
- prompt
- 成果物

### Phase 3.5: Proposal

実装前に、候補を最大 3 件までに絞って提示する。

各候補は必ず次の形式にする。

```markdown
### Candidate {n}
- Change: {何が変わるか}
- Benefit: {利点}
- Risk: {リスク}
- Approval: required | optional
```

候補を出した後は、承認があるまで実装に進まない。

### Phase 4: Implement

必要なファイルだけ小さく追加・更新する。

- 既存パターン優先
- 変更は最小差分
- ループの暴走防止を先に入れる
- 承認済み候補だけ反映する
- 未承認の `.codex/` と `.agents/` 変更は行わない

### Phase 5: Verify

最低限、次を確認する。

- skill の説明文で trigger が成立しそうか
- rules が意図どおり prompt / allow / forbidden か
- 変更した設定ファイルが読めるか
- 実行後レポートの書式が明確か

### Phase 6: Hand-off

最後に次を返す。

1. 何が自動化されたか
2. 何がまだ手動か
3. 次に automation 化する候補
4. 必要なら `SDK / MCP` に進む理由

## Mode Separation

各返答の先頭で、現在のモードを明示する。

- `Mode: Research`
- `Mode: Proposal`
- `Mode: Apply`
- `Mode: Review`

`Mode: Research` と `Mode: Apply` を同じ返答内で併記してはならない。

## Best-Practice Defaults

デフォルトでは次を推奨する。

- 自律度: `承認付き半自動`
- 更新先: `AGENTS.md + skill`
- rules: `read/search は allow`, `破壊的変更と外部影響は prompt`
- 評価: `diff + test + representative prompts`
- automation: まずは提案のみ、安定後に schedule 化

詳細は `references/default-stack.md` を読む。

## Do Not Do

- いきなり SDK 前提で設計しない
- UI がないのに選択式 UI がある前提で進めない
- skill に過剰なロジックを詰め込まない
- 承認が必要な操作を自動実行前提にしない
- 既存 `AGENTS.md` を無断で全面置換しない
- 調査フェーズ中に実装案を先走って反映しない
- 4 件以上の候補を一度に提案しない
- `次の一手` を曖昧なまま返さない

## Output Contract

設計提案や実装後の報告は、次の順で返す。

```markdown
Mode: {Research|Proposal|Apply|Review}

## Summary
- {what changed}

## Loop Design
- Goal: {goal}
- Trigger: {trigger}
- Stop Conditions: {stop conditions}
- Evaluation: {evaluation}

## Files
- {file 1}
- {file 2}

## Next Step
- {current phase で次にやる 1 手}
```
