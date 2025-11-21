---
created: 2025-06-06T10:26
updated: 2025-06-12T18:40
---
# Claude Code 概要

> Anthropicが開発したエージェント型コーディングツールであるClaude Codeについて学びましょう。現在はベータ版として研究プレビュー中です。

Claude Codeは、ターミナル上で動作し、コードベースを理解し、自然言語コマンドを通じてより速くコーディングできるようサポートするエージェント型コーディングツールです。開発環境に直接統合することで、追加のサーバーや複雑なセットアップを必要とせずにワークフローを効率化します。

```bash
npm install -g @anthropic-ai/claude-code
```

Claude Codeの主な機能は以下の通りです：

* コードベース全体でのファイル編集とバグ修正
* コードのアーキテクチャとロジックに関する質問への回答
* テスト、リンティング、その他のコマンドの実行と修正
* Gitの履歴検索、マージ競合の解決、コミットとPRの作成
* エンタープライズ導入のための[Amazon BedrockとGoogle Vertex AI](/ja/docs/claude-code/bedrock-vertex-proxies)との連携

<Note>
  **研究プレビュー**

  Codeは研究プレビューとしてベータ版です。AIとの協業の好み、AIアシスタンスが最も役立つワークフロー、エージェント体験の改善方法について開発者からのフィードバックを収集しています。

  この初期バージョンはユーザーフィードバックに基づいて進化します。今後数週間で、ツール実行の信頼性、長時間実行コマンドのサポート、ターミナルレンダリング、Claudeの自己能力認識の向上を計画しています。

  バグは`/bug`コマンドで直接報告するか、[GitHubリポジトリ](https://github.com/anthropics/claude-code)を通じて報告してください。
</Note>

## なぜClaude Codeなのか？

Claude Codeはターミナル上で直接動作し、プロジェクトのコンテキストを理解して実際のアクションを実行します。コンテキストにファイルを手動で追加する必要はなく、Claudeは必要に応じてコードベースを探索します。Claude Codeはデフォルトで`claude-opus-4-20250514`を使用します。

### エンタープライズ統合

Claude Codeはエンタープライズ向けAIプラットフォームとシームレスに統合されます。組織の要件を満たす安全で準拠した導入のために、[Amazon BedrockまたはGoogle Vertex AI](/ja/docs/claude-code/bedrock-vertex-proxies)に接続できます。

### 設計段階からのセキュリティとプライバシー

コードのセキュリティは最重要事項です。Claude Codeのアーキテクチャは以下を保証します：

* **直接APIコネクション**: クエリは中間サーバーを経由せず、直接AnthropicのAPIに送信されます
* **あなたの作業環境で動作**: ターミナル上で直接操作します
* **コンテキストを理解**: プロジェクト構造全体を把握します
* **アクションを実行**: ファイルの編集やコミットの作成など、実際の操作を実行します

## はじめに

Claude Codeを始めるには、システム要件、インストール手順、認証プロセスを説明した[インストールガイド](/ja/docs/claude-code/getting-started)に従ってください。

## クイックツアー

Claude Codeでできることの例です：

### 質問から解決策まで数秒で

```bash
# コードベースについて質問する
claude
> 認証システムはどのように動作しますか？

# 1つのコマンドでコミットを作成
claude commit

# 複数のファイルにまたがる問題を修正
claude "auth モジュールの型エラーを修正して"
```

### 馴染みのないコードを理解する

```
> 決済処理システムは何をしますか？
> ユーザー権限がチェックされる場所を見つけて
> キャッシュレイヤーがどのように動作するか説明して
```

### Git操作を自動化する

```
> 変更をコミットして
> PRを作成して
> 12月にマークダウンのテストを追加したのはどのコミット？
> mainにリベースして、マージ競合を解決して
```

## 次のステップ

<CardGroup>
  <Card title="はじめに" icon="rocket" href="/ja/docs/claude-code/getting-started">
    Claude Codeをインストールして使い始める
  </Card>

  <Card title="主要機能" icon="star" href="/ja/docs/claude-code/common-tasks">
    Claude Codeができることを探索する
  </Card>

  <Card title="コマンド" icon="terminal" href="/ja/docs/claude-code/cli-usage">
    CLIコマンドとコントロールについて学ぶ
  </Card>

  <Card title="設定" icon="gear" href="/ja/docs/claude-code/settings">
    ワークフローに合わせてClaude Codeをカスタマイズする
  </Card>
</CardGroup>

## 追加リソース

<CardGroup>
  <Card title="Claude Codeチュートリアル" icon="graduation-cap" href="/ja/docs/claude-code/tutorials">
    一般的なタスクのステップバイステップガイド
  </Card>

  <Card title="トラブルシューティング" icon="wrench" href="/ja/docs/claude-code/troubleshooting">
    Claude Codeの一般的な問題に対する解決策
  </Card>

  <Card title="BedrockとVertex統合" icon="cloud" href="/ja/docs/claude-code/bedrock-vertex-proxies">
    Claude CodeをAmazon BedrockまたはGoogle Vertex AIで構成する
  </Card>

  <Card title="リファレンス実装" icon="code" href="https://github.com/anthropics/claude-code/tree/main/.devcontainer">
    開発コンテナのリファレンス実装をクローンする
  </Card>
</CardGroup>

## ライセンスとデータ使用

Claude Codeは、Anthropicの[商用利用規約](https://www.anthropic.com/legal/commercial-terms)に基づくベータ版研究プレビューとして提供されています。

### データの使用方法

私たちはデータの使用方法について完全に透明性を持つことを目指しています。フィードバックを製品やサービスの改善に使用することがありますが、Claude Codeからのフィードバックを使用して生成モデルをトレーニングすることはありません。潜在的に機密性の高い性質を考慮して、ユーザーフィードバックの記録は30日間のみ保存します。

#### フィードバック記録

Claude Codeの使用記録など、フィードバックを送信することを選択した場合、Anthropicはそのフィードバックを関連する問題のデバッグやClaude Codeの機能改善（例：将来同様のバグが発生するリスクを減らすなど）に使用することがあります。このフィードバックを使用して生成モデルをトレーニングすることはありません。

### プライバシー保護

機密情報の保持期間の制限、ユーザーセッションデータへのアクセス制限、モデルトレーニングにフィードバックを使用しないという明確なポリシーなど、データを保護するためのいくつかの保護措置を実施しています。

詳細については、[商用利用規約](https://www.anthropic.com/legal/commercial-terms)と[プライバシーポリシー](https://www.anthropic.com/legal/privacy)をご確認ください。

### ライセンス

© Anthropic PBC. All rights reserved. 使用はAnthropicの[商用利用規約](https://www.anthropic.com/legal/commercial-terms)に従います。
