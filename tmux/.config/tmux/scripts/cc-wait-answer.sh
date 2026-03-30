#!/bin/bash
set -euo pipefail

# WAITING ペインから選択肢を抽出し、fzf で選択して送信する
# Usage: cc-wait-answer.sh <session_name>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cc-common.sh
source "$SCRIPT_DIR/cc-common.sh"

session_name="${1:-}"

if [ -z "$session_name" ]; then
  exit 0
fi

CC_RESPOND="$SCRIPT_DIR/cc-wait-respond.sh"

pane_id=$(find_waiting_pane "$session_name")

if [ -z "$pane_id" ]; then
  exit 0
fi

# ペイン出力をキャプチャ
pane_output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null) || exit 0

# 質問テキストを抽出
# ☐ がある場合: ☐ と ❯ の間（AskUserQuestion）
# ☐ がない場合: ❯ の直前の非空行（Do you want ... ? など）
question=$(echo "$pane_output" | awk '
  { lines[NR]=$0 }
  /☐/ { header=NR }
  END {
    if (header) {
      selector=0
      for (i=header+1; i<=NR; i++) {
        if (lines[i] ~ /❯/) { selector=i; break }
      }
      if (!selector) exit
      result=""
      for (i=header+1; i<selector; i++) {
        line=lines[i]
        if (line ~ /^──/) continue
        if (line ~ /^[[:space:]]*$/) continue
        if (result != "") result = result "\n"
        result = result line
      }
      printf "%s", result
    } else {
      last_sel=0
      for (i=NR; i>=1; i--) {
        if (lines[i] ~ /❯/) { last_sel=i; break }
      }
      if (!last_sel) exit
      for (i=last_sel-1; i>=1; i--) {
        if (lines[i] ~ /^[[:space:]]*$/) continue
        if (lines[i] ~ /^──/) continue
        if (lines[i] ~ /^╌/) continue
        printf "%s", lines[i]
        exit
      }
    }
  }
')

# 番号付き選択肢+説明文を抽出（最後の☐またはDo you want以降の❯行から）
choices=$(echo "$pane_output" | awk '
  /☐/ || /Do you want/ || /Would you like/ || /Allow/ { start=NR }
  { lines[NR]=$0 }
  END {
    if (!start) start=1
    for (i=start; i<=NR; i++) print lines[i]
  }
' | awk '
  /❯/ { found=1 }
  found {
    line=$0
    gsub(/^[[:space:]]*❯[[:space:]]*/, "", line)
    gsub(/^[[:space:]]*/, "", line)
    if (line ~ /^[0-9]+\./) {
      if (NR > 1 && item != "") print item
      item = line
    } else if (line ~ /^[^─╌]/ && line != "" && line !~ /^Enter to/ && line !~ /to navigate/ && line !~ /^Esc to/) {
      if (item != "") item = item "\t" line
    }
  }
  END { if (item != "") print item }
')

if [ -z "$choices" ]; then
  exit 0
fi

header="${question:-$session_name}"
selected=$(echo "$choices" | fzf \
  --layout=reverse --no-sort --no-info \
  --delimiter '\t' --with-nth '1,2' \
  --header "$header" \
  --header-first) || exit 0

if [ -z "$selected" ]; then
  exit 0
fi

# "Type something" を選んだ場合はセッションに切り替え
if echo "$selected" | grep -qiE 'Type something|Other'; then
  tmux switch-client -t "$session_name"
  exit 0
fi

option_number=$(echo "$selected" | cut -f1 | grep -oE '^\d+' | head -1)

if [ -n "$option_number" ]; then
  "$CC_RESPOND" "$session_name" "$option_number"
fi
