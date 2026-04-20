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

# sesh-sessions.sh の出力を後処理: 行頭に状態マーカーを挿入
#   💤 = Sleep 中（claude kill 済、closed-sessions.jsonl に記録あり）
#   💡 = Sleep 候補（idle だがまだ claude 生存）
#   "   " = 通常（バッジ幅 4 と整合）
# 優先度: 💤 > 💡 > 無印
# ENVIRON 経由で渡す（-v sleeping="..." だと改行を含む変数が壊れる）
sesh_output_filtered() {
	"$SESH_SESSIONS" "$@" | SLEEPING="$sleeping_sessions" CANDIDATE="$candidate_sessions" awk '
		BEGIN {
			n = split(ENVIRON["SLEEPING"], arr, "\n")
			for (i=1; i<=n; i++) if (arr[i] != "") sleeping[arr[i]] = 1
			m = split(ENVIRON["CANDIDATE"], arr2, "\n")
			for (i=1; i<=m; i++) if (arr2[i] != "") candidate[arr2[i]] = 1
		}
		{
			# ANSI 色 + 先頭の Nerd Font アイコン + 空白を除去 → 最初の単語が session 名
			# sesh-sessions.sh は " <icon> <session> ..." 形式で出力
			plain = $0
			gsub(/\033\[[0-9;]*[a-zA-Z]/, "", plain)         # ANSI strip
			sub(/^[^a-zA-Z0-9_-]+/, "", plain)               # 先頭のアイコン + 空白除去
			n = split(plain, fields, " ")
			name = (n > 0) ? fields[1] : ""
			if (name in sleeping) print "💤 " $0
			else if (name in candidate) print "💡 " $0
			else print "   " $0
		}
	'
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
	--bind "ctrl-d:execute-silent(tmux kill-session -t \$(echo {} | sed 's/^💤 //;s/^💡 //;s/^   //' | awk '{print \$2}'))+change-prompt(  )+reload($SESH_SESSIONS -t)" \
	--bind "ctrl-e:execute-silent(touch $KEY_MARKER)+accept" \
	--bind "ctrl-y:execute-silent(tmux send-keys -t \$(echo {} | sed 's/^💤 //;s/^💡 //;s/^   //' | awk '{print \$2}') Enter)+reload($SESH_SESSIONS -t)" \
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
	# 行頭に "💤 " / "💡 " (emoji+space, 5byte) or "   " (3space) のプレフィックス。
	# emoji は awk の field 1 にカウントされるが空白は無視されるため、
	# 単純に sed で剥がしてから print $2 に統一する。
	session=$(echo "$selection" | sed 's/^💤 //;s/^💡 //;s/^   //' | awk '{print $2}')

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

		# 💤 付きの行（Sleep 中セッション）なら、attach 後に claude --resume を自動送信
		if [[ "$selection" == 💤* ]] && [ -s "$SLEEP_LOG" ] && command -v jq >/dev/null 2>&1; then
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
