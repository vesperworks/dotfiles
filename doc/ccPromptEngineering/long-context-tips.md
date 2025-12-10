# 長文コンテキストのプロンプト作成のヒント

---

<Note>
While these tips apply broadly to all Claude models, you can find prompting tips specific to extended thinking models [here](/docs/en/build-with-claude/prompt-engineering/extended-thinking-tips).
</Note>

Claudeの拡張コンテキストウィンドウ（Claude 3モデルでは200Kトークン）により、複雑でデータ豊富なタスクを処理することができます。このガイドでは、この機能を効果的に活用する方法を説明します。

## 長文コンテキストのプロンプトに関する重要なヒント

- **長文データを上部に配置**: 長文の文書や入力（約20K以上のトークン）をプロンプトの上部、クエリや指示、例の上に配置します。これにより、すべてのモデルにおいてClaudeのパフォーマンスが大幅に向上します。

    <Note>特に複雑な複数文書の入力の場合、クエリを最後に配置することで、応答の品質が最大30%向上することがテストで示されています。</Note>

- **XMLタグを使用して文書のコンテンツとメタデータを構造化**: 複数の文書を使用する場合、各文書を`<document>`タグで囲み、`<document_content>`と`<source>`（およびその他のメタデータ）のサブタグを使用して明確にします。

    <section title="複数文書構造の例">

    ```xml
    <documents>
      <document index="1">
        <source>annual_report_2023.pdf</source>
        <document_content>
          {{ANNUAL_REPORT}}
        </document_content>
      </document>
      <document index="2">
        <source>competitor_analysis_q2.xlsx</source>
        <document_content>
          {{COMPETITOR_ANALYSIS}}
        </document_content>
      </document>
    </documents>

    年次報告書と競合分析を分析し、戦略的優位性を特定してQ3の重点分野を推奨してください。
    ```
    
</section>

- **引用を使用して応答の根拠を示す**: 長文文書のタスクでは、タスクを実行する前に、Claudeに関連する文書の部分を引用するよう依頼します。これにより、Claudeは文書の残りの「ノイズ」を切り分けることができます。

    <section title="引用抽出の例">

    ```xml
    あなたはAI医師アシスタントです。医師が患者の病気を診断するのを支援することがあなたの任務です。

    <documents>
      <document index="1">
        <source>patient_symptoms.txt</source>
        <document_content>
          {{PATIENT_SYMPTOMS}}
        </document_content>
      </document>
      <document index="2">
        <source>patient_records.txt</source>
        <document_content>
          {{PATIENT_RECORDS}}
        </document_content>
      </document>
      <document index="3">
        <source>patient01_appt_history.txt</source>
        <document_content>
          {{PATIENT01_APPOINTMENT_HISTORY}}
        </document_content>
      </document>
    </documents>

    患者の報告された症状の診断に関連する患者記録と予約履歴からの引用を見つけてください。これらを<quotes>タグ内に配置してください。次に、これらの引用に基づいて、医師が患者の症状を診断するのに役立つすべての情報をリストアップしてください。診断情報を<info>タグ内に配置してください。
    ```
    
</section>

***

<CardGroup cols={3}>
  <Card title="プロンプトライブラリ" icon="link" href="/docs/ja/resources/prompt-library/library">
    様々なタスクやユースケースのために厳選されたプロンプトで着想を得ましょう。
  </Card>
  <Card title="GitHubプロンプト作成チュートリアル" icon="link" href="https://github.com/anthropics/prompt-eng-interactive-tutorial">
    当社のドキュメントに記載されているプロンプトエンジニアリングの概念を網羅した、例が豊富なチュートリアルです。
  </Card>
  <Card title="Google Sheetsプロンプト作成チュートリアル" icon="link" href="https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8">
    インタラクティブなスプレッドシートを通じた、より軽量版のプロンプトエンジニアリングチュートリアルです。
  </Card>
</CardGroup>