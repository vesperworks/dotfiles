# フェーズ 3B: 初期セットアップ

## ステップ 3B.1: セットアップガイドの読み込み

GraphQL ミューテーションの詳細は `.claude/skills/pm-agent/GRAPHQL.md` を参照。

## ステップ 3B.2: 現在の状態を確認

```bash
gh project list --owner @me
```

## ステップ 3B.3: セットアップ計画の提示

セットアップ計画はリポジトリタイプによって異なる:

### 個人リポジトリの場合:
```markdown
## セットアップ計画（個人リポジトリ）

📍 対象: @me のProjects #1

### 作成するカスタムフィールド（Projects V2）:
- Priority: High / Medium / Low（ラベルではなくFieldで管理）
- Effort: 時間（数値）
- Sprint: 2週間イテレーション

### 作成するビュー:
- Kanban - Dev（開発者向け）
- Roadmap - Exec（経営層向け）
- Table - PM（PM向け）

### 作成するラベル:
- type:epic, type:feature, type:story, type:task, type:bug

⚠️ priority:*ラベルは作成しません（Projects V2 Fieldで管理）
```

### 組織リポジトリの場合:
```markdown
## セットアップ計画（組織リポジトリ）

📍 対象: organization のProjects #1

### Issue Types（組織設定で管理）:
→ Settings > Planning > Issue types で確認/設定
デフォルト: task, bug, feature

### 作成するカスタムフィールド（Projects V2）:
- Priority: High / Medium / Low
- Effort: 時間（数値）
- Sprint: 2週間イテレーション

### 作成するビュー:
- Kanban - Dev（開発者向け）
- Roadmap - Exec（経営層向け）
- Table - PM（PM向け）

⚠️ type:*ラベルは作成しません（Issue Typesで管理）
⚠️ priority:*ラベルは作成しません（Projects V2 Fieldで管理）
```

**必ず AskUserQuestion で確認**:
```yaml
AskUserQuestion:
  questions:
    - question: "セットアップを実行しますか？"
      header: "セットアップ"
      multiSelect: false
      options:
        - label: "はい、実行する"
          description: "リポジトリタイプに応じたリソースを作成"
        - label: "キャンセル"
          description: "セットアップを中止"
```

## ステップ 3B.4: セットアップの実行

承認された場合、リポジトリタイプに応じて実行:

### 個人リポジトリの場合:
1. `pm-setup-labels.sh` でtype:*ラベルを作成
2. カスタムフィールドを作成（GraphQL）: Priority, Effort, Sprint
3. ビューを作成（GraphQL）: Kanban, Roadmap, Table

### 組織リポジトリの場合:
1. Issue Types確認を案内（Settings > Planning > Issue types）
2. カスタムフィールドを作成（GraphQL）: Priority, Effort, Sprint
3. ビューを作成（GraphQL）: Kanban, Roadmap, Table

**共通**: priority:*ラベルは作成しない（Projects V2 Fieldで管理）

参照: `.claude/skills/pm-agent/GRAPHQL.md`

## ステップ 3B.5: 結果の報告

### 個人リポジトリの場合:
```markdown
✅ セットアップ完了！

## 作成されたリソース

### カスタムフィールド（Projects V2）:
- ✅ Priority
- ✅ Effort
- ✅ Sprint

### ビュー:
- ✅ Kanban - Dev
- ✅ Roadmap - Exec
- ✅ Table - PM

### ラベル:
- ✅ type:* (5種類)

📊 Projects: https://github.com/users/xxx/projects/1
```

### 組織リポジトリの場合:
```markdown
✅ セットアップ完了！

## 作成されたリソース

### Issue Types:
→ 組織設定で管理（Settings > Planning > Issue types）
利用可能: task, bug, feature (+ カスタム)

### カスタムフィールド（Projects V2）:
- ✅ Priority
- ✅ Effort
- ✅ Sprint

### ビュー:
- ✅ Kanban - Dev
- ✅ Roadmap - Exec
- ✅ Table - PM

📊 Projects: https://github.com/orgs/xxx/projects/1
```

## 前提条件

```bash
# 認証状態確認
gh auth status

# project スコープが必要な場合
gh auth refresh -s project
```

必要なスコープ: `repo`（Issue作成・編集）、`project`（Projects操作）

## トラブルシューティング

| エラー | 原因 | 解決方法 |
|--------|------|----------|
| HTTP 401: Bad credentials | 認証切れ | `gh auth refresh -s project` |
| Resource not accessible | スコープ不足 | `gh auth refresh -s repo,project` |
| API rate limit exceeded | レート制限 | 待機後リトライ、バッチサイズ削減 |
| Field already exists | フィールド重複 | 既存フィールドを確認して使用 |

## 確認コマンド

```bash
# プロジェクト詳細確認
gh project view PROJECT_NUMBER --owner @me

# フィールド一覧（pm-project-fields.sh 使用推奨）
.claude/skills/pm-agent/scripts/pm-project-fields.sh \
  --project 1 --owner @me --list-fields
```
