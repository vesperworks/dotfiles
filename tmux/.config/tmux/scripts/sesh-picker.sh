#!/bin/bash
# sesh session picker with fzf
# - Select existing session: choose from list and Enter
# - Create new session: type new name and Enter
# - Kill session: Ctrl+d on a session
# - Move current pane to selected session: Ctrl+o
# - Answer WAITING CC: Ctrl+y (yes) / Ctrl+u (no)

SESH_SESSIONS=~/.config/tmux/scripts/sesh-sessions.sh
CC_PREVIEW=~/.config/tmux/scripts/cc-question-preview.sh
CC_RESPOND=~/.config/tmux/scripts/cc-wait-respond.sh

result=$($SESH_SESSIONS -t | fzf-tmux -p 55%,60% \
  --layout=reverse \
  --no-sort --ansi --border-label "  sesh " --prompt "  " \
  --header "  ^a all ^t tmux ^x zoxide ^d kill ^o move ^y yes ^u no" \
  --print-query \
  --expect=ctrl-o,ctrl-y,ctrl-u \
  --preview "$CC_PREVIEW {}" \
  --preview-window "right,45%,wrap,<80(bottom,40%,wrap)" \
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

  case "$key" in
    ctrl-o)
      # Ctrl+o: 現在のペインを選択したセッションに移動
      tmux break-pane       # 現在のペインを新しいウィンドウに分離
      tmux move-window -t "$session:"  # そのウィンドウを移動
      tmux switch-client -t "$session"
      ;;
    ctrl-y)
      # Ctrl+y: WAITING ペインに "y" を送信してセッションに移動
      "$CC_RESPOND" "$session" y
      sesh connect "$session"
      ;;
    ctrl-u)
      # Ctrl+n: WAITING ペインに "n" を送信してセッションに移動
      "$CC_RESPOND" "$session" n
      sesh connect "$session"
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
