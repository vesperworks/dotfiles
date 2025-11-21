# doc/ref_blog/ からの重要知見抽出サマリー

**作成日**: 2025-11-21
**分析対象**: doc/ref_blog/ 内の6つのブログ記事

---

## 1. MCPの本質的理解（オカムラ氏ツイート）

### 核心的洞察

**「MCPツールは本質的にプロンプトである」**

この理解が、MCP設計のすべての基礎となる。

### 具体的なTips

#### ① ツール定義の重要性
- **ツール名、説明、パラメーター名を正確に詳細に定義することが非常に重要**
- MCPツールは本質的にプロンプトであるため、モデルの動作はツール定義方法に大きく影響される

#### ② 1つのMCPサーバー内のツールは1〜2個に絞る
- **従来のAPI開発**: 細かい粒度で「get projects」「get posts」など複数の具体的なエンドポイント
- **MCPの正解**: 複数の情報を取得するタスクに対して「get info」のような**抽象度の高いツールを1つだけ**用意

→ モデルの効率的な呼び出しに役立つ

#### ③ 類似のMCPサーバー設定はアンチパターン
- 類似の機能を持つ複数の異なるMCPサーバーを接続することは避ける
- 例: AsanaとLinerを両方接続 → どちらのプロジェクト情報を参照するか混乱を招く

---

## 2. Code Execution × MCP（新しいパラダイム）

### ツールコール時代の終焉

Anthropicが示した明確な結論：

>  **「ツールを直接叩く時代は終わる。
>  エージェントはコードを書いて実行し、その中でツールを扱う。」**

### 従来の問題点

#### スケール時の破綻
- ツール定義を全部コンテキストに前詰め → **質問に答える前に15万トークン使う**
- 中間結果を全部モデルに戻す → トークン地獄
- 通常対話がエージェント化で最大4倍、マルチエージェントで最大15倍のトークン消費

### 新しい解決策：Code Execution × MCP

#### 基本フロー
1. エージェントはまず**ファイル構造**を見る
   ```
   mcp-workspace/
   ├── progress-server/src/list_tasks.ts
   ├── attendance-server/src/input_worktime.ts
   └── knowledge-server/src/post_article.ts
   ```

2. 必要な時だけ `read_file` で読み込む
   - 全ツール定義を最初から積まない
   - トークン消費が劇的に下がる

3. LLMは**コードを書く**
   ```typescript
   import * as gdrive from './servers/google-drive';
   import * as salesforce from './servers/salesforce';

   const transcript = (await gdrive.getDocument({ documentId: 'abc123' })).content;
   await salesforce.updateRecord({
     objectType: 'SalesMeeting',
     recordId: '00Q5f000001abcXYZ',
     data: { Notes: transcript }
   });
   ```

4. コード内でMCPツールをimportして使う
   - "APIを叩く"のではなく"コード部品を組む"

5. 中間処理（フィルタ・整形・ループ）はコード側で完結
   - LLMは"意思決定"だけに集中

6. 最終結果だけAIに返す
   - **トークン −98.7% の削減**が実例として報告

### 具体的な効果

**従来の方法**（全ツール定義をコンテキストに含める）:
- 150,000トークン

**Code Execution × MCP**（ファイルシステムベース）:
- 2,000トークン（**98.7%削減**）

---

## 3. Skills vs SubAgents の正しい理解

### 基本概念

| 要素 | Skills | SubAgents |
|------|--------|-----------|
| **本質** | 再利用可能な専門知識（教科書） | 独立した実行環境（専門チーム） |
| **コンテキスト** | Progressive Disclosure | 独立したコンテキストウィンドウ |
| **実行** | モデル呼び出し型（自動発見） | 明示的呼び出しまたは自動委譲 |
| **権限** | allowed-toolsで制限 | toolsフィールドで独自権限 |
| **並列性** | なし | 複数SubAgentsが同時実行可能 |

### Progressive Disclosure（段階的開示）

#### 仕組み
1. **L1（メタデータ層）**: スキル名＋description（1024文字まで）のみ初期ロード
2. **L2（本文層）**: SKILL.md（500行以下）を必要時のみロード
3. **L3（詳細層）**: references/, examples/, scripts/をさらに必要時にロード

#### 効果
**従来の方法**（全てをメインプロンプトに含める）:
- 専門知識A: 5000トークン
- 専門知識B: 5000トークン
- 専門知識C: 5000トークン
- **合計: 15,000トークン（常に消費）**

**Skillsを使う方法**（Progressive Disclosure）:
- Skillメタデータ × 3: 300トークン（常に消費）
- 必要なSkillの詳細: 5000トークン（使う時だけ）
- **平均消費: 5,300トークン（約65%削減）**

### 公式推奨パターン：SubAgent → Skills

#### なぜこの構成が最適か？

1. **コンテキストの効率化**: SubAgentの独立環境内でのみSkillsを展開
2. **再利用性の向上**: 同じSkillを複数のSubAgentで共有
3. **責任の明確化**:
   - SubAgents = タスク実行エンジン
   - Skills = 専門知識データベース

#### 実践例（研究エージェントシステム）
```
- Project: "研究プロジェクト全体の背景と目標"
- MCP: Brave Search, arXiv, データベース接続
- Skills:
  - "学術論文分析フレームワーク"（共有知識）
  - "統計分析手法"（共有知識）
  - "引用評価基準"（共有知識）
- SubAgents:
  - 論文検索エージェント → Skillsで分析
  - データ収集エージェント → Skillsで評価
  - レポート生成エージェント → Skillsで構造化
```

**この設計の利点**:
- 3つのSubAgentが同じSkillsを共有し、重複を排除
- 各SubAgentが独立して動作し、並列処理で処理速度向上
- 分析フレームワーク（Skills）の更新が全SubAgentに即座に反映

---

## 4. Skills実装の具体的制約

### SKILL.md設計ガイドライン

#### 厳格な制限
- **SKILL.md本文**: 500行以下
- **description**: 1024文字まで
- **ZIPファイル**: 8MBまで

#### 推奨構造
```
skills/{skill-name}/
├── SKILL.md                    # 核心プロンプト（500行以下）
│   ├── frontmatter (name, description, allowed-tools)
│   ├── 核心の目的
│   ├── 基本的な使い方
│   ├── 重要な概念
│   └── より詳しく知る（references/へのリンク）
├── references/                 # 詳細参照（必要時のみロード）
│   ├── advanced-methods.md
│   └── integration-patterns.md
├── examples/                   # 実例（学習用）
│   └── practical-example.md
└── scripts/                    # 補助スクリプト
    └── utility.sh
```

### Code execution toolベース

Claude Skillsの実装は：
- Bashコマンドをサンドボックス内で自由に実行
- package.jsonやrequirements.txtで外部モジュール利用
- SKILL.mdをエントリーポイントとして実行

---

## 5. 階層構造の理解（Codexディレクトリ構成から）

### 3つのレイヤー

#### ① 認知・選択層（Orchestration Layer）
- **AGENTS.md**: Codex（AI）へのインストラクション定義
- どのスキルを使うべきかを判断するための基準を提供

#### ② 索引・定義層（Definition & Index Layer）
- **skills/index.json (L1層)**: スキルのディレクトリ（目次）
- **browser-devtools/SKILL.md (L2層)**: 個別スキルの取扱説明書

#### ③ 実行・実体層（Implementation Layer）
- **scripts/**: 実処理を行うスクリプト群
- **resources/**: 補助資料（cheatsheet.md等）
- **package.json**: 依存関係管理

### 役割分担の明確化
1. **AIの頭脳**: AGENTS.md（全体方針）
2. **地図**: index.json（スキル一覧）
3. **マニュアル**: SKILL.md（使い方）
4. **道具**: scripts/（実行プログラム）

---

## 6. PRPへの反映が必要な重要ポイント

### 追加すべき新しい知見

#### ① MCP設計のベストプラクティス（新セクション追加）
- MCPツールは本質的にプロンプト
- 1サーバー1-2ツールの原則
- 抽象度の高いツール設計
- 類似サーバー複数接続の禁止

#### ② Code Execution × MCP統合戦略（優先度引き上げ）
- ツールコールからコード実行へのパラダイムシフト
- ファイルシステムベースのツール配置
- 98.7%トークン削減の実績
- この方向が将来の標準になることを明記

#### ③ Progressive Disclosureの具体的効果（数値追加）
- 65%コンテキスト削減（Skills）
- 98.7%トークン削減（Code Execution × MCP）
- 具体的なトークン数比較

#### ④ SubAgent→Skills連携の強調（設計パターン昇格）
- 公式推奨パターンとして明記
- 研究エージェント実例の追加
- 責任分離の明確化

#### ⑤ Skills実装の具体的制約（実装ガイド追加）
- 500行、1024文字制限
- 3層構造（L1メタデータ→L2本文→L3詳細）
- Code execution tool前提の設計

### 優先順位の再評価

**現在のPRPでの優先度**:
1. サブエージェント強化（高）
2. スキル段階的開示（高）
3. プロンプトフック（高）
4. MCP統合（中）
5. プラグイン化（中）

**ブログ知見を踏まえた新優先度**:
1. **Code Execution × MCP統合**（最高） ← 新規追加、優先度大幅引き上げ
2. **スキル段階的開示**（最高） ← Progressive Disclosureの実績明確化
3. **SubAgent→Skills連携**（最高） ← 新規追加、公式推奨パターン
4. サブエージェント強化（高）
5. プロンプトフック（高）
6. プラグイン化（中）

---

## 7. Explorerレポートへの反映が必要な重要ポイント

### 追加・修正すべきセクション

#### ① 「MCPの本質的理解」セクション（新規追加）
- MCPツール = プロンプト
- ツール定義設計の重要性
- 1-2ツール/サーバーの原則

#### ② 「Code Execution × MCPの新パラダイム」セクション（新規追加）
- ツールコール時代の終焉
- ファイルシステムベースのツール配置
- 98.7%トークン削減実績

#### ③ 「スキルの段階的開示」セクション（詳細強化）
- Progressive Disclosureの3層構造
- L1→L2→L3の具体的な動作
- 65%コンテキスト削減実績
- 500行、1024文字制限

#### ④ 「SubAgent→Skills推奨パターン」セクション（新規追加）
- 公式推奨構成として明記
- 研究エージェント実例
- 責任分離の明確化

#### ⑤ 「優先度付き推奨事項」セクション（大幅書き換え）
- Code Execution × MCP統合を最高優先度に
- SubAgent→Skills連携を高優先度に
- 具体的なトークン削減効果を明記

---

## 8. 結論

### 最重要インサイト

1. **パラダイムシフト**: ツールコール → Code Execution × MCP
2. **設計原則**: MCPツール = プロンプト（1-2ツール/サーバー）
3. **効率化実績**: 98.7%トークン削減（Code Execution）、65%削減（Skills）
4. **推奨パターン**: SubAgent → Skills連携が公式ベストプラクティス
5. **実装制約**: SKILL.md 500行、description 1024文字、3層構造

### PRPとExplorerレポートへの影響

両ドキュメントは、これらの最新知見を反映していない**時代遅れの状態**にある。
特に：
- Code Execution × MCPの重要性が全く言及されていない
- Progressive Disclosureの具体的効果（数値）が記載されていない
- SubAgent→Skills連携が公式推奨パターンとして強調されていない
- MCP設計のベストプラクティスが欠如している

**即座に修正が必要**。
