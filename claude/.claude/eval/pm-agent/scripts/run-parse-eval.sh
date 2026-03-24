#!/bin/bash
# run-parse-eval.sh - PM Agent パース精度テスト
#
# 使用方法:
#   ./eval/pm-agent/scripts/run-parse-eval.sh <old|new> [--runs N] [--cases A1,A2,A3,A4]
#
# 説明:
#   テストケース（議事録）をClaude Code に渡し、4層構造のJSON出力を取得する。
#   Issue作成は行わず、パース結果のみを評価する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR=""
RUNS=3
CASES="A1,A2,A3,A4"
DELAY=5

usage() {
  echo "使用方法: $0 <old|new> [--runs N] [--cases A1,A2,...] [--delay SEC]"
  echo ""
  echo "引数:"
  echo "  old|new           旧版(develop)または新版(feature)の結果ディレクトリ"
  echo "  --runs N          各ケースの繰り返し回数（デフォルト: 3）"
  echo "  --cases LIST      実行するケースのカンマ区切りリスト（デフォルト: A1,A2,A3,A4）"
  echo "  --delay SEC       実行間の待機秒数（デフォルト: 5）"
  exit 1
}

# 引数パース
[[ $# -lt 1 ]] && usage
VERSION="$1"; shift

case "$VERSION" in
  old|new|split|rules|fewshot|english|unified) RESULTS_DIR="${EVAL_DIR}/results/${VERSION}" ;;
  *) echo "エラー: 第1引数は 'old', 'new', 'split', 'rules', または 'fewshot' を指定してください"; exit 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs) RUNS="$2"; shift 2 ;;
    --cases) CASES="$2"; shift 2 ;;
    --delay) DELAY="$2"; shift 2 ;;
    *) usage ;;
  esac
done

mkdir -p "$RESULTS_DIR"

PROMPT_TEMPLATE='/np:pm 以下の議事録を4層構造に分類してください。

【絶対厳守】Issue作成・GitHub操作・gh コマンド実行は禁止です。構造提案のみJSON形式で出力してください。

出力JSON形式:
{"items": [{"title": "タスク名", "type": "epic|feature|story|task|bug", "estimateHours": 2, "parent": "親タスクのタイトル（あれば、なければnull）"}], "summary": {"epic": 0, "feature": 0, "story": 0, "task": 0, "bug": 0}, "milestone": "マイルストーン名（あれば、なければnull）", "milestoneDate": "YYYY-MM（あれば、なければnull）"}

---
'

echo "📋 PM Agent パース精度テスト"
echo "  バージョン: ${VERSION}"
echo "  ケース: ${CASES}"
echo "  繰り返し: ${RUNS}回"
echo "  結果ディレクトリ: ${RESULTS_DIR}"
echo ""

IFS=',' read -ra CASE_ARRAY <<< "$CASES"

for case_id in "${CASE_ARRAY[@]}"; do
  case_file="${EVAL_DIR}/test-cases/${case_id}.md"
  if [[ ! -f "$case_file" ]]; then
    echo "⚠️ テストケースが見つかりません: ${case_file}"
    continue
  fi

  case_input=$(cat "$case_file")

  for run in $(seq 1 "$RUNS"); do
    output_file="${RESULTS_DIR}/${case_id}_run${run}.txt"
    echo "▶ ${case_id} run${run}..."

    # Claude Code のプロンプトモードで実行
    # --allowedTools は Skill(pm-agent) のみ。Bash は許可しない = gh コマンド実行不可
    claude -p "${PROMPT_TEMPLATE}${case_input}" \
      --allowedTools "Skill(pm-agent)" \
      > "$output_file" 2>/dev/null || {
        echo "  ❌ 実行失敗"
        echo '{"error": "execution_failed"}' > "$output_file"
        continue
      }

    echo "  ✅ 保存: ${output_file}"

    # レート制限回避（最後のケースの最後の実行以外は待機）
    LAST_CASE="${CASE_ARRAY[${#CASE_ARRAY[@]}-1]}"
    if [[ $run -lt $RUNS ]] || [[ "$case_id" != "$LAST_CASE" ]]; then
      echo "  ⏳ ${DELAY}秒待機..."
      sleep "$DELAY"
    fi
  done
done

echo ""
echo "✅ 完了。結果: ${RESULTS_DIR}/"
echo "次のステップ: ./eval/pm-agent/scripts/score-parse.sh ${VERSION}"
