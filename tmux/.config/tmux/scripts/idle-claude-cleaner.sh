#!/bin/bash
# idle-claude-cleaner.sh — detached pane で idle な claude プロセスを検出/kill
#
# Usage:
#   idle-claude-cleaner.sh             # 検出のみ（dry-run、デフォルト）
#   idle-claude-cleaner.sh --kill      # 該当 claude プロセスを SIGTERM + 記録
#   IDLE_HOURS=4 idle-claude-cleaner.sh --kill   # 閾値変更
#
# 判定基準:
#   - tmux session が detached
#   - pane_current_command が "claude"
#   - tmux session activity が IDLE_HOURS（デフォルト 2）時間以上前
#
# kill 時に ~/.claude/closed-sessions.jsonl に1行 JSON 追記:
#   {closed_at, session, window, pane, pwd, project_id, claude_session_id, idle_hours}
#
# 文脈ロスゼロ運用:
#   Claude のセッション履歴は ~/.claude/projects/<path-hash>/<session-id>.jsonl に
#   常時保存される。プロセスを kill しても会話は失われず、
#   `claude --resume <session-id>` または `claude-resume-recent` で復帰可能。

set -euo pipefail

IDLE_HOURS=${IDLE_HOURS:-2}
DO_KILL=0
[ "${1:-}" = "--kill" ] && DO_KILL=1

LOG="$HOME/.claude/closed-sessions.jsonl"
mkdir -p "$(dirname "$LOG")"

now=$(date +%s)
threshold=$((now - IDLE_HOURS * 3600))

# Header (dry-run 時)
if [ "$DO_KILL" = 0 ]; then
	printf "%-22s %4s %-30s %5s %s\n" "SESSION" "W.P" "PWD" "IDLE" "SESSION_ID"
	printf "%-22s %4s %-30s %5s %s\n" "----------------------" "----" "------------------------------" "-----" "----------"
fi

tmux list-panes -a -F '#{session_name}|#{?session_attached,A,-}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_pid}|#{pane_current_path}|#{session_activity}' 2>/dev/null |
	while IFS='|' read -r session attach win pane cmd pid pwd activity; do
		[ "$attach" != "-" ] && continue
		[ "$activity" -gt "$threshold" ] && continue
		# Claude Code は pane_current_command として実バイナリ名 "claude" でなく
		# バージョン文字列（例 "2.1.118"）を表示することがある（process.title 上書き）。
		# どちらのケースも拾うため、pane の子プロセスに実 claude PID があるかで判定。
		case "$cmd" in
		claude | [0-9]*.[0-9]*.[0-9]*) ;;
		*) continue ;;
		esac

		# claude 実プロセス（pane_pid の子で実コマンド名が claude のもの）
		claude_pid=$(pgrep -P "$pid" -x claude 2>/dev/null | head -1)
		[ -z "$claude_pid" ] && continue

		# Claude Code の project hash 規約: スラッシュをハイフンに置換
		# 例: ~/Works/proj → -<home_root>-Works-proj
		path_hash="${pwd//\//-}"
		project_dir="$HOME/.claude/projects/$path_hash"

		# 最新の jsonl から session_id 推定（mtime 順）
		claude_session_id=""
		if [ -d "$project_dir" ]; then
			latest=$(/bin/ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1)
			[ -n "$latest" ] && claude_session_id=$(basename "$latest" .jsonl)
		fi

		idle_hr=$(((now - activity) / 3600))
		pwd_short="${pwd/#$HOME/\~}"
		[ ${#pwd_short} -gt 30 ] && pwd_short="…${pwd_short: -29}"

		if [ "$DO_KILL" = 1 ]; then
			if kill "$claude_pid" 2>/dev/null; then
				printf '{"closed_at":%d,"session":"%s","window":%s,"pane":%s,"pwd":"%s","project_id":"%s","claude_session_id":"%s","idle_hours":%d}\n' \
					"$now" "$session" "$win" "$pane" "$pwd" "$path_hash" "$claude_session_id" "$idle_hr" >>"$LOG"
				echo "✓ Killed $session/$win.$pane  PID=$claude_pid  idle=${idle_hr}h  resume: claude-resume-recent"
			else
				echo "✗ Failed to kill $session/$win.$pane  PID=$claude_pid"
			fi
		else
			printf "%-22s %4s %-30s %4dh %s\n" "$session" "$win.$pane" "$pwd_short" "$idle_hr" "${claude_session_id:-?}"
		fi
	done

if [ "$DO_KILL" = 0 ]; then
	echo ""
	echo "Run with --kill to actually terminate. Closed sessions are logged to:"
	echo "  $LOG"
	echo "Resume them with: claude-resume-recent"
fi
