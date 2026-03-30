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

# セッション情報を取得
win_count=$(tmux list-windows -t "$session_name" 2>/dev/null | wc -l | tr -d ' ') || win_count=0
pane_count=$(tmux list-panes -t "$session_name" -a 2>/dev/null | wc -l | tr -d ' ') || pane_count=0
session_path=$(tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null) || session_path=""
session_path=${session_path/#$HOME/\~}

# セパレータ（プレビュー幅に合わせて長めに）
sep="${COLOR_DIM}$(printf '%.0s─' {1..44})${COLOR_RESET}"

# ヘッダー: セッション名 + メタ情報
echo "${COLOR_DIM}${session_name}  ${win_count}w ${pane_count}p${COLOR_RESET}"
if [ -n "$session_path" ]; then
  echo "${COLOR_DIM}${session_path}${COLOR_RESET}"
fi

waiting_pane=$(find_waiting_pane "$session_name") || true

if [ -n "$waiting_pane" ]; then
  echo ""
  echo "${COLOR_YELLOW}◐ WAITING — 入力待ち${COLOR_RESET}"
  echo "$sep"
  echo ""

  pane_content=$(tmux capture-pane -t "$waiting_pane" -S - -pe 2>/dev/null | trim_blank_lines | tail -25) || true
  echo "$pane_content"

  echo ""
  echo "$sep"
  echo "${COLOR_YELLOW}ctrl-e${COLOR_RESET} 選択肢を開く  ${COLOR_YELLOW}ctrl-y${COLOR_RESET} Enter送信"
else
  local_pane=$(tmux list-panes -t "$session_name" -F "#{pane_id}" 2>/dev/null | head -1) || true

  if [ -n "$local_pane" ]; then
    pane_plain=$(tmux capture-pane -t "$local_pane" -S - -p 2>/dev/null | trim_blank_lines | tail -20) || true
    pane_output=$(tmux capture-pane -t "$local_pane" -S - -pe 2>/dev/null | trim_blank_lines | tail -20) || true

    echo ""
    if echo "$pane_plain" | grep -qiE "$BUSY_PATTERN"; then
      echo "${COLOR_GREEN}● BUSY — 処理中${COLOR_RESET}"
    elif echo "$pane_plain" | grep -qE -- '-- INSERT --|⏎'; then
      echo "${COLOR_BLUE}○ IDLE — 入力待ち${COLOR_RESET}"
    else
      echo "${COLOR_MAGENTA}◇ DONE — 応答完了${COLOR_RESET}"
    fi
    echo "$sep"
    echo ""
    echo "$pane_output"
  else
    echo ""
    echo "${COLOR_DIM}No panes${COLOR_RESET}"
  fi
fi
