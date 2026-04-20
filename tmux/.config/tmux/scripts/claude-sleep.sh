#!/bin/bash
# claude-sleep.sh — detached pane で idle な claude プロセスをスリープさせる
#
# Modes:
#   claude-sleep.sh                 候補リスト表示（dry-run、デフォルト）
#   claude-sleep.sh --all           全候補を一斉スリープ + 記録
#   claude-sleep.sh --count         候補件数のみ stdout（同期計測）
#   claude-sleep.sh --count-cached  キャッシュ値を即時返す + bg 更新（picker 用）
#   IDLE_HOURS=4 claude-sleep.sh --all   閾値変更
#
# 「スリープ」と呼ぶ理由: kill するが Claude のセッション履歴は
# ~/.claude/projects/<path-hash>/<session-id>.jsonl に保存され続ける。
# `claude-wake` で fzf picker から選んで `claude --resume <id>` で復帰可能。
# 文脈ロスはない。
#
# 判定基準:
#   - tmux session が detached
#   - pane の子プロセスに claude 実プロセスが存在
#     （pane_current_command は Claude Code が process.title を上書きして
#     バージョン文字列「2.1.118」になることがあり、名前判定では不十分）
#   - tmux session activity が IDLE_HOURS（デフォルト 2）時間以上前
#
# --all 時に ~/.claude/closed-sessions.jsonl に1行 JSON 追記:
#   {closed_at, session, window, pane, pwd, project_id, claude_session_id, idle_hours}

set -euo pipefail

IDLE_HOURS=${IDLE_HOURS:-2}
CACHE_TTL=${CLAUDE_SLEEP_CACHE_TTL:-60}
CACHE_FILE="${HOME}/.cache/claude-sleep-count"

MODE="list" # list | all | count | count-cached
case "${1:-}" in
--all) MODE=all ;;
--count) MODE=count ;;
--count-cached) MODE=count-cached ;;
--list | "") MODE=list ;;
*)
	echo "Usage: $0 [--list|--all|--count|--count-cached]" >&2
	exit 2
	;;
esac

# --count-cached: キャッシュを即時返す + 古ければ background で更新
if [ "$MODE" = "count-cached" ]; then
	mkdir -p "$(dirname "$CACHE_FILE")"

	# キャッシュ読み出し（なければ "?"）
	if [ -f "$CACHE_FILE" ]; then
		cat "$CACHE_FILE"
		mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
		age=$(($(date +%s) - mtime))
	else
		echo "?"
		age=999999
	fi

	# 古ければ background で再計算（呼び出し元はブロックしない）
	if [ "$age" -gt "$CACHE_TTL" ]; then
		(
			"$0" --count >"${CACHE_FILE}.tmp" 2>/dev/null && mv "${CACHE_FILE}.tmp" "$CACHE_FILE"
		) </dev/null >/dev/null 2>&1 &
		disown 2>/dev/null || true
	fi
	exit 0
fi

LOG="$HOME/.claude/closed-sessions.jsonl"
mkdir -p "$(dirname "$LOG")"

now=$(date +%s)
threshold=$((now - IDLE_HOURS * 3600))

# Header (list モード)
if [ "$MODE" = "list" ]; then
	printf "%-22s %4s %-30s %5s %s\n" "SESSION" "W.P" "PWD" "IDLE" "SESSION_ID"
	printf "%-22s %4s %-30s %5s %s\n" "----------------------" "----" "------------------------------" "-----" "----------"
fi

count=0

# 全 pane を走査
panes=$(tmux list-panes -a -F '#{session_name}|#{?session_attached,A,-}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_pid}|#{pane_current_path}|#{session_activity}' 2>/dev/null) || panes=""

while IFS='|' read -r session attach win pane cmd pid pwd activity; do
	[ -z "$session" ] && continue
	[ "$attach" != "-" ] && continue
	[ "$activity" -gt "$threshold" ] && continue
	case "$cmd" in
	claude | [0-9]*.[0-9]*.[0-9]*) ;;
	*) continue ;;
	esac

	claude_pid=$(pgrep -P "$pid" -x claude 2>/dev/null | head -1)
	[ -z "$claude_pid" ] && continue

	count=$((count + 1))

	[ "$MODE" = "count" ] && continue

	# Claude Code の project hash 規約: スラッシュをハイフンに置換
	path_hash="${pwd//\//-}"
	project_dir="$HOME/.claude/projects/$path_hash"

	claude_session_id=""
	if [ -d "$project_dir" ]; then
		latest=$(/bin/ls -t "$project_dir"/*.jsonl 2>/dev/null | head -1)
		[ -n "$latest" ] && claude_session_id=$(basename "$latest" .jsonl)
	fi

	idle_hr=$(((now - activity) / 3600))
	pwd_short="${pwd/#$HOME/\~}"
	[ ${#pwd_short} -gt 30 ] && pwd_short="…${pwd_short: -29}"

	if [ "$MODE" = "all" ]; then
		if kill "$claude_pid" 2>/dev/null; then
			printf '{"closed_at":%d,"session":"%s","window":%s,"pane":%s,"pwd":"%s","project_id":"%s","claude_session_id":"%s","idle_hours":%d}\n' \
				"$now" "$session" "$win" "$pane" "$pwd" "$path_hash" "$claude_session_id" "$idle_hr" >>"$LOG"
			echo "💤 $session/$win.$pane  idle=${idle_hr}h  → claude-wake で復帰可"
		else
			echo "✗ Failed: $session/$win.$pane  PID=$claude_pid"
		fi
	else
		printf "%-22s %4s %-30s %4dh %s\n" "$session" "$win.$pane" "$pwd_short" "$idle_hr" "${claude_session_id:-?}"
	fi
done <<<"$panes"

if [ "$MODE" = "count" ]; then
	echo "$count"
elif [ "$MODE" = "list" ]; then
	echo ""
	if [ "$count" = 0 ]; then
		echo "No sleep candidates (threshold: ${IDLE_HOURS}h idle)"
	else
		echo "→ Run claude-sleep --all to sleep all $count candidates"
		echo "  (logged to $LOG, resume with claude-wake)"
	fi
fi
