---
name: commit-helper
description: jj 優先のコミット運用を補助する skill。ユーザーが「コミットして」「段階コミットして」「コミットメッセージを整えて」と言ったときに使う。変更分析、論理グループ化、センシティブ情報チェック、コミットメッセージ整形、承認付きの jj 実行までを案内する。
---

# Commit Helper

この skill は、Claude Code の `vw:commit` の思想を Codex 向けに移したものです。入口は自然文 trigger とし、Codex 標準の plan と承認フローに沿って動きます。

## Use When

- ユーザーが `コミットして` と言ったとき
- ユーザーが `段階コミットして` と言ったとき
- ユーザーが `コミットメッセージを整えて` と言ったとき
- ユーザーが `jj でコミットして` と言ったとき

## Trigger Phrases

- `コミットして`
- `段階コミットして`
- `jj でコミットして`
- `コミットメッセージを整えて`

## Goal

- 変更を論理単位に分ける
- センシティブ情報の混入を防ぐ
- `jj` 優先で安全にコミットする
- コミットメッセージを一貫した形式に揃える

## Workflow

### Mode: Analyze

1. 変更ファイル一覧を取得する
2. 変更内容を読み、論理グループを提案する
3. `scripts/vcs-detect.sh` で VCS を判定する
4. `scripts/commit-security.sh` でセンシティブ情報を確認する
5. この時点ではコミットしない

### Mode: Proposal

候補は最大 3 件までに絞る。各候補には必ず次を付ける。

- Change: 何をどの単位でコミットするか
- Benefit: なぜその分け方がよいか
- Risk: 何に注意が必要か
- Approval: required | optional

段階コミット時は、次のように出す。

```markdown
### Candidate 1
- Change: docs と skill 変更を 1 コミットに分ける
- Benefit: 履歴が読みやすい
- Risk: scope が曖昧なら subject を再調整する
- Approval: required
```

### Mode: Apply

承認された候補だけ実行する。

- `jj` repo では `jj split`, `jj describe`, `jj commit`, `jj new` を使う
- `git` repo では fallback として `git add`, `git commit` を使う
- `jj split` が必要な場合は必ず承認を取る

### Mode: Review

最後に次を返す。

- 作成したコミット
- 実行した検証
- 残るリスク

## Commit Message Policy

原則:

```text
<type>(<scope>): <subject>
```

body は必要なときだけ短く付ける。

### Allowed Types

- `feat`
- `fix`
- `docs`
- `refactor`
- `test`
- `chore`

### Forbidden Content

以下をコミットメッセージに含めない。

- `Co-Authored-By:`
- `Author:`
- `Generated with ...`
- AI 絵文字や AI 由来フッター

## Grouping Rules

- 同じ目的の変更を 1 コミットにまとめる
- 設定変更と機能変更は原則分ける
- docs だけの変更は docs として独立させる
- 無関係な変更を 1 コミットに混ぜない

## Security Check

コミット前に、少なくとも次を確認する。

- ユーザー名
- 絶対パス
- token / secret / key 相当

必要なら `scripts/commit-security.sh` を使う。

## Script Usage

- `scripts/vcs-detect.sh`: `jj` / `git` 判定
- `scripts/commit-security.sh`: センシティブ情報チェック

## Output Contract

```markdown
Mode: {Analyze|Proposal|Apply|Review}

## Summary
- {what will be committed or was committed}

## Commits
- {candidate or actual commit}

## Checks
- {security check}
- {diff/test check}

## Next Step
- {current phase で次にやる 1 手}
```
