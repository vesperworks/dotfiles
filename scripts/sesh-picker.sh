#!/bin/bash
# sesh session picker with fzf
# - Select existing session: choose from list and Enter
# - Create new session: type new name and Enter
# - Kill session: Ctrl+d on a session
# - Move current pane to selected session: Ctrl+o

SESH_SESSIONS=~/.config/tmux/scripts/sesh-sessions.sh

result=$($SESH_SESSIONS -t | fzf-tmux -p 55%,60% \
  --layout=reverse \
  --no-sort --ansi --border-label "  sesh " --prompt "  " \
  --header "  ^a all ^t tmux ^x zoxide ^d kill ^o move" \
  --print-query \
  --expect=ctrl-o \
  --bind "tab:down,btab:up" \
  --bind "ctrl-a:change-prompt(  )+reload($SESH_SESSIONS)" \
  --bind "ctrl-t:change-prompt(  )+reload($SESH_SESSIONS -t)" \
  --bind "ctrl-x:change-prompt(  )+reload(sesh list -z -i)" \
  --bind "ctrl-d:execute-silent(tmux kill-session -t \$(echo {} | awk '{print \$2}'))+change-prompt(  )+reload($SESH_SESSIONS -t)")

# --expect と --print-query の出力:
# Line 1: query (入力テキスト)
# Line 2: key (押されたキー: ctrl-o, または空)
# Line 3: selection (選択された行)

query=$(echo "$result" | sed -n '1p')
key=$(echo "$result" | sed -n '2p')
selection=$(echo "$result" | sed -n '3p')

if [ -n "$selection" ]; then
  session=$(echo "$selection" | awk '{print $2}')

  if [ "$key" = "ctrl-o" ]; then
    # Ctrl+o: 現在のペインを選択したセッションに移動
    tmux break-pane       # 現在のペインを新しいウィンドウに分離
    tmux move-window -t "$session:"  # そのウィンドウを移動
    tmux switch-client -t "$session"
  else
    # Enter: 通常のセッション接続
    sesh connect "$session"
  fi
elif [ -n "$query" ]; then
  # No selection but query exists: create new tmux session directly
  tmux new-session -d -s "$query" 2>/dev/null
  tmux switch-client -t "$query"
fi

exit 0
