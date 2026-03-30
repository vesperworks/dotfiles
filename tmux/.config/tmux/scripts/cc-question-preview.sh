#!/bin/bash
set -euo pipefail

# fzf --preview callback for sesh picker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cc-common.sh
source "$SCRIPT_DIR/cc-common.sh"

session_name=$(echo "$1" | awk '{print $2}')

if [ -z "$session_name" ]; then
  echo "${COLOR_DIM}No session selected${COLOR_RESET}"
  exit 0
fi

if ! tmux has-session -t "$session_name" 2>/dev/null; then
  echo "${COLOR_DIM}Directory: ${session_name}${COLOR_RESET}"
  exit 0
fi

waiting_pane=$(find_waiting_pane "$session_name")

if [ -n "$waiting_pane" ]; then
  echo "${COLOR_YELLOW}◐ WAITING — 入力待ち${COLOR_RESET}"
  echo "${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
  echo ""

  pane_content=$(tmux capture-pane -t "$waiting_pane" -pe 2>/dev/null) || true
  echo "$pane_content" | tail -25

  echo ""
  echo "${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
  echo "${COLOR_YELLOW}ctrl-y${COLOR_RESET} 選択肢を開く"
else
  local_pane=$(tmux list-panes -t "$session_name" -F "#{pane_id}" 2>/dev/null | head -1) || true

  if [ -n "$local_pane" ]; then
    pane_plain=$(tmux capture-pane -t "$local_pane" -p 2>/dev/null | tail -20) || true
    pane_output=$(tmux capture-pane -t "$local_pane" -pe 2>/dev/null | tail -20) || true

    if echo "$pane_plain" | grep -qiE "$BUSY_PATTERN"; then
      echo "${COLOR_GREEN}● BUSY — 処理中${COLOR_RESET}"
    elif echo "$pane_plain" | grep -qE -- '-- INSERT --|⏎'; then
      echo "${COLOR_BLUE}○ IDLE — 入力待ち${COLOR_RESET}"
    else
      echo "${COLOR_MAGENTA}◇ DONE — 応答完了${COLOR_RESET}"
    fi

    echo "${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
    echo ""
    echo "$pane_output"
  else
    echo "${COLOR_DIM}No panes${COLOR_RESET}"
  fi
fi
