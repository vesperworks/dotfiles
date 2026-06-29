# Agent Loop Pattern Catalog

6つの協調パターンの判定基準と5ムーブテンプレート集。
Phase 1（パターン判定）と Phase 3（5ムーブ設計）で参照する。

出典: Anthropic "Building effective agents" 系のエージェントデザインパターン +
Loop Engineering (Steinberger / Cherny / Osmani, 2026) の 5 ムーブ理論。

---

## 判定マトリクス

お題から6つのシグナルを判定し、マトリクスに照合して上位3パターンを推奨確率つきでサジェストする。

### シグナル定義

| # | シグナル | 判定質問 |
|---|---------|---------|
| S1 | 対象の同質性 | **同じ作業**を繰り返す対象の列（TODO、warning）か？ 対象ごとに観点や作業内容が異質（監査の観点別スキャン等）なら立たない |
| S2 | 検証の機械化 | PASS/FAIL をテスト・lint・コンパイル・数値で自動判定できるか？ **LLM judge による判定は含まない**（それは S2 不成立） |
| S3 | 並列の利得 | 分割して並列実行すると時間短縮が大きいか？ 目安: 対象 30 件超 or 逐次見積もり 60 分超 |
| S4 | 人間承認の要否 | 外部影響（push/merge/公開/送信）や不可逆操作、定性的判断を含むか？ |
| S5 | 解空間の広さ | 正解が未知で、候補の探索・比較が必要か？ |
| S6 | 磨き込みの要否 | 1発生成では足りず、評価→改善の反復で品質を上げる必要があるか？ |

### マトリクス

| パターン | S1同質 | S2機械検証 | S3並列 | S4人間承認 | S5探索 | S6磨き込み |
|---------|--------|-----------|--------|-----------|--------|-----------|
| Retry Loop | ◎ | ◎ | − | − | − | − |
| Plan-Execute-Verify | ○ | ○ | − | ○ | − | − |
| Explore-Narrow | − | − | ○ | − | ◎ | − |
| Human-in-the-Loop | − | ✕（定性的） | − | ◎ | − | − |
| Orchestrator-Workers | ○ | ○ | ◎ | − | − | − |
| Evaluator-Optimiser | − | ✕（定性的） | − | − | − | ◎ |

◎ = 強いシグナル（このパターンの決め手）/ ○ = あると適合 / − = 無関係 / ✕ = このシグナルが立つと不適合

### 判定手順（ゲート方式）

**シグナルごとの独立加算はしない。** 各パターンの「決め手」（◎ の組）は AND 条件であり、◎ シグナルが**すべて**立って初めてそのパターンに適合する。部分一致に点を与えると誤判定する（例: S1 だけ立った監査タスクを Retry と誤判定）。

1. お題から S1〜S6 を判定（不明なシグナルは AskUserQuestion で1回だけ確認）
2. **除外**: ✕ 指定のシグナルが立っているパターンを候補から外す
3. **ゲート判定**: 各パターンの ◎ シグナルが**すべて**立っているものを強候補とする
4. **典型例マッチ**: お題が各パターンの「典型例」に直接一致する場合、そのパターンを強候補に昇格する（ゲートと同格以上。例:「多角的に監査」→ Orchestrator-Workers、「議事録トリアージを毎朝」→ Plan-Execute-Verify）
5. **順位付け**: 強候補 > ○ 一致数。同格なら典型例マッチ優先。それでも並ぶ場合は順位を付けず、判断材料を description に書いてユーザーに委ねる
6. 上位3パターンを推奨確率つきで提示（合計100%、最有力を先頭に。description にはゲート充足/典型例一致の根拠と、**立っていない決め手シグナル**も正直に書く）
7. **合成を検討する**（下記）

判定に迷う組み合わせ:
- S1 と S3 が両方立つ →「同じ作業の並列化」なら Orchestrator-Workers、S3 の目安（30件/60分）未満なら Retry
- S4 が立って HITL が強候補に並ぶ → **HITL は修飾子なので単独首位にしない**。他に強候補（ゲート通過 or 典型例一致）があればそちらを主パターンとし、HITL は合成で反映する。HITL が主パターンになるのは他に強候補がない場合のみ
- 検証手段が adversarial verify（LLM judge）しかない → S2 は立たない。ただしそれ自体はパターン除外要因ではなく、Verification ムーブの設計と実行レベル（難しい）に影響するだけ

### 合成ルール

パターンは排他ではない。特に:

- **HITL は修飾子**: 単独で選ばれるより「他パターン + 人間ゲート」の形が多い。
  S4 が立ったら、主パターンに Stop 境界（承認ゲート / inbox / draft）を合成する
- **Evaluator-Optimiser は Verification の強化形**: 主パターンの Verification ムーブに
  reject+理由→再生成 のサブループとして埋め込める
- **Orchestrator-Workers の worker 内部**は Retry や Plan-Execute-Verify であることが多い

---

## Pattern 1: Retry Loop

**一言**: 同質な対象を1つずつ処理。失敗したら元に戻して次へ。

- **決め手**: S1 + S2。対象が列挙可能・検証が機械的・各処理が独立
- **実行レベル**: 基本（Sonnet-only）
- **実行形式**: `/loop 繰り返し型`（loop-patterns.md Pattern A）
- **典型例**: TODO 消化、lint warning 修正、deprecation 対応、依存更新

### 5ムーブ設計指針

| ムーブ | 設計 |
|--------|------|
| Discovery | 列挙コマンド（grep / lint --list 等）で未処理対象を1つ選ぶ |
| Handoff | 1対象 = 1イテレーション。worktree 不要（逐次のため） |
| Verification | テスト / lint 実行。失敗 → revert して次へ |
| Persistence | 処理済みリスト or 「残数」自体が状態（再実行で自然に再発見） |
| Scheduling | self-paced /loop（interval なし）。定期監視なら interval 付き |

### 落とし穴

- 同一対象の再選択 → 「直前に処理した対象を連続で選ばない」を明記（Hallucination 対策）
- 修正が別の warning を生む → 完了条件を「単調減少」でなく「最終的に0」にする

---

## Pattern 2: Plan-Execute-Verify Loop

**一言**: 毎ターン「何をすべきか判断 → 実行 → 検証」の定型サイクル。

- **決め手**: Discovery に判断が要る（単純列挙でない）+ 検証可能。定期実行と相性が良い
- **実行レベル**: 基本（Sonnet-only）。多段化するなら難しい判定 → Workflow pipeline
- **実行形式**: `/loop 目標達成型`（Pattern B）or 定期 `/loop` + 設計書
- **典型例**: 朝のトリアージ（CI失敗・Issue・議事録を読んで対処）、カバレッジ向上、定期レポート

### 5ムーブ設計指針

| ムーブ | 設計 |
|--------|------|
| Discovery | 複数ソース（CI / issues / commits / 受信箱）を読み、今ターンやる価値のある1件を判断で選ぶ |
| Handoff | 選んだ1件をタスク化。並列化するなら worktree 隔離 |
| Verification | Plan と突合する別 Sonnet evaluator（「計画通りか」+ 機械検証） |
| Persistence | 状態ファイル（`./state/*.md`）に findings + status を毎ターン追記 |
| Scheduling | interval 付き /loop or cron。状態ファイルが翌ターンの Discovery 入力になる |

### 落とし穴

- Discovery をスキルでなく壁テキストにすると腐る（Blind Loop）→ 判断基準を設計書に固定
- Plan の妥当性を Generator 自身に評価させない → 別 evaluator が Plan と結果を突合

---

## Pattern 3: Explore-Narrow Loop

**一言**: 広く探索 → 絞り込み → 深掘り。解空間が広いときの漏斗型。

- **決め手**: S5。正解が未知、候補の比較が必要、1つの検索角度では網羅できない
- **実行レベル**: 難しい寄り（並列探索の利得が大きい）。小規模なら Sonnet-only 逐次でも可
- **実行形式**: Workflow（並列 explore → barrier で絞り込み → 深掘り）or /loop 逐次漏斗
- **典型例**: 技術選定、原因調査（マルチモーダルスイープ）、リファクタ候補の洗い出し

### 5ムーブ設計指針

| ムーブ | 設計 |
|--------|------|
| Discovery | 探索角度（by-container / by-content / by-entity / by-time 等）を列挙し、各角度に explorer を割当 |
| Handoff | 角度ごとに独立 Sonnet explorer（読み取り専用なら worktree 不要） |
| Verification | 絞り込み judge（barrier）: 全候補を集めてスコアリング・dedup。ここだけ barrier が正当 |
| Persistence | 候補リスト + 採否理由を状態ファイルに（再探索時に既知候補を除外） |
| Scheduling | 通常はワンショット多段。dry counter 付きで「新候補が2ラウンド出なければ終了」 |

### 落とし穴

- 絞り込みなしで全部深掘り → token blowout。漏斗の絞り比を設計時に決める（例: 12候補→3本命）
- 探索の網羅性を1エージェントに頼る → 角度別に分ける（multi-modal sweep）

---

## Pattern 4: Human-in-the-Loop

**一言**: ループの中に人間の承認ゲートを構造的に埋め込む。

- **決め手**: S4。外部影響・不可逆操作・定性的判断。**S2 が立たない**（機械検証で代替できない）
- **実行レベル**: 基本（Sonnet-only）
- **実行形式**: `/loop` + 各ターン確認、または inbox / draft 方式（非同期承認）
- **典型例**: Issue/PR の自動起票（draft まで）、メール下書き、リリース判断、コンテンツ公開

### 5ムーブ設計指針

| ムーブ | 設計 |
|--------|------|
| Discovery | 通常パターンと同じ |
| Handoff | 通常パターンと同じ |
| Verification | 事前チェック（機械検証+LLM）を通した上で、**最終判定は人間** |
| Persistence | inbox ファイル / draft 状態。人間の判断待ちキューを状態として持つ |
| Scheduling | 同期型: 各ターン AskUserQuestion / 非同期型: inbox に積んで人間のペースで捌く |

### 落とし穴

- 「人間に見せる」だけで承認を求めない → cognitive surrender の入口。明示的な Yes/No を取る
- 全件承認にすると人間がボトルネック → 事前チェックで自明なものを間引き、判断が要るものだけ inbox へ
- **Workflow の agent 内では AskUserQuestion が使えない** → 同期承認が要るなら /loop 型にする

---

## Pattern 5: Orchestrator-Workers

**一言**: 分割統治。orchestrator がタスクを分割し、Sonnet workers が並列処理、結果を統合。

- **決め手**: S3。大規模・分割可能・並列で時間短縮が大きい
- **実行レベル**: 難しい（Sonnet 連携）
- **実行形式**: Workflow（pipeline / parallel + `model: 'sonnet'` workers）。ファイル変更を伴うなら worktree 隔離必須
- **典型例**: 大規模リファクタ・マイグレーション、リポジトリ横断監査、多次元レビュー

### 5ムーブ設計指針

| ムーブ | 設計 |
|--------|------|
| Discovery | orchestrator が作業リストを列挙（scout inline first: 先にメインで対象を洗い出してから fan-out） |
| Handoff | worker ごとに worktree 隔離（Tangled Loop 防止）。読み取り専用 worker は不要 |
| Verification | worker とは**別の** Sonnet reviewer が各成果を検証（worker の自己申告を信用しない） |
| Persistence | 各 worker は schema 強制の構造化出力 → orchestrator が統合して状態ファイルへ |
| Scheduling | 通常ワンショット。定期化するなら外側に Plan-Execute-Verify を被せる |

### 落とし穴

- 全 worker が同一ディレクトリに書く → Tangled Loop。`isolation: 'worktree'` を明示
- worker 数を固定で大きくする → budget guard（`budget.remaining()`）でスケール制御
- worker の返り値を検証なしで統合 → Nodding Loop。reviewer 段を必ず挟む

---

## Pattern 6: Evaluator-Optimiser

**一言**: Generator と Evaluator の maker–checker 対。reject + 理由 → 再生成で磨き込む。

- **決め手**: S6。品質基準は言語化できるが機械検証できない（文章品質、設計、UX）
- **実行レベル**: 難しい（Sonnet 連携）。**Sonnet-only 指示書では自己採点に堕ちるため、必ず別エージェントに分離する**
- **実行形式**: Workflow（generate → 懐疑 judge → reject なら理由付きで再生成、N ラウンド上限）
- **典型例**: ドキュメント/レポート生成、設計案の磨き込み、テストケースの網羅性向上

### 5ムーブ設計指針

| ムーブ | 設計 |
|--------|------|
| Discovery | 初回入力（要件・素材）の受領。反復中は evaluator の reject 理由が次の入力 |
| Handoff | Generator と Evaluator は**別の Sonnet agent 呼び出し**（同一コンテキスト内の自問自答は不可） |
| Verification | Evaluator は「壊れている前提」で開始（DO NOT praise. Find what fails.）。動かせるものは動かして判定 |
| Persistence | 各ラウンドの出力 + reject 理由を保存（振動検知: 同じ指摘が2回出たら人間へ） |
| Scheduling | ラウンド上限（デフォルト3〜5）+ 「evaluator が PASS」で終了 |

### 落とし穴

- Generator に自己評価させる → 毎回自分を褒めて終わる（論文の核心的警告）
- Evaluator の基準が曖昧 → reject 理由が毎回変わり収束しない。チェックリストを設計書に固定
- 無限磨き込み → ラウンド上限 + 「前ラウンドと同じ指摘なら停止して人間へ」

---

## 設計書テンプレート（Phase 5 成果物）

設計書は「他環境の Sonnet に渡してもそのまま動く」手順駆動レベルまで具体化する。
コマンドは実物を書く（プレースホルダを残さない）。

```markdown
# Loop Design: {title}

- 日付: {date} / パターン: {pattern}（+合成: {modifiers}）
- 実行レベル: 基本（Sonnet-only）| 難しい（Sonnet 連携 Workflow）
- 実行形式: /loop | Workflow

## Goal / 完了条件

- ゴール: {measurable goal}
- 完了条件（目標達成型）: {condition}（自動判定コマンド: `{cmd}`。閾値・severity・対象範囲をフラグで固定し多義性を残さない）
  - 永続型（毎朝回す等、"完了"がないジョブ）の場合はこの欄を「1ターンの成功条件」に読み替える: {その朝の未処理分が0 等}
- 停止条件: 最大 {N} イテレーション / 同一エラー {M} 回連続 / dry {K} ラウンド

## 5ムーブ

| ムーブ | 設計 |
|--------|------|
| Discovery | {何を読んで今ターンの仕事を見つけるか。コマンド実物} |
| Handoff | {隔離単位。worktree 要否} |
| Verification | {誰が「No」と言うか。Generator と別であること} |
| Persistence | {状態ファイルのパスと1行のフォーマット。既定: リポジトリルートの `.brain/{project}/loop-state/{slug}.md`} |
| Scheduling | {何が次のターンを回すか} |

## 実行手順（Sonnet 用・番号付き）

1. {具体的な手順。コマンドは実物}
2. ...

## Evaluator 指示（別エージェント用）

ROLE: 懐疑的レビュアー。この成果物は壊れている前提で検査する。褒めない。
CHECK（順に）:
1. {動かして確認する項目}
2. ...
VERDICT: 全チェック PASS のときのみ PASS。それ以外は REJECT + 理由列挙。

## Stop 境界（人間の扉）※必須・スキップ不可

- マージしない・削除しない・自信が持てないものは {inbox path} へ
- 人間チェックポイント: {どこで人間が見るか}

## アンチパターン監査結果

| 監査 | 結果 |
|------|------|
| Nodding（検証スキップ） | {OK/対策} |
| Amnesiac（永続化スキップ） | {OK/対策} |
| Manual（スケジュールスキップ） | {OK/対策} |
| Blind（発見スキップ） | {OK/対策} |
| Tangled（隔離スキップ） | {OK/対策} |

## コスト上限

- token cap: {per-run / daily} / 最大リトライ: {N}
- 予想規模: イテレーション {N} 回 × {X} 分 ≒ {Y}
```
