#!/bin/bash
# claude-wake.sh — closed-sessions.jsonl から fzf picker で resume
#
# claude-sleep.sh --all で記録されたセッションを fzf で選び、
# 元の作業ディレクトリに cd して `claude --resume <id>` を実行する。
#
# tmux popup から呼び出されることを前提に、bash で書かれている
# （zsh function 版だと `zsh -ic` 起動コストが大きい）。

set -euo pipefail

LOG="$HOME/.claude/closed-sessions.jsonl"

if [ ! -s "$LOG" ]; then
	echo "No closed sessions yet."
	echo "Run claude-sleep --all to populate, or ^s in sesh picker."
	echo ""
	read -r -p "Press Enter to close..."
	exit 1
fi

# 直近 50 件を fzf で表示
selected=$(tail -r "$LOG" | head -50 | jq -r '
  [(.closed_at | tostring), .session, .pwd, (.claude_session_id // "?"), (.idle_hours | tostring)] | @tsv
' | awk -F'\t' '{
  cmd="date -r " $1 " +\"%m/%d %H:%M\""
  cmd | getline d; close(cmd)
  printf "%s\t%s\t%s\t%s\tidle %sh\n", d, $2, $3, $4, $5
}' | column -t -s $'\t' | fzf --layout=reverse \
	--prompt='💤 → wake> ' \
	--header='WHEN  TMUX_SESSION  PWD  CLAUDE_SESSION_ID  IDLE')

[ -z "$selected" ] && exit 0

# column -t は連続スペースで区切る → awk の field number で抽出
# Field: 1:date_md 2:date_hm 3:tmux_session 4:pwd 5:session_id 6:"idle" 7:"Nh"
pwd_path=$(echo "$selected" | awk '{print $4}')
session_id=$(echo "$selected" | awk '{print $5}')

if [ ! -d "$pwd_path" ]; then
	echo "PWD does not exist: $pwd_path"
	read -r -p "Press Enter to close..."
	exit 1
fi

cd "$pwd_path" || exit 1

if [ "$session_id" = "?" ] || [ -z "$session_id" ]; then
	echo "No session_id recorded — starting fresh claude in $pwd_path"
	exec claude
else
	echo "Resuming claude session $session_id in $pwd_path"
	exec claude --resume "$session_id"
fi
