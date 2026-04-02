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
KEY_MARKER="${TMPDIR:-/tmp}/sesh-picker-key-$$-$RANDOM"
trap 'rm -f "$KEY_MARKER"' EXIT

result=$($SESH_SESSIONS -t | fzf-tmux -p 65%,65% \
	--layout=reverse \
	--no-sort --ansi --border-label "  sesh " --prompt "  " \
	--header "  ^a all  ^t tmux  ^x zoxide  ^d kill  ^o move  ^e edit  ^y yes" \
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
	--bind "ctrl-y:execute-silent(tmux send-keys -t \$(echo {} | awk '{print \$2}') Enter)+reload($SESH_SESSIONS -t)")

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

if [ -n "$selection" ]; then
	session=$(echo "$selection" | awk '{print $2}')

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
		;;
	esac
elif [ -n "$query" ]; then
	# No selection but query exists: create new tmux session directly
	tmux new-session -d -s "$query" 2>/dev/null
	tmux switch-client -t "$query"
fi

exit 0
