# フェーズ 4: 会話フローでのKanban Status更新

**重要**: このフェーズで扱う「Status」は **Projects V2のKanbanボード列**（Todo/In Progress/Done）であり、IssueのOpen/Closed状態ではない。

## 重要な区別

| 用語 | 意味 | 操作方法 |
|------|------|----------|
| **Issue State** | Open/Closed | `gh issue close/reopen` |
| **Kanban Status** | Todo/In Progress/In Review/Done | `pm-project-fields.sh --status` |

**このフェーズでは「Kanban Status」のみを扱う。**

## ステップ 4.1: キーワード検出

ユーザーの発言から以下のキーワードを検出:

| キーワード | 提案するKanban Status |
|-----------|----------------------|
| 「着手」「開始」「取り掛かる」「始める」 | In Progress |
| 「レビュー」「確認お願い」「PR出した」 | In Review |
| 「完了」「終わった」「Done」「マージした」 | Done |

**注意**: 「クローズ」はIssue Stateの変更（`gh issue close`）なので、Kanban Statusとは別に確認する。

## ステップ 4.2: Status更新提案

キーワード検出時、自動的にAskUserQuestion:

```yaml
AskUserQuestion:
  questions:
    - question: "「{keyword}」を検出しました。IssueのStatusを更新しますか？"
      header: "Status更新"
      multiSelect: false
      options:
        - label: "はい、{new_status}に更新"
          description: "Issue #{number} のStatusを更新"
        - label: "別のIssueを更新"
          description: "Issue番号を指定して更新"
        - label: "更新しない"
          description: "Statusはそのまま"
```

## ステップ 4.3: Status更新実行

承認後に実行:

```bash
.claude/skills/vw-pm/scripts/pm-project-fields.sh {number} \
  --status "{new_status}" \
  --project 1 --owner @me
```

## ステップ 4.4: 更新報告

```markdown
✅ Status更新完了

Issue #{number}: {old_status} → **{new_status}**

📊 Projects: https://github.com/users/xxx/projects/1
```

## ステップ 4.5: 直接Status更新リクエスト

ユーザーが明示的にStatus更新を要求した場合（例: 「#123をDoneにして」）は、ユーザーの発言自体が確認済みの意思表示であるため、AskUserQuestion を省略してよい。

1. Issue番号とStatusを抽出
2. 即座に更新
3. 更新結果を報告

```bash
# 直接リクエスト例
.claude/skills/vw-pm/scripts/pm-project-fields.sh 123 \
  --status "Done" \
  --project 1 --owner @me
```
