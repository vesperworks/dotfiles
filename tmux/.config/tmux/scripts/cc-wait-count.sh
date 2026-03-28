#!/bin/bash
# tmux status-right widget: show WAITING AI session count
# Output: "◐ N WAIT " (yellow) when N > 0, empty when 0

AI_COMM_NAMES='claude|agent|codex|gemini'
WAITING_PATTERN='esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'

count=0

for sess in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do
  found=false
  while IFS=$'\t' read -r pane_pid pane_id; do
    [ -z "$pane_pid" ] && continue
    $found && continue

    # Quick check: does this pane have an AI process?
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
            if (base ~ "^(" pat ")$") { print 1; exit }
          }
        }
      }
    ') || true

    [ -z "$has_ai" ] && continue

    output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -30) || true
    if echo "$output" | grep -qiE "$WAITING_PATTERN"; then
      count=$((count + 1))
      found=true
    fi
  done < <(tmux list-panes -t "$sess" -F "#{pane_pid}	#{pane_id}" 2>/dev/null)
done

if [ "$count" -gt 0 ]; then
  # Tokyo Night yellow: #e0af68
  echo "#[fg=#e0af68,bold]◐ ${count} WAIT #[default]"
fi
