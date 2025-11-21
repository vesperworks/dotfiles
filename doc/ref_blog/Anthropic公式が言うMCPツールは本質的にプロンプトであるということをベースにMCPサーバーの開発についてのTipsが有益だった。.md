---
created: None
updated: None
---
# Anthropic公式が言う"MCPツールは本質的にプロンプトである"ということをベースにMCPサーバーの開発についてのTipsが有益だった。

![rw-book-cover](https://pbs.twimg.com/profile_images/1764893279286620160/S7bcBcD1.jpg)

## Metadata
- Author: [[オカムラ | 株式会社メイク・ア・チェンジ]]
- Full Title: Anthropic公式が言う"MCPツールは本質的にプロンプトである"ということをベースにMCPサーバーの開発についてのTipsが有益だった。
- Category: #tweets
- Summary: Anthropicの指摘「MCPツールは本質的にプロンプトである」を踏まえ、MCPサーバー設計の具体的なTipsが有益だった。  
ツール名や説明、パラメーターを正確に定義し、サーバー内のツールは1〜2個に絞ると効率的。  
類似機能の別サーバーを複数接続するのは混乱を招くため避けるべき。
- URL:
[https://x.com/masa_oka108/status/1977866014286356755/?rw_tt_thread=True](https://x.com/masa_oka108/status/1977866014286356755/?rw_tt_thread=True)
[[]]

## Full Document
Anthropic公式が言う"MCPツールは本質的にプロンプトである"ということをベースにMCPサーバーの開発についてのTipsが有益だった。

①ツール名、説明、パラメーター名を正確に詳細に定義することが非常に重要  
MCPツールは本質的にプロンプトであるため、モデルの動作はツールの定義方法に大きく影響される。

②一つのMCPサーバー内のツールは1〜2個に絞る  
その方がモデルの効率的な呼び出しに役立つ。  
従来のAPI開発の場合、細かい粒度で「get projects」「get posts」など複数の具体的なエンドポイントを用意する。  
しかし、MCPの場合は複数の情報を取得するタスクに対して「get info」のような抽象度の高いツールを1つだけ用意するのが効果的。

③「類似のMCPサーバーの設定」はアンチパターン  
類似の機能を持つ複数の異なるMCPサーバーを接続することは避ける。  
例えばAsanaとLinerなど。どちらのプロジェクト情報を参照するか混乱を招く。

ソースは👇

![](https://pbs.twimg.com/media/G3LKp-abwAA0OGp.jpg)

---

[youtube.com/watch?v=aZLr96…](https://www.youtube.com/watch?v=aZLr962R6Ag)
