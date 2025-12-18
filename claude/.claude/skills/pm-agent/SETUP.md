# GitHub Projects 初期セットアップガイド

## 概要

GitHub Projects の初期セットアップを自動化するガイド。

## 前提条件

### 認証確認

```bash
# 認証状態確認
gh auth status

# project スコープが必要な場合
gh auth refresh -s project
```

### 必要なスコープ

- `repo`: Issue作成・編集
- `project`: Projects操作

## セットアップフロー

### Step 1: 対象確認

```bash
# 個人のProjects一覧
gh project list --owner @me

# 組織のProjects一覧
gh project list --owner ORGANIZATION_NAME
```

### Step 2: カスタムフィールド作成

#### Type フィールド（Single Select）

```bash
# gh CLI では Single Select フィールドの作成が制限的
# GraphQL API を使用
```

GraphQL mutation:
```graphql
mutation {
  createProjectV2Field(input: {
    projectId: "PROJECT_ID"
    dataType: SINGLE_SELECT
    name: "Type"
    singleSelectOptions: [
      {name: "Epic", color: PURPLE, description: "マイルストーン"}
      {name: "Feature", color: BLUE, description: "機能要件"}
      {name: "Story", color: GREEN, description: "ユーザーストーリー"}
      {name: "Task", color: GRAY, description: "実装タスク"}
      {name: "Bug", color: RED, description: "バグ修正"}
    ]
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
      }
    }
  }
}
```

#### Priority フィールド

```graphql
mutation {
  createProjectV2Field(input: {
    projectId: "PROJECT_ID"
    dataType: SINGLE_SELECT
    name: "Priority"
    singleSelectOptions: [
      {name: "High", color: RED, description: "最優先"}
      {name: "Medium", color: YELLOW, description: "通常"}
      {name: "Low", color: GREEN, description: "低優先度"}
    ]
  }) {
    projectV2Field {
      ... on ProjectV2SingleSelectField {
        id
        name
      }
    }
  }
}
```

#### Effort フィールド（Number）

```graphql
mutation {
  createProjectV2Field(input: {
    projectId: "PROJECT_ID"
    dataType: NUMBER
    name: "Effort"
  }) {
    projectV2Field {
      ... on ProjectV2Field {
        id
        name
      }
    }
  }
}
```

### Step 3: Iteration フィールド作成

**注意**: Iteration フィールドは GraphQL API でのみ作成可能

```graphql
mutation {
  createProjectV2Field(input: {
    projectId: "PROJECT_ID"
    dataType: ITERATION
    name: "Sprint"
  }) {
    projectV2Field {
      ... on ProjectV2IterationField {
        id
        name
        configuration {
          duration
          startDay
        }
      }
    }
  }
}
```

### Step 4: ビュー作成

#### Kanban ビュー（開発者向け）

```graphql
mutation {
  createProjectV2View(input: {
    projectId: "PROJECT_ID"
    name: "Kanban - Dev"
    layout: BOARD_LAYOUT
  }) {
    projectV2View {
      id
      name
    }
  }
}
```

#### Roadmap ビュー（経営層向け）

```graphql
mutation {
  createProjectV2View(input: {
    projectId: "PROJECT_ID"
    name: "Roadmap - Exec"
    layout: ROADMAP_LAYOUT
  }) {
    projectV2View {
      id
      name
    }
  }
}
```

#### Table ビュー（PM向け）

```graphql
mutation {
  createProjectV2View(input: {
    projectId: "PROJECT_ID"
    name: "Table - PM"
    layout: TABLE_LAYOUT
  }) {
    projectV2View {
      id
      name
    }
  }
}
```

### Step 5: ラベル作成

```bash
# Type ラベル
gh label create "type:epic" --color "5319E7" --description "マイルストーン"
gh label create "type:feature" --color "0052CC" --description "機能要件"
gh label create "type:story" --color "00875A" --description "ユーザーストーリー"
gh label create "type:task" --color "97A0AF" --description "実装タスク"
gh label create "type:bug" --color "D73A4A" --description "バグ修正"

# Priority ラベル
gh label create "priority:high" --color "B60205" --description "最優先"
gh label create "priority:medium" --color "FBCA04" --description "通常"
gh label create "priority:low" --color "0E8A16" --description "低優先度"
```

## 実行例

### セットアップコマンド実行

```
@vw-pm-agent 初期設定して

PMAgent: GitHub Projectsの初期セットアップを開始します。

📍 対象: @me のProjects

作成するカスタムフィールド:
- Type: Epic / Feature / Story / Task / Bug
- Priority: High / Medium / Low
- Effort: 時間（数値）
- Sprint: 2週間イテレーション

作成する推奨ビュー:
- Kanban（開発者向け）
- Roadmap（経営層向け）
- Table（PM向け）

作成するラベル:
- type:* (5種類)
- priority:* (3種類)

実行しますか？ [Yes / キャンセル]
```

## トラブルシューティング

### 認証エラー

```
エラー: HTTP 401: Bad credentials

解決:
1. gh auth status で確認
2. gh auth refresh -s project で再認証
```

### スコープ不足

```
エラー: Resource not accessible by integration

解決:
gh auth refresh -s repo,project
```

### レート制限

```
エラー: API rate limit exceeded

解決:
1. 待機後にリトライ
2. バッチサイズを削減（20件 → 10件）
```

### フィールド重複

```
エラー: Field already exists

解決:
1. 既存フィールドを確認
2. 既存フィールドを使用するか確認
```

## 確認コマンド

```bash
# プロジェクト詳細確認
gh project view PROJECT_NUMBER --owner @me

# フィールド一覧
gh api graphql -f query='
  query {
    user(login: "USERNAME") {
      projectV2(number: PROJECT_NUMBER) {
        fields(first: 20) {
          nodes {
            ... on ProjectV2Field {
              id
              name
            }
            ... on ProjectV2SingleSelectField {
              id
              name
              options {
                id
                name
              }
            }
            ... on ProjectV2IterationField {
              id
              name
            }
          }
        }
      }
    }
  }
'
```

## スクリプト連携

### 概要

pm-agentスキルには、Issue一括作成を堅牢に行うためのヘルパースクリプトが含まれています。
これらのスクリプトは、vw:pmコマンドから自動的に呼び出されます。

### スクリプト配置

```
~/.claude/skills/pm-agent/scripts/
├── pm-utils.sh           # 共通ユーティリティ（source用）
├── pm-setup-labels.sh    # ラベル一括作成
├── pm-bulk-issues.sh     # Issue一括作成（チェックポイント付き）
└── pm-link-hierarchy.sh  # Sub-issue関係設定
```

### 実行順序

Issue作成時は以下の順序でスクリプトを実行します:

```
1. pm-setup-labels.sh     # ラベル準備（必須）
       ↓
2. pm-bulk-issues.sh      # Issue一括作成
       ↓
3. pm-link-hierarchy.sh   # 階層関係設定
```

### 統合ワークフロー例

```bash
# Step 1: リポジトリ確認（git remote origin から取得）
REPO=$(git remote get-url origin | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')

# Step 2: ラベル準備
~/.claude/skills/pm-agent/scripts/pm-setup-labels.sh "$REPO"

# Step 3: Milestone作成（期限必須）
MILESTONE=$(gh api "repos/$REPO/milestones" \
  -X POST \
  -f title="Sprint 1" \
  -f due_on="2025-01-31T00:00:00Z" \
  --jq '.number')

# Step 4: Issue一括作成（ドライラン→本実行）
~/.claude/skills/pm-agent/scripts/pm-bulk-issues.sh /tmp/claude/issues.json \
  --repo "$REPO" \
  --milestone "$MILESTONE" \
  --dry-run

~/.claude/skills/pm-agent/scripts/pm-bulk-issues.sh /tmp/claude/issues.json \
  --repo "$REPO" \
  --milestone "$MILESTONE"

# Step 5: 階層関係設定
~/.claude/skills/pm-agent/scripts/pm-link-hierarchy.sh /tmp/claude/hierarchy.json \
  --repo "$REPO"
```

### チェックポイント機能

`pm-bulk-issues.sh` はチェックポイント機能を持ち、途中失敗時に再開可能です:

```bash
# デフォルトのチェックポイントファイル
/tmp/claude/pm-checkpoint.json

# カスタムチェックポイント
pm-bulk-issues.sh issues.json --checkpoint /tmp/claude/my-checkpoint.json
```

チェックポイントファイル形式:
```json
{
  "created": [
    {"number": "1", "title": "タスク1"},
    {"number": "2", "title": "タスク2"}
  ]
}
```

### Sub-issue階層について

GitHub REST APIの Sub-issues エンドポイントを使用して階層関係を設定します。
これにより、GitHub Projects で「Parent issue」「Sub-issue progress」フィールドが利用可能になります。

参照: https://docs.github.com/en/rest/issues/sub-issues
