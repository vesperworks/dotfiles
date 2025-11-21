---
created: None
updated: None
---
# Claude CodeにおけるClaude SkillsとSubAgentsの使い分けと併用を理解する

![rw-book-cover](https://res.cloudinary.com/zenn/image/upload/s--2a6czZ_O--/c_fit%2Cg_north_west%2Cl_text:notosansjp-medium.otf_55:Claude%2520Code%25E3%2581%25AB%25E3%2581%258A%25E3%2581%2591%25E3%2582%258BClaude%2520Skills%25E3%2581%25A8SubAgents%25E3%2581%25AE%25E4%25BD%25BF%25E3%2581%2584%25E5%2588%2586%25E3%2581%2591%25E3%2581%25A8%25E4%25BD%25B5%25E7%2594%25A8%25E3%2582%2592%25E7%2590%2586%25E8%25A7%25A3%25E3%2581%2599%25E3%2582%258B%2Cw_1010%2Cx_90%2Cy_100/g_south_west%2Cl_text:notosansjp-medium.otf_37:nogu%2Cx_203%2Cy_121/g_south_west%2Ch_90%2Cl_fetch:aHR0cHM6Ly9zdG9yYWdlLmdvb2dsZWFwaXMuY29tL3plbm4tdXNlci11cGxvYWQvYXZhdGFyLzhhYjVjZTI5ZGYuanBlZw==%2Cr_max%2Cw_90%2Cx_87%2Cy_95/v1627283836/default/og-base-w1200-v2.png?_a=BACAGSGT)

## Metadata
- Author: [[Zenn]]
- Full Title: Claude CodeにおけるClaude SkillsとSubAgentsの使い分けと併用を理解する
- Category: #articles
- Summary: ClaudeのSkillsは再利用できる専門知識の「教科書」で、必要なときだけ中身を読み込みます。  
SubAgentsは独立した実行環境を持つ「専門チーム」で、並列処理や権限分離が可能です。  
推奨はSubAgentからSkillsを呼び出す構成で、コンテキスト効率と保守性が高まります。
- URL:
[https://zenn.dev/nogu66/articles/claude-code-think-abount-skills-and-subagent](https://zenn.dev/nogu66/articles/claude-code-think-abount-skills-and-subagent)
[[]]

## Full Document
####  はじめに

Claude CodeやClaude APIを使っていて、こんな疑問を持ったことはありませんか？

* 「SkillsとSubAgents、どっちを使えばいいの？」
* 「両方使うなら、どう組み合わせるのが効率的？」
* 「Skillsのコンテキスト効率がいいって、具体的に何がすごいの？」

この記事では、SkillsとSubAgentsの違いと、効果的な使い分け・連携パターンを解説します。

#####  この記事で得られること

* SkillsとSubAgentsの基本概念が理解できる
* Progressive Disclosure（段階的開示）の仕組みが分かる
* 公式推奨の連携パターン（SubAgent → Skills）が理解できる
* 実務での使い分け指針が明確になる

#####  この記事で扱わないこと

* Skills、SubAgentsの具体的な作成手順
* 実装コードの詳細

**対象読者**：ClaudeのSkillsやSubAgentsを使い始めた方、または使い分けに悩んでいる開発者を想定しています。

####  SkillsとSubAgentとは？

本題に入る前に、SkillsとSubAgentの基本について理解しましょう。

#####  Claude Skills とは

**Skillsは、Claudeに特定分野の専門知識を提供する「再利用可能な学習教材」です。**

公式の定義では、「Claudeがタスクに関連したタイミングで動的に検出・読み込みする指示、スクリプト、リソースを含むフォルダ」とされています。Excelスプレッドシートの操作から組織のブランドガイドラインの遵守まで、特定の分野における専門知識をClaudeに提供する、専門的なトレーニングマニュアルのようなものです。

![Claude Skill](https://res.cloudinary.com/zenn/image/fetch/s--gTZdvrku--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_1200/https://storage.googleapis.com/zenn-user-upload/deployed-images/8d97d8f90eb5cf1a4d870e4b.png%3Fsha%3D69c734afb9784db266de2d98368c57aa56fa61e6)Claude Skill
**Skillsの主な特徴**：

* **再利用可能**：複数の会話やプロジェクト全体で共有できる
* **段階的読み込み**：必要な時だけ詳細を読み込む（Progressive Disclosure）
* **専門知識の保持**：組織のガイドライン、ドメイン専門知識などを保存

詳しくは、こちらをご覧ください。

#####  SubAgents とは

**SubAgentsは、独立したコンテキストで特定タスクを処理する「専門家ユニット」です。**

独自のコンテキストウィンドウ、カスタムシステムプロンプト、特定のツール権限を持つ専門的なAIアシスタントと考えてください。Claude CodeやClaudeエージェントSDKで利用でき、個別のタスクを独立して処理します。

![SubAgent](https://res.cloudinary.com/zenn/image/fetch/s--ZVOGIvVd--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_1200/https://storage.googleapis.com/zenn-user-upload/deployed-images/1e5be3a4e1128e03e997fc01.png%3Fsha%3Dda7809c13c05048004dbc139c116b764ed4cd648)
**SubAgentsの主な特徴**：

* **独自の権限**：メインエージェントと異なるツール権限を設定可能
* **独立実行**：個別のコンテキストで独立して動作
* **並列処理**：複数のSubAgentsが同時にタスクを実行可能

詳しくは、こちらをご覧ください。

#####  一言で言うと

* **Skills** = 再利用可能な専門知識（ポータブルな教科書）
* **SubAgents** = 独立した専門家ユニット（特定タスクを担当する専門チーム）

####  なぜSkillsとSubAgentsの使い分けが重要なのか

基本を理解したところで、なぜ使い分けが重要なのか見ていきましょう。

Claudeでエージェントシステムを構築する際、多くの開発者が以下のような課題に直面します：

#####  コンテキストウィンドウの浪費

すべての専門知識をメインの会話に詰め込むと、トークン数が膨大になり、コストとレスポンス速度に影響します。

#####  再利用性の低さ

同じような専門知識を複数のエージェントで使いたい場合、それぞれにコピー＆ペーストするのは非効率的です。

#####  責任分離の不明確さ

「タスク実行」と「専門知識の提供」が混在すると、システムの保守性が低下します。

####  SkillsとSubAgentsの設計思想を理解する

Claude公式は、明確な使い分け指針を提示しています。

#####  Skillsの本質：「専門知識の保持」

Skillsは**段階的な開示**という設計を採用しています。

######  スキルの読み込む

![スキルの読み込み](https://res.cloudinary.com/zenn/image/fetch/s--hUIbLTvH--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_1200/https://storage.googleapis.com/zenn-user-upload/deployed-images/54c031387b1851c0a7f1dc60.png%3Fsha%3D27cd4d6e6b1fad3fdb9ae8bdb3e22bda46852220)
重要なのは、エージェント側には「**スキルの名前**」しか置かず、必要な時だけ中身を読み込みます。これにより、**無駄なコンテキスト消費**を防ぎます。

#####  SubAgentsの本質：「独立したタスク実行環境」

SubAgentsは以下の特徴を持つ独立した実行環境です：

* **独自のツール権限**：メインエージェントと異なる権限を設定可能
* **コンテキスト分離**：メインの会話から独立した専用コンテキスト
* **並列実行**：複数のSubAgentsを同時に動かせる

![独立したテスク実行環境](https://res.cloudinary.com/zenn/image/fetch/s--nq8QkCJ9--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_1200/https://storage.googleapis.com/zenn-user-upload/deployed-images/352f37227a6acd9d2bfc726b.png%3Fsha%3D5ea3a6278bd87aac0e43c384085bb97b64a23c14)
直近で申し訳ありませんが、11/22（土）の打ち合わせ、私用のため23（日）以外でリスケさせていただきたいです。  

 の方の都合が悪いようでしたら、最悪欠席とさせてください。

重要なのは、SubAgentsの「**独立した環境**」が強みなので、そこでSkillsを呼び出すことで効果が最大化されます。

####  スキル vs サブエージェント

公式の指針をもとに、実務での判断フローを整理します：

#####  スキルの使用

公式のスキルを選択する指針は以下の通りです。

>  スキルを使用するのは、どのClaudeインスタンスでも読み込んで使用できる機能が必要な場合です。スキルはトレーニング教材のようなもので、あらゆる会話においてClaudeが特定のタスクをより効率的に実行できるようにします。
> 
>  

つまり、以下のようなときに選択します。

* 複数のエージェントや会話で同じ専門知識が必要
* データ分析フレームワークや評価基準など、ロジックが主体
* 頻繁に更新される可能性がある知識体系

具体的には、以下のような場面での使用が考えられると思います。

* コードレビューの評価基準
* データ分析の手法・フレームワーク
* 業界特有の専門知識

#####  サブエージェントの使用

公式のサブエージェント選択する指針は以下の通りです。

>  サブエージェントを使用するのは、特定の目的のために設計された、ワークフローを独立して処理する完全な自己完結型エージェントが必要な場合です。サブエージェントは、独自のコンテキストとツール権限を持つ専門の従業員のようなものです。
> 
>  

つまり、以下のようなときに選択します。

* 独立したタスクとして並列実行したい
* メインエージェントと異なるツール権限が必要
* コンテキストを分離して管理したい
* 大規模データの並列処理
* 外部API呼び出しを伴う調査タスク
* セキュリティ上、権限を制限したい処理

#####  スキルとサブエージェントの併用

また、以下のようなケースでの併用が推奨されています。

>  専門知識を持つサブエージェントが必要な場合。例えば、コードレビューサブエージェントは、言語固有のベストプラクティスにスキルを使用することで、サブエージェントの独立性とスキルの移植性の高い専門知識を組み合わせることができます。
> 
>  

つまり、以下のようなときに 併用します。

* 専門知識を持ったエージェントを複数並列実行したい
* 再利用可能な知識とタスク実行を分離したい

具体的には、以下のような場面での使用が考えられると思います。

![スキルとサブエージェントの併用](https://res.cloudinary.com/zenn/image/fetch/s--z-7t4_zj--/c_limit%2Cf_auto%2Cfl_progressive%2Cq_auto%2Cw_1200/https://storage.googleapis.com/zenn-user-upload/deployed-images/8b41bde00707dde46181a6a3.png%3Fsha%3Da6c418f8c176ab39d90b13d7c90e489f11b4762a)
* SubAgent A (市場調査) → Skill (分析フレームワーク) を呼び出し
* SubAgent B (競合分析) → 同じSkill (分析フレームワーク) を呼び出し
* SubAgent C (トレンド分析) → 同じSkill (分析フレームワーク) を呼び出し

#####  なぜSubAgentからSkillsを呼び出すのか？

1. **コンテキストの効率化**：SubAgentの独立環境内でのみSkillsを展開
2. **再利用性の向上**：同じSkillを複数のSubAgentで共有
3. **責任の明確化**：
	* SubAgents = タスク実行エンジン
	* Skills = 専門知識データベース

####  実践例：研究エージェントシステム

公式ブログで紹介されている研究エージェントの構成を見てみましょう：

```
# 多層アーキテクチャの例
- Project: "研究プロジェクト全体の背景と目標"

- MCP:
  - Brave Search（Web検索）
  - arXiv（論文検索）
  - データベース接続

- Skills:
  - "学術論文分析フレームワーク"
  - "統計分析手法"
  - "引用評価基準"

- SubAgents:
  - 論文検索エージェント（Skillsで分析）
  - データ収集エージェント（Skillsで評価）
  - レポート生成エージェント（Skillsで構造化）

```

**この設計の利点**：

1. **効率的なコンテキスト管理**：3つのSubAgentが同じSkillsを共有し、重複を排除
2. **並列処理**：各SubAgentが独立して動作し、処理速度を向上
3. **保守性**：分析フレームワーク（Skills）の更新が全SubAgentに即座に反映

####  コンテキスト効率の具体的な数値

Progressive Disclosureがどれだけ効率的か、数値で見てみましょう：

```
【従来の方法】全てをメインプロンプトに含める
- 専門知識A: 5000トークン
- 専門知識B: 5000トークン
- 専門知識C: 5000トークン
合計: 15,000トークン（常に消費）

【Skillsを使う方法】必要な時だけ読み込む
- Skillメタデータ × 3: 300トークン（常に消費）
- 必要なSkillの詳細: 5000トークン（使う時だけ）
平均消費: 5,300トークン（約65%削減）

```

####  まとめ

SkillsとSubAgentsの使い分けは、以下の本質を理解することが重要です：

* **Skills：専門知識の保持**（ポータブルで再利用可能）
* **SubAgents：タスク実行環境**（独立性と並列性）
* **推奨パターン：SubAgentからSkillsを呼び出す**（両者の強みを活かす）

段階的な読み込みにより、Skillsはコンテキスト効率に優れた設計になっています。この特性を活かし、SubAgentsの独立した実行環境でSkillsを呼び出すことで、スケーラブルで保守性の高いエージェントシステムを構築できます。

####  Xフォローしてね

Xではより頻繁に情報発信していますので、フォローしていただけると励みになります。

####  参考文献
