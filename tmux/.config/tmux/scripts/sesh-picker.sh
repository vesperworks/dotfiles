#!/bin/bash
# sesh session picker with fzf
# - Select existing session: choose from list and Enter
# - Create new session: type new name and Enter
# - Kill session: Ctrl+d on a session
# - Move current pane to selected session: Ctrl+o
# - Answer WAITING CC: Ctrl+e で選択肢popup表示, Ctrl+y で Enter送信(yes)

SESH_SESSIONS=~/.config/tmux/scripts/sesh-sessions.sh
CC_PREVIEW=~/.config/tmux/scripts/cc-question-preview.sh
CC_ANSWER=~/.config/tmux/scripts/cc-wait-answer.sh
CLAUDE_SLEEP=~/.config/tmux/scripts/claude-sleep.sh
CLAUDE_SLEEP_CONFIRM=~/.config/tmux/scripts/claude-sleep-confirm.sh
SLEEP_LOG="$HOME/.claude/closed-sessions.jsonl"
KEY_MARKER="${TMPDIR:-/tmp}/sesh-picker-key-$$-$RANDOM"
SLEEP_MARKER="${TMPDIR:-/tmp}/sesh-picker-sleep-$$-$RANDOM"
trap 'rm -f "$KEY_MARKER" "$SLEEP_MARKER"' EXIT

# 💤 Sleep 中セッション（claude kill 済、JSONL 記録あり）
# 直近24h で sleep されたセッション集合から、今 attach 中のものを除外
sleeping_sessions=""
if [ -s "$SLEEP_LOG" ] && command -v jq >/dev/null 2>&1; then
	cutoff=$(($(date +%s) - 86400))
	closed_recent=$(jq -r --argjson c "$cutoff" 'select(.closed_at >= $c) | .session' "$SLEEP_LOG" 2>/dev/null | sort -u)
	attached_now=$(tmux list-sessions -F '#{?session_attached,#{session_name},}' 2>/dev/null | grep -v '^$' | sort -u)
	sleeping_sessions=$(comm -23 <(echo "$closed_recent") <(echo "$attached_now") 2>/dev/null)
fi
if [ -z "$sleeping_sessions" ]; then
	sleeping_count=0
else
	sleeping_count=$(echo "$sleeping_sessions" | grep -c . 2>/dev/null || echo 0)
fi

# 💡 Sleep 候補セッション（idle だがまだ claude 生存）
# --count-cached はキャッシュ即時返却、bg で更新（picker 起動を遅延させない）
candidate_count=$("$CLAUDE_SLEEP" --count-cached 2>/dev/null || echo "?")
candidate_sessions=$("$CLAUDE_SLEEP" --list-sessions 2>/dev/null || true)

# バッジ構築: 💤 sleeping + 💡 candidate
sleep_badge=""
if [ "$sleeping_count" != "0" ] 2>/dev/null; then
	sleep_badge="${sleep_badge}💤 $sleeping_count sleeping  "
fi
if [ "$candidate_count" != "0" ] && [ "$candidate_count" != "?" ]; then
	sleep_badge="${sleep_badge}💡 $candidate_count candidate  "
fi

# sesh-sessions.sh に SLEEPING / CANDIDATE 環境変数を渡し、
# ステータス列で 💤 SLEEP / 💡 SLEEPY を表示させる（行頭マーカーは廃止）
sesh_output_filtered() {
	SLEEPING="$sleeping_sessions" CANDIDATE="$candidate_sessions" "$SESH_SESSIONS" "$@"
}

result=$(sesh_output_filtered -t | fzf-tmux -p 65%,65% \
	--layout=reverse \
	--no-sort --ansi --border-label "  sesh " --prompt "  " \
	--header "${sleep_badge}^a all  ^t tmux  ^x zoxide  ^d kill  ^o move  ^e edit  ^y yes  ^s sleep" \
	--header-first \
	--padding 0,1 \
	--print-query \
	--expect=ctrl-o \
	--preview "$CC_PREVIEW {}" \
	--preview-window "right,50%,wrap,follow,<80(bottom,40%,wrap,follow)" \
	--bind "tab:down,btab:up" \
	--bind "ctrl-n:preview-down,ctrl-p:preview-up" \
	--bind "ctrl-a:change-prompt(  )+reload($SESH_SESSIONS)" \
	--bind "ctrl-t:change-prompt(  )+reload($SESH_SESSIONS -t)" \
	--bind "ctrl-x:change-prompt(  )+reload(sesh list -z -i)" \
	--bind "ctrl-d:execute-silent(tmux kill-session -t \$(echo {} | awk '{print \$2}'))+change-prompt(  )+reload($SESH_SESSIONS -t)" \
	--bind "ctrl-e:execute-silent(touch $KEY_MARKER)+accept" \
	--bind "ctrl-y:execute-silent(tmux send-keys -t \$(echo {} | awk '{print \$2}') Enter)+reload($SESH_SESSIONS -t)" \
	--bind "ctrl-s:execute-silent(touch $SLEEP_MARKER)+accept")

# --expect と --print-query の出力:
# Line 1: query (入力テキスト)
# Line 2: key (押されたキー: ctrl-o, または空)
# Line 3: selection (選択された行)

query=$(echo "$result" | sed -n '1p')
key=$(echo "$result" | sed -n '2p')
selection=$(echo "$result" | sed -n '3p')

# ctrl-e のマーカーファイルチェック
if [ -f "$KEY_MARKER" ]; then
	rm -f "$KEY_MARKER"
	key="ctrl-e"
fi

# ^s: fzf-tmux popup を抜けた後（= fzf-tmux の親 tmux に戻った後）に
# tmux display-popup を呼ぶ。fzf-tmux 内から入れ子で popup を出すと表示されない。
if [ -f "$SLEEP_MARKER" ]; then
	rm -f "$SLEEP_MARKER"
	tmux display-popup -E -w 70% -h 70% -T ' 💤 Claude Sleep ' "$CLAUDE_SLEEP_CONFIRM"
	exit 0
fi

if [ -n "$selection" ]; then
	# 行頭にプレフィックス無し（行頭マーカーは廃止）。
	# 出力フォーマット: " <icon> <session_name> ..." なので $2 が session 名。
	session=$(echo "$selection" | awk '{print $2}')

	# このセッションが SLEEP 中（claude kill 済）かを判定
	is_sleeping=0
	if [ -n "$sleeping_sessions" ] && echo "$sleeping_sessions" | grep -qxF "$session"; then
		is_sleeping=1
	fi

	case "$key" in
	ctrl-o)
		# Ctrl+o: 現在のペインを選択したセッションに移動
		tmux break-pane
		tmux move-window -t "$session:"
		tmux switch-client -t "$session"
		;;
	ctrl-e)
		# Ctrl+e: popup で選択肢表示
		tmux display-popup -E -w 60% -h 40% -T " $session — 選択肢 " \
			"$CC_ANSWER '$session'"
		;;
	*)
		# Enter: 通常のセッション接続
		sesh connect "$session"

		# SLEEP 中セッションなら、attach 後に claude --resume を自動送信
		if [ "$is_sleeping" = "1" ] && [ -s "$SLEEP_LOG" ] && command -v jq >/dev/null 2>&1; then
			# closed-sessions.jsonl から該当 session の最新エントリを引く
			resume_info=$(jq -r --arg s "$session" \
				'select(.session == $s) | [(.claude_session_id // ""), (.pwd // "")] | @tsv' \
				"$SLEEP_LOG" 2>/dev/null | tail -1)
			session_id=$(echo "$resume_info" | awk -F'\t' '{print $1}')
			pwd_path=$(echo "$resume_info" | awk -F'\t' '{print $2}')

			if [ -n "$session_id" ]; then
				resume_cmd="claude --resume $session_id"
			else
				resume_cmd="claude"
			fi
			if [ -n "$pwd_path" ] && [ -d "$pwd_path" ]; then
				resume_cmd="cd '$pwd_path' && $resume_cmd"
			fi

			# 該当 session のアクティブ pane に送信（zsh プロンプト待ち前提）
			tmux send-keys -t "$session" "$resume_cmd" Enter 2>/dev/null || true
		fi
		;;
	esac
elif [ -n "$query" ]; then
	# No selection but query exists: create new tmux session directly
	tmux new-session -d -s "$query" 2>/dev/null
	tmux switch-client -t "$query"
fi

exit 0
