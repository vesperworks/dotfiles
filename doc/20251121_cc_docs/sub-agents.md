# サブエージェント

> Claude Codeで特化したAIサブエージェントを作成・使用して、タスク固有のワークフローとコンテキスト管理を改善します。

Claude Codeのカスタムサブエージェントは、特定の種類のタスクを処理するために呼び出すことができる特化したAIアシスタントです。タスク固有の設定、カスタマイズされたシステムプロンプト、ツール、および独立したコンテキストウィンドウを提供することで、より効率的な問題解決を実現します。

## サブエージェントとは？

サブエージェントは、Claude Codeがタスクを委譲できる事前設定されたAIパーソナリティです。各サブエージェント：

* 特定の目的と専門分野を持っています
* メイン会話とは別の独立したコンテキストウィンドウを使用します
* 使用を許可された特定のツールで設定できます
* その動作をガイドするカスタムシステムプロンプトを含みます

Claude Codeがサブエージェントの専門分野に一致するタスクに遭遇すると、そのタスクを特化したサブエージェントに委譲でき、サブエージェントは独立して動作し、結果を返します。

## 主な利点

<CardGroup cols={2}>
  <Card title="コンテキストの保持" icon="layer-group">
    各サブエージェントは独立したコンテキストで動作し、メイン会話の汚染を防ぎ、高レベルの目標に焦点を当てた状態を保ちます。
  </Card>

  <Card title="特化した専門知識" icon="brain">
    サブエージェントは特定のドメイン向けの詳細な指示で微調整でき、指定されたタスクでより高い成功率につながります。
  </Card>

  <Card title="再利用性" icon="rotate">
    一度作成されたサブエージェントは、異なるプロジェクト全体で使用でき、チームと共有して一貫したワークフローを実現できます。
  </Card>

  <Card title="柔軟な権限" icon="shield-check">
    各サブエージェントは異なるツールアクセスレベルを持つことができ、強力なツールを特定のサブエージェントタイプに制限できます。
  </Card>
</CardGroup>

## クイックスタート

最初のサブエージェントを作成するには：

<Steps>
  <Step title="サブエージェントインターフェースを開く">
    次のコマンドを実行します：

    ```
    /agents
    ```
  </Step>

  <Step title="「新しいエージェントを作成」を選択">
    プロジェクトレベルまたはユーザーレベルのサブエージェントを作成するかを選択します
  </Step>

  <Step title="サブエージェントを定義">
    * **推奨**: まずClaudeで生成してから、カスタマイズして自分のものにします
    * サブエージェントを詳細に説明し、いつ使用すべきかを記述します
    * アクセスを許可するツールを選択します（すべてのツールを継承する場合は空白のままにします）
    * インターフェースはすべての利用可能なツールを表示し、選択を簡単にします
    * Claudeで生成する場合、`e`を押して独自のエディターでシステムプロンプトを編集することもできます
  </Step>

  <Step title="保存して使用">
    サブエージェントが利用可能になりました！Claudeは適切な場合に自動的にそれを使用するか、明示的に呼び出すことができます：

    ```
    > Use the code-reviewer subagent to check my recent changes
    ```
  </Step>
</Steps>

## サブエージェント設定

### ファイルの場所

サブエージェントはYAMLフロントマター付きのMarkdownファイルとして、2つの可能な場所に保存されます：

| タイプ                | 場所                  | スコープ              | 優先度 |
| :----------------- | :------------------ | :---------------- | :-- |
| **プロジェクトサブエージェント** | `.claude/agents/`   | 現在のプロジェクトで利用可能    | 最高  |
| **ユーザーサブエージェント**   | `~/.claude/agents/` | すべてのプロジェクト全体で利用可能 | 低い  |

サブエージェント名が競合する場合、プロジェクトレベルのサブエージェントがユーザーレベルのサブエージェントより優先されます。

### プラグインエージェント

[プラグイン](/ja/plugins)は、Claude Codeとシームレスに統合するカスタムサブエージェントを提供できます。プラグインエージェントはユーザー定義エージェントと同じように動作し、`/agents`インターフェースに表示されます。

**プラグインエージェントの場所**: プラグインは`agents/`ディレクトリ（またはプラグインマニフェストで指定されたカスタムパス）にエージェントを含めます。

**プラグインエージェントの使用**:

* プラグインエージェントはカスタムエージェントと一緒に`/agents`に表示されます
* 明示的に呼び出すことができます：「Use the code-reviewer agent from the security-plugin」
* 適切な場合、Claudeによって自動的に呼び出すことができます
* `/agents`インターフェースを通じて管理（表示、検査）できます

プラグインエージェントの作成の詳細については、[プラグインコンポーネントリファレンス](/ja/plugins-reference#agents)を参照してください。

### CLIベースの設定

`--agents` CLIフラグを使用してサブエージェントを動的に定義することもできます。このフラグはJSONオブジェクトを受け入れます：

```bash  theme={null}
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer. Use proactively after code changes.",
    "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

**優先度**: CLIで定義されたサブエージェントはプロジェクトレベルのサブエージェントより優先度が低いですが、ユーザーレベルのサブエージェントより優先度が高いです。

**ユースケース**: このアプローチは以下に役立ちます：

* サブエージェント設定の迅速なテスト
* 保存する必要がないセッション固有のサブエージェント
* カスタムサブエージェントが必要なオートメーションスクリプト
* ドキュメントやスクリプトでのサブエージェント定義の共有

JSON形式と利用可能なすべてのオプションの詳細については、[CLIリファレンスドキュメント](/ja/cli-reference#agents-flag-format)を参照してください。

### ファイル形式

各サブエージェントは、この構造を持つMarkdownファイルで定義されます：

```markdown  theme={null}
---
name: your-sub-agent-name
description: Description of when this subagent should be invoked
tools: tool1, tool2, tool3  # Optional - inherits all tools if omitted
model: sonnet  # Optional - specify model alias or 'inherit'
---

Your subagent's system prompt goes here. This can be multiple paragraphs
and should clearly define the subagent's role, capabilities, and approach
to solving problems.

Include specific instructions, best practices, and any constraints
the subagent should follow.
```

#### 設定フィールド

| フィールド         | 必須  | 説明                                                                                                                                              |
| :------------ | :-- | :---------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`        | はい  | 小文字とハイフンを使用した一意の識別子                                                                                                                             |
| `description` | はい  | サブエージェントの目的の自然言語説明                                                                                                                              |
| `tools`       | いいえ | 特定のツールのカンマ区切りリスト。省略した場合、メインスレッドのすべてのツールを継承します                                                                                                   |
| `model`       | いいえ | このサブエージェントが使用するモデル。モデルエイリアス（`sonnet`、`opus`、`haiku`）または`'inherit'`を指定してメイン会話のモデルを使用できます。省略した場合、[設定されたサブエージェントモデル](/ja/model-config)にデフォルト設定されます |

### モデル選択

`model`フィールドを使用して、サブエージェントが使用する[AIモデル](/ja/model-config)を制御できます：

* **モデルエイリアス**: 利用可能なエイリアスのいずれかを使用します：`sonnet`、`opus`、または`haiku`
* **`'inherit'`**: メイン会話と同じモデルを使用します（一貫性を求める場合に便利です）
* **省略**: 指定されていない場合、サブエージェント用に設定されたデフォルトモデル（`sonnet`）を使用します

<Note>
  `'inherit'`を使用することは、サブエージェントがメイン会話のモデル選択に適応し、セッション全体で一貫した機能と応答スタイルを確保する場合に特に便利です。
</Note>

### 利用可能なツール

サブエージェントには、Claude Codeの内部ツールのいずれかへのアクセスを許可できます。利用可能なツールの完全なリストについては、[ツールドキュメント](/ja/settings#tools-available-to-claude)を参照してください。

<Tip>
  **推奨:** `/agents`コマンドを使用してツールアクセスを変更します。これは、接続されたMCPサーバーツールを含むすべての利用可能なツールをリストする対話的インターフェースを提供し、必要なツールを選択しやすくします。
</Tip>

ツール設定には2つのオプションがあります：

* **`tools`フィールドを省略**してメインスレッドのすべてのツール（デフォルト）を継承します。MCPツールを含みます
* **個別のツールを指定**してカンマ区切りリストとしてより細かい制御を行います（手動または`/agents`経由で編集できます）

**MCPツール**: サブエージェントは設定されたMCPサーバーからのMCPツールにアクセスできます。`tools`フィールドを省略すると、サブエージェントはメインスレッドで利用可能なすべてのMCPツールを継承します。

## サブエージェントの管理

### /agentsコマンドの使用（推奨）

`/agents`コマンドは、サブエージェント管理用の包括的なインターフェースを提供します：

```
/agents
```

これにより、以下を実行できる対話的メニューが開きます：

* すべての利用可能なサブエージェント（組み込み、ユーザー、プロジェクト）を表示
* ガイド付きセットアップで新しいサブエージェントを作成
* ツールアクセスを含む既存のカスタムサブエージェントを編集
* カスタムサブエージェントを削除
* 重複が存在する場合、どのサブエージェントがアクティブかを確認
* **利用可能なツールの完全なリストで簡単にツール権限を管理**

### ファイルの直接管理

ファイルを直接操作してサブエージェントを管理することもできます：

```bash  theme={null}
# プロジェクトサブエージェントを作成
mkdir -p .claude/agents
echo '---
name: test-runner
description: Use proactively to run tests and fix failures
---

You are a test automation expert. When you see code changes, proactively run the appropriate tests. If tests fail, analyze the failures and fix them while preserving the original test intent.' > .claude/agents/test-runner.md

# ユーザーサブエージェントを作成
mkdir -p ~/.claude/agents
# ... サブエージェントファイルを作成
```

## サブエージェントを効果的に使用

### 自動委譲

Claude Codeは以下に基づいてタスクを積極的に委譲します：

* リクエスト内のタスク説明
* サブエージェント設定の`description`フィールド
* 現在のコンテキストと利用可能なツール

<Tip>
  より積極的なサブエージェント使用を促すために、`description`フィールドに「use PROACTIVELY」または「MUST BE USED」などのフレーズを含めます。
</Tip>

### 明示的な呼び出し

コマンドでサブエージェントに言及して、特定のサブエージェントをリクエストします：

```
> Use the test-runner subagent to fix failing tests
> Have the code-reviewer subagent look at my recent changes
> Ask the debugger subagent to investigate this error
```

## 組み込みサブエージェント

Claude Codeには、すぐに利用可能な組み込みサブエージェントが含まれています：

### Planサブエージェント

Planサブエージェントは、プランモード中に使用するために設計された特化した組み込みエージェントです。Claudeがプランモード（非実行モード）で動作している場合、Planサブエージェントを使用してコードベースに関する調査を実施し、プランを提示する前に情報を収集します。

**主な特性：**

* **モデル**: より有能な分析のためにSonnetを使用します
* **ツール**: コードベース探索用のRead、Glob、Grep、Bashツールにアクセスできます
* **目的**: ファイルを検索し、コード構造を分析し、コンテキストを収集します
* **自動呼び出し**: Claudeはプランモード中にコードベースを調査する必要がある場合、このエージェントを自動的に使用します

**動作方法：**
プランモード中にClaudeがプランを作成するためにコードベースを理解する必要がある場合、調査タスクをPlanサブエージェントに委譲します。これにより、エージェントの無限ネストを防ぎます（サブエージェントは他のサブエージェントを生成できません）。同時に、Claudeが必要なコンテキストを収集できます。

**シナリオ例：**

```
User: [In plan mode] Help me refactor the authentication module

Claude: Let me research your authentication implementation first...
[Internally invokes Plan subagent to explore auth-related files]
[Plan subagent searches codebase and returns findings]
Claude: Based on my research, here's my proposed plan...
```

<Tip>
  Planサブエージェントはプランモードでのみ使用されます。通常の実行モードでは、Claudeは汎用エージェントまたは作成した他のカスタムサブエージェントを使用します。
</Tip>

## サブエージェントの例

### コードレビュアー

```markdown  theme={null}
---
name: code-reviewer
description: Expert code review specialist. Proactively reviews code for quality, security, and maintainability. Use immediately after writing or modifying code.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards of code quality and security.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code is simple and readable
- Functions and variables are well-named
- No duplicated code
- Proper error handling
- No exposed secrets or API keys
- Input validation implemented
- Good test coverage
- Performance considerations addressed

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)

Include specific examples of how to fix issues.
```

### デバッガー

```markdown  theme={null}
---
name: debugger
description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
tools: Read, Edit, Bash, Grep, Glob
---

You are an expert debugger specializing in root cause analysis.

When invoked:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works

Debugging process:
- Analyze error messages and logs
- Check recent code changes
- Form and test hypotheses
- Add strategic debug logging
- Inspect variable states

For each issue, provide:
- Root cause explanation
- Evidence supporting the diagnosis
- Specific code fix
- Testing approach
- Prevention recommendations

Focus on fixing the underlying issue, not just symptoms.
```

### データサイエンティスト

```markdown  theme={null}
---
name: data-scientist
description: Data analysis expert for SQL queries, BigQuery operations, and data insights. Use proactively for data analysis tasks and queries.
tools: Bash, Read, Write
model: sonnet
---

You are a data scientist specializing in SQL and BigQuery analysis.

When invoked:
1. Understand the data analysis requirement
2. Write efficient SQL queries
3. Use BigQuery command line tools (bq) when appropriate
4. Analyze and summarize results
5. Present findings clearly

Key practices:
- Write optimized SQL queries with proper filters
- Use appropriate aggregations and joins
- Include comments explaining complex logic
- Format results for readability
- Provide data-driven recommendations

For each analysis:
- Explain the query approach
- Document any assumptions
- Highlight key findings
- Suggest next steps based on data

Always ensure queries are efficient and cost-effective.
```

## ベストプラクティス

* **Claudeで生成されたエージェントから始める**: 最初のサブエージェントをClaudeで生成してから、それを反復して個人のものにすることを強くお勧めします。このアプローチは最良の結果をもたらします。特定のニーズに合わせてカスタマイズできる堅実な基盤です。

* **焦点を絞ったサブエージェントを設計**: 1つのサブエージェントにすべてをさせようとするのではなく、単一で明確な責任を持つサブエージェントを作成します。これにより、パフォーマンスが向上し、サブエージェントがより予測可能になります。

* **詳細なプロンプトを作成**: システムプロンプトに特定の指示、例、制約を含めます。提供するガイダンスが多いほど、サブエージェントのパフォーマンスが向上します。

* **ツールアクセスを制限**: サブエージェントの目的に必要なツールのみを許可します。これにより、セキュリティが向上し、サブエージェントが関連するアクションに焦点を当てるのに役立ちます。

* **バージョン管理**: プロジェクトサブエージェントをバージョン管理にチェックインして、チームが協力して改善できるようにします。

## 高度な使用方法

### サブエージェントのチェーン

複雑なワークフローの場合、複数のサブエージェントをチェーンできます：

```
> First use the code-analyzer subagent to find performance issues, then use the optimizer subagent to fix them
```

### 動的サブエージェント選択

Claude Codeはコンテキストに基づいてインテリジェントにサブエージェントを選択します。最良の結果を得るために、`description`フィールドを具体的でアクション指向にします。

### 再開可能なサブエージェント

サブエージェントを再開して以前の会話を続けることができます。これは、複数の呼び出しにわたって続ける必要がある長時間実行される調査または分析タスクに特に役立ちます。

**動作方法：**

* 各サブエージェント実行には一意の`agentId`が割り当てられます
* エージェントの会話は別のトランスクリプトファイルに保存されます：`agent-{agentId}.jsonl`
* `resume`パラメータを使用して`agentId`を提供することで、以前のエージェントを再開できます
* 再開すると、エージェントは以前の会話から完全なコンテキストで続行します

**ワークフロー例：**

初期呼び出し：

```
> Use the code-analyzer agent to start reviewing the authentication module

[Agent completes initial analysis and returns agentId: "abc123"]
```

エージェントを再開：

```
> Resume agent abc123 and now analyze the authorization logic as well

[Agent continues with full context from previous conversation]
```

**ユースケース：**

* **長時間実行される調査**: 大規模なコードベース分析を複数のセッションに分割
* **反復的な改善**: コンテキストを失わずにサブエージェントの作業を継続的に改善
* **マルチステップワークフロー**: サブエージェントが関連するタスクを順序立てて実行し、コンテキストを維持

**技術的詳細：**

* エージェントトランスクリプトはプロジェクトディレクトリに保存されます
* 再開中にメッセージの重複を避けるため、記録は無効になります
* 同期エージェントと非同期エージェントの両方を再開できます
* `resume`パラメータは以前の実行からのエージェントIDを受け入れます

**プログラマティック使用：**

Agent SDKを使用しているか、AgentToolと直接対話している場合、`resume`パラメータを渡すことができます：

```typescript  theme={null}
{
  "description": "Continue analysis",
  "prompt": "Now examine the error handling patterns",
  "subagent_type": "code-analyzer",
  "resume": "abc123"  // Agent ID from previous execution
}
```

<Tip>
  後で再開したいタスクのエージェントIDを追跡します。Claude Codeはサブエージェントが作業を完了したときにエージェントIDを表示します。
</Tip>

## パフォーマンスに関する考慮事項

* **コンテキスト効率**: エージェントはメインコンテキストを保持するのに役立ち、より長いセッション全体を実現します
* **レイテンシー**: サブエージェントは呼び出されるたびにクリーンな状態で開始され、効果的に仕事をするために必要なコンテキストを収集する際にレイテンシーが追加される可能性があります。

## 関連ドキュメント

* [プラグイン](/ja/plugins) - プラグインを通じてカスタムエージェントでClaude Codeを拡張
* [スラッシュコマンド](/ja/slash-commands) - 他の組み込みコマンドについて学ぶ
* [設定](/ja/settings) - Claude Codeの動作を設定
* [フック](/ja/hooks) - イベントハンドラーでワークフローを自動化
