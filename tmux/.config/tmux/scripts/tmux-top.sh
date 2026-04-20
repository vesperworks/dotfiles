#!/bin/bash
# tmux-top.sh — tmux セッション別 CPU/MEM/idle を集計表示
#
# Usage:
#   tmux-top.sh           全セッション表示（CPU 降順）
#   tmux-top.sh --idle    detached セッションのみ表示
#
# 仕組み: 各 pane の TTY (#{pane_tty}) に紐づく全プロセスの %cpu/rss を
# `ps -t` で集計し、session 単位で合算する。pane_pid は shell の PID で
# 子プロセス（claude/nvim 等）を取り逃すため、TTY 経由が正確。
#
# FLAG の意味:
#   ⚠ stale 7d+        : detached かつ 7日以上アイドル（kill 候補）
#   ⚠ detached busy    : detached なのに CPU > 1% （バックグラウンドで暴走中）

set -euo pipefail

show_idle_only=0
[ "${1:-}" = "--idle" ] && show_idle_only=1

now=$(date +%s)

tmux_data=$(tmux list-panes -a -F '#{session_name}|#{?session_attached,A,-}|#{pane_current_command}|#{pane_tty}|#{session_activity}' 2>/dev/null) || {
	echo "No tmux server / sessions" >&2
	exit 1
}

# Header
printf "%-22s %4s %-15s %7s %8s %8s %s\n" "SESSION" "ATCH" "TOP_CMD" "CPU%" "MEM(MB)" "IDLE" "FLAG"
printf "%-22s %4s %-15s %7s %8s %8s %s\n" "----------------------" "----" "---------------" "-------" "--------" "--------" "-----"

# 各 pane の TTY ベースで CPU/MEM 集計 → awk で session 単位に集約
echo "$tmux_data" | while IFS='|' read -r session attach cmd tty activity; do
	tty_short="${tty##/dev/}"
	totals=$(ps -t "$tty_short" -o %cpu=,rss= 2>/dev/null | awk '{cpu+=$1; mem+=$2} END {printf "%.1f|%d", cpu+0, mem+0}')
	echo "$session|$attach|$cmd|$totals|$activity"
done | awk -F'|' -v now="$now" -v idle_only="$show_idle_only" '
	{
		s=$1; a=$2; cmd=$3; cpu=$4; mem=$5; act=$6
		attach[s]=a
		# zsh より具体的なコマンドを優先表示
		if (cmd != "zsh" && (!(s in topcmd) || topcmd[s] == "zsh")) topcmd[s]=cmd
		else if (!(s in topcmd)) topcmd[s]=cmd
		cpu_sum[s]+=cpu+0
		mem_sum[s]+=mem+0
		if (act+0 > activity[s]) activity[s]=act
	}
	END {
		for (s in attach) {
			diff = now - activity[s]
			if (diff >= 86400) idle = sprintf("%dd", int(diff/86400))
			else if (diff >= 3600) idle = sprintf("%dh", int(diff/3600))
			else idle = sprintf("%dm", int(diff/60))

			mem_mb = int(mem_sum[s]/1024)

			flag = ""
			if (attach[s] == "-" && diff > 7*86400) flag = "⚠ stale 7d+"
			else if (attach[s] == "-" && cpu_sum[s] > 1.0) flag = "⚠ detached busy"

			if (idle_only && attach[s] != "-") next

			printf "%s\t%s\t%s\t%.1f\t%d\t%s\t%s\n", s, attach[s], topcmd[s], cpu_sum[s], mem_mb, idle, flag
		}
	}
' | sort -t$'\t' -k4 -nr | awk -F'\t' '{ printf "%-22s %4s %-15s %7.1f %8d %8s %s\n", $1, $2, $3, $4, $5, $6, $7 }'
