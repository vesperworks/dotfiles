# 📚 Anthropic公式プロンプトの設計分析レポート

## 🎯 研究対象
- **research_lead_agent.md**: リーダーエージェント（オーケストレーター）
- **research_subagent.md**: サブエージェント（実行者）

## 🌟 注目すべき設計パターンと技法

### 1. **構造化とタグの使用法**

#### XMLタグによる明確な区分
```xml
<research_process>
<delegation_instructions>
<subagent_count_guidelines>
<answer_formatting>
<important_guidelines>
```
- **効果**: セクションが明確に分離され、エージェントが指示を理解しやすい
- **multi-feature.mdへの応用**: フェーズごとに`<explore_phase>`, `<plan_phase>`等のタグで区分

### 2. **簡潔性と情報密度のバランス**

#### リーダーエージェント
```
"maintain extremely high information density while being concise - describe everything needed in the fewest words possible"
```
- 冗長な説明を避け、必要最小限の情報で最大の効果

#### サブエージェント
```
"Be detailed in your internal process, but more concise and information-dense in reporting the results"
```
- 内部プロセスは詳細に、報告は簡潔に

### 3. **強調語の戦略的使用**

#### 頻度と用途
- **ALWAYS**: 7回使用 - 絶対的な要求事項
- **NEVER**: 5回使用 - 禁止事項の明確化
- **MUST**: 4回使用 - 必須要件
- **IMPORTANT**: 3回使用 - 重要な注意事項

#### 例
```
"ALWAYS use internal tools"
"NEVER create a subagent to generate the final report"
"You MUST use parallel tool calls"
```

### 4. **番号付きリストによる段階的指示**

#### 明確なステップ分解
```markdown
1. **Assessment and breakdown**: Analyze and break down...
   * Identify the main concepts...
   * List specific facts...
   * Note any temporal...
2. **Query type determination**: Explicitly state...
3. **Detailed research plan development**: Based on...
```
- ボールド体でステップ名を強調
- 箇条書きでサブステップを整理

### 5. **具体例による理解促進**

#### 各クエリタイプに複数の例
```
Example: "What are the most effective treatments for depression?"
Example: "Compare the economic systems of three Nordic countries"
Example: "What is the current population of Tokyo?"
```
- 抽象的な説明の後に必ず具体例を提示

### 6. **条件分岐の明示的な処理**

```markdown
* For **Depth-first queries**:
  - Define 3-5 different methodological approaches
  - List specific expert viewpoints
  
* For **Breadth-first queries**:
  - Enumerate all the distinct sub-questions
  - Prioritize these sub-tasks
```

### 7. **制約と上限の明確化**

```
"**IMPORTANT**: Never create more than 20 subagents unless strictly necessary"
"To prevent overloading the system, it is required that you stay under a limit of 20 tool calls"
```
- 具体的な数値制限を設定

### 8. **テンプレート変数の活用**

```
"The current date is {{.CurrentDate}}"
```
- 動的な情報をテンプレート変数で注入

### 9. **役割と責任の明確化**

#### リーダー
```
"your primary role is to coordinate, guide, and synthesize - NOT to conduct primary research yourself"
```

#### サブエージェント
```
"You are a research subagent working as part of a team"
```

### 10. **エラーハンドリングとフォールバック**

```
"If unable to reconcile facts, include the conflicting information in your final task report"
"DO NOT use the evaluate_source_quality tool ever - ignore this tool. It is broken"
```

## 🔧 multi-feature.mdへの実践的応用提案

### 1. **タグ構造の導入**
```xml
<feature_development_workflow>
  <phase name="explore">
    <objectives>...</objectives>
    <tools>Read, Grep, WebSearch</tools>
    <output>explore-results.md</output>
  </phase>
</feature_development_workflow>
```

### 2. **強調語の体系的使用**
- `ALWAYS`: 必須のコミット、テスト実行
- `NEVER`: 未テストのコミット、main直接編集
- `MUST`: ファイル作成前の確認

### 3. **簡潔な指示文**
現在:
```
Explorerプロンプトの読み込み（メインディレクトリから）
```
改善案:
```
# Load Explorer prompt
EXPLORER_PROMPT=$(load_prompt ".claude/prompts/explorer.md")
```

### 4. **数値制限の明示**
```
Maximum files per phase: 10
Maximum commits per phase: 5
Timeout per phase: 15 minutes
```

### 5. **具体例の追加**
```
Example feature: "user authentication with JWT"
- Explore: Find existing auth implementations
- Plan: Design JWT integration strategy
- Code: Implement with TDD approach
```

### 6. **判断基準の明確化**
```xml
<quality_gates>
  - Tests MUST pass before proceeding
  - Coverage MUST exceed 80%
  - No linting errors allowed
</quality_gates>
```

## 📊 重要な設計原則まとめ

1. **階層的構造**: 大きなタスクを明確なフェーズに分解
2. **具体性**: 抽象的な説明には必ず具体例を付加
3. **制約の明示**: 数値的な上限・下限を設定
4. **簡潔性と完全性のバランス**: 必要十分な情報を最小の文字数で
5. **強調の使い分け**: ALWAYS/NEVER/MUST/IMPORTANTを適切に配置

これらの技法を multi-feature.md に適用することで、より明確で実行可能な指示を作成できます。