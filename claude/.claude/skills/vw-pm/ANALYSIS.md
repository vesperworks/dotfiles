# フェーズ 3C: Issue 分析（フェーズ2機能）

## 前提: SCOPE_REPOS の使用

Phase 2.2 で取得済みの `SCOPE_REPOS` を使う。単一 repo モードなら 1 件、マルチリポモードなら複数 repo を横断して分析する。

## ステップ 3C.1: 各 repo の Issue を取得（横断）

`pm-list-issues.sh` が SCOPE_REPOS を並列で横断取得し、各 Issue に `repo` フィールドを付与した JSON を返す（インラインの while ループは書かない — permission パターンに乗らないため）:

```bash
${CLAUDE_SKILL_DIR}/scripts/pm-list-issues.sh --state all > "${TMPDIR}/vw-pm-issues.json"
```

scope は cwd から自動解決される。明示する場合は `--scope '<json>'` / `--repos a/r1,a/r2` を使う。

## ステップ 3C.2: 分析結果の提示

リポジトリタイプは **repo ごとに評価**（混在もあり得る）。全体サマリ + repo 別ブレークダウンの 2 段構成:

```markdown
## 現状分析

📊 Issue状況（全体）:
- 総Issue数: 47件
- Open: 30件 / Closed: 17件

📦 repo 別ブレークダウン:
- owner/r1 (Personal): Open 20 / Closed 12
- owner/r2 (Personal): Open 10 / Closed 5

🏷️ 分類状況:
- 分類なし: 12件
- type分類済み: 20件（ラベル or Issue Types）

⚠️ 改善提案:

### 分類の統一（repo タイプ別）
個人リポジトリ:
- bug → type:bug ラベルに統一
- enhancement → type:feature ラベルに統一

組織リポジトリ:
- ラベルではなくIssue Typesに移行推奨
- Settings > Planning > Issue types で確認

### Priority管理（全 repo 共通）
- priority:*ラベルを廃止し、Projects V2 Fieldに移行
- pm-project-fields.sh --bulk で一括設定可能

### 粒度の改善
- owner/r1#23「認証機能実装」→ 3つに分割推奨（3時間ルール）
```

## ステップ 3C.3: 改善提案の実行

**必ず AskUserQuestion で確認**:

```yaml
AskUserQuestion:
  questions:
    - question: "改善提案を実行しますか？"
      header: "実行確認"
      multiSelect: false
      options:
        - label: "一括実行"
          description: "すべての改善を実行（全 SCOPE_REPOS 対象）"
        - label: "repo 単位で個別確認"
          description: "repo ごとに実行可否を確認"
        - label: "1 件ずつ確認"
          description: "Issue 単位で確認しながら実行"
        - label: "キャンセル"
          description: "改善を中止"
```

ラベル一括作成が必要な場合は `pm-setup-labels.sh --all-repos` を使うと SCOPE_REPOS 全部に展開できる。
