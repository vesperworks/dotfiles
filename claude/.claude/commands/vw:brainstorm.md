---
name: vw:brainstorm
allowed-tools: Read, Write, Bash, Glob, Grep, Agent, Workflow, AskUserQuestion
description: 'SCAMPER法による並列ブレインストーミング（Opus facilitator + Sonnet×10）'
---

## vw:brainstorm — Parallel SCAMPER Brainstorming

テーマを受け取り、Opus（ファシリテーター）+ Sonnet×10（ブレスター）でSCAMPER法ベースのブレインストーミングを実行する。

### 使い方

```
/vw:brainstorm AI時代の新しい学習体験
/vw:brainstorm                          # テーマを対話で聞く
```

### 実行

このコマンドが呼ばれたら、`vw-brainstorm` スキルの手順に従って実行してください。

1. テーマが引数 `$ARGUMENTS` にあればそれを使用、なければ AskUserQuestion で聞く
2. `.idea/` ディレクトリを作成
3. Workflow で Sonnet×10 を並列起動（各自 SCAMPER 担当分のアイディアを生成）
4. 全ノードを集約して放射状レイアウト計算
5. `references/canvas-template.html` ベースで `.idea/index.html` を生成
6. `open .idea/index.html` でブラウザ表示
