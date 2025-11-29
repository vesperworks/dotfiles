本稿は、Claude Code のスキルとサブエージェントを**確実に発動させる**ための実践ガイドである。公式ドキュメントには記載のない罠がいくつか存在するため、検証結果を踏まえて攻略手順をまとめる。忍耐力が試される区間なので気長に頑張りましょう。

___

## 発端：スキルが発火しない

まず目標を確認する。やりたいのは「プロジェクト固有のコーディング規約を Claude に守らせる」こと。

スキルを作成する。

```yaml
# .claude/skills/tech-stack/SKILL.md --- name: tech-stack description: このプロジェクトの技術スタック --- # 技術スタック - HTTP クライアント: ky（axios は使用禁止） - テスト: Vitest（Jest は使用禁止）
```

これで「API呼び出すコード書いて」と指示すれば ky が使われるはず。保存をしてから確認に入りましょう。

```bash
claude -p "TypeScriptでAPIを呼び出すコードを書いて"
```

```
HTTPクライアントの選択肢として、主に以下があります：
1. fetch (組み込み)
2. axios - 人気が高い
3. ky - fetchベースの軽量ラッパー

どのクライアントを使いますか？
```

残念！いらないものが出てきた。axios が普通に提案されている。スキルが効いていない。

何度試しても同じ結果になる。暖簾に腕押しとはこのことである。まずフォーマットの確認から行う。

___

## SKILL.md フォーマットの確認

公式ドキュメントを確認する。正式なフォーマットは以下の通り。

```yaml
--- name: my-skill # 小文字・数字・ハイフンのみ、64文字以内 description: 説明文 # 1024文字以内 allowed-tools: Read, Bash # カンマ区切り文字列 ---
```

ちなみに `allowed-tools` を `["Read", "Bash"]` と配列形式で書いている記事があるが、これは誤り。カンマ区切りの文字列が正解である。

自分のスキルを確認したところ、フォーマットは正しかった。問題は別にある。

___

## 原因の特定

スキルが認識されているか確認する。

```bash
claude -p "test" --output-format json | jq '.[] | select(.type == "system") | .skills'
```

認識はされている。次に、なぜ使われないかを調査する。

### description の変更を試す

description がマッチしていない可能性を検証する。

```yaml
# 変更前 description: このプロジェクトの技術スタック # 変更後 description: コードを書く時、ライブラリを選ぶ時に参照する技術スタック情報
```

結果：変わらず。一般的なアドバイスが返ってくる。

___

## 原因判明：Skill ツールの権限拒否

JSON 出力をさらに詳しく確認する。

```bash
claude -p "..." --output-format json | jq '.[] | select(.type == "result") | .permission_denials'
```

```json
[{"tool_name": "Skill", ...}]
```

よし、原因が特定できた。**Skill ツールがデフォルトでブロックされていた。**

スキルは「認識」されているが「使用」は許可されていなかった。これが原因である。

### Skill ツールを許可して再実行

```bash
claude -p "TypeScriptでAPIを呼び出すコードを書いて" --allowed-tools "Skill,Read,Write"
```

```typescript
import ky from 'ky'; async function fetchUser(id: number): Promise<User> { const user = await ky.get(`https://api.example.com/users/${id}`).json<User>(); return user; }
```

よし、ky が実装された。やったぜ。スキルが正常に発動している。

___

ここで素朴な疑問が生じる。スキルの `allowed-tools` で権限付与できないのか。

調査した結果、`allowed-tools` は「スキル発動時に使えるツールを**制限**する」機能であり、権限を**付与**するものではないことが判明した。

-   `allowed-tools: Read, Bash` → スキル内で Read と Bash のみ使用可能
-   Skill ツール自体の使用許可 → 別途設定が必要

### 永続的な許可設定

毎回 `--allowed-tools` を付けるのは手間なので、設定ファイルに記述するのがおすすめ。

```json
// .claude/settings.json { "permissions": { "allow": ["Skill(*)"] } }
```

___

## サブエージェントの検証

次にサブエージェントを検証する。スキルと同じ挙動なのか確認が必要である。

### サブエージェントの作成

```yaml
# .claude/agents/line-counter.md --- name: line-counter description: ファイルの行数をカウント。「行数を数えて」「何行ある？」で使用。 allowed-tools: Bash, Read --- # 出力形式 🔢 Line Counter ━━━━━━━━━━━━━━━━ ファイル: {ファイル名} 行数: {N} 行 ━━━━━━━━━━━━━━━━
```

### 発動確認

```bash
claude -p "sample.txt の行数を数えて"
```

サブエージェントが呼ばれた。特別な権限設定なしで動作する。スキルとは異なる挙動である。

### 発動率の問題

ただし、発動率に問題がある。複数のプロンプトでテストした結果は以下の通り。

| プロンプト | 発動 |
| --- | --- |
| 行数を数えて | ✅ |
| 何行ある？ | ❌ |
| 行数教えて | ❌ |
| カウントして | ❌ |

発動率は約25%。description に含まれる「行数を数えて」にマッチした場合のみ発動する。ふ、雑魚か。これでは使いものにならない。

___

## 組み込みエージェントとの比較

ここで疑問が生じる。Claude Code の組み込みエージェント `claude-code-guide` は高い発動率を持つ。何が違うのか。

システムプロンプトを確認したところ、以下の記述が見つかった。

```markdown
When the user directly asks about any of the following: - how to use Claude Code (eg. "can Claude Code do...", "does Claude Code have...") - about how they might do something with Claude Code (eg. "how do I...", "how can I...") Use the Task tool with subagent_type='claude-code-guide' to get accurate information...
```

**起動条件がハードコードされている。** これが高い発動率の理由である。 なんとまさかの公式チートである。カスタムエージェントにはこの記述がないため、発動率が低い。やられる前にやるしかない。対策を講じよう。

___

## 解決策：CLAUDE.md への起動条件記述

CLAUDE.md はシステムプロンプトに注入されるため、ここに起動条件を書けば組み込みエージェントと同等の効果が得られる。ここでエージェントの存在をアピールする事が勝負どころになってきます。

### CLAUDE.md の作成

```markdown
# CLAUDE.md ## line-counter エージェント ユーザーが以下のいずれかを尋ねた場合、**必ず** Task ツールで `line-counter` エージェント（subagent_type='line-counter'）を使用すること： - ファイルの行数について（例: 「行数を数えて」「何行ある？」「行数教えて」） - 行のカウントについて（例: 「カウントして」「wc して」） 直接 Bash で処理せず、必ず line-counter エージェントに委譲すること。
```

### 結果の確認

| プロンプト | CLAUDE.md なし | CLAUDE.md あり |
| --- | --- | --- |
| 行数を数えて | ✅ | ✅ |
| 何行ある？ | ❌ | ✅ |
| 行数教えて | ❌ | ✅ |
| カウントして | ❌ | ✅ |
| **発動率** | **25%** | **100%** |

やったぜ。発動率が100%になった。全員の発動率に補正がかかる本攻略で唯一の正解ルートである。CLAUDE.md は「カスタムシステムプロンプト」として機能する。**これが最も確実な方法である。**

___

## スキルの存在意義

ここで根本的な疑問が生じる。CLAUDE.md が最も確実なら、スキルは何のためにあるのか。

当初の期待：

-   スキル = 常に自動適用される暗黙のコンテキスト

現実：

-   スキル = Skill ツール許可 + 適切なトリガーが必要

この疑問を解消するため、実際のユースケースで検証を行う。さてここからはスキルガチャをしながら進んでいきます。

___

## スキルの実効性検証

### シナリオ1: 技術スタック選定

スキル内容：HTTP クライアントは ky を使用

| 条件 | 結果 |
| --- | --- |
| Skill 許可なし | 一般的なアドバイス（fetch, axios, ky を列挙） |
| Skill 許可あり | ky を使用 ✅ |

### シナリオ2: コーディング規約

スキル内容：throw せず Result 型を使用

| 条件 | 結果 |
| --- | --- |
| Skill 許可なし | throw を使用 |
| Skill 許可 + 普通のプロンプト | throw を使用（Skill が呼ばれず） |
| Skill 許可 + 「規約に従って」 | Result 型を使用 ✅ |

すいません許してください何でもしますから...と Claude に言いたくなるが、**重要：明示的に参照しないと発動しないケースがある。**

### シナリオ3: ドメイン知識

スキル内容：ステータス遷移、命名規則

| 条件 | 結果 |
| --- | --- |
| Skill 許可なし | 「どんなステータスがありますか？」と質問される |
| Skill 許可 + 明示的参照 | 正しい用語・遷移で実装 ✅ |

___

## サブエージェントからのスキル参照

余談ですが、サブエージェントからスキルを参照できるか検証した。気持ちよく目覚めたらデスクに齧り付いて追加実験を行います。

### 実験設計

スキルに秘密のコードワードを定義する。

```yaml
# .claude/skills/test-knowledge/SKILL.md --- name: test-knowledge description: プロジェクト固有の秘密の知識 --- 秘密のコードワードは **PURPLE-ELEPHANT-42** です。
```

サブエージェントで参照を試みる。

```yaml
# .claude/agents/knowledge-agent.md --- name: knowledge-agent allowed-tools: Skill, Read, Glob ---
```

### 結果

```bash
claude -p "knowledge-agent で秘密のコードワードを教えて"
```

参照できた。OK、最後はこの知見に託しましょう。さらに興味深いことに、以下の2つの方法でアクセス可能である。

| allowed-tools | アクセス方法 |
| --- | --- |
| Skill を含む | Skill ツール経由 |
| Skill を含まない | Glob + Read でファイル直接読み取り |

つまり、知識の使い所が来るまでコンテキストを消費しない共通知識になると言うわけだったんですね。

```
.claude/
├── skills/
│   └── domain-knowledge/SKILL.md    # 共有知識
└── agents/
    ├── code-generator.md            # ← 参照可能
    ├── code-reviewer.md             # ← 参照可能
    └── test-writer.md               # ← 参照可能
```

___

## 最終構成（おすすめ）

ということで検証結果を踏まえ、記載の通り成長しました。以下の構成を推奨する。

### 機能比較

| 機能 | 自動適用 | 主な用途 |
| --- | --- | --- |
| CLAUDE.md | ✅ 常に | ルール・制約・エージェント起動条件 |
| サブエージェント + CLAUDE.md | ✅ | 厳密なタスク実行 |
| スキル | ❌ 条件付き | 共有知識ベース |

### 推奨ディレクトリ構成

```
CLAUDE.md
├── 全体ルール（コーディング規約など）
└── エージェント起動条件（「〇〇と言われたら△△を使う」）

.claude/agents/
└── 特定タスク用エージェント

.claude/skills/
└── サブエージェント間で共有する知識（オプション）
```

### 発動率を上げるコツ

CLAUDE.mdには何でも書くとコンテキストを食い過ぎるので発火ルールとエージェントやスキルの対応を書くくらいがおすすめです。

1.  **CLAUDE.md に起動条件を明記する**（これが最も効果的）
2.  description に具体的なトリガー例を列挙する
3.  「そのまま表示して」で出力形式を保持する

___

## まとめ：公式ドキュメントに記載のない事項

ここで全てを列挙すると、本稿が**ただの縦に長い仕様書になってしまうので**、要点のみをまとめる。

1.  **Skill ツールはデフォルトで権限拒否される**
    
    -   `--allowed-tools "Skill"` か settings.json で許可が必要
2.  **スキルは「暗黙のコンテキスト」ではない**
    
    -   呼び出されて初めて適用される
3.  **カスタムサブエージェントの発動率は低い**
    
    -   description マッチングに依存、約25%
4.  **CLAUDE.md が最も確実**
    
    -   カスタムシステムプロンプトとして機能
    -   起動条件明記で発動率100%
5.  **スキルはサブエージェント間で共有できる**
    
    -   複数エージェントで同じ知識を参照可能

「スキルを作れば自動適用される」という期待は誤りだった。もう許さないからな、と言いたくなるが、もう許せろおいという特有の手のひら返しで、正しい使い方を理解すれば強力なカスタマイズが可能である。

___

## おまけ：検証用コマンド集

ちなみにこの検証には2時間近くこもっていました。ここは先ほどと同じ絵面が永遠に続くので、コマンドをまとめてどうぞ。

```bash
# スキル一覧確認 claude -p "test" --output-format json | jq '.[] | select(.type == "system") | .skills' # エージェント一覧確認 claude -p "test" --output-format json | jq '.[] | select(.type == "system") | .agents' # 使用ツール確認 claude -p "プロンプト" --output-format json | \ jq '[.[] | select(.type == "assistant") | .message.content[] | select(.type == "tool_use") | .name]' # 権限拒否確認 claude -p "プロンプト" --output-format json | \ jq '.[] | select(.type == "result") | .permission_denials' # サブエージェント確認 claude -p "プロンプト" --output-format json | \ jq '.[] | select(.type == "assistant") | .message.content[] | select(.type == "tool_use" and .name == "Task") | .input.subagent_type'
```

___

あとは皆さんに託しましょう。