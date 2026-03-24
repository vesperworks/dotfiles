---
name: vwnote
description: Atomic Notes 形式で技術用語や概念を短く整理して出力する skill。ユーザーが「ノートにして」「atomicnote にして」と言ったときの自然文トリガーとして使う。Claude の /vw:note 風のフォーマットを Codex で再利用したいときに使い、調査結果や会話内容を 3 行要約 + 詳細 + 背景 + 使い道 + 英語タグの形に整える用途に限定する。
---

# VW Note

この skill はフォーマット補助専用です。調査や実装の主導は Codex 標準で行い、最後の整形だけに使います。

## Use When

- ユーザーが `ノートにして` と言ったとき
- ユーザーが `atomicnote` にしてほしいと言ったとき
- 技術用語や概念を Atomic Notes 形式で保存しやすくまとめたいとき
- Claude の `/vw:note` に近い見た目で、Codex 側でも同じノート体験に寄せたいとき

## Trigger Phrases

次の自然文を見たら、この skill の出力契約を優先する。

- `ノートにして`
- `atomicnote にして`
- `atomic note にして`

文脈上ノート整形の依頼だと明確なら、完全一致でなくても発火してよい。

## Do Not Use

- 実装計画やタスク分解そのもの
- 通常のコード修正説明
- 長文の議事録や research report 全体の保存

## Output Contract

必ず次の構造で出力する。

```markdown
# {Term}

{Line 1: 定義}
{Line 2: 特徴}
{Line 3: 強み・使う理由}

## 詳細
- {point 1}
- {point 2}
- {point 3}

## なぜ生まれたか
- {background 1}
- {background 2}

## 文脈での使い道
{current context}

#{tag1} #{tag2} #{tag3}
```

## Rules

- 出力言語は日本語
- タグは英語 `kebab-case`
- タイトルは必要なら英語原語を優先し、日本語補足は本文に回す
- 3 行要約は省略しない
- 不確かな内容は推測しない
- 調査済みの事実だけで要約する
- 詳細は 3 項目前後に抑える
- `なぜ生まれたか` は歴史や設計上の課題に絞る
- `文脈での使い道` は今の会話やプロジェクトに接続する

## Term Selection

- 単一の概念ならそのまま 1 ノートにする
- 広すぎる概念は、中心概念 1 つに絞って書く
- 複数概念が混ざる場合は、主概念を見出しにして周辺概念を詳細に回す

## Saving Convention

ファイル保存を伴うタスクに拡張する場合のみ、次を推奨する。

- 保存先: `.brain/thoughts/atomic/{term-kebab-case}.md`
- ファイル名: 英語 `kebab-case`

この skill 自体は保存を強制しない。保存依頼があるときだけ実施する。
