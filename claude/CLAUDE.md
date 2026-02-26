# CLAUDE.md

This file provides guidance to Claude Code when working with the claude package.

## このパッケージの構造

このパッケージは **dotfiles リポジトリ内の Claude Code 設定パッケージ** です。

### GNU Stow 構成

```
~/dotfiles/claude/           ← stow パッケージ
├── CLAUDE.md                ← このファイル（パッケージ固有、stow除外）
├── .stow-local-ignore       ← CLAUDE.md を stow 対象から除外
└── .claude/                 ← stow -t ~ claude → ~/.claude/ にリンク
    ├── CLAUDE.md            ← グローバル設定（全プロジェクト共通）
    ├── settings.json        ← Claude Code 設定
    ├── agents/              ← 16エージェント
    ├── commands/            ← カスタムコマンド（/vw:*）
    ├── skills/              ← スキル（Progressive Disclosure）
    ├── hooks/               ← フック
    ├── scripts/             ← 共通ユーティリティ
    ├── rules/               ← コーディング規約
    └── ATTRIBUTION.md
```

### ファイル修正時の注意

| 対象 | ファイル | 影響範囲 |
|------|----------|----------|
| 全プロジェクト共通ルール | `.claude/CLAUDE.md` | すべての Claude Code セッション |
| このパッケージ固有 | `CLAUDE.md`（このファイル） | claude パッケージ開発時のみ |

**新しいグローバルルールの追加・変更は `.claude/CLAUDE.md` に行ってください。**

---

## パッケージ概要

Claude Code のカスタムコマンド・エージェント・スキルを管理するパッケージ。GNU Stow で `~/.claude/` にリンクし、設定を即座に反映します。

## 技術スタック

- **Language**: Markdown, Bash
- **Runtime**: Bash (macOS/Linux)
- **Tools**: rg, bat, eza, fd (モダンCLIツール)
- **MCP Integration**: Context7, Playwright

## 重要なコマンド

### カスタムコマンド
- `/vw:commit`: スマートコミット
- `/vw:plan-prp "feature-name"`: PRP生成（対話的仕様決定）
  - **単一モード**: 高速PRP生成（デフォルト）
  - **マルチモード**: 4つのアプローチ（Minimalist/Architect/Pragmatist/Conformist）で並列生成・評価
  - **トリガーワード**: 「複数案で」「4パターンで」「比較検討して」「じっくり考えて」「マルチモード」
- `/vw:dev-prp [PRP_PATH]`: PRP実行（TDD実装→検証ループ）
- `/vw:pm [meeting_notes]`: GitHub Projects PM Agent（議事録→タスク作成、Projects管理）
- `/vw:run`: Playwright MCPでユーザー操作テスト
- `/vw:research`: 対話型リサーチアシスタント（壁打ち・インタビュー・包括的調査）
- `/vw:note [term]`: 技術用語の解説・記録（Atomic Notes形式）
- `/vw:task`: プロジェクト進捗管理・PRP整理（自動スキャン）
- `/vw:reader <path_or_url>`: ドキュメント並走リーダー（ネタバレなし・Q&A追跡）
- `/vw:websearch "query"`: Gemini CLIによるWeb検索（概念理解用）

### エージェント直接呼び出し
- `@vw-dev-orchestra`: PRP実行オーケストレーター（TDD実装→検証→デバッグループ）
- `@vw-prp-orchestrator`: PRP生成オーケストレーター（SubAgent→Skillsパターン）
- `@vw-pm-agent`: GitHub Projects PM Agent（議事録→タスク作成）

## コーディング規約

### Bashスクリプト
- `#!/bin/bash` で開始（shebang必須）
- 2スペースインデント
- 関数はスネークケース（`function_name`）
- エラーハンドリング必須（`set -euo pipefail` 推奨）
- shellcheck準拠

### Markdown
- 見出しレベルの一貫性
- コードブロックに言語指定
- リスト形式の統一

### 設計原則・品質コマンド

グローバル `.claude/CLAUDE.md` の規約に従う。

詳細は [.claude/rules/](.claude/rules/) 参照。

## 開発ワークフロー

### 推奨フロー

```
/vw:research     → 探索・技術調査（hl-* subAgents）
      │
      ▼
/vw:plan-prp     → PRP生成（vw-prp-orchestrator）
      │
      ▼
/vw:dev-prp      → PRP実行（vw-dev-orchestra）
      │               ├── Main Claude: TDD実装（直接実行）
      │               ├── vw-dev-reviewer: 静的解析（subAgent）
      │               └── vw-dev-tester: E2E（subAgent）
      ▼
/vw:commit       → スマートコミット
```

### エージェント構成（16エージェント）

#### 開発ワークフローエージェント（vw-devシリーズ: 3）
- **vw-dev-orchestra**: PRP実行オーケストレーター（TDD実装→検証→デバッグループ制御）
- **vw-dev-reviewer**: 静的解析・品質ゲート（Lint/Format/Test/Build）
- **vw-dev-tester**: E2Eテスト（Playwright MCP）

#### PRP生成エージェント（vw-prpシリーズ: 5）
- **vw-prp-orchestrator**: PRP生成オーケストレーター（単一/マルチモード制御）
- **vw-prp-plan-minimal**: Minimalistアプローチ（YAGNI+KISS、haiku）
- **vw-prp-plan-architect**: Architectアプローチ（SOLID+DRY、sonnet）
- **vw-prp-plan-pragmatist**: Pragmatistアプローチ（バランス型、sonnet）
- **vw-prp-plan-conformist**: Conformistアプローチ（公式準拠、sonnet+Context7）

#### PMエージェント（vw-pmシリーズ: 1）
- **vw-pm-agent**: GitHub Projects PM Agent（議事録→タスク作成、4層構造管理）

#### ナレッジベースエージェント（vw-notetaker: 1）
- **vw-notetaker**: 技術用語解説・Atomic Notes記録（MOC自動提案）

#### 内部サブエージェント（hl-*シリーズ: 6）
`/vw:research`や`/vw:task`から並列起動される軽量エージェント：
- **hl-codebase-locator**: コードベース内のファイル・コンポーネント位置特定
- **hl-codebase-analyzer**: 実装詳細の分析（HOWを正確にドキュメント化）
- **hl-codebase-pattern-finder**: 類似実装・パターンの検索
- **hl-thoughts-locator**: .brain/thoughts/内の関連ドキュメント検索
- **hl-thoughts-analyzer**: ドキュメントから高価値な洞察を抽出
- **hl-web-search-researcher**: Web検索で最新情報を収集

## vw-* エージェント起動ルール

ユーザーが以下の要求をした場合、適切なエージェントを**必ず**使用してください。

### vw-dev-orchestra（PRP実行オーケストレーター）
以下のいずれかの場合に使用：
- PRPを使った実装（例: 「PRPを使って実装」「PRP/feature.mdで実装」）
- TDD実装→検証ループ（例: 「TDDで開発」「テスト駆動で実装」）
- 複数コンポーネント開発（例: 「全体の実装」「システム全体」）

### vw-prp-orchestrator（PRP生成統括）
以下のいずれかの場合に使用：
- PRP生成（例: 「PRP作って」「PRP生成」）
- 複数案での設計比較（例: 「複数案で」「4パターンで」「比較検討して」）

### vw-dev-tester（E2Eテスト）
以下のいずれかの場合に使用：
- ブラウザテスト（例: 「E2Eテスト」「Playwrightでテスト」）
- 実装完了後の検証（例: 「本番前の最終確認」）

### vw-dev-reviewer（静的解析・品質ゲート）
以下のいずれかの場合に使用：
- コードレビュー（例: 「レビューして」「品質確認」）
- 品質ゲート実行（例: 「Lint/Format/Test/Build」）

## Web検索ツールの使い分け

| ツール | 用途 | 特徴 |
|--------|------|------|
| WebSearch（組み込み） | 公式ドキュメント、引用が必要な場合 | ソースURL付き |
| /vw:websearch（Gemini CLI） | 技術背景、設計思想、比較分析 | 深い解説（URLなし） |

## ディレクトリ規約

### 中間成果物・ナレッジ（.brain/）
- **目的**: エージェントの中間成果物・ドキュメント・ナレッジ
- **形式**: `.brain/{project}/{category}/{timestamp}-{name}.md`
- **gitignore**: 公開リポは ignore 必須

### PRP管理ルール
すべてのPRPは以下の3つのディレクトリのいずれかに配置：
- **.brain/{project}/prp/done/** - 実装完了・テスト通過・マージ済み
- **.brain/{project}/prp/cancel/** - キャンセル・要件変更・不要
- **.brain/{project}/prp/tbd/** - 要件不明確・意思決定待ち

## 品質要件

### Bashスクリプト品質チェック
- **Shellcheck**: Bashスクリプトの静的解析
- **構文チェック**: `bash -n script.sh` で構文エラー検出
- **実行テスト**: テストスクリプトの実行確認

## 重要な注意事項

- **GNU Stow**: `stow -t ~ claude` で `~/.claude/` にリンク
- **stow除外**: `CLAUDE.md` はパッケージ固有のため stow 対象外（`.stow-local-ignore`）
- **Bashスクリプト品質**: shellcheckによる静的解析を推奨
- **成果物管理**: 中間結果は `.brain/` に保存（gitignore 対象）
- **モダンツール**: rg、bat、eza、fd の使用を推奨

## セットアップ

```bash
# dotfiles リポジトリから stow で適用
cd ~/dotfiles
stow -t ~ --no-folding claude

# 個別に解除
stow -t ~ -D claude
```

## Continuity Ledger

CONTINUITY.md が存在する場合、毎ターン開始時に continuity-ledger スキルに従って：
1. Ledger を読み込み、現在の状態を把握する
2. 変更があれば CONTINUITY.md を更新する
3. Ledger Snapshot を返答の冒頭に表示する
