# Claudeの応答を事前入力してより大きな出力制御を実現

---

<Note>
While these tips apply broadly to all Claude models, you can find prompting tips specific to extended thinking models [here](/docs/en/build-with-claude/prompt-engineering/extended-thinking-tips).
</Note>

<Note>
事前入力は非拡張思考モードでのみ利用可能です。拡張思考では現在サポートされていません。
</Note>

Claudeを使用する場合、`Assistant`メッセージを事前入力することでその応答をガイドする独自の機能があります。この強力なテクニックにより、Claudeのアクションを指示し、前置きをスキップし、JSONやXMLなどの特定の形式を強制し、ロールプレイシナリオでキャラクターの一貫性を保つことさえできます。

Claudeが期待通りに機能していない場合がありますが、いくつかの事前入力された文がClaudeのパフォーマンスを大幅に向上させることができます。少しの事前入力は大きな効果があります！

## Claudeの応答を事前入力する方法

事前入力するには、`Assistant`メッセージに目的の初期テキストを含めます（Claudeの応答は`Assistant`メッセージが終わるところから続きます）：

```python
import anthropic

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "What is your favorite color?"},
        {"role": "assistant", "content": "As an AI assistant, I don't have a favorite color, But if I had to pick, it would be green because"}  # Prefill here
    ]
)
```

<Warning>
  事前入力コンテンツは末尾の空白で終わることはできません。`"As an AI assistant, I "`（末尾にスペースがある）のような事前入力はエラーになります。
</Warning>

### 例

#### 例1：出力形式の制御と前置きのスキップ

<Tip>**パワーユーザーのヒント**：`{`を事前入力することで、Claudeは前置きをスキップしてJSONオブジェクトを直接出力するようになります。これはより清潔で、より簡潔で、プログラムが追加の処理なしで解析しやすくなります。</Tip>

    <section title="例：事前入力なしの構造化データ抽出">

    | Role | Content |
    | ---- | --- |
    | User | この製品説明からJSONオブジェクトとして名前、サイズ、価格、色を抽出してください：<br/><br/>\<description><br/>SmartHome Miniはコンパクトなスマートホームアシスタントで、黒または白で\$49.99でのみ利用可能です。幅わずか5インチで、音声またはアプリを介してライト、サーモスタット、その他の接続されたデバイスを制御できます。自宅のどこに配置しても問題ありません。この手頃な価格のハブは、スマートデバイスに便利なハンズフリー制御をもたらします。<br/>\</description> |
    | Assistant | 抽出された情報をJSON形式で示します：<br/><br/>\`\`\`json<br/>\{<br/>  "name": "SmartHome Mini",<br/>  "size": "5 inches wide",<br/>  "price": "\$49.99",<br/>  "colors": ["black", "white"]<br/>\}<br/>\`\`\`<br/><br/>製品説明から次の詳細を抽出しました：<br/>- **名前**：SmartHome Mini<br/>- **サイズ**：幅5インチ<br/>- **価格**：\$49.99<br/>- **色**：黒と白で利用可能<br/><br/>JSONオブジェクトはプログラムが解析して使用しやすい構造化形式を提供します。変更が必要な場合や他にご質問がある場合はお知らせください！ |
    
</section>

    <section title="例：事前入力ありの構造化データ抽出">

    | Role | Content |
    | ---- | --- |
    | User | この製品説明からJSONオブジェクトとして名前、サイズ、価格、色を抽出してください：<br/><br/>\<description><br/>SmartHome Miniはコンパクトなスマートホームアシスタントで、黒または白で\$49.99でのみ利用可能です。幅わずか5インチで、音声またはアプリを介してライト、サーモスタット、その他の接続されたデバイスを制御できます。自宅のどこに配置しても問題ありません。この手頃な価格のハブは、スマートデバイスに便利なハンズフリー制御をもたらします。<br/>\</description> |
    | Assistant (prefill) | \{ |
    | Assistant (Claude's response) | "name": "SmartHome Mini",<br/>"size": "5 inches wide",<br/>"price": "\$49.99",<br/>"colors": [<br/>  "black",<br/>  "white"<br/>]<br/>\} |
    
</section>

#### 例2：ロールプレイシナリオでキャラクターを維持

<Tip>**ロールプレイのヒント**：括弧で囲まれた`[ROLE_NAME]`を事前入力することで、より長く複雑な会話でもClaudeがキャラクターを保つことができます。これは`system`パラメータでのロールプロンプティングと組み合わせると特に強力です。</Tip>

    <section title="例：ロールプロンプティングなしでキャラクターを維持">

    | Role | Content |
    | ---- | --- |
    | User ("Sherlock Holmes" Claudeとの50会話ターン後) | この靴の所有者について何を推測しますか？\<image>muddy_shoe.jpg\</image> |
    | Assistant | AIアシスタントとして、提供されたと思われる泥だらけの靴の画像を分析させていただきます。以下が私の推測です... |
    
</section>

    <section title="例：ロールプロンプティングありでキャラクターを維持">

    | Role | Content |
    | ---- | --- |
    | User ("Sherlock Holmes" Claudeとの50会話ターン後) | この靴の所有者について何を推測しますか？<br/>\<image>muddy_shoe.jpg\</image> |
    | Assistant (prefill) | [Sherlock Holmes] |
    | Assistant (Claude's response) | ああ、ここに何があるのか？最も奇妙な標本だ、ワトソン！この靴を識別眼で調べてみましょう。ご覧ください、この泥は一般的なロンドンの粘土ではなく、ハムステッド・ヒースの周辺でのみ見られる鉄分豊富な土壌の特徴的な赤褐色です。しかし、靴底の摩耗はホワイトチャペルの石畳に適した歩き方を示唆しており、ヒースの緩やかな斜面ではありません。<br/><br/>さあ、靴ひもを見てください！これらは医療専門家に好まれる特定の結び方で結ばれています。おそらく手術用ガウンを結ぶ年月の間に習得した習慣でしょう。しかし、つま先ボックスの傷跡は異なる物語を語っています。それらは武道、特にバリツで使用される蹴る動きと一致しています。<br/><br/>したがって、この不在の靴の所有者は医者、おそらく外科医で、ホワイトチャペルに住んでいますがハムステッド・ヒースに頻繁に訪れます。おそらく好奇心の強い目から離れた秘密のバリツ練習のためです。非常に興味深いケースだ、ワトソン！急がなければなりません。ゲームが始まったのです！ |
    
</section>

---

<CardGroup cols={3}>
  <Card title="メッセージの操作" icon="messages" href="/docs/ja/build-with-claude/working-with-messages">
    事前入力およびその他のMessages APIパターンのより多くの例を参照してください。
  </Card>
  <Card title="プロンプトライブラリ" icon="link" href="/docs/ja/resources/prompt-library/library">
    様々なタスクとユースケースのためのキュレーションされたプロンプトの選択から着想を得てください。
  </Card>
  <Card title="GitHubプロンプティングチュートリアル" icon="link" href="https://github.com/anthropics/prompt-eng-interactive-tutorial">
    ドキュメントに記載されているプロンプトエンジニアリングの概念をカバーする例が豊富なチュートリアル。
  </Card>
  <Card title="Google Sheetsプロンプティングチュートリアル" icon="link" href="https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8">
    インタラクティブなスプレッドシートを介したプロンプトエンジニアリングチュートリアルのより軽量なバージョン。
  </Card>
</CardGroup>