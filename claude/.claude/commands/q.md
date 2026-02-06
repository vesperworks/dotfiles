---
description: '直前の会話の質問をAskUserQuestionでまとめて聞く'
allowed-tools: AskUserQuestion
---

# /q - Quick Question

直前の会話で出てきた質問を AskUserQuestion ツールでまとめて聞く。

## 実行

1. 直前の会話から質問・選択肢を抽出
2. AskUserQuestion で最大4問まとめて質問
3. 回答を受けて続行

## ルール

- **最大4問**にまとめる
- **header**: 12文字以内
- **推奨オプションを先頭**に配置し "(推奨)" を付与
- 選択肢が明確でない場合は適切に設計する
