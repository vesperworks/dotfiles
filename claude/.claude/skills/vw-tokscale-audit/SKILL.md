---
name: vw-tokscale-audit
description: tokscale の集計 JSON を統計的・構造的に解析し、トークンスパイク／モデルミスマッチ／セッション肥大／履歴リプレイ疑惑／オーバーヘッド過多の 5 カテゴリで異常を検出。アクティブな全クライアント（claude/codex/gemini/opencode 等）を横断集計し、怪しい TOP 5 と抑制案を推奨確率付きで提示。詳細レポートを `.brain/thoughts/shared/research/{date}-tokscale-audit.md` に保存する。Use when the user says 「トークン監査して」「tokscale 解析」「異常検出」「ヘビーユーザー特定」「セッションリーク調査」「課金スパイク調査」「/vw-tokscale-audit」等。NOT for 単純な消費量確認（`tokscale monthly --month` を直接実行すれば足りる）and NOT for リアルタイムモニタリング（バッチ集計の事後解析用途）。
---

# vw-tokscale-audit トークン監査スキル

トークン消費オブザーバビリティの専門家として、`tokscale` CLI の集計データを統計的・構造的に解析し、異常パターンを検出する。

## 背景（なぜこのスキルが必要か）

複数の AI クライアント（Claude Code / Codex / Gemini / OpenCode / Hermes / OpenClaw など）を併用していると、課金が膨れた時に **どのクライアントの何が原因か** が分からなくなる。`tokscale` の生 JSON はカラム数が多く、目視では気付けない異常がある:

- セッション再起動による履歴リプレイ
- 軽作業に対する高コストモデル誤ルーティング
- コンテキスト肥大化による cache token の暴走
- 単発スパイク（中央値 ×3 超）

このスキルはバッチ集計を事後解析し、**抑制すべき箇所を推奨確率付きで提示** する。アラート系ではなく、課金が気になった時の事後検視ツール。

## トリガー

ユーザーの発話例:

- 「トークン監査して」「tokscale 解析」
- 「先週のスパイクの原因調べて」「課金が伸びた理由を特定して」
- 「セッションリーク疑い」「履歴リプレイされてないか見て」
- 「ヘビーユーザー特定」「オーバーヘッド多いクライアント特定」
- 「/vw-tokscale-audit」「/vw-tokscale-audit --client claude」

## 動作環境の前提

### tokscale CLI

- 実バイナリ: `~/.bun/bin/tokscale`（bun global install 経由）
- subcommand 形式: `tokscale {monthly|hourly|models|clients|graph} [OPTIONS]`
- `--json` は subcommand 配下のフラグ（`tokscale --json` ではなく `tokscale monthly --json`）
- クライアント絞り込みフラグ: `--claude` / `--codex` / `--hermes` / `--gemini` / `--cursor` / `--amp` / `--opencode` / `--copilot` / `--openclaw` / `--pi` / `--kimi` / `--qwen` / `--roocode` / `--kilocode` / `--kilo` / `--mux` / `--crush` / `--synthetic` / `--droid`
- 期間フラグ: `--today` / `--week` / `--month` / `--year YYYY` / `--since YYYY-MM-DD` / `--until YYYY-MM-DD`
- `--group-by` の strategy（`models` subcommand のみ）: `model` / `client,model` / `client,provider,model` / `workspace,model`

### サンドボックス・ネットワーク

- `tokscale` は LiteLLM (raw.githubusercontent.com) と OpenRouter (openrouter.ai) から pricing 表を fetch する
- **両ホストとも settings.json `permissions.allow` に WebFetch(domain:...) で登録済み** → サンドボックス内で動作する
- `monthly` / `models` subcommand は pricing fetch 失敗時もキャッシュで継続するが、**`hourly` は pricing fetch 必須で失敗時 exit 1**
- 万一 network エラーで停止する場合は `dangerouslyDisableSandbox: true` で retry

### 作業ディレクトリ

- **AUDIT_DIR は絶対パス固定**: `AUDIT_DIR="/tmp/claude/tokscale-audit"`
- 理由: sandbox の write-allow prefix が `/tmp/claude/` のため、配下にネストする必要がある（`/tmp/claude-tokscale-audit` のようなフラット名は `Operation not permitted` で `mkdir` 失敗）
- `$TMPDIR` は sandbox/no-sandbox で値が変わる（`/tmp/claude-503/` vs `/var/folders/.../T/`）ため使わない
- 起動時に `mkdir -p "$AUDIT_DIR"` を実行

### シェル互換性（zsh 注意）

- jq snippet 内で **`!=`** は使わない。zsh の history expansion が `!` を `\!` にエスケープし jq compile error を起こす事象あり
- 代わりに **`(.x == y) | not`** 形式を使う（本 Skill 内の jq snippet は全てこの形式）

## 実行手順

### Phase 0: アクティブクライアント検出

`tokscale clients` でローカルにスキャン可能（msgs > 0 かつ session path ✓）なクライアントを特定する。

```bash
tokscale clients > "$AUDIT_DIR/clients.txt" 2>/dev/null
```

clients.txt の各クライアントブロックは以下の形式:

```
  Claude Code
  sessions: ~/.claude/projects ✓
  messages: 37.1K
```

**判定ルール**:
- `messages: 0` → 未使用、解析対象外（Phase 3 で「未使用」と通知）
- `sessions: ... ✗` のみ → パス無し、解析対象外
- `sessions: ... ✓` かつ `messages: > 0` → アクティブ、Phase 1 に投入

ユーザーが `--client {name}` を指定した場合は判定スキップしてそのクライアントだけ処理。

### Phase 1: データ収集（並列実行）

**期間デフォルトは `--year $(date +%Y)`**。理由: クライアントによって最終活動月が異なり、`--month` (=current month) では今月活動していないクライアントが空になる。年単位なら全クライアントの近況を揃えて見られる。

アクティブな各クライアント `$C` ごとに以下を並列実行:

| コマンド | 用途 |
|---|---|
| `tokscale monthly --json --year YYYY --$C --no-spinner 2>/dev/null` | 年次サマリ |
| `tokscale monthly --json --month --$C --no-spinner 2>/dev/null` | 当月サマリ（空の可能性あり）|
| `tokscale models --json --group-by client,model --year YYYY --$C --no-spinner 2>/dev/null` | モデルミスマッチ検出 |
| `tokscale models --json --group-by workspace,model --year YYYY --$C --no-spinner 2>/dev/null` | workspace 肥大検出 |

加えてグローバル（クライアント横断）:

| コマンド | 用途 |
|---|---|
| `tokscale hourly --json --since $(date -v-7d +%Y-%m-%d) --no-spinner 2>/dev/null` | スパイク検出（直近 7 日）|

> 期間や対象クライアント引数があれば各コマンドに反映。`--week` 等のショートハンドはユーザー要望時のみ。
> ユーザーが `--client {name}` を指定した場合は Phase 0 をスキップして該当クライアントだけ処理。

### Phase 2: 異常検出（5 カテゴリ）

#### JSON スキーマ（実フィールド名）

`monthly` / `hourly` / `models` の JSON は概ね同形:

```json
{
  "entries": [
    {
      "month": "2026-04",          // hourly は "hour", models 集計は workspaceKey/workspaceLabel/model/client 等
      "models": ["claude-sonnet-4-6", "claude-opus-4-7"],
      "input": 377501,             // input tokens
      "output": 11533089,          // output tokens
      "cacheRead": 4518616849,     // cache read tokens
      "cacheWrite": 107237402,     // cache write tokens
      "messageCount": 19392,
      "cost": 3149.15              // 実 USD（tokscale 内部で価格表から算出済み）
    }
  ],
  "totalCost": 3149.15,
  "processingTimeMs": 6284
}
```

> 重要: `cost` は tokscale が公式価格表から算出済みの **実値**。USD 推定計算は不要。

#### 共通フィルタ

すべてのカテゴリで以下を最初に適用する:

```jq
.entries
| map(select(.messageCount > 0 and ((.model == "<synthetic>") | not)))
```

> `<synthetic>` は tokscale 内部で「モデル名が判定できない message」を分類する placeholder（subagent summary、system reminder 応答など）。cost=$0 / token=0 で集計影響ゼロだが、entry に混じるとノイズになるため除外する。**隠蔽の意図ではない**。

#### 1. トークンスパイク

- ルール: hourly の合計トークンが中央値 ×3 または p90 超
- データ: hourly JSON
- 計算: 中央値ベース（p90 補助）

```jq
.entries
| map(.input + .output + .cacheRead + .cacheWrite) | sort as $sorted
| length as $n
| $sorted[$n/2|floor] as $median
| .entries
| map(select((.input + .output + .cacheRead + .cacheWrite) > ($median * 3)))
| sort_by(-(.input + .output + .cacheRead + .cacheWrite))
| .[:5]
| map("\(.hour): total=\(.input+.output+.cacheRead+.cacheWrite) msgs=\(.messageCount) cost=$\(.cost)")
| .[]
```

#### 2. モデルミスマッチ

- ルール: 高コストモデル × 軽作業
- フラグ条件: モデル名が `gpt-5-pro` / `opus*` / `o3-pro` / `claude-opus-*` のいずれか **かつ** 平均出力長 < 1K tokens **かつ** 平均単価 > $0.10/msg
- 注: Claude Code は tool-heavy で `output/msg` が短いのは構造的特徴。フラグされても **「false positive ではなく特徴情報」として残す**（隠蔽しない）。判定の根拠を証拠としてレポートに書く。

```jq
.entries
| map(select(.messageCount > 0 and ((.model == "<synthetic>") | not)))
| map(. + {
    output_per_msg: ((.output / .messageCount) | floor),
    cost_per_msg: (.cost / .messageCount),
    mismatch: (
      ((.model | test("opus|gpt-5-pro|o3-pro"; "i"))) and
      ((.output / .messageCount) < 1000) and
      ((.cost / .messageCount) > 0.10)
    )
  })
| sort_by(-.cost)
```

#### 3. セッション/workspace 肥大

- ルール: 1 workspace あたり > 1M tokens or > $50
- データ: `models --group-by workspace,model`
- 注意: tokscale は session 単位を直接公開しない。workspace 単位で代替。**警報過多になっても巨大セッション発見が目的なのでしきい値は緩めない**。

```jq
.entries
| map(select(.messageCount > 0 and ((.model == "<synthetic>") | not)))
| map(. + {
    total_tokens: (.input + .output + .cacheRead + .cacheWrite),
    overhead: (if .output > 0 then ((.input + .cacheRead + .cacheWrite) / .output) else 0 end),
    cache_per_msg: ((.cacheRead / .messageCount) | floor),
    bloat: (.cost > 50 or (.input + .output + .cacheRead + .cacheWrite) > 1000000)
  })
| sort_by(-.cost)
```

#### 4. 履歴リプレイ疑惑

- ルール: 同 workspace で 1h 以内に 3+ の hourly entry **かつ** 各 entry の `cacheRead/messageCount` が当該クライアント全体平均の 2× 以上
- データ: hourly + workspace JSON の cross reference
- workspace 情報なし fallback: hourly 単独で `cacheRead/messageCount` の outlier 検出（中央値 ×2.5 以上）

```jq
# fallback: hourly cacheRead/msg outlier
.entries
| map(select(.messageCount > 10))
| map(. + {cache_per_msg: ((.cacheRead / .messageCount) | floor)})
| (map(.cache_per_msg) | sort) as $sorted
| $sorted[length/2|floor] as $median
| map(. + {ratio: (.cache_per_msg / $median)})
| map(select(.ratio > 2.5))
| sort_by(-.cache_per_msg)
| .[:5]
```

#### 5. オーバーヘッド過多

- ルール: `(input + cacheRead + cacheWrite) / output > 1000` **または** `cacheRead / messageCount > 500K`
- 注意: Claude Code 通常運用は overhead 比 300〜500 が標準。**1000 超は明確な異常**、500〜1000 は「弱い兆候」として TOP 5 末尾 or 既に他カテゴリで FLAG された entry の補強証拠に使う。

```jq
.entries
| map(select(.messageCount > 0 and ((.model == "<synthetic>") | not)))
| map(. + {
    overhead: (if .output > 0 then ((.input + .cacheRead + .cacheWrite) / .output) else 0 end),
    cache_per_msg: ((.cacheRead / .messageCount) | floor)
  })
| map(select(.overhead > 1000 or .cache_per_msg > 500000))
| sort_by(-.overhead)
```

### Phase 3: レポート出力

要約をユーザーに表示し、詳細版を `.brain/thoughts/shared/research/{date}-tokscale-audit.md` に保存する。保存前に `mkdir -p` でディレクトリ作成。

#### ユーザー提示用（要約・チャット表示）

```
## Tokscale Audit ({期間})
総消費: {N} tokens (input/output/cacheRead/cacheWrite 内訳付き)
実 cost: ${tokscale.totalCost}
異常検出: {M} 件

### アクティブクライアント
- claude: $XXX / Y msgs
- codex: $XXX / Y msgs
- gemini: $XXX / Y msgs
（msgs=0 / ✗ のクライアントは末尾「未使用」セクションに）

### 怪しい TOP 3
1. {一行サマリー} → {抑制案}
2. ...
3. ...

最優先アクション: {top 1}
詳細: .brain/thoughts/shared/research/{date}-tokscale-audit.md
```

#### ファイル保存用（詳細・Markdown）

frontmatter は `tags: [audit, tokscale, observability]` を必ず付ける。本体テンプレ:

```markdown
## Tokscale Audit ({期間})
- 総消費: {input + output + cacheRead + cacheWrite} tokens
  - input: {N1} / output: {N2} / cacheRead: {N3} / cacheWrite: {N4}
- 実 cost: ${tokscale.totalCost}（tokscale 算出値）
- 異常検出: {M} 件

### アクティブクライアント別サマリ
| Client | Tokens | Cost ($) | msgs | 主モデル |
|---|---|---|---|---|

### 怪しい TOP 5
#### #1 {タイトル}
- 検出カテゴリ: {1-5}
- 証拠: {具体的な data point: 数値・モデル名・workspace 名}
- 推定原因: {仮説}
- 抑制案: {提案} (推奨 XX%)

### モデル別傾向
| Model | messageCount | output/msg | cost/msg | overhead比 |
|---|---|---|---|---|

### 推奨アクション（推奨確率付き）
1. {action} (XX%)
2. {action} (YY%)
3. {action} (ZZ%)

### 未使用クライアント
- Hermes Agent: msgs=0 / sessions ✗
- OpenClaw: msgs=0 / sessions ✗
（解析対象外）
```

## 検出しきい値（実データ参照のベースライン）

2026-04 月次の参考値（claude のみ、調整の基準として）:
- input=377K / output=11.5M / cacheRead=4.5B / cacheWrite=107M / messageCount=19,392 / cost=$3149
- 1 msg あたり: output ~595 tokens / cacheRead ~233K / cost ~$0.16
- overhead 比 `(input+cacheRead+cacheWrite)/output` ≈ 401（**この水準は通常運用**）

| カテゴリ | デフォルトしきい値 | 調整方針 |
|---|---|---|
| スパイク | hourly 合計が中央値 ×3 / p90 超 | 静かな期間は ×5 に緩和 |
| モデルミスマッチ | 高コスト × 平均出力 <1K × 平均単価 >$0.10/msg | 構造的特徴で false positive 多めだが**敢えて残す** |
| セッション/workspace 肥大 | 1 workspace > 1M tokens or > $50 | **巨大セッション発見が目的なので緩めない** |
| 履歴リプレイ | 1h で 3+ entry × cacheRead/msg が平均×2 | HermesAgent 専用で 1h で 5+ に緩和 |
| オーバーヘッド | `(input+cacheRead+cacheWrite)/output > 1000` or `cacheRead/msg > 500K` | リサーチ系は 1500 / 800K に緩和 |

ユーザーが「しきい値ゆるめて」「厳しく」と言ったら本表を更新。

## 言語・思考プロセス

- **Think**: English（統計用語の正確性のため）
- **Communicate（ユーザー応答）**: 日本語
- **Code comments**: English

## フォールバック

### `tokscale` コマンドが無い環境

`command -v tokscale` で事前判定。無ければ:

1. **Claude Code 単体なら**: `claude-history` CLI（brew、`alias ch=claude-history`）でセッション JSONL を読み、簡易集計を提案
2. **複数クライアント横断**: 「`bun add -g tokscale` でセットアップが必要です」と案内し中止

### サンドボックス内で `hourly` が exit 1

`raw.githubusercontent.com` と `openrouter.ai` が settings.json の WebFetch domain allowlist に登録されていれば通るはず。それでも失敗する場合:

1. `dangerouslyDisableSandbox: true` で retry
2. settings.json `permissions.allow` に `WebFetch(domain:openrouter.ai)` が無ければ追加

### 別マシンの集計が必要な場合

ローカルの `tokscale` は当該マシン分のみ集計。複数マシン横断で見たい場合は `tokscale submit` 経由でクラウド集約を提案（要 `tokscale login`）。

## 実行例

### 例 1: 履歴リプレイ検出
- 検出: 2026-04-23 09:00-22:00 に hourly entries で cacheRead/msg=599K（中央値の 3×）が連続 3 件
- 推定原因: セッション再起動時の全履歴リプレイ
- 抑制案: 再起動前の `/compact` 実行 + 同セッション継続を心がける（推奨 65%）

### 例 2: 軽作業 Opus 浪費
- 検出: workspace=script-edit で `claude-opus-4-7` の messageCount=120, output=80K (output/msg=666), cost=$28 (cost/msg=$0.23)
- 推定原因: 短文編集に opus がルーティングされている
- 抑制案: `/model haiku` ルーティング切り替え（推奨 85%）

### 例 3: workspace 肥大
- 検出: workspace=aiss-neppch-design で cost=$822（月予算の 26%）、cache/msg=320K（基準 ×1.38）
- 推定原因: 大規模ファイル参照 + `/compact` 未実施
- 抑制案: `/compact` 50 turn ごと習慣化 + 巨大ファイルを部分参照に（推奨 80%）

### 例 4: スパイク逆引き
- 検出: 04-23 17:00 に 1h で 82M tokens / $46（中央値の 8.6×）
- 抑制案: `claude-history` で当該時刻の session を引き当て、ループ・無限読み込みの根本原因特定（推奨 70%）

## 注意事項（MUST）

- **モデルミスマッチで claude-opus がフラグされても隠蔽しない**。「Claude Code の構造的特徴」と注釈を添えてレポートに残す。ユーザーが情報を判断する。
- **workspace 肥大のしきい値は緩めない**。警報過多でも「巨大セッション発見」が目的。
- **抑制案は必ず推奨確率を添える**（CLAUDE.md ルール準拠）。最低 3 案、推奨 % 順。
- **検出ロジックは tokscale の JSON スキーマに依存**。スキーマ変更時は Phase 2 jq snippets を更新。スキーマが想定と違ったら推測せずユーザーに「実際の JSON を見せてください」と確認。
- **過去研究は必ず参照**: `.brain/thoughts/shared/research/2026-04-30-tokscale-audit.md`（直近 audit 結果）, `.brain/thoughts/shared/research/2026-04-29-hermesagent-token-efficiency-orchestration.md`（HermesAgent 既知パターン）
- **`tokscale` の生 JSON はチャット出力に貼らない**（行数膨張）。集計済みの数値だけを提示。
- **`cost` は tokscale 算出値をそのまま使う**。USD 推定計算を独自にやらない。
- **`2>/dev/null` を必ず付ける**。LiteLLM ネットワーク警告が JSON パースを壊さないように。
- **個人情報・機密が混入していないか**を確認してから `.brain/` に保存。`.brain/` は gitignore 対象だが、保険として workspace 名や session id にメールアドレス等が含まれていれば伏字にする。
- **Phase 0 で msgs=0 のクライアントを Phase 1 に投入しない**。空の集計を量産しても意味がない。Phase 3 末尾で「未使用」として通知するのみ。

## 対象外

- **リアルタイムアラート**（このスキルはバッチ事後解析。リアルタイム監視は別系統）
- **モデル選択の最終判断**（抑制案は提示するが、実際にモデルを切り替えるかはユーザー判断）
- **`tokscale` のセットアップ・トラブルシューティング**（このスキルは集計済みデータの解析専用）
- **session 単位の細粒度トレース**（tokscale は workspace までしか公開しない。session 詳細が要るなら `claude-history` を使う）
