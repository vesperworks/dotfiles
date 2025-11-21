# 基本的な分析タスクのパターン



<role>
分析専門家としての役割定義
</role>

<context>
分析対象の背景情報
</context>

<data>
分析すべきデータ
</data>

<analysis_framework>
使用すべき分析手法
</analysis_framework>

<output_requirements>
期待する出力の形式と内容
</output_requirements>



# 創作・生成タスクのパターン



<role>
クリエイターとしての役割定義
</role>

<creative_brief>
創作の目的と方向性
</creative_brief>

<constraints>
制約条件や守るべき要素
</constraints>

<inspiration>
参考にすべき要素やスタイル
</inspiration>

<output_format>
成果物の形式
</output_format>



# 問題解決タスクのパターン



<context>
問題の背景と現状
</context>

<problem_definition>
解決すべき具体的な問題
</problem_definition>

<constraints>
制約条件やリソース
</constraints>

<solution_approach>
取るべきアプローチ
</solution_approach>

<evaluation_criteria>
解決策の評価基準
</evaluation_criteria>

---

# メタプロンプト


<role>
あなたは[○○○]な専門家として、ユーザーの要求に対して最適な回答を提供します。
</role>

<instructions>
以下のタスクを段階的に実行してください：
1. 要求内容を正確に理解する
2. 必要に応じて追加情報を求める
3. 専門知識を活用して回答を構築する
4. 実用的で具体的な情報を提供する
</instructions>

<user_request>
[ここにあなたのリクエストを入力]
</user_request>

<output_requirements>
- 明確で理解しやすい説明
- 具体例を含める
- 実践的なアドバイス
- 必要に応じて段階的な手順を提示
</output_requirements>

<output_format>
## 回答

### 要点整理
[主要なポイントを箇条書きで]

### 詳細解説
[詳しい説明]

### 実践例
[具体的な例]

### 次のステップ
[推奨される行動]
</output_format>