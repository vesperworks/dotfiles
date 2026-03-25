#!/bin/bash
set -euo pipefail

# SHARDED Audit Eval Runner (E1: Output Capture)
# Usage: ./run-eval.sh [red|green] [test-id] [runs]
# Example: ./run-eval.sh red I1 3

PHASE="${1:-red}"
TEST_ID="${2:-all}"
RUNS="${3:-3}"

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
CASES_DIR="${EVAL_DIR}/test-cases"
RESULTS_DIR="${EVAL_DIR}/results/${PHASE}"

mkdir -p "${RESULTS_DIR}"

# Map test ID to command and eval wrapper
get_eval_prompt() {
  local id="$1"
  local input
  input="$(cat "${CASES_DIR}/${id}.md")"

  case "${id}" in
    I*)
      cat <<PROMPT
以下のユーザー入力に対して /vw:issue コマンドのフォーマットに従ったIssue内容を生成してください。
実際のIssue作成は不要です。フォーマットされたIssue内容のみをMarkdownで出力してください。
AskUserQuestionは使わず、テキスト出力のみにしてください。

/vw:issue ${input}
PROMPT
      ;;
    N*)
      cat <<PROMPT
以下のユーザー入力に対して /vw:note コマンドのフォーマットに従ったAtomicNote内容を生成してください。
実際のファイル作成は不要です。フォーマットされたノート内容のみをMarkdownで出力してください。
AskUserQuestionは使わず、テキスト出力のみにしてください。

/vw:note ${input}
PROMPT
      ;;
    R*)
      cat <<PROMPT
以下のユーザー入力に対して /vw:research コマンドの出力フォーマットに従ったリサーチドキュメントを生成してください。
実際のファイル作成やサブエージェント起動は不要です。フォーマットされたリサーチ内容のみをMarkdownで出力してください。
AskUserQuestionは使わず、テキスト出力のみにしてください。

/vw:research ${input}
PROMPT
      ;;
    P*)
      cat <<PROMPT
以下のユーザー入力に対して /vw:plan-prp コマンド（単一モード）のフォーマットに従ったPRPドキュメントを生成してください。
実際のファイル作成やサブエージェント起動は不要です。フォーマットされたPRP内容のみをMarkdownで出力してください。
AskUserQuestionは使わず、テキスト出力のみにしてください。

/vw:plan-prp ${input}
PROMPT
      ;;
    *)
      echo "Unknown test ID: ${id}" >&2
      exit 1
      ;;
  esac
}

run_single() {
  local id="$1"
  local run_num="$2"
  local output_file="${RESULTS_DIR}/${id}_run${run_num}.txt"
  local prompt
  prompt="$(get_eval_prompt "${id}")"

  echo "=== Running ${id} run ${run_num} ==="

  # E1: Allow Skill/Read for natural SHARDED loading
  # Block all side-effect tools
  echo "${prompt}" | claude -p \
    --allowedTools "Read,Glob,Grep,Skill" \
    --model sonnet \
    --output-format text \
    2>/dev/null \
    > "${output_file}" || true

  local size
  size="$(wc -c < "${output_file}")"
  echo "  -> ${output_file} (${size} bytes)"
}

run_all_for_id() {
  local id="$1"
  for ((i = 1; i <= RUNS; i++)); do
    run_single "${id}" "${i}"
    sleep 2  # Rate limit buffer
  done
}

if [[ "${TEST_ID}" == "all" ]]; then
  for case_file in "${CASES_DIR}"/*.md; do
    id="$(basename "${case_file}" .md)"
    run_all_for_id "${id}"
  done
else
  run_all_for_id "${TEST_ID}"
fi

echo ""
echo "=== Eval complete ==="
echo "Phase: ${PHASE}"
echo "Results: ${RESULTS_DIR}/"
echo ""
echo "Next: Score results with ./score-eval.sh ${PHASE}"
