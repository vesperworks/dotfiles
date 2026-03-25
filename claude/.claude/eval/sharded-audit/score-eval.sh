#!/bin/bash
set -euo pipefail

# SHARDED Audit Eval Scorer
# Usage: ./score-eval.sh [red|green]
# Reads results and scores against expected/*.json patterns

PHASE="${1:-red}"

EVAL_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPECTED_DIR="${EVAL_DIR}/expected"
RESULTS_DIR="${EVAL_DIR}/results/${PHASE}"

if [[ ! -d "${RESULTS_DIR}" ]]; then
  echo "No results found for phase: ${PHASE}"
  exit 1
fi

echo "=== SHARDED Audit Scoring: ${PHASE} ==="
echo ""

# For each expected file, score all matching results
for expected_file in "${EXPECTED_DIR}"/*.json; do
  id="$(basename "${expected_file}" .json)"
  target="$(jq -r '.target' "${expected_file}")"
  name="$(jq -r '.name' "${expected_file}")"
  max_score="$(jq -r '.maxScore' "${expected_file}")"

  echo "--- ${id}: ${name} (${target}) ---"

  # Get all check patterns
  checks="$(jq -r '.checks | keys[]' "${expected_file}")"

  total_runs=0
  total_score=0

  for result_file in "${RESULTS_DIR}/${id}_run"*.txt; do
    [[ -f "${result_file}" ]] || continue
    run_name="$(basename "${result_file}" .txt)"
    run_score=0

    for check in ${checks}; do
      pattern="$(jq -r ".checks.${check}.pattern // empty" "${expected_file}")"
      weight="$(jq -r ".checks.${check}.weight" "${expected_file}")"
      expect="$(jq -r ".checks.${check}.expect // \"present\"" "${expected_file}")"

      if [[ -n "${pattern}" ]]; then
        if [[ "${expect}" == "absent" ]]; then
          if ! grep -qiE "${pattern}" "${result_file}" 2>/dev/null; then
            run_score=$((run_score + weight))
          fi
        else
          if grep -qiE "${pattern}" "${result_file}" 2>/dev/null; then
            run_score=$((run_score + weight))
          fi
        fi
      else
        # Manual check needed - score as 0 for automated
        echo "    [MANUAL] ${check} (weight: ${weight})"
      fi
    done

    pct=$((run_score * 100 / max_score))
    echo "  ${run_name}: ${run_score}/${max_score} (${pct}%)"
    total_score=$((total_score + run_score))
    total_runs=$((total_runs + 1))
  done

  if [[ ${total_runs} -gt 0 ]]; then
    avg_score=$((total_score / total_runs))
    avg_pct=$((avg_score * 100 / max_score))
    echo "  AVG: ${avg_score}/${max_score} (${avg_pct}%)"
  else
    echo "  No results found"
  fi
  echo ""
done
