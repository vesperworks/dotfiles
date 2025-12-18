---
name: pm-agent
description: GitHub Projects PM Agent skill. Converts meeting notes to structured tasks (Epic/Feature/Story/Task) and manages GitHub Projects setup. Key UX: "Throw messy meeting notes, get organized tasks."
---

# PM Agent Skill

## Overview

GitHub Projects PM（プロジェクトマネジメント）スキル。
議事録やメモから自動的にタスクを抽出し、GitHub Issues/Projectsに構造化して登録する。

**キラーUX**: 「雑に議事録を投げるとタスク化してくれる」

## When to Use

- 議事録からタスクを作成したい
- GitHub Projects の初期設定をしたい
- 既存Issueの整理・改善提案が欲しい
- プロジェクトの進捗レポートが欲しい

## Progressive Disclosure Structure

このスキルは Progressive Disclosure パターンを使用:

- **SKILL.md** (常に読み込み): 概要とエントリポイント
- **PARSER.md** (必要時): 議事録パース詳細ロジック
- **SETUP.md** (必要時): 初期セットアップ手順
- **GRAPHQL.md** (必要時): GraphQL API リファレンス

## Core Features

### 1. 議事録 → タスク変換（MVP）

```
入力: 議事録テキスト or ファイル参照
出力: 4層構造（Epic/Feature/Story/Task）の提案
```

### 2. Projects 初期セットアップ（MVP）

```
自動作成:
- カスタムフィールド（Type/Priority/Effort）
- Iterationフィールド（GraphQL API）
- 推奨ビュー（Kanban/Roadmap/Table）
```

### 3. 現状分析・改善提案（Phase 2）

```
分析対象:
- 既存Issueの分類
- ラベル整理
- 粒度不適切なチケット
```

## 4層チケット構造

| 層 | Type | 粒度 | 例 |
|----|------|------|-----|
| Epic | マイルストーン | 「v1.0正式リリース」 |
| Feature | 1-3スプリント | 「在庫管理機能搭載」 |
| Story | 1スプリント以内 | 「在庫管理ができるようになる」 |
| Task/Bug | 3時間以内 | 「DBスキーマ設計」 |

## Invocation

このスキルは `vw-pm-agent` エージェントを通じて呼び出される。

```
@vw-pm-agent [議事録テキスト or コマンド]
```

### コマンド例

```bash
# 議事録からタスク作成
@vw-pm-agent 以下の議事録からタスクを作って
[議事録テキスト]

# ファイル参照
@vw-pm-agent @path/to/meeting-notes.md からタスクを作って

# 初期セットアップ
@vw-pm-agent 初期設定して

# 現状分析
@vw-pm-agent 現状のIssue整理して
```

## Default Configuration

### GitHub Settings

| 設定 | デフォルト値 | 説明 |
|------|-------------|------|
| owner | `@me` | 個人の場合は `@me`、組織の場合は組織名 |
| project_number | `1` | `gh project list` で確認 |

### Custom Fields

| フィールド | 種類 | 選択肢 | カラー |
|-----------|------|--------|--------|
| **Type** | Single Select | Epic / Feature / Story / Task / Bug | purple / blue / green / gray / red |
| **Priority** | Single Select | High / Medium / Low | red / yellow / green |
| **Effort** | Number | - | - |

### Labels (Auto-created)

| ラベル | カラーコード | 説明 |
|--------|-------------|------|
| `type:epic` | `5319E7` | マイルストーン |
| `type:feature` | `0052CC` | 機能要件 |
| `type:story` | `00875A` | ユーザーストーリー |
| `type:task` | `97A0AF` | 実装タスク |
| `type:bug` | `D73A4A` | バグ修正 |
| `priority:high` | `B60205` | 最優先 |
| `priority:medium` | `FBCA04` | 通常 |
| `priority:low` | `0E8A16` | 低優先度 |

### Granularity Rules

| ルール | 値 | 説明 |
|--------|-----|------|
| 実装タスク最大時間 | **3時間** | 超えたら分割提案 |
| 警告閾値 | 2時間 | 警告表示 |

### Rate Limit Settings

| 設定 | 値 | 説明 |
|------|-----|------|
| バッチサイズ | 20件 | 一度に処理する最大Issue数 |
| 遅延 | 1000ms | バッチ間の待機時間 |
| リトライ | 3回 | 最大リトライ回数 |

### Recommended Views

| ビュー名 | タイプ | 対象 |
|---------|--------|------|
| Kanban - Dev | Board | 開発者向け（statusでグループ化） |
| Roadmap - Exec | Roadmap | 経営層向け（parentでグループ化） |
| Table - PM | Table | PM向け（priorityでソート） |

## Error Handling

| エラー | 対応 |
|--------|------|
| 認証エラー | `gh auth refresh -s project` を案内 |
| API失敗 | 操作を中断し `AskUserQuestion` でユーザーに確認 |
| レート制限 | バッチ処理（20件/回）、遅延挿入 |
| フィールド重複 | 既存フィールドを使用するか確認 |

## Rollback / Recovery

- **Issue作成失敗**: 作成済みのIssueを列挙し、手動削除を案内
- **セットアップ失敗**: 作成済みリソースを列挙し、部分的な再実行を提案
- **API障害**: 操作ログを表示し、後日再試行を案内
