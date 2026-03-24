#!/bin/bash
# score-parse.sh - パース結果のスコアリング
#
# 使用方法:
#   ./eval/pm-agent/scripts/score-parse.sh <old|new|compare>
#
# 説明:
#   run-parse-eval.sh の出力から JSON を抽出し、期待値と比較してスコアを算出する。
#   compare モードでは old/new 両方の結果を比較表で出力する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EVAL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 出力ファイルからJSONブロックを抽出
extract_json() {
  local file="$1"
  # ```json ... ``` ブロックを抽出、なければファイル全体をJSONとして試行
  if grep -q '```json' "$file" 2>/dev/null; then
    sed -n '/```json/,/```/p' "$file" | sed '1d;$d'
  else
    cat "$file"
  fi
}

# タイトルマッチ（正規表現パターン対応、パイプ区切り = OR）
title_matches() {
  local title="$1"
  local pattern="$2"
  echo "$title" | grep -qiE "$pattern"
}

# 1ケースのスコア計算
score_case() {
  local case_id="$1"
  local result_file="$2"
  local expected_file="${EVAL_DIR}/expected/${case_id}.json"

  if [[ ! -f "$expected_file" ]]; then
    echo "  ⚠️ 期待値なし: ${case_id}"
    return
  fi

  local result_json
  result_json=$(extract_json "$result_file" 2>/dev/null) || {
    echo "  ❌ JSON抽出失敗: ${result_file}"
    return
  }

  # 基本チェック: items 配列が存在するか
  local item_count
  item_count=$(echo "$result_json" | jq '.items | length' 2>/dev/null) || {
    echo "  ❌ JSON パース失敗"
    return
  }

  # 期待されるタイトル数
  local expected_titles
  expected_titles=$(jq -r '.expected.requiredTitles[]' "$expected_file" 2>/dev/null)
  local expected_count
  expected_count=$(echo "$expected_titles" | wc -l | tr -d ' ')

  # タイトルマッチ（Recall計算）
  local matched=0
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    # items の各 title と照合
    local found=false
    for i in $(seq 0 $((item_count - 1))); do
      local title
      title=$(echo "$result_json" | jq -r ".items[$i].title" 2>/dev/null)
      if echo "$title" | grep -qiE "$pattern"; then
        found=true
        break
      fi
    done
    if $found; then
      matched=$((matched + 1))
    fi
  done <<< "$expected_titles"

  # Recall / Precision / F1
  local recall precision f1
  if [[ $expected_count -gt 0 ]]; then
    recall=$(echo "scale=3; $matched / $expected_count" | bc)
  else
    recall="1.000"
  fi

  # totalItems の期待値チェック
  local expected_total
  expected_total=$(jq '.expected.totalItems' "$expected_file" 2>/dev/null)

  if echo "$expected_total" | grep -q '{'; then
    # range: { "min": N, "max": M }
    local min max
    min=$(echo "$expected_total" | jq '.min')
    max=$(echo "$expected_total" | jq '.max')
    if [[ $item_count -ge $min ]] && [[ $item_count -le $max ]]; then
      precision="1.000"
    else
      precision=$(echo "scale=3; 1 - ($(echo "scale=0; if ($item_count < $min) $min - $item_count; else $item_count - $max; fi" | bc) / $item_count)" | bc 2>/dev/null || echo "0.500")
    fi
  else
    # exact count
    if [[ "$expected_total" != "null" ]] && [[ $item_count -eq $expected_total ]]; then
      precision="1.000"
    elif [[ "$expected_total" != "null" ]]; then
      local diff=$(( item_count > expected_total ? item_count - expected_total : expected_total - item_count ))
      precision=$(echo "scale=3; 1 - ($diff / $item_count)" | bc 2>/dev/null || echo "0.500")
    else
      precision="1.000"
    fi
  fi

  # F1
  if [[ "$recall" == "0.000" ]] && [[ "$precision" == "0.000" ]]; then
    f1="0.000"
  else
    f1=$(echo "scale=3; 2 * $recall * $precision / ($recall + $precision)" | bc 2>/dev/null || echo "0.000")
  fi

  echo "${case_id}|${recall}|${precision}|${f1}|${item_count}|${matched}/${expected_count}"
}

# メイン処理
case "${1:-}" in
  old|new)
    VERSION="$1"
    RESULTS_DIR="${EVAL_DIR}/results/${VERSION}"
    echo "📊 パース精度スコア (${VERSION})"
    echo ""
    printf "%-6s | %-8s | %-9s | %-6s | %-5s | %-10s\n" "ケース" "Recall" "Precision" "F1" "件数" "マッチ"
    echo "-------|----------|-----------|--------|-------|----------"

    for result_file in "${RESULTS_DIR}"/A*_run*.txt; do
      [[ ! -f "$result_file" ]] && continue
      filename=$(basename "$result_file" .txt)
      case_id="${filename%%_*}"
      score_case "$case_id" "$result_file"
    done | sort | while IFS='|' read -r case_id recall precision f1 count match; do
      printf "%-6s | %-8s | %-9s | %-6s | %-5s | %-10s\n" "$case_id" "$recall" "$precision" "$f1" "$count" "$match"
    done
    ;;

  compare)
    echo "📊 旧版 vs 新版 比較"
    echo ""
    echo "TODO: old/new 両方のスコアを集約して比較表を生成"
    echo "各ケースの3回平均F1を算出し、delta を計算"
    ;;

  *)
    echo "使用方法: $0 <old|new|compare>"
    exit 1
    ;;
esac
