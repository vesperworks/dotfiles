# XMLタグブロックの使い方ガイド

## 概要
XMLタグブロックは、構造化された情報を定義し、文書内で参照・実行指示を行うための記法です。

## シンプルなXML構造の特徴

1. **単一のルートタグ**
   - 明確な役割を示すタグ名（例：`subagent_count_guidelines`）

2. **階層構造なしのフラットな内容**
   - 番号付きリストで整理
   - **太字**で重要ポイントを強調
   - 箇条書きで具体例を提示

3. **読みやすいMarkdown風の記法**
   - 番号リスト、箇条書きを活用
   - インデントで視覚的な階層を表現
   - 太字や強調表示で重要部分を明確化

4. **強調語の体系的使用**
   - `ALWAYS`: 必須のコミット、テスト実行に使用
   - `NEVER`: 未テストのコミット、main直接編集の禁止に使用
   - `MUST`: ファイル作成前の確認、品質ゲート通過に使用
   - `IMPORTANT`: 重要な注意事項に限定使用

このような構造で、他の設定やガイドラインも表現できます。例えば：

```xml
<task_execution_guidelines>
タスク実行時の基本原則：
1. **探索フェーズ**: 必ず最初に問題を理解する
   - コードベースの調査
   - 既存実装の確認
   - 影響範囲の特定
2. **計画フェーズ**: 実装前に戦略を立てる
   - 具体的なステップの列挙
   - リスクの洗い出し
   - 成功基準の定義
3. **実装フェーズ**: 段階的に進める
   - TDDアプローチの採用
   - 小さなコミット単位
   - 継続的な動作確認
**IMPORTANT**: 各フェーズを飛ばさず、順番に実行すること
</task_execution_guidelines>
```

## 1. タグブロックの定義

### 基本構文
```xml
<tag_name>
内容をここに記述
</tag_name>
```

### 実例
```xml
<answer_formatting>
Before providing a final answer:
1. Review the most recent fact list compiled during the search process.
2. Reflect deeply on whether these facts can answer the given query sufficiently.
3. Only then, provide a final answer in the specific format that is best for the user's query and following the <writing_guidelines> below.
4. Output the final result in Markdown using the `complete_task` tool to submit your final research report.
5. Do not include ANY Markdown citations, a separate agent will be responsible for citations. Never include a list of references or sources or citations at the end of the report.
</answer_formatting>
```

## 2. タグブロックの参照方法

### 文中での参照
- `<tag_name>`を参照してください
- 前述の`<writing_guidelines>`に従って実装
- 下記の`<answer_formatting>`セクションを確認

### 実行指示での参照
```
"<answer_formatting>ブロックの手順に従って最終回答を作成してください"
"<writing_guidelines>に記載されているルールを適用して文章を構成"
```

## 3. 複数ブロックの連携

```xml
<main_process>
1. まず<preparation_phase>を実行
2. 次に<execution_phase>を開始
3. 最後に<verification_phase>で確認
</main_process>

<preparation_phase>
準備段階の詳細手順...
</preparation_phase>

<execution_phase>
実行段階の詳細手順...
</execution_phase>

<verification_phase>
検証段階の詳細手順...
</verification_phase>
```

## 4. ブロック参照の実例

### プロンプト内での使用例
```
タスクを実行する際は、以下の順序で進めてください：
1. <task_analysis>ブロックの基準に従ってタスクを分析
2. <implementation_guidelines>を参照して実装方針を決定
3. <quality_checks>の各項目を満たすことを確認
```

### 動的な参照例
```
もし複雑なクエリの場合は<subagent_count_guidelines>の
「Medium complexity queries」セクションを参照し、
3-5個のサブエージェントを作成してください。
```

## 5. ブロック指定のベストプラクティス

### 明確な命名
- 役割が一目でわかるタグ名を使用
- 例：`<error_handling>`, `<validation_rules>`

### 一貫性のある参照
- バッククォートで囲む：`<tag_name>`
- 明示的に「ブロック」や「セクション」と呼ぶ

### 階層的な整理
```xml
<main_guidelines>
全体的なガイドライン
詳細は<specific_rules>を参照
</main_guidelines>

<specific_rules>
具体的なルール...
</specific_rules>
```

## 6. 実践的な使用例

### サブエージェント数のガイドライン
```xml
<subagent_count_guidelines>
When determining how many subagents to create, follow these guidelines: 
1. **Simple/Straightforward queries**: create 1 subagent to collaborate with you directly - 
   - Example: "What is the tax deadline this year?" or "Research bananas" → 1 subagent
   - Even for simple queries, always create at least 1 subagent to ensure proper source gathering
2. **Standard complexity queries**: 2-3 subagents
   - For queries requiring multiple perspectives or research approaches
   - Example: "Compare the top 3 cloud providers" → 3 subagents (one per provider)
3. **Medium complexity queries**: 3-5 subagents
   - For multi-faceted questions requiring different methodological approaches
   - Example: "Analyze the impact of AI on healthcare" → 4 subagents (regulatory, clinical, economic, technological aspects)
4. **High complexity queries**: 5-10 subagents (maximum 20)
   - For very broad, multi-part queries with many distinct components 
   - Identify the most effective algorithms to efficiently answer these high-complexity queries with around 20 subagents. 
   - Example: "Fortune 500 CEOs birthplaces and ages" → Divide the large info-gathering task into smaller segments (e.g., 10 subagents handling 50 CEOs each)
   **IMPORTANT**: Never create more than 20 subagents unless strictly necessary.
</subagent_count_guidelines>
```

### タスク実行ガイドライン
```xml
<task_execution_guidelines>
タスク実行時の基本原則：
1. **探索フェーズ**: 必ず最初に問題を理解する
   - コードベースの調査
   - 既存実装の確認
   - 影響範囲の特定
2. **計画フェーズ**: 実装前に戦略を立てる
   - 具体的なステップの列挙
   - リスクの洗い出し
   - 成功基準の定義
3. **実装フェーズ**: 段階的に進める
   - TDDアプローチの採用
   - 小さなコミット単位
   - 継続的な動作確認
**重要**: 各フェーズを飛ばさず、順番に実行すること
</task_execution_guidelines>
```

## まとめ

XMLタグブロックを使用することで：
- 構造化された情報の定義が可能
- 文書内での明確な参照が実現
- 実行時の指示が簡潔に記述可能
- 複雑なワークフローの整理が容易

このガイドラインに従って、効果的なXMLタグブロックの活用を行ってください。