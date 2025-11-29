AIエージェントの未来は、数百、数千ものツール間でモデルがシームレスに連携する時代です。Git操作、ファイル操作、パッケージマネージャー、テストフレームワーク、デプロイメントパイプラインを統合するIDEアシスタント。Slack、GitHub、Google Drive、Jira、企業データベース、そして数十台のMCPサーバーを同時に接続する運用コーディネーター。

[効果的なエージェントを構築](https://www.anthropic.com/research/building-effective-agents)するには、すべての定義を事前にコンテキストに詰め込むことなく、無制限のツールライブラリを利用できる必要があります。MCP[でのコード実行](https://www.anthropic.com/engineering/code-execution-with-mcp)に関するブログ記事では、エージェントがリクエストを読み取るまでに、ツールの結果と定義で50,000以上のトークンが消費される場合があることについて説明しました。エージェントは、現在のタスクに関連するものだけを保持し、オンデマンドでツールを検出して読み込む必要があります。

エージェントには、コードからツールを呼び出す機能も必要です。自然言語ツールの呼び出しでは、各呼び出しに完全な推論パスが必要となり、中間結果は有用かどうかに関わらずコンテキスト内に蓄積されます。コードは、ループ、条件分岐、データ変換といったオーケストレーションロジックに最適です。エージェントには、タスクに応じてコード実行と推論を選択できる柔軟性が必要です。

エージェントは、スキーマ定義だけでなく、例からもツールの正しい使い方を学ぶ必要があります。JSONスキーマは構造的に有効なものを定義しますが、オプションパラメータを含めるタイミング、適切な組み合わせ、APIが期待する規則など、使用パターンを表現することはできません。

本日、これを可能にする 3 つの機能をリリースします。

-   **ツール検索ツール。**これにより、クロードは検索ツールを使用して、コンテキストウィンドウを消費することなく何千ものツールにアクセスできます。
-   **プログラムによるツール呼び出し**により、Claude はコード実行環境でツールを呼び出すことができ、モデルのコンテキスト ウィンドウへの影響を軽減できます。
-   **ツールの使用例**。特定のツールを効果的に使用する方法を示すための普遍的な基準を提供します。

社内テストでは、これらの機能によって、従来のツール利用パターンでは実現不可能だったものを構築できることが分かりました。例えば、**[Excel版Claudeは、](https://www.claude.com/claude-for-excel)**プログラムによるツール呼び出しを利用して、モデルのコンテキストウィンドウに過負荷をかけることなく、数千行に及ぶスプレッドシートの読み取りと変更を行っています。**[](https://www.claude.com/claude-for-excel)**

私たちの経験から、これらの機能により、Claude で構築できるものに新たな可能性が開かれると信じています。

<iframe frameborder="0" allowfullscreen="" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" title="Claude Opus 4.5がパズルゲームを解く" width="100%" height="100%" src="https://www.youtube-nocookie.com/embed/2MJDdzSXL74?autoplay=0&amp;mute=0&amp;controls=1&amp;origin=https%3A%2F%2Fwww.anthropic.com&amp;playsinline=1&amp;showinfo=0&amp;rel=0&amp;iv_load_policy=3&amp;modestbranding=1&amp;enablejsapi=1&amp;widgetid=1&amp;forigin=https%3A%2F%2Fwww.anthropic.com%2Fengineering%2Fadvanced-tool-use%3Fref%3Dblog.lai.so&amp;aoriginsup=1&amp;gporigin=https%3A%2F%2Fwww.youtube.com%2F&amp;vf=1" id="widget2" data-gtm-yt-inspected-13="true"></iframe>

### 課題

MCPツールの定義は重要なコンテキストを提供しますが、接続するサーバーが増えるにつれて、トークンの数も増える可能性があります。5台のサーバー構成を考えてみましょう。

-   GitHub: 35 ツール (約 26,000 トークン)
-   Slack: 11 ツール (約 21K トークン)
-   セントリー：ツール5個（約3Kトークン）
-   Grafana: 5 つのツール (約 3K トークン)
-   Splunk: 2 つのツール (約 2K トークン)

つまり、58個のツールが、会話が始まる前に約55,000トークンを消費していることになります。Jira（これだけで約17,000トークンを使用）などのサーバーを追加すると、すぐに100,000トークン以上のオーバーヘッドに近づきます。Anthropicでは、ツール定義が最適化前に134,000トークンを消費した例があります。

しかし、トークンコストだけが問題ではありません。最も一般的な失敗は、ツールの選択ミスやパラメータの誤りです。特に、ツール名が`notification-send-user`「vs.」のように似ている場合、その傾向が顕著です`notification-send-channel`。

### 私たちのソリューション

ツール検索ツールは、すべてのツール定義を事前に読み込むのではなく、オンデマンドでツールを検出します。Claude は、現在のタスクに実際に必要なツールのみを参照します。

![ツール検索ツール図](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2Ff359296f770706608901eadaffbff4ca0b67874c-1999x1125.png&w=3840&q=75)

_ツール検索ツールは、Claude の従来のアプローチの 122,800 トークンと比較して、191,300 トークンのコンテキストを保存します。_

従来のアプローチ:

-   すべてのツール定義が事前にロードされます（50 以上の MCP ツールに対して約 72K トークン）
-   会話履歴とシステムプロンプトが残りのスペースを奪い合う
-   総コンテキスト消費量: 作業開始前のトークン数: 約 77,000

ツール検索ツールを使用すると:

-   ツール検索ツールのみが事前にロードされます（約500トークン）
-   必要に応じてオンデマンドで検出されるツール（関連ツール 3～5 個、トークン数約 3,000 個）
-   総コンテキスト消費量: 約8.7Kトークン、コンテキストウィンドウの95%を維持

これにより、ツールライブラリ全体へのアクセスを維持しながら、トークン使用量を85%削減できます。社内テストでは、大規模なツールライブラリを使用した場合のMCP評価の精度が大幅に向上しました。ツール検索ツールを有効にした場合、Opus 4では49%から74%に、Opus 4.5では79.5%から88.1%に向上しました。

### ツール検索ツールの仕組み

ツール検索ツールを使用すると、Claude は事前にすべての定義を読み込むのではなく、動的にツールを検出できます。API にすべてのツール定義を提供しますが、ツールに マークを付けることで、`defer_loading: true`オンデマンドで検出できるようになります。遅延ツールは、最初は Claude のコンテキストに読み込まれません。Claude が参照できるのは、ツール検索ツール自体と、 マークが付いているツール`defer_loading: false`（最も重要で頻繁に使用されるツール）のみです。

クロードが特定の機能を必要とする場合、関連するツールを検索します。ツール検索ツールは一致するツールへの参照を返し、それらはクロードのコンテキストで完全な定義に展開されます。

たとえば、Claude が GitHub とやり取りする必要がある場合、「github」を検索して GitHub だけが読み込まれ`github.createPullRequest`、`github.listIssues`Slack、Jira、Google Drive などの 50 を超える他のツールは読み込まれません。

この方法により、Claude は実際に必要なツールに対してのみトークン コストを支払いながら、完全なツール ライブラリにアクセスできるようになります。

**プロンプトのキャッシュに関する注意：**ツール検索ツールは、遅延ツールが初期プロンプトから完全に除外されるため、プロンプトのキャッシュを中断しません。遅延ツールはClaudeが検索した後にのみコンテキストに追加されるため、システムプロンプトとコアツールの定義はキャッシュ可能なままです。

**実装：**

```
{<span></span>
  "tools": [<span></span>
    // Include a tool search tool (regex, BM25, or custom)<span></span>
    {"type": "tool_search_tool_regex_20251119", "name": "tool_search_tool_regex"},<span></span>
<span></span>
    // Mark tools for on-demand discovery<span></span>
    {<span></span>
      "name": "github.createPullRequest",<span></span>
      "description": "Create a pull request",<span></span>
      "input_schema": {...},<span></span>
      "defer_loading": true<span></span>
    }<span></span>
    // ... hundreds more deferred tools with defer_loading: true<span></span>
  ]<span></span>
}<span></span>
```

MCP サーバーの場合、使用頻度の高い特定のツールをロードしたまま、サーバー全体のロードを延期することができます。

```
{<span></span>
  "type": "mcp_toolset",<span></span>
  "mcp_server_name": "google-drive",<span></span>
  "default_config": {"defer_loading": true}, # defer loading the entire server<span></span>
  "configs": {<span></span>
    "search_files": {<span></span>
"defer_loading": false<span></span>
    }  // Keep most used tool loaded<span></span>
  }<span></span>
}
```

Claude 開発者プラットフォームでは、正規表現ベースおよび BM25 ベースの検索ツールがすぐに使用できますが、埋め込みやその他の戦略を使用してカスタム検索ツールを実装することもできます。

### ツール検索ツールを使用する場合

他のアーキテクチャ上の決定と同様に、ツール検索ツールの有効化にはトレードオフが伴います。この機能はツールの呼び出し前に検索ステップを追加するため、コンテキストの節約と精度の向上がレイテンシの増加を上回る場合に、最大のROIを実現します。

**次の場合に使用します:**

-   10Kトークン以上を消費するツール定義
-   ツール選択の精度に問題が発生する
-   複数のサーバーでMCPを利用したシステムを構築する
-   10以上のツールが利用可能

**以下の場合には効果が低くなります:**

-   小さなツールライブラリ（<10 ツール）
-   各セッションで頻繁に使用されるすべてのツール
-   ツール定義はコンパクト

### 課題

従来のツール呼び出しでは、ワークフローが複雑になるにつれて、次の 2 つの根本的な問題が発生します。

-   **中間結果によるコンテキスト汚染**：クロードが10MBのログファイルを分析してエラーパターンを調べる際、必要なのはエラー頻度のサマリーだけであるにもかかわらず、ファイル全体がコンテキストウィンドウに入ります。複数のテーブルにまたがる顧客データを取得する際、関連性に関わらずすべてのレコードがコンテキストに蓄積されます。こうした中間結果は膨大なトークンバジェットを消費し、重要な情報がコンテキストウィンドウから完全に排除されてしまう可能性があります。
-   **推論のオーバーヘッドと手動合成**：各ツールの呼び出しには、完全なモデル推論パスが必要です。結果を受け取った後、クロードはデータを「目視」して関連情報を抽出し、各要素がどのように組み合わさるかを推論し、次に何をすべきかを決定します。これらはすべて自然言語処理によって行われます。5つのツールを使用するワークフローでは、5つの推論パスに加え、クロードが各結果を解析し、値を比較し、結論を合成する作業が必要になります。これは時間がかかり、エラーが発生しやすい作業です。

### 私たちのソリューション

プログラムによるツール呼び出しにより、Claude は個々の API ラウンドトリップではなく、コードを通じてツールをオーケストレーションできます。Claude はツールを 1 つずつ呼び出し、その結果をそれぞれのコンテキストに返すのではなく、複数のツールを呼び出し、その出力を処理し、コンテキストウィンドウに実際に入力される情報を制御するコードを記述します。

クロードはコード作成に長けており、自然言語ツールの呼び出しではなくPythonでオーケストレーションロジックを記述することで、より信頼性が高く正確な制御フローを実現しています。ループ、条件分岐、データ変換、エラー処理はすべて、クロードの論理では暗黙的に記述されているのではなく、コード内で明示的に記述されています。

#### 例: 予算コンプライアンスチェック

一般的なビジネスタスクについて考えてみましょう: 「第 3 四半期の出張予算を超過したのはどのチーム メンバーか?」

利用できるツールは 3 つあります。

-   `get_team_members(department)`\- IDとレベルを含むチームメンバーリストを返します
-   `get_expenses(user_id, quarter)`\- ユーザーの経費明細を返します
-   `get_budget_by_level(level)`\- 従業員レベルの予算制限を返します

**従来のアプローチ**：

-   チームメンバーを取得 → 20人
-   各人の第 3 四半期の経費を取得します → 20 回のツール呼び出しで、それぞれ 50～100 の項目 (フライト、ホテル、食事、領収書) が返されます
-   従業員レベル別に予算制限を取得する
-   これらすべてがクロードのコンテキストに入ります: 2,000 以上の経費明細 (50 KB 以上)
-   クロードは各人の支出を手作業で合計し、予算を調べ、支出を予算限度額と比較します
-   モデルへのラウンドトリップの増加、コンテキストの消費量の増加

**プログラムによるツール呼び出しの場合**:

各ツールの結果をクロードに返す代わりに、クロードはワークフロー全体を制御するPythonスクリプトを作成します。このスクリプトはコード実行ツール（サンドボックス環境）内で実行され、ツールからの結果が必要なときに一時停止します。ツールの結果をAPI経由で返すと、モデルではなくスクリプトによって処理されます。スクリプトは実行を継続し、クロードは最終的な出力のみを参照します。

![プログラムによるツール呼び出しフロー](https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F65737d69a3290ed5c1f3c3b8dc873645a9dcc2eb-1999x1491.png&w=3840&q=75)

プログラムによるツール呼び出しにより、Claude は個別の API ラウンドトリップではなくコードを通じてツールを調整できるようになり、並列ツール実行が可能になります。

予算コンプライアンス タスクに対する Claude のオーケストレーション コードは次のようになります。

```
team = await get_team_members("engineering")<span></span>
<span></span>
# Fetch budgets for each unique level<span></span>
levels = list(set(m["level"] for m in team))<span></span>
budget_results = await asyncio.gather(*[<span></span>
    get_budget_by_level(level) for level in levels<span></span>
])<span></span>
<span></span>
# Create a lookup dictionary: {"junior": budget1, "senior": budget2, ...}<span></span>
budgets = {level: budget for level, budget in zip(levels, budget_results)}<span></span>
<span></span>
# Fetch all expenses in parallel<span></span>
expenses = await asyncio.gather(*[<span></span>
    get_expenses(m["id"], "Q3") for m in team<span></span>
])<span></span>
<span></span>
# Find employees who exceeded their travel budget<span></span>
exceeded = []<span></span>
for member, exp in zip(team, expenses):<span></span>
    budget = budgets[member["level"]]<span></span>
    total = sum(e["amount"] for e in exp)<span></span>
    if total &gt; budget["travel_limit"]:<span></span>
        exceeded.append({<span></span>
            "name": member["name"],<span></span>
            "spent": total,<span></span>
            "limit": budget["travel_limit"]<span></span>
        })<span></span>
<span></span>
print(json.dumps(exceeded))
```

クロードのコンテキストには、最終結果、つまり予算を超過した2～3人のみが反映されます。2,000件を超える明細項目、中間集計、予算参照はクロードのコンテキストには影響を与えないため、200KBもの経費生データからわずか1KBの結果にまで消費量が削減されます。

効率性は大きく向上します。

-   **トークンの節約**：中間結果をクロードのコンテキストから切り離すことで、PTCはトークン消費量を大幅に削減しました。平均使用量は43,588トークンから27,297トークンに減少し、複雑な調査タスクでは37%の削減となりました。
-   **レイテンシの削減**：APIのラウンドトリップごとにモデル推論（数百ミリ秒から数秒）が必要です。Claudeが20以上のツール呼び出しを単一のコードブロックでオーケストレーションすることで、19以上の推論パスを削減できます。APIはツールの実行を毎回モデルに戻ることなく処理します。
-   **精度の向上**：明示的なオーケストレーションロジックを記述することで、Claudeは複数のツールの結果を自然言語で処理する場合よりもエラーが少なくなりました。内部知識検索は25.6%から28.5%に、[GIAベンチマークは](https://arxiv.org/abs/2311.12983)46.5%から51.2%に向上しました。

生産ワークフローには、複雑なデータ、条件付きロジック、そしてスケールが必要な操作が伴います。Programmatic Tool Calling を使用すると、Claude はこれらの複雑さをプログラムで処理しながら、生データの処理ではなく実用的な結果に重点を置くことができます。

### プログラムによるツール呼び出しの仕組み

#### 1\. ツールをコードから呼び出し可能としてマークする

ツールに code\_execution を追加し、プログラムによる実行をオプトインするツールに allowed\_callers を設定します。

```
{<span></span>
  "tools": [<span></span>
    {<span></span>
      "type": "code_execution_20250825",<span></span>
      "name": "code_execution"<span></span>
    },<span></span>
    {<span></span>
      "name": "get_team_members",<span></span>
      "description": "Get all members of a department...",<span></span>
      "input_schema": {...},<span></span>
      "allowed_callers": ["code_execution_20250825"] # opt-in to programmatic tool calling<span></span>
    },<span></span>
    {<span></span>
      "name": "get_expenses",<span></span>
 ...<span></span>
    },<span></span>
    {<span></span>
      "name": "get_budget_by_level",<span></span>
...<span></span>
    }<span></span>
  ]<span></span>
}
```

API はこれらのツール定義を、Claude が呼び出せる Python 関数に変換します。

#### 2\. クロードがオーケストレーションコードを書く

ツールを 1 つずつリクエストする代わりに、Claude は Python コードを生成します。

```
{<span></span>
  "type": "server_tool_use",<span></span>
  "id": "srvtoolu_abc",<span></span>
  "name": "code_execution",<span></span>
  "input": {<span></span>
    "code": "team = get_team_members('engineering')\n..." # the code example above<span></span>
  }<span></span>
}
```

#### 3\. ツールはクロードのコンテキストにヒットせずに実行される

コードが get\_expenses() を呼び出すと、呼び出し元フィールドを含むツール要求を受け取ります。

```
{<span></span>
  "type": "tool_use",<span></span>
  "id": "toolu_xyz",<span></span>
  "name": "get_expenses",<span></span>
  "input": {"user_id": "emp_123", "quarter": "Q3"},<span></span>
  "caller": {<span></span>
    "type": "code_execution_20250825",<span></span>
    "tool_id": "srvtoolu_abc"<span></span>
  }<span></span>
}
```

結果を提供すると、それはClaudeのコンテキストではなく、コード実行環境で処理されます。このリクエストとレスポンスのサイクルは、コード内のツール呼び出しごとに繰り返されます。

#### 4\. 最終出力のみがコンテキストに入る

コードの実行が終了すると、コードの結果のみが Claude に返されます。

```
{<span></span>
  "type": "code_execution_tool_result",<span></span>
  "tool_use_id": "srvtoolu_abc",<span></span>
  "content": {<span></span>
    "stdout": "[{\"name\": \"Alice\", \"spent\": 12500, \"limit\": 10000}...]"<span></span>
  }<span></span>
}
```

クロードが目にするのはこれだけで、途中で処理された 2,000 件を超える経費明細は見えません。

### プログラムによるツール呼び出しを使用する場合

プログラムによるツール呼び出しは、ワークフローにコード実行ステップを追加します。この追加オーバーヘッドは、トークンの節約、レイテンシの改善、そして精度の向上が顕著であれば、大きな効果を発揮します。

**最も効果的な場合:**

-   集計や要約のみが必要な大規模データセットの処理
-   3 つ以上の依存ツール呼び出しを含む複数ステップのワークフローを実行する
-   クロードが見る前にツールの結果をフィルタリング、並べ替え、または変換する
-   中間データがクロードの推論に影響を与えないタスクの処理
-   多数のアイテムにまたがる並列操作の実行（たとえば、50 個のエンドポイントのチェック）

**以下の場合には効果が低くなります:**

-   シンプルな単一ツール呼び出しの作成
-   クロードがすべての中間結果を確認し、推論する必要があるタスクに取り組んでいます
-   短い応答でクイック検索を実行する

### 課題

JSON スキーマは、構造 (型、必須フィールド、許可された列挙型) を定義するのに優れていますが、オプションのパラメーターをいつ含めるか、どのような組み合わせが意味をなすか、API がどのような規則を期待するかといった使用パターンを表現することはできません。

サポート チケット API を検討します。

```
{<span></span>
  "name": "create_ticket",<span></span>
  "input_schema": {<span></span>
    "properties": {<span></span>
      "title": {"type": "string"},<span></span>
      "priority": {"enum": ["low", "medium", "high", "critical"]},<span></span>
      "labels": {"type": "array", "items": {"type": "string"}},<span></span>
      "reporter": {<span></span>
        "type": "object",<span></span>
        "properties": {<span></span>
          "id": {"type": "string"},<span></span>
          "name": {"type": "string"},<span></span>
          "contact": {<span></span>
            "type": "object",<span></span>
            "properties": {<span></span>
              "email": {"type": "string"},<span></span>
              "phone": {"type": "string"}<span></span>
            }<span></span>
          }<span></span>
        }<span></span>
      },<span></span>
      "due_date": {"type": "string"},<span></span>
      "escalation": {<span></span>
        "type": "object",<span></span>
        "properties": {<span></span>
          "level": {"type": "integer"},<span></span>
          "notify_manager": {"type": "boolean"},<span></span>
          "sla_hours": {"type": "integer"}<span></span>
        }<span></span>
      }<span></span>
    },<span></span>
    "required": ["title"]<span></span>
  }<span></span>
}
```

スキーマは有効なものを定義しますが、重要な質問には答えません。

-   **形式のあいまいさ:**`due_date`「2024-11-06」、「Nov 6, 2024」、または「2024-11-06T00:00:00Z」のどれを使用する必要がありますか?
-   **ID 規則:**`reporter.id` UUID は「USR-12345」ですか、それとも単に「12345」ですか?
-   **ネストされた構造の使用:** Claude はいつデータを入力する必要がありますか`reporter.contact`?
-   **パラメータの相関関係:**`escalation.level`と優先度はどのように`escalation.sla_hours`関係しますか?

これらの曖昧さにより、ツール呼び出しが不正になったり、パラメータの使用が一貫していなかったりする可能性があります。

### 私たちのソリューション

ツール使用例を使用すると、ツール定義内で直接ツール呼び出しのサンプルを提供できます。スキーマだけに頼るのではなく、具体的な使用パターンをClaudeに示します。

```
{<span></span>
    "name": "create_ticket",<span></span>
    "input_schema": { /* same schema as above */ },<span></span>
    "input_examples": [<span></span>
      {<span></span>
        "title": "Login page returns 500 error",<span></span>
        "priority": "critical",<span></span>
        "labels": ["bug", "authentication", "production"],<span></span>
        "reporter": {<span></span>
          "id": "USR-12345",<span></span>
          "name": "Jane Smith",<span></span>
          "contact": {<span></span>
            "email": "jane@acme.com",<span></span>
            "phone": "+1-555-0123"<span></span>
          }<span></span>
        },<span></span>
        "due_date": "2024-11-06",<span></span>
        "escalation": {<span></span>
          "level": 2,<span></span>
          "notify_manager": true,<span></span>
          "sla_hours": 4<span></span>
        }<span></span>
      },<span></span>
      {<span></span>
        "title": "Add dark mode support",<span></span>
        "labels": ["feature-request", "ui"],<span></span>
        "reporter": {<span></span>
          "id": "USR-67890",<span></span>
          "name": "Alex Chen"<span></span>
        }<span></span>
      },<span></span>
      {<span></span>
        "title": "Update API documentation"<span></span>
      }<span></span>
    ]<span></span>
  }
```

これら 3 つの例から、クロードは次のことを学びます。

-   **フォーマット規則**: 日付はYYYY-MM-DD、ユーザーIDはUSR-XXXXX、ラベルはケバブケースを使用します
-   **ネストされた構造パターン**: ネストされた連絡先オブジェクトを使用してレポーターオブジェクトを構築する方法
-   **オプションパラメータの相関関係**: 重大なバグには完全な連絡先情報と厳しいSLAによるエスカレーションがあります。機能リクエストには報告者がいますが、連絡先/エスカレーションはありません。内部タスクにはタイトルのみがあります。

弊社の社内テストでは、ツールの使用例により、複雑なパラメータ処理の精度が 72% から 90% に向上しました。

### ツールの使用例

ツール使用例はツール定義にトークンを追加するため、精度の向上が追加コストを上回る場合に最も価値があります。

**最も効果的な場合:**

-   有効な JSON が正しい使用法を意味しない複雑なネスト構造
-   多くのオプションパラメータと包含パターンを持つツールが重要
-   スキーマに取り込まれていないドメイン固有の規則を持つ API
-   どちらを使用するかを明確にする例がある類似ツール（例：`create_ticket`vs `create_incident`）

**以下の場合には効果が低くなります:**

-   使い方が明らかなシンプルな単一パラメータツール
-   クロードがすでに理解しているURLやメールなどの標準形式
-   検証に関する懸念はJSONスキーマ制約によってより適切に処理されます

## ベストプラクティス

現実世界で行動するエージェントを構築するには、スケール、複雑性、そして精度を同時に処理する必要があります。これら3つの機能は連携して、ツール使用ワークフローにおけるさまざまなボトルネックを解決します。ここでは、これらを効果的に組み合わせる方法をご紹介します。

### 戦略的に機能を重ねる

すべてのエージェントが特定のタスクで3つの機能すべてを使用する必要はありません。まずは最大のボトルネックから始めましょう。

-   ツール定義によるコンテキストの肥大化 → ツール検索ツール
-   コンテキストを汚染する大きな中間結果 → プログラムによるツール呼び出し
-   パラメータエラーと不正な呼び出し → ツールの使用例

この重点的なアプローチにより、事前に複雑さを追加するのではなく、エージェントのパフォーマンスを制限する特定の制約に対処できます。

必要に応じて追加機能を追加してください。これらは互いに補完し合っており、ツール検索ツールは適切なツールの検出を、プログラムによるツール呼び出しは効率的な実行を、ツール使用例は正しい呼び出しを保証します。

### より良い発見のためにツール検索ツールを設定する

ツールの検索は名前と説明と照合されるため、明確で説明的な定義によって検出の精度が向上します。

```
// Good<span></span>
{<span></span>
    "name": "search_customer_orders",<span></span>
    "description": "Search for customer orders by date range, status, or total amount. Returns order details including items, shipping, and payment info."<span></span>
}<span></span>
<span></span>
// Bad<span></span>
{<span></span>
    "name": "query_db_orders",<span></span>
    "description": "Execute order query"<span></span>
}
```

利用可能なものをクロードが把握できるように、システム プロンプト ガイダンスを追加します。

```
You have access to tools for Slack messaging, Google Drive file management, <span></span>
Jira ticket tracking, and GitHub repository operations. Use the tool search <span></span>
to find specific capabilities.
```

最もよく使う3～5個のツールを常に起動し、残りのツールは後回しにしましょう。これにより、よく使う操作への即時アクセスと、その他のツールへのオンデマンドの検出を両立できます。

### 正しく実行するためにプログラムによるツール呼び出しを設定する

クロードはツールの出力を解析するコードを書くので、戻り値の形式を明確に文書化してください。これにより、クロードは正しい解析ロジックを記述できるようになります。

```
{<span></span>
    "name": "get_orders",<span></span>
    "description": "Retrieve orders for a customer.<span></span>
Returns:<span></span>
    List of order objects, each containing:<span></span>
    - id (str): Order identifier<span></span>
    - total (float): Order total in USD<span></span>
    - status (str): One of 'pending', 'shipped', 'delivered'<span></span>
    - items (list): Array of {sku, quantity, price}<span></span>
    - created_at (str): ISO 8601 timestamp"<span></span>
}
```

プログラムによるオーケストレーションのメリットを享受できるオプトイン ツールについては、以下を参照してください。

-   並列実行（独立した操作）できるツール
-   再試行しても安全な操作（べき等性）

### パラメータ精度のためのツール使用例の設定

行動の明確さを示す例を作成します。

-   現実的なデータ（実際の都市名、妥当な価格、「文字列」や「値」ではなく）を使用する
-   最小限、部分的、完全な仕様パターンで多様性を示す
-   簡潔にまとめる: ツールごとに1～5個の例
-   曖昧さに焦点を当てる（スキーマから正しい使用法が明らかでない場合にのみ例を追加する）

## はじめる

これらの機能はベータ版でご利用いただけます。有効にするには、ベータヘッダーを追加し、必要なツールを組み込んでください。

```
client.beta.messages.create(<span></span>
    betas=["advanced-tool-use-2025-11-20"],<span></span>
    model="claude-sonnet-4-5-20250929",<span></span>
    max_tokens=4096,<span></span>
    tools=[<span></span>
        {"type": "tool_search_tool_regex_20251119", "name": "tool_search_tool_regex"},<span></span>
        {"type": "code_execution_20250825", "name": "code_execution"},<span></span>
        # Your tools with defer_loading, allowed_callers, and input_examples<span></span>
    ]<span></span>
)
```

詳細な API ドキュメントと SDK の例については、以下をご覧ください。

-   [](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)ツール検索ツールの[ドキュメント](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)と[クック](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)[ブック](https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/tool_search_with_embeddings.ipynb)
-   [](https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling)プログラムによるツール呼び出しの[ドキュメント](https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling)と[クックブック](https://github.com/anthropics/claude-cookbooks/blob/main/tool_use/programmatic_tool_calling_ptc.ipynb)
-   [](https://platform.claude.com/docs/en/agents-and-tools/tool-use/implement-tool-use#providing-tool-use-examples)ツールの使用例の[ドキュメント](https://platform.claude.com/docs/en/agents-and-tools/tool-use/implement-tool-use#providing-tool-use-examples)

これらの機能により、ツールの使用は単純な関数呼び出しからインテリジェントなオーケストレーションへと移行します。エージェントが数十のツールと大規模なデータセットにまたがるより複雑なワークフローに取り組むようになると、動的な検出、効率的な実行、そして信頼性の高い呼び出しが基盤となります。

私たちはあなたが何を構築するかを見るのを楽しみにしています。

## 謝辞

Bin Wuが執筆し、Adam Jones、Artur Renault、Henry Tay、Jake Noble、Nathan McCandlish、Noah Picard、Sam Jiang、そしてClaude Developer Platformチームの協力を得ました。本研究は、Chris Gorgolewski、Daniel Jiang、Jeremy Fox、Mike Lambertによる基礎研究に基づいています。また、[Joel PobarのLLMVM](https://github.com/9600dev/llmvm)、[CloudflareのCode Mode](https://blog.cloudflare.com/code-mode/)、そして[Code Execution as MCP](https://www.anthropic.com/engineering/code-execution-with-mcp)など、AIエコシステム全体からインスピレーションを得ました。Andy Schumeister、Hamish Kerr、Keir Bradwell、Matt Bleifer、Molly Vorwerckのサポートに深く感謝いたします。