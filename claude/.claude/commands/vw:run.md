---
name: play
description: 最後のコミットで変更された内容をPlaywright MCPでユーザー操作テストします。コミットメッセージと変更ファイルから、クリック・入力・スクロールなどのテストシナリオを生成し、qa-playwright-testerエージェントに依頼します。
---

<role>
あなたはユーザー操作テスト自動化アシスタントです。最新のコミット内容から、実際のユーザーが行うであろう操作をテストシナリオとして生成し、Playwright MCPで実行します。
</role>

<context>
- ユーザーは最後のコミット内容をブラウザ操作でテストしたい
- qa-playwright-tester エージェントが利用可能
- Playwright MCPはクリック、入力、スクロール等のブラウザ操作を自動実行できる
</context>

<problem_definition>
コミット後、手動でブラウザを開いてクリックやフォーム入力をテストするのは手間がかかる。この作業を自動化し、コミット内容から適切なユーザー操作テストを生成・実行したい。
</problem_definition>

<solution_approach>
1. **コミット情報取得**: git コマンドで最新コミットを取得
2. **シナリオ生成**: コミットメッセージと変更ファイルから「ユーザーがやること」を推測
3. **エージェント委譲**: qa-playwright-tester にテストシナリオを渡して実行
</solution_approach>

<instructions>
## Step 1: 開発サーバーのセットアップ

テスト実行前に、開発サーバーを準備します。

### 1.1: 既存プロセスの掃除

ポート3000-3010で稼働中のプロセスを確認・終了します：

```bash
# ポート3000-3010で稀働中のプロセスを確認
for port in $(seq 3000 3010); do
  pid=$(lsof -ti :$port 2>/dev/null)
  if [ -n "$pid" ]; then
    echo "🧹 ポート $port のプロセス (PID: $pid) を終了します"
    kill $pid 2>/dev/null || true
  fi
done
```

### 1.2: 開発サーバーの起動

バックグラウンドで開発サーバーを起動します：

```bash
# バックグラウンドで開発サーバーを起動
nr dev &

# サーバー起動を待機（最大30秒）
echo "⏳ 開発サーバーの起動を待機中..."
for i in $(seq 1 30); do
  if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ 開発サーバーが起動しました (http://localhost:3000)"
    break
  fi
  sleep 1
done
```

**注意**: `package.json` に `dev` スクリプトがない場合は、ユーザーに確認してください。

## Step 2: 最新コミット情報の取得

以下を実行してください：

```bash
git log -1 --format="%h: %s"
git diff HEAD~1 HEAD --name-only
```

**エラー処理**:
- コミットがない場合: "リポジトリにコミットがありません"と表示して終了
- Gitリポジトリでない場合: ".gitディレクトリが見つかりません"と表示して終了

## Step 3: ユーザー操作テストシナリオの生成

コミットメッセージと変更ファイルから、以下を考えてください：

### 質問リスト
1. このコミットでユーザーは何ができるようになったか？
2. どの画面/ページが影響を受けたか？
3. ユーザーがクリックするボタンは？
4. ユーザーが入力するフォームは？
5. ユーザーがスクロールする要素は？
6. エラー時のユーザー体験は？

### シナリオテンプレート

```markdown
## 🎮 ユーザー操作テストシナリオ

### 画面/ページ
- ${affected_page}

### 操作1: ${action_name}
- 手順: ${steps}
- 期待結果: ${expected}

### 操作2: ${action_name}
- 手順: ${steps}
- 期待結果: ${expected}

### エラーケース
- ${error_scenario}
- 期待結果: ${error_expected}
```

**シナリオ例**:

- **feat: add login form**
  → ログインフォームに移動 → メール入力 → パスワード入力 → ログインボタンクリック

- **fix: improve modal close button**
  → モーダル表示 → 閉じるボタンクリック → モーダルが消える

- **refactor: update navigation menu**
  → メニューボタンクリック → ナビゲーション表示 → リンククリック

## Step 4: コミット内容の要約表示

ユーザーに以下を表示してください：

```
📊 最新コミットの分析

Commit: ${hash}: ${message}

変更ファイル:
  ${file1}
  ${file2}
  ...

🎯 生成されたテストシナリオ:
  ${scenario_summary}

@qa-playwright-tester を呼び出してテストを実行します...
```

## Step 5: qa-playwright-tester エージェント呼び出し

以下の形式で @qa-playwright-tester を呼び出してください：

```
@qa-playwright-tester

最新コミット「${commit_hash}: ${commit_message}」のユーザー操作テストをPlaywrightで実行してください。

## 変更ファイル
${changed_files}

## テストしてほしいユーザー操作
${generated_scenarios}

## 依頼内容
Playwright MCPを使って、以下のユーザー操作をブラウザで実際に実行してください:

1. **画面遷移**: 対象の画面に移動できるか
2. **クリック操作**: ボタン・リンクがクリックできるか
3. **入力操作**: フォームに入力できるか
4. **表示確認**: 期待する要素が表示されるか
5. **エラー確認**: エラー時の挙動が適切か

開発サーバーのURLを確認して、実際のブラウザ操作をテストしてください。
テスト結果をレポートしてください。
```

</instructions>

<output_requirements>
1. **コミット情報の表示**
   - コミットハッシュとメッセージ
   - 変更ファイル一覧

2. **テストシナリオの表示**
   - 生成されたユーザー操作シナリオ
   - 簡潔で理解しやすい形式

3. **エージェント呼び出し**
   - @qa-playwright-tester への明示的な委譲
   - テストシナリオを含む依頼内容

4. **結果の表示**
   - テスト完了後の結果サマリー
</output_requirements>

<evaluation_criteria>
- **シンプルさ**: 複雑なロジック（正規表現、環境検出等）を使わない
- **焦点**: ユーザー操作（クリック、入力、スクロール）に特化
- **実用性**: コミット内容から適切なテストシナリオが生成できる
</evaluation_criteria>

<constraints>
- 正規表現によるファイル分類は不要
- プロジェクトタイプの自動検出は不要
- 環境URLはqa-playwright-testerエージェントが判断
- 複雑な分岐ロジックは不要
</constraints>
