---
created: 2025-11-21 06:23:22.723124+00:00
updated: 2025-11-21 06:23:22.723124+00:00
---
# Anthropic社の「Code Execution With McP」が示す未来 ―― ツールコール時代の終焉と、エージェント設計の次

![rw-book-cover](https://res.cloudinary.com/zenn/image/upload/s--RcL-ZNsp--/c_fit%2Cg_north_west%2Cl_text:notosansjp-medium.otf_55:Anthropic%25E7%25A4%25BE%25E3%2581%25AE%25E3%2580%258CCode%2520Execution%2520with%2520MCP%25E3%2580%258D%25E3%2581%258C%25E7%25A4%25BA%25E3%2581%2599%25E6%259C%25AA%25E6%259D%25A5%2520%2520%25E2%2580%2595%25E2%2580%2595%2520%25E3%2583%2584%25E3%2583%25BC%25E3%2583%25AB%25E3%2582%25B3%25E3%2583%25BC%25E3%2583%25AB%25E6%2599%2582%25E4%25BB%25A3%25E3%2581%25AE%25E7%25B5%2582%25E7%2584%2589...%2Cw_1010%2Cx_90%2Cy_100/g_south_west%2Cl_text:notosansjp-medium.otf_37:hatyibei%2Cx_203%2Cy_121/g_south_west%2Ch_90%2Cl_fetch:aHR0cHM6Ly9zdG9yYWdlLmdvb2dsZWFwaXMuY29tL3plbm4tdXNlci11cGxvYWQvYXZhdGFyLzUxMTdlYWRkODAuanBlZw==%2Cr_max%2Cw_90%2Cx_87%2Cy_95/v1627283836/default/og-base-w1200-v2.png?_a=BACAGSGT)

## Metadata
- Author: [[Zenn]]
- Full Title: Anthropic社の「Code Execution With McP」が示す未来 ―― ツールコール時代の終焉と、エージェント設計の次
- Category: #articles
- Summary: AnthropicはMCPを使っても「ツール定義を全部コンテキストに入れる」方法はスケールで破綻すると示した。代わりにエージェントにコードを書かせ、必要なファイルだけ読み込んで実行する「Code Execution × MCP」を提案している。これによりトークン消費とコストが激減し、将来のエージェント設計の新基準になる。
- URL:
[https://share.google/MPy4mrfUgfJHVtlRb](https://share.google/MPy4mrfUgfJHVtlRb)
[[2025-11-21]]

## Full Document
####  はじめに

MCP（Model Context Protocol）はすでに多くの人が触れ始めていますが、  

**本当に重要なのは「MCPそのもの」ではなく、Anthropicが示した “Code Execution × MCP” という新しい設計思想です。**

MCPは外部ツールの標準化という基礎として重要ですが、Anthropicの最新記事が示したのは明確です。

>  **「ツールを直接叩く時代は終わる。」**  
>  **「エージェントはコードを書いて実行し、その中でツールを扱う時代になる。」**
> 
>  

この記事では、この“設計思想の転換点”を広く浅くまとめます。

####  1. MCPは“軽く”おさらいだけ

MCPは一言でいうと、

>  **AIに“USBポート”のような標準化された外部接続点を生やすプロトコル。**
> 
>  

* ChatGPT / Claude / Gemini / 自前LLM どれでも扱える
* DB / SaaS / API / Wiki / ファイル などを統一方式で操作できる
* BotのN×M地獄を解消できる

この記事の主題はここではなく、  

**「MCPをどう使うか」より、「MCPをどう扱うべきか」です。**

####  2. Anthropicが突きつけた現実

#####  ── MCPは便利すぎて、スケールすると“死ぬ”

Anthropicチームの研究では、次のような事実が報告されています。

#####  ● エージェントはトークンを異常に食う

* 通常対話 →  
 エージェント化すると **最大4倍**
* マルチエージェント →  
 **最大15倍**のトークン消費

#####  ● もっと深刻な問題：

“ツール定義” と “中間情報” がコンテキストを埋め尽くす

ありがちな誤った実装例：

* MCPツールを10個以上用意
* すべてのツール定義をコンテキストに前詰め
* 中間結果を全部モデルに戻す
* LLMに「どのツールを呼ぶか」も判断させる

>  **「質問に答える前に15万トークン使っていた」**  
>  という実例が報告されている。
> 
>  

MCPの思想自体は正しい。  

 しかし、**素直に実装するとレイテンシとコストで破綻する。**

####  3. 解決策：

###  **「ツールコール中心の思想」そのものを捨てること**

#####  これが Anthropic の提示した結論

Anthropicの解決策を一言で言うと：

>  **「ツールを直接呼ぶのではなく、コードに変換して実行しろ。」**
> 
>  

これが “Code Execution × MCP” の中心思想。

####  4. Code Execution × MCP の仕組み

#####  ── ツールを「API」から「コードの部品」へ

Anthropic式の流れはこうです。

#####  ① エージェントはまず“ファイル構造”を見る

mcp-workspace/ progress-server/src/list\_tasks.ts attendance-server/src/input\_worktime.ts knowledge-server/src/post\_article.ts

#####  ② 必要な時だけ `read_file` で読み込む

→ 全ツール定義を最初から積まない  

 → トークン消費が劇的に下がる

#####  ③ LLMは「コードを書く」

例：TypeScript / Python のスクリプト生成

#####  ④ コード内で MCPツールを import して使う

→ “APIを叩く” のではなく “コード部品を組む”

#####  ⑤ 中間処理（フィルタ・整形・ループ）はコード側で完結

→ 状態管理もコードに押し出す  

 → LLMは“意思決定”だけに集中

#####  ⑥ 最終結果だけAIに返す

→ トークン −98.7% の削減が実例として報告

これが「ツールコール中心 → コード実行中心」への転換点。

####  5. なぜこの方式が“次の標準”になるのか？

#####  ① エージェントが肥大化する未来に耐えられる

ツール定義・内部検索結果・制約など  

 AIが読むべき情報は際限なく増える。

→ 必要なファイルだけ読む構造でないと破綻。

#####  ② マルチモデル時代に相性が良い

ChatGPT / Claude / Gemini  

 どれが主流になるかわからない。

>  **“コードファイル”という形はどのモデルでも読める。**
> 
>  

モデル依存が消える。

#####  ③ LLM・MCP・コードの役割分担が綺麗になる

* LLM = 意思決定
* MCP = 接続の標準化
* コード = 状態・処理・制御

この三層構造は大規模エージェントに極めて相性が良い。

####  6. 具体構成例（浅く、広く）

#####  ● progress-server

* list\_tasks

#####  ● knowledge-server

* generate\_template
* revise\_article

#####  ● attendance-server

* input\_worktime
* set\_attendance
* list\_scheduled\_hours

これらを全部「ファイルとして存在させる」だけで良い。  

 LLMは必要時だけ読む。

####  7. これからMCPを触る人への結論

**最初から “コード実行前提” で設計したほうがいい。**

ツール定義をコンテキストに全部詰める旧式MCPサーバは  

 1〜2年以内に確実に陳腐化する。

今から作るなら：

* ツールは `src/*.ts` のコードファイルにする
* エージェントは必要時に read\_file で読む
* AIには意思決定だけやらせる

この方向で組んだ方が確実に長持ちする。

####  8. まとめ

* MCPはツール接続の標準化
* だがスケールするとトークン地獄になる
* Anthropicは「コード実行 × 必要時ファイル読み」の解決策を提示
* これはエージェント設計の新しい基準になる
* 今後のMCPサーバは“コードファイル化”が前提になる

####  最後に：この記事が伝えたい一番シンプルな結論

>  **“ツールコール時代は終わる。  
>  エージェントはコードを書く。”**
> 
>  

これを理解しているだけで  

 2025〜2026のAIエージェント界隈で  

 確実に一歩先を走れるはずです。

![](https://static.zenn.studio/images/drawing/discussion.png)
