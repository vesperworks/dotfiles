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
CLAUDE_WAKE=~/.config/tmux/scripts/claude-wake.sh
KEY_MARKER="${TMPDIR:-/tmp}/sesh-picker-key-$$-$RANDOM"
SLEEP_MARKER="${TMPDIR:-/tmp}/sesh-picker-sleep-$$-$RANDOM"
WAKE_MARKER="${TMPDIR:-/tmp}/sesh-picker-wake-$$-$RANDOM"
trap 'rm -f "$KEY_MARKER" "$SLEEP_MARKER" "$WAKE_MARKER"' EXIT

# 💤 idle Claude 候補数（キャッシュ即時、bg 更新）— picker 起動を遅延させない
sleep_count=$("$CLAUDE_SLEEP" --count-cached 2>/dev/null || echo "?")
if [ "$sleep_count" != "0" ] && [ "$sleep_count" != "?" ]; then
	sleep_badge="💤 $sleep_count idle  "
else
	sleep_badge=""
fi

# 直近24h で sleep されたセッション集合（attached なら除外）
SLEEP_LOG="$HOME/.claude/closed-sessions.jsonl"
sleeping_sessions=""
if [ -s "$SLEEP_LOG" ] && command -v jq >/dev/null 2>&1; then
	cutoff=$(($(date +%s) - 86400))
	# closed-sessions から最近24hのsession名を抽出
	closed_recent=$(jq -r --argjson c "$cutoff" 'select(.closed_at >= $c) | .session' "$SLEEP_LOG" 2>/dev/null | sort -u)
	# attach 中のセッション名（再起動済みなので除外）
	attached_now=$(tmux list-sessions -F '#{?session_attached,#{session_name},}' 2>/dev/null | grep -v '^$' | sort -u)
	# 差集合: 最近 closed かつ 今 detached
	sleeping_sessions=$(comm -23 <(echo "$closed_recent") <(echo "$attached_now") 2>/dev/null)
fi

# sesh-sessions.sh の出力を後処理: sleeping セッション行頭に "💤 " を挿入
# それ以外は "   " で揃える（バッジ幅 4 と整合）
# ENVIRON 経由で渡す（-v sleeping="..." だと改行を含む変数が壊れる）
# 注: bash の "VAR=x cmd1 | cmd2" は VAR を cmd1 にしか渡さないので、
# パイプの後 (awk の直前) で再度 SLEEPING= を指定する必要がある
sesh_output_filtered() {
	"$SESH_SESSIONS" "$@" | SLEEPING="$sleeping_sessions" awk '
		BEGIN {
			n = split(ENVIRON["SLEEPING"], arr, "\n")
			for (i=1; i<=n; i++) if (arr[i] != "") s[arr[i]] = 1
		}
		{
			# ANSI 色 + 先頭の Nerd Font アイコン + 空白を除去 → 最初の単語が session 名
			# sesh-sessions.sh は " <icon> <session> ..." 形式で出力
			plain = $0
			gsub(/\033\[[0-9;]*[a-zA-Z]/, "", plain)         # ANSI strip
			sub(/^[^a-zA-Z0-9_-]+/, "", plain)               # 先頭のアイコン + 空白除去
			n = split(plain, fields, " ")
			name = (n > 0) ? fields[1] : ""
			if (name in s) print "💤 " $0
			else print "   " $0
		}
	'
}

result=$(sesh_output_filtered -t | fzf-tmux -p 65%,65% \
	--layout=reverse \
	--no-sort --ansi --border-label "  sesh " --prompt "  " \
	--header "${sleep_badge}^a all  ^t tmux  ^x zoxide  ^d kill  ^o move  ^e edit  ^y yes  ^s sleep  ^w wake" \
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
	--bind "ctrl-d:execute-silent(tmux kill-session -t \$(echo {} | sed 's/^💤 //;s/^   //' | awk '{print \$2}'))+change-prompt(  )+reload($SESH_SESSIONS -t)" \
	--bind "ctrl-e:execute-silent(touch $KEY_MARKER)+accept" \
	--bind "ctrl-y:execute-silent(tmux send-keys -t \$(echo {} | sed 's/^💤 //;s/^   //' | awk '{print \$2}') Enter)+reload($SESH_SESSIONS -t)" \
	--bind "ctrl-s:execute-silent(touch $SLEEP_MARKER)+accept" \
	--bind "ctrl-w:execute-silent(touch $WAKE_MARKER)+accept")

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

# alt-s / alt-w: fzf-tmux popup を抜けた後（= fzf-tmux の親 tmux に戻った後）に
# tmux display-popup を呼ぶ。fzf-tmux 内から入れ子で popup を出すと表示されない。
if [ -f "$SLEEP_MARKER" ]; then
	rm -f "$SLEEP_MARKER"
	tmux display-popup -E -w 70% -h 70% -T ' 💤 Claude Sleep ' "$CLAUDE_SLEEP_CONFIRM"
	exit 0
fi
if [ -f "$WAKE_MARKER" ]; then
	rm -f "$WAKE_MARKER"
	tmux display-popup -E -w 80% -h 60% -T ' 🌅 Claude Wake ' "$CLAUDE_WAKE"
	exit 0
fi

if [ -n "$selection" ]; then
	# 行頭に "💤 " (emoji+space, 5byte) or "   " (3space) のプレフィックス。
	# emoji は awk の field 1 にカウントされるが空白は無視されるため、
	# 単純に sed で剥がしてから print $2 に統一する。
	session=$(echo "$selection" | sed 's/^💤 //;s/^   //' | awk '{print $2}')

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
