#!/bin/bash
set -euo pipefail

# Send response to WAITING AI pane in a tmux session
# Usage: cc-wait-respond.sh <session_name> <y|n|text>

session_name="${1:-}"
response="${2:-}"

if [ -z "$session_name" ] || [ -z "$response" ]; then
  echo "Usage: cc-wait-respond.sh <session_name> <y|n|text>" >&2
  exit 1
fi

# AI CLI process names
AI_COMM_NAMES='claude|agent|codex|gemini'
WAITING_PATTERN='esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'

# Find the WAITING pane with AI process
find_waiting_pane() {
  local sess=$1
  while IFS=$'\t' read -r pane_pid pane_id; do
    [ -z "$pane_pid" ] && continue

    # Check if pane has AI CLI process
    local has_ai
    has_ai=$(ps -o pid=,ppid=,comm= -ax 2>/dev/null | awk -v root="$pane_pid" -v pat="$AI_COMM_NAMES" '
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

    if [ -z "$has_ai" ]; then
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

pane_id=$(find_waiting_pane "$session_name")

if [ -z "$pane_id" ]; then
  # No WAITING pane found — silent exit (not an error)
  exit 0
fi

# Send response to the pane
tmux send-keys -t "$pane_id" "$response" Enter
