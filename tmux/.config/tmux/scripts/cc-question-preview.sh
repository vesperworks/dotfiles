#!/bin/bash
set -euo pipefail

# fzf --preview callback for sesh picker
# Shows WAITING pane question content or session overview

# === Tokyo Night カラー定義 ===
COLOR_YELLOW=$'\033[38;2;224;175;104m'  # #e0af68 (WAITING)
COLOR_BLUE=$'\033[38;2;122;162;247m'    # #7aa2f7 (IDLE)
COLOR_GREEN=$'\033[38;2;115;218;202m'   # #73daca (BUSY)
COLOR_DIM=$'\033[38;2;86;95;137m'       # #565f89
COLOR_RESET=$'\033[0m'

# AI CLI process names (same as sesh-sessions.sh)
AI_COMM_NAMES='claude|agent|codex|gemini'

# WAITING detection patterns (same as sesh-sessions.sh detect_ai_status)
WAITING_PATTERN='esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'
BUSY_PATTERN='esc to interrupt|ctrl\+c to interrupt'

# Extract session name from fzf line (icon + name format)
session_name=$(echo "$1" | awk '{print $2}')

if [ -z "$session_name" ]; then
  echo "${COLOR_DIM}No session selected${COLOR_RESET}"
  exit 0
fi

# Check if this is a tmux session
if ! tmux has-session -t "$session_name" 2>/dev/null; then
  echo "${COLOR_DIM}Directory: ${session_name}${COLOR_RESET}"
  exit 0
fi

# Find WAITING pane with AI process
find_waiting_pane() {
  local sess=$1
  while IFS=$'\t' read -r pane_pid pane_id; do
    [ -z "$pane_pid" ] && continue

    # Check if pane has AI CLI process
    local child_pids
    child_pids=$(ps -o pid=,ppid=,comm= -ax 2>/dev/null | awk -v root="$pane_pid" -v pat="$AI_COMM_NAMES" '
      BEGIN { queue[root]=1 }
      { pid[NR]=$1; ppid[NR]=$2; comm[NR]=$3 }
      END {
        changed=1
        while (changed) {
          changed=0
          for (i=1; i<=NR; i++) {
            if ((ppid[i] in queue) && !(pid[i] in queue)) {
              queue[pid[i]]=1; changed=1
            }
          }
        }
        for (i=1; i<=NR; i++) {
          if (pid[i] in queue) {
            n=split(comm[i], parts, "/")
            base=tolower(parts[n])
            if (base ~ "^(" pat ")$") { print pid[i]; exit }
          }
        }
      }
    ') || true

    if [ -z "$child_pids" ]; then
      continue
    fi

    # Check pane output for WAITING pattern
    local pane_output
    pane_output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -30) || true

    if echo "$pane_output" | grep -qiE "$WAITING_PATTERN"; then
      echo "$pane_id"
      return
    fi
  done < <(tmux list-panes -t "$sess" -F "#{pane_pid}	#{pane_id}" 2>/dev/null)
}

# Find pane status and display preview
waiting_pane=$(find_waiting_pane "$session_name")

if [ -n "$waiting_pane" ]; then
  # WAITING: show question context
  echo "${COLOR_YELLOW}◐ WAITING — 入力待ち${COLOR_RESET}"
  echo "${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
  echo ""

  # Capture pane content and extract question area
  pane_content=$(tmux capture-pane -t "$waiting_pane" -p 2>/dev/null) || true

  # Show the last 25 lines (question context)
  echo "$pane_content" | tail -25

  echo ""
  echo "${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
  echo "${COLOR_YELLOW}ctrl-y${COLOR_RESET} yes  ${COLOR_YELLOW}ctrl-u${COLOR_RESET} no"
else
  # Not WAITING: show general pane content
  local_pane=$(tmux list-panes -t "$session_name" -F "#{pane_id}" 2>/dev/null | head -1) || true

  if [ -n "$local_pane" ]; then
    pane_output=$(tmux capture-pane -t "$local_pane" -p 2>/dev/null | tail -20) || true

    # Detect status from output
    if echo "$pane_output" | grep -qiE "$BUSY_PATTERN"; then
      echo "${COLOR_GREEN}● BUSY — 処理中${COLOR_RESET}"
    else
      echo "${COLOR_BLUE}○ IDLE${COLOR_RESET}"
    fi

    echo "${COLOR_DIM}────────────────────────────────${COLOR_RESET}"
    echo ""
    echo "$pane_output"
  else
    echo "${COLOR_DIM}No panes${COLOR_RESET}"
  fi
fi
