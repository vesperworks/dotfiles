#!/bin/bash
set -euo pipefail

# WAITING ペインの番号付き選択肢を選択して送信する
# Usage: cc-wait-respond.sh <session_name> <option_number>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cc-common.sh
source "$SCRIPT_DIR/cc-common.sh"

session_name="${1:-}"
option_number="${2:-}"

if [ -z "$session_name" ] || [ -z "$option_number" ]; then
  echo "Usage: cc-wait-respond.sh <session_name> <option_number>" >&2
  exit 1
fi

pane_id=$(find_waiting_pane "$session_name")

if [ -z "$pane_id" ]; then
  exit 0
fi

# Up をバッチ送信して先頭に移動、Down で N 番目へ、Enter で確定
# sleep はエスケープシーケンスの誤解釈を防ぐため
tmux send-keys -t "$pane_id" Up Up Up Up Up Up Up Up Up Up
sleep 0.1

down_keys=""
for _ in $(seq 2 "$option_number"); do
  down_keys+="Down "
done
if [ -n "$down_keys" ]; then
  # shellcheck disable=SC2086
  tmux send-keys -t "$pane_id" $down_keys
  sleep 0.1
fi

tmux send-keys -t "$pane_id" Enter
