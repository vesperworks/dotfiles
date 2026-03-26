#!/bin/bash
set -euo pipefail

# SHARDED Audit Eval Runner (E1: Output Capture)
# Usage: ./run-eval.sh [red|green] [test-id] [runs]
#
# RED:   command展開 → Skill tool呼出（SHARDEDパターン発生）
# GREEN: 統合SKILL.md全文を1メッセージで直接渡す（0ホップ）

PHASE="${1:-red}"
TEST_ID="${2:-all}"
RUNS="${3:-3}"

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
CASES_DIR="${EVAL_DIR}/test-cases"
RESULTS_DIR="${EVAL_DIR}/results/${PHASE}"
SKILLS_DIR="${EVAL_DIR}/../../skills"

mkdir -p "${RESULTS_DIR}"

# Map test ID to skill path
get_skill_path() {
  local id="$1"
  case "${id}" in
    I*) echo "${SKILLS_DIR}/vw-issue/SKILL.md" ;;
    N*) echo "${SKILLS_DIR}/vw-note/SKILL.md" ;;
    R*) echo "${SKILLS_DIR}/vw-research/SKILL.md" ;;
    P*) echo "${SKILLS_DIR}/prp-generation/SKILL.md" ;;
    *) echo "Unknown test ID: ${id}" >&2; exit 1 ;;
  esac
}

# RED: command展開 → Skill tool経由（SHARDED 2+ hops）
get_red_prompt() {
  local id="$1"
  local input
  input="$(cat "${CASES_DIR}/${id}.md")"

  local cmd_name
  case "${id}" in
    I*) cmd_name="/vw:issue" ;;
    N*) cmd_name="/vw:note" ;;
    R*) cmd_name="/vw:research" ;;
    P*) cmd_name="/vw:plan-prp" ;;
  esac

  local task_type
  case "${id}" in
    I*) task_type="Issue内容" ;;
    N*) task_type="AtomicNote内容" ;;
    R*) task_type="リサーチドキュメント" ;;
    P*) task_type="PRPドキュメント" ;;
  esac

  cat <<PROMPT
以下のユーザー入力に対して ${cmd_name} コマンドのフォーマットに従った${task_type}を生成してください。
実際のファイル作成やサブエージェント起動は不要です。フォーマットされた内容のみをMarkdownで出力してください。
AskUserQuestionは使わず、テキスト出力のみにしてください。

${cmd_name} ${input}
PROMPT
}

# GREEN: 統合SKILL.md全文を1メッセージで渡す（0 hops）
get_green_prompt() {
  local id="$1"
  local input
  input="$(cat "${CASES_DIR}/${id}.md")"
  local skill_path
  skill_path="$(get_skill_path "${id}")"

  if [[ ! -f "${skill_path}" ]]; then
    echo "Skill file not found: ${skill_path}" >&2
    exit 1
  fi

  local skill_content
  skill_content="$(cat "${skill_path}")"

  local task_type
  case "${id}" in
    I*) task_type="Issue内容" ;;
    N*) task_type="AtomicNote内容" ;;
    R*) task_type="リサーチドキュメント" ;;
    P*) task_type="PRPドキュメント" ;;
  esac

  cat <<PROMPT
以下のスキル定義に従って、ユーザー入力に対するフォーマットされた${task_type}を生成してください。
実際のファイル作成やサブエージェント起動は不要です。フォーマットされた内容のみをMarkdownで出力してください。
AskUserQuestionは使わず、テキスト出力のみにしてください。

--- SKILL DEFINITION ---
${skill_content}
--- END SKILL DEFINITION ---

--- USER INPUT ---
${input}
--- END USER INPUT ---
PROMPT
}

run_single() {
  local id="$1"
  local run_num="$2"
  local output_file="${RESULTS_DIR}/${id}_run${run_num}.txt"
  local prompt

  if [[ "${PHASE}" == "red" ]]; then
    prompt="$(get_red_prompt "${id}")"
  else
    prompt="$(get_green_prompt "${id}")"
  fi

  echo "=== Running ${id} run ${run_num} (${PHASE}) ==="

  if [[ "${PHASE}" == "red" ]]; then
    # RED: Allow Skill tool for natural SHARDED loading
    echo "${prompt}" | claude -p \
      --allowedTools "Read,Glob,Grep,Skill" \
      --model sonnet \
      --output-format text \
      2>/dev/null \
      > "${output_file}" || true
  else
    # GREEN: No Skill tool needed (all content inline)
    echo "${prompt}" | claude -p \
      --allowedTools "Read,Glob,Grep" \
      --model sonnet \
      --output-format text \
      2>/dev/null \
      > "${output_file}" || true
  fi

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
