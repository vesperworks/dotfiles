# フェーズ 3C: Issue 分析（フェーズ2機能）

## ステップ 3C.1: 現在の状態を分析

```bash
gh issue list --state all --limit 100 --json number,title,labels,state
```

## ステップ 3C.2: 分析結果の提示

リポジトリタイプに応じた分析を表示:

```markdown
## 現状分析

📊 Issue状況:
- 総Issue数: 47件
- Open: 30件
- Closed: 17件

🏷️ 分類状況:
- 分類なし: 12件
- type分類済み: 20件（ラベル or Issue Types）

⚠️ 改善提案:

### 分類の統一
（個人リポジトリの場合）
- bug → type:bug ラベルに統一
- enhancement → type:feature ラベルに統一

（組織リポジトリの場合）
- ラベルではなくIssue Typesに移行推奨
- Settings > Planning > Issue types で確認

### Priority管理
- priority:*ラベルを廃止し、Projects V2 Fieldに移行
- pm-project-fields.sh --bulk で一括設定可能

### 粒度の改善
- #23「認証機能実装」→ 3つに分割推奨（3時間ルール）
```

**必ず AskUserQuestion で確認**:
```yaml
AskUserQuestion:
  questions:
    - question: "改善提案を実行しますか？"
      header: "実行確認"
      multiSelect: false
      options:
        - label: "一括実行"
          description: "すべての改善を実行"
        - label: "個別確認"
          description: "1件ずつ確認しながら実行"
        - label: "キャンセル"
          description: "改善を中止"
```
