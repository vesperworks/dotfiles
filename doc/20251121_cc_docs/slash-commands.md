# スラッシュコマンド

> インタラクティブセッション中にスラッシュコマンドを使用してClaudeの動作を制御します。

## 組み込みスラッシュコマンド

| コマンド                      | 目的                                                                              |
| :------------------------ | :------------------------------------------------------------------------------ |
| `/add-dir`                | 追加の作業ディレクトリを追加                                                                  |
| `/agents`                 | 特殊なタスク用のカスタムAIサブエージェントを管理                                                       |
| `/bashes`                 | バックグラウンドタスクをリストおよび管理                                                            |
| `/bug`                    | バグを報告（会話をAnthropicに送信）                                                          |
| `/clear`                  | 会話履歴をクリア                                                                        |
| `/compact [instructions]` | オプションのフォーカス指示付きで会話をコンパクト化                                                       |
| `/config`                 | 設定インターフェース（設定タブ）を開く                                                             |
| `/context`                | 現在のコンテキスト使用状況をカラーグリッドで可視化                                                       |
| `/cost`                   | トークン使用統計を表示（サブスクリプション固有の詳細については[コスト追跡ガイド](/ja/costs#using-the-cost-command)を参照） |
| `/doctor`                 | Claude Codeインストールの健全性をチェック                                                      |
| `/exit`                   | REPLを終了                                                                         |
| `/export [filename]`      | 現在の会話をファイルまたはクリップボードにエクスポート                                                     |
| `/help`                   | 使用方法ヘルプを取得                                                                      |
| `/hooks`                  | ツールイベント用のフック設定を管理                                                               |
| `/init`                   | CLAUDE.mdガイドでプロジェクトを初期化                                                         |
| `/login`                  | Anthropicアカウントを切り替え                                                             |
| `/logout`                 | Anthropicアカウントからサインアウト                                                          |
| `/mcp`                    | MCPサーバー接続とOAuth認証を管理                                                            |
| `/memory`                 | CLAUDE.mdメモリファイルを編集                                                             |
| `/model`                  | AIモデルを選択または変更                                                                   |
| `/output-style [style]`   | 出力スタイルを直接設定するか、選択メニューから設定                                                       |
| `/permissions`            | [権限](/ja/iam#configuring-permissions)を表示または更新                                   |
| `/pr_comments`            | プルリクエストコメントを表示                                                                  |
| `/privacy-settings`       | プライバシー設定を表示および更新                                                                |
| `/review`                 | コードレビューをリクエスト                                                                   |
| `/sandbox`                | より安全で自律的な実行のためのファイルシステムとネットワーク分離を備えたサンドボックス化されたbashツールを有効化                      |
| `/rewind`                 | 会話またはコードを巻き戻し                                                                   |
| `/status`                 | 設定インターフェース（ステータスタブ）を開く（バージョン、モデル、アカウント、接続性を表示）                                  |
| `/statusline`             | Claude CodeのステータスラインUIをセットアップ                                                   |
| `/terminal-setup`         | 改行用のShift+Enterキーバインディングをインストール（iTerm2およびVSCodeのみ）                              |
| `/todos`                  | 現在のTODOアイテムをリスト                                                                 |
| `/usage`                  | プラン使用制限とレート制限ステータスを表示（サブスクリプションプランのみ）                                           |
| `/vim`                    | vimモードに入る（挿入モードとコマンドモードを交互に切り替え）                                                |

## カスタムスラッシュコマンド

カスタムスラッシュコマンドを使用すると、頻繁に使用するプロンプトをMarkdownファイルとして定義でき、Claude Codeが実行できます。コマンドはスコープ（プロジェクト固有または個人用）で整理され、ディレクトリ構造を通じた名前空間をサポートします。

### 構文

```
/<command-name> [arguments]
```

#### パラメータ

| パラメータ            | 説明                                |
| :--------------- | :-------------------------------- |
| `<command-name>` | Markdownファイル名から派生した名前（`.md`拡張子なし） |
| `[arguments]`    | コマンドに渡されるオプション引数                  |

### コマンドタイプ

#### プロジェクトコマンド

リポジトリに保存され、チームと共有されるコマンド。`/help`にリストされる場合、これらのコマンドは説明の後に「(project)」と表示されます。

**場所**: `.claude/commands/`

次の例では、`/optimize`コマンドを作成します：

```bash  theme={null}
# プロジェクトコマンドを作成
mkdir -p .claude/commands
echo "Analyze this code for performance issues and suggest optimizations:" > .claude/commands/optimize.md
```

#### 個人用コマンド

すべてのプロジェクト全体で利用可能なコマンド。`/help`にリストされる場合、これらのコマンドは説明の後に「(user)」と表示されます。

**場所**: `~/.claude/commands/`

次の例では、`/security-review`コマンドを作成します：

```bash  theme={null}
# 個人用コマンドを作成
mkdir -p ~/.claude/commands
echo "Review this code for security vulnerabilities:" > ~/.claude/commands/security-review.md
```

### 機能

#### 名前空間

サブディレクトリ内でコマンドを整理します。サブディレクトリは組織用に使用され、コマンド説明に表示されますが、コマンド名自体には影響しません。説明には、コマンドがプロジェクトディレクトリ（`.claude/commands`）またはユーザーレベルディレクトリ（`~/.claude/commands`）のどちらから来ているか、およびサブディレクトリ名が表示されます。

ユーザーレベルとプロジェクトレベルのコマンド間の競合はサポートされていません。それ以外の場合、同じベースファイル名を持つ複数のコマンドが共存できます。

たとえば、`.claude/commands/frontend/component.md`のファイルは、説明に「(project:frontend)」と表示される`/component`コマンドを作成します。
一方、`~/.claude/commands/component.md`のファイルは、説明に「(user)」と表示される`/component`コマンドを作成します。

#### 引数

引数プレースホルダーを使用して、コマンドに動的値を渡します：

##### `$ARGUMENTS`を使用したすべての引数

`$ARGUMENTS`プレースホルダーは、コマンドに渡されたすべての引数をキャプチャします：

```bash  theme={null}
# コマンド定義
echo 'Fix issue #$ARGUMENTS following our coding standards' > .claude/commands/fix-issue.md

# 使用方法
> /fix-issue 123 high-priority
# $ARGUMENTSは「123 high-priority」になります
```

##### `$1`、`$2`などを使用した個別引数

位置パラメータ（シェルスクリプトと同様）を使用して、特定の引数に個別にアクセスします：

```bash  theme={null}
# コマンド定義  
echo 'Review PR #$1 with priority $2 and assign to $3' > .claude/commands/review-pr.md

# 使用方法
> /review-pr 456 high alice
# $1は「456」、$2は「high」、$3は「alice」になります
```

位置引数を使用する場合：

* コマンドのさまざまな部分で引数に個別にアクセスする必要がある
* 欠落している引数のデフォルトを提供する
* 特定のパラメータロールを持つより構造化されたコマンドを構築する

#### Bashコマンド実行

`!`プレフィックスを使用して、スラッシュコマンドが実行される前にbashコマンドを実行します。出力はコマンドコンテキストに含まれます。`allowed-tools`に`Bash`ツールを含める必要がありますが、許可する特定のbashコマンドを選択できます。

例：

```markdown  theme={null}
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
description: Create a git commit
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Based on the above changes, create a single git commit.
```

#### ファイル参照

`@`プレフィックスを使用してコマンドにファイルコンテンツを含め、[ファイルを参照](/ja/common-workflows#reference-files-and-directories)します。

例：

```markdown  theme={null}
# 特定のファイルを参照

Review the implementation in @src/utils/helpers.js

# 複数のファイルを参照

Compare @src/old-version.js with @src/new-version.js
```

#### 思考モード

スラッシュコマンドは、[拡張思考キーワード](/ja/common-workflows#use-extended-thinking)を含めることで拡張思考をトリガーできます。

### フロントマター

コマンドファイルはフロントマターをサポートしており、コマンドに関するメタデータを指定するのに便利です：

| フロントマター                    | 目的                                                                                                                    | デフォルト         |
| :------------------------- | :-------------------------------------------------------------------------------------------------------------------- | :------------ |
| `allowed-tools`            | コマンドが使用できるツールのリスト                                                                                                     | 会話から継承        |
| `argument-hint`            | スラッシュコマンドに予想される引数。例：`argument-hint: add [tagId] \| remove [tagId] \| list`。このヒントはスラッシュコマンドをオートコンプリートするときにユーザーに表示されます。 | なし            |
| `description`              | コマンドの簡潔な説明                                                                                                            | プロンプトの最初の行を使用 |
| `model`                    | 特定のモデル文字列（[モデル概要](https://docs.claude.com/en/docs/about-claude/models/overview)を参照）                                   | 会話から継承        |
| `disable-model-invocation` | `SlashCommand`ツールがこのコマンドを呼び出すのを防ぐかどうか                                                                                 | false         |

例：

```markdown  theme={null}
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
argument-hint: [message]
description: Create a git commit
model: claude-3-5-haiku-20241022
---

Create a git commit with message: $ARGUMENTS
```

位置引数を使用した例：

```markdown  theme={null}
---
argument-hint: [pr-number] [priority] [assignee]
description: Review pull request
---

Review PR #$1 with priority $2 and assign to $3.
Focus on security, performance, and code style.
```

## プラグインコマンド

[プラグイン](/ja/plugins)はClaude Codeとシームレスに統合されるカスタムスラッシュコマンドを提供できます。プラグインコマンドはユーザー定義コマンドと同じように機能しますが、[プラグインマーケットプレイス](/ja/plugin-marketplaces)を通じて配布されます。

### プラグインコマンドの仕組み

プラグインコマンドは：

* **名前空間化**: コマンドは競合を避けるために`/plugin-name:command-name`形式を使用できます（名前の衝突がない限り、プラグインプレフィックスはオプション）
* **自動的に利用可能**: プラグインがインストールされて有効になると、そのコマンドが`/help`に表示されます
* **完全に統合**: すべてのコマンド機能をサポート（引数、フロントマター、bash実行、ファイル参照）

### プラグインコマンド構造

**場所**: プラグインルート内の`commands/`ディレクトリ

**ファイル形式**: フロントマター付きMarkdownファイル

**基本的なコマンド構造**:

```markdown  theme={null}
---
description: Brief description of what the command does
---

# Command Name

Detailed instructions for Claude on how to execute this command.
Include specific guidance on parameters, expected outcomes, and any special considerations.
```

**高度なコマンド機能**:

* **引数**: コマンド説明で`{arg1}`のようなプレースホルダーを使用
* **サブディレクトリ**: 名前空間化のためにサブディレクトリ内でコマンドを整理
* **Bash統合**: コマンドはシェルスクリプトとプログラムを実行できます
* **ファイル参照**: コマンドはプロジェクトファイルを参照および変更できます

### 呼び出しパターン

```shell 競合がない場合の直接コマンド theme={null}
/command-name
```

```shell 曖昧さを排除する必要がある場合のプラグインプレフィックス theme={null}
/plugin-name:command-name
```

```shell 引数を使用する場合（コマンドがサポートしている場合） theme={null}
/command-name arg1 arg2
```

## MCPスラッシュコマンド

MCPサーバーはプロンプトをスラッシュコマンドとして公開でき、Claude Codeで利用可能になります。これらのコマンドは接続されたMCPサーバーから動的に検出されます。

### コマンド形式

MCPコマンドは次のパターンに従います：

```
/mcp__<server-name>__<prompt-name> [arguments]
```

### 機能

#### 動的検出

MCPコマンドは以下の場合に自動的に利用可能になります：

* MCPサーバーが接続されてアクティブ
* サーバーがMCPプロトコルを通じてプロンプトを公開
* 接続中にプロンプトが正常に取得される

#### 引数

MCPプロンプトはサーバーで定義された引数を受け入れることができます：

```
# 引数なし
> /mcp__github__list_prs

# 引数付き
> /mcp__github__pr_review 456
> /mcp__jira__create_issue "Bug title" high
```

#### 命名規則

* サーバーとプロンプト名は正規化されます
* スペースと特殊文字はアンダースコアになります
* 一貫性のため名前は小文字になります

### MCP接続の管理

`/mcp`コマンドを使用して：

* 構成されたすべてのMCPサーバーを表示
* 接続ステータスをチェック
* OAuth対応サーバーで認証
* 認証トークンをクリア
* 各サーバーから利用可能なツールとプロンプトを表示

### MCPの権限とワイルドカード

[MCPツールの権限](/ja/iam#tool-specific-permission-rules)を設定する場合、**ワイルドカードはサポートされていない**ことに注意してください：

* ✅ **正しい**: `mcp__github`（githubサーバーからのすべてのツールを承認）
* ✅ **正しい**: `mcp__github__get_issue`（特定のツールを承認）
* ❌ **正しくない**: `mcp__github__*`（ワイルドカードはサポートされていません）

MCPサーバーからのすべてのツールを承認するには、サーバー名のみを使用します：`mcp__servername`。特定のツールのみを承認するには、各ツールを個別にリストします。

## `SlashCommand`ツール

`SlashCommand`ツールを使用すると、Claudeは会話中に[カスタムスラッシュコマンド](/ja/slash-commands#custom-slash-commands)をプログラムで実行できます。これにより、Claudeは必要に応じてあなたの代わりにカスタムコマンドを呼び出す機能が得られます。

Claudeが`SlashCommand`ツールをトリガーするよう促すには、指示（プロンプト、CLAUDE.mdなど）が一般的にコマンドをスラッシュ付きで名前で参照する必要があります。

例：

```
> Run /write-unit-test when you are about to start writing tests.
```

このツールは、利用可能な各カスタムスラッシュコマンドのメタデータを文字予算制限までコンテキストに入れます。`/context`を使用してトークン使用状況を監視し、以下の操作に従ってコンテキストを管理できます。

### `SlashCommand`ツールがサポートするコマンド

`SlashCommand`ツールは以下のカスタムスラッシュコマンドのみをサポートします：

* ユーザー定義。`/compact`や`/init`などの組み込みコマンドはサポート\_されていません\_。
* `description`フロントマターフィールドが入力されている。コンテキストで説明を使用します。

Claude Codeバージョン>= 1.0.124の場合、`claude --debug`を実行してクエリをトリガーすることで、`SlashCommand`ツールが呼び出せるカスタムスラッシュコマンドを確認できます。

### `SlashCommand`ツールを無効化

Claudeがツール経由でスラッシュコマンドを実行するのを防ぐには：

```bash  theme={null}
/permissions
# 拒否ルールに追加: SlashCommand
```

これにより、SlashCommandツール（およびスラッシュコマンド説明）もコンテキストから削除されます。

### 特定のコマンドのみを無効化

特定のスラッシュコマンドが利用可能になるのを防ぐには、スラッシュコマンドのフロントマターに`disable-model-invocation: true`を追加します。

これにより、コマンドのメタデータもコンテキストから削除されます。

### `SlashCommand`権限ルール

権限ルールは以下をサポートします：

* **完全一致**: `SlashCommand:/commit`（引数なしで`/commit`のみを許可）
* **プレフィックス一致**: `SlashCommand:/review-pr:*`（任意の引数で`/review-pr`を許可）

### 文字予算制限

`SlashCommand`ツールには、Claudeに表示されるコマンド説明のサイズを制限するための文字予算が含まれています。これにより、多くのコマンドが利用可能な場合のトークンオーバーフローを防ぎます。

予算には、各カスタムスラッシュコマンドの名前、引数、説明が含まれます。

* **デフォルト制限**: 15,000文字
* **カスタム制限**: `SLASH_COMMAND_TOOL_CHAR_BUDGET`環境変数で設定

文字予算を超えた場合、Claudeは利用可能なコマンドのサブセットのみを表示します。`/context`では、「M of N commands」という警告が表示されます。

## スキルとスラッシュコマンド

**スラッシュコマンド**と**エージェントスキル**はClaude Codeで異なる目的を果たします：

### スラッシュコマンドを使用する場合

**クイック、頻繁に使用されるプロンプト**:

* よく使用する単純なプロンプトスニペット
* クイックリマインダーまたはテンプレート
* 1つのファイルに収まる頻繁に使用される指示

**例**:

* `/review` → 「このコードをバグについてレビューし、改善を提案してください」
* `/explain` → 「このコードを簡単な言葉で説明してください」
* `/optimize` → 「このコードをパフォーマンスの問題について分析してください」

### スキルを使用する場合

**複数のステップを持つ包括的な機能**:

* 複数のステップを持つ複雑なワークフロー
* スクリプトまたはユーティリティが必要な機能
* 複数のファイルに整理されたナレッジ
* 標準化したいチームワークフロー

**例**:

* フォーム入力スクリプトと検証を備えたPDF処理スキル
* さまざまなデータ型の参照ドキュメント付きデータ分析スキル
* スタイルガイドとテンプレート付きドキュメンテーションスキル

### 主な違い

| 側面       | スラッシュコマンド            | エージェントスキル               |
| -------- | -------------------- | ----------------------- |
| **複雑さ**  | シンプルなプロンプト           | 複雑な機能                   |
| **構造**   | 単一の.mdファイル           | SKILL.md +リソースを含むディレクトリ |
| **検出**   | 明示的な呼び出し（`/command`） | 自動（コンテキストに基づく）          |
| **ファイル** | 1つのファイルのみ            | 複数のファイル、スクリプト、テンプレート    |
| **スコープ** | プロジェクトまたは個人用         | プロジェクトまたは個人用            |
| **共有**   | gitを通じて              | gitを通じて                 |

### 例の比較

**スラッシュコマンドとして**:

```markdown  theme={null}
# .claude/commands/review.md
Review this code for:
- Security vulnerabilities
- Performance issues
- Code style violations
```

使用方法：`/review`（手動呼び出し）

**スキルとして**:

```
.claude/skills/code-review/
├── SKILL.md (overview and workflows)
├── SECURITY.md (security checklist)
├── PERFORMANCE.md (performance patterns)
├── STYLE.md (style guide reference)
└── scripts/
    └── run-linters.sh
```

使用方法：「このコードをレビューできますか？」（自動検出）

スキルはより豊富なコンテキスト、検証スクリプト、整理された参照資料を提供します。

### 各を使用する場合

**スラッシュコマンドを使用**:

* 同じプロンプトを繰り返し呼び出す
* プロンプトが1つのファイルに収まる
* それが実行される時期を明示的に制御したい

**スキルを使用**:

* Claudeが機能を自動的に検出する必要がある
* 複数のファイルまたはスクリプトが必要
* 検証ステップを含む複雑なワークフロー
* チームが標準化された詳細なガイダンスが必要

スラッシュコマンドとスキルは共存できます。ニーズに合ったアプローチを使用してください。

[エージェントスキル](/ja/skills)についてさらに詳しく学びます。

## 関連項目

* [プラグイン](/ja/plugins) - プラグインを通じたカスタムコマンドでClaude Codeを拡張
* [アイデンティティとアクセス管理](/ja/iam) - MCPツール権限を含む権限の完全ガイド
* [インタラクティブモード](/ja/interactive-mode) - ショートカット、入力モード、インタラクティブ機能
* [CLIリファレンス](/ja/cli-reference) - コマンドラインフラグとオプション
* [設定](/ja/settings) - 設定オプション
* [メモリ管理](/ja/memory) - セッション全体でのClaudeのメモリ管理
