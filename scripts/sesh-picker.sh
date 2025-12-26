#!/bin/bash
# sesh session picker with fzf
# - Select existing session: choose from list and Enter
# - Create new session: type new name and Enter
# - Kill session: Ctrl+d on a session

result=$(sesh list -t -i | fzf-tmux -p 55%,60% \
  --layout=reverse \
  --no-sort --ansi --border-label "  sesh " --prompt "  " \
  --header "  ^a all ^t tmux ^x zoxide ^k kill" \
  --print-query \
  --bind "tab:down,btab:up" \
  --bind "ctrl-a:change-prompt(  )+reload(sesh list -i)" \
  --bind "ctrl-t:change-prompt(  )+reload(sesh list -t -i)" \
  --bind "ctrl-x:change-prompt(  )+reload(sesh list -z -i)" \
  --bind "ctrl-k:execute-silent(tmux kill-session -t \$(echo {} | sed 's/^[^ ]* //'))+change-prompt(  )+reload(sesh list -t -i)")

# --print-query outputs:
# Line 1: query (what was typed)
# Line 2: selection (what was selected, empty if no match)

query=$(echo "$result" | head -n 1)
selection=$(echo "$result" | sed -n '2p')

if [ -n "$selection" ]; then
  # Selection exists: use sesh connect (handles icons automatically with {2..} equivalent)
  session=$(echo "$selection" | sed 's/^[^ ]* //')
  sesh connect "$session"
elif [ -n "$query" ]; then
  # No selection but query exists: create new tmux session directly
  tmux new-session -d -s "$query" 2>/dev/null
  tmux switch-client -t "$query"
fi

exit 0
