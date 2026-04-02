#!/bin/bash
# tmux status-right widget: show WAITING AI session count
# Output: "◐ N WAIT " (yellow) when N > 0, empty when 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cc-common.sh"

count=0

for sess in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do
	if find_waiting_pane "$sess" >/dev/null 2>&1; then
		count=$((count + 1))
	fi
done

if [ "$count" -gt 0 ]; then
	# Tokyo Night yellow: #e0af68
	echo "#[fg=#e0af68,bold]◐ ${count} WAIT #[default]"
fi
