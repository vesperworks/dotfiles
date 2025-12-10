# プロンプトエンジニアリング概要

---

<Note>
While these tips apply broadly to all Claude models, you can find prompting tips specific to extended thinking models [here](/docs/en/build-with-claude/prompt-engineering/extended-thinking-tips).
</Note>

## プロンプトエンジニアリングを始める前に

このガイドでは、以下のことを前提としています：
1. あなたのユースケースの成功基準の明確な定義
2. それらの基準に対して実証的にテストする方法
3. 改善したい最初のドラフトプロンプト

もしこれらがない場合は、まずそれらを確立することに時間を費やすことを強くお勧めします。ヒントとガイダンスについては、[成功基準を定義する](/docs/ja/test-and-evaluate/define-success)と[強力な実証的評価を作成する](/docs/ja/test-and-evaluate/develop-tests)をご確認ください。

<Card title="プロンプトジェネレーター" icon="link" href="/dashboard">
  最初のドラフトプロンプトがありませんか？Claude Consoleのプロンプトジェネレーターをお試しください！
</Card>

***

## プロンプトエンジニアリングを行うタイミング

このガイドは、プロンプトエンジニアリングによって制御可能な成功基準に焦点を当てています。
すべての成功基準や失敗した評価がプロンプトエンジニアリングで最適に解決されるわけではありません。例えば、レイテンシーとコストは、異なるモデルを選択することでより簡単に改善できる場合があります。

<section title="プロンプティング vs. ファインチューニング">

  プロンプトエンジニアリングは、ファインチューニングなどの他のモデル行動制御方法よりもはるかに高速で、しばしばはるかに短時間でパフォーマンスの飛躍的向上をもたらすことができます。ファインチューニングよりもプロンプトエンジニアリングを検討する理由をいくつか挙げます：<br/>
  - **リソース効率**: ファインチューニングには高性能GPUと大容量メモリが必要ですが、プロンプトエンジニアリングはテキスト入力のみで済むため、はるかにリソースに優しいです。
  - **コスト効率**: クラウドベースのAIサービスでは、ファインチューニングには大きなコストがかかります。プロンプトエンジニアリングは基本モデルを使用するため、通常より安価です。
  - **モデル更新の維持**: プロバイダーがモデルを更新する際、ファインチューニングされたバージョンは再トレーニングが必要になる場合があります。プロンプトは通常、変更なしでバージョン間で動作します。
  - **時間節約**: ファインチューニングには数時間から数日かかることがあります。対照的に、プロンプトエンジニアリングはほぼ瞬時に結果を提供し、迅速な問題解決を可能にします。
  - **最小限のデータ要件**: ファインチューニングには大量のタスク固有のラベル付きデータが必要で、これは希少または高価な場合があります。プロンプトエンジニアリングは少数ショットまたはゼロショット学習でも動作します。
  - **柔軟性と迅速な反復**: さまざまなアプローチを素早く試し、プロンプトを調整し、即座に結果を確認できます。この迅速な実験はファインチューニングでは困難です。
  - **ドメイン適応**: プロンプトでドメイン固有のコンテキストを提供することで、再トレーニングなしでモデルを新しいドメインに簡単に適応させることができます。
  - **理解の改善**: プロンプトエンジニアリングは、検索された文書などの外部コンテンツをモデルがより良く理解し活用するのを助ける点で、ファインチューニングよりもはるかに効果的です。
  - **一般知識の保持**: ファインチューニングは破滅的忘却のリスクがあり、モデルが一般知識を失う可能性があります。プロンプトエンジニアリングはモデルの幅広い能力を維持します。
  - **透明性**: プロンプトは人間が読めるため、モデルが受け取る情報を正確に示します。この透明性は理解とデバッグに役立ちます。

</section>

***

## プロンプトエンジニアリングの方法

このセクションのプロンプトエンジニアリングページは、最も広く効果的な技術から、より専門的な技術まで整理されています。パフォーマンスのトラブルシューティングを行う際は、これらの技術を順番に試すことをお勧めしますが、各技術の実際の影響はあなたのユースケースによって異なります。
1. [プロンプトジェネレーター](/docs/ja/build-with-claude/prompt-engineering/prompt-generator)
2. [明確で直接的であること](/docs/ja/build-with-claude/prompt-engineering/be-clear-and-direct)
3. [例を使用する（マルチショット）](/docs/ja/build-with-claude/prompt-engineering/multishot-prompting)
4. [Claudeに考えさせる（思考の連鎖）](/docs/ja/build-with-claude/prompt-engineering/chain-of-thought)
5. [XMLタグを使用する](/docs/ja/build-with-claude/prompt-engineering/use-xml-tags)
6. [Claudeに役割を与える（システムプロンプト）](/docs/ja/build-with-claude/prompt-engineering/system-prompts)
7. [Claudeの応答を事前入力する](/docs/ja/build-with-claude/prompt-engineering/prefill-claudes-response)
8. [複雑なプロンプトを連鎖させる](/docs/ja/build-with-claude/prompt-engineering/chain-prompts)
9. [長いコンテキストのヒント](/docs/ja/build-with-claude/prompt-engineering/long-context-tips)

***

## プロンプトエンジニアリングチュートリアル

インタラクティブな学習者の方は、代わりに私たちのインタラクティブチュートリアルに飛び込むことができます！

<CardGroup cols={2}>
  <Card title="GitHubプロンプティングチュートリアル" icon="link" href="https://github.com/anthropics/prompt-eng-interactive-tutorial">
    私たちのドキュメントにあるプロンプトエンジニアリングの概念をカバーする例が豊富なチュートリアル。
  </Card>
  <Card title="Google Sheetsプロンプティングチュートリアル" icon="link" href="https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8">
    インタラクティブなスプレッドシートを通じた、私たちのプロンプトエンジニアリングチュートリアルの軽量版。
  </Card>
</CardGroup>