#!/bin/bash
set -euo pipefail

# Send response to WAITING AI pane in a tmux session
# Detects prompt type and sends appropriate key sequence:
#   - Permission prompt ([y/n]) → sends "y"/"n" + Enter
#   - Selector UI (AskUserQuestion) → sends Enter (accept) or Escape (cancel)
# Usage: cc-wait-respond.sh <session_name> <y|n|text>

session_name="${1:-}"
response="${2:-}"

if [ -z "$session_name" ] || [ -z "$response" ]; then
  echo "Usage: cc-wait-respond.sh <session_name> <y|n|text>" >&2
  exit 1
fi

# AI CLI process names
AI_COMM_NAMES='claude|agent|codex|gemini'
# Prompt types:
#   Permission: [y/n], allow command, Allow execution, Do you want, Would you like
#   Selector:   esc to cancel, enter to select, ready to submit
PERMISSION_PATTERN='\[y/n\]|\[Y/n\]|allow command|Allow execution|Do you want|Would you like'
SELECTOR_PATTERN='esc to cancel|enter to select|ready to submit'
# Find the WAITING pane with AI process, output: pane_id<TAB>prompt_type
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

    # Check pane output for WAITING pattern and detect type
    local pane_output
    pane_output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -30) || true

    if echo "$pane_output" | grep -qiE "$SELECTOR_PATTERN"; then
      printf '%s\t%s\n' "$pane_id" "selector"
      return
    elif echo "$pane_output" | grep -qiE "$PERMISSION_PATTERN"; then
      printf '%s\t%s\n' "$pane_id" "permission"
      return
    fi
  done < <(tmux list-panes -t "$sess" -F "#{pane_pid}	#{pane_id}" 2>/dev/null)
}

result=$(find_waiting_pane "$session_name")

if [ -z "$result" ]; then
  # No WAITING pane found — silent exit (not an error)
  exit 0
fi

pane_id=$(echo "$result" | cut -f1)
prompt_type=$(echo "$result" | cut -f2)

# Send appropriate key sequence based on prompt type
case "$prompt_type" in
  selector)
    # AskUserQuestion / interactive selector UI
    # y → Enter (accept current selection)
    # n → Escape (cancel)
    if [ "$response" = "y" ]; then
      tmux send-keys -t "$pane_id" Enter
    elif [ "$response" = "n" ]; then
      tmux send-keys -t "$pane_id" Escape
    else
      # Free text: type it and press Enter
      tmux send-keys -t "$pane_id" "$response" Enter
    fi
    ;;
  permission)
    # Permission prompt ([y/n])
    tmux send-keys -t "$pane_id" "$response" Enter
    ;;
  *)
    # Fallback: send as-is
    tmux send-keys -t "$pane_id" "$response" Enter
    ;;
esac
