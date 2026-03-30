#!/bin/bash
set -euo pipefail

# WAITING ペインから選択肢を抽出し、fzf で選択して送信する
# sesh-picker.sh の ctrl-y から呼ばれる（マーカーファイル + accept → display-popup）
# Usage: cc-wait-answer.sh <session_name>

session_name="${1:-}"

if [ -z "$session_name" ]; then
  exit 0
fi

CC_RESPOND=~/.config/tmux/scripts/cc-wait-respond.sh

# AI CLI process names
AI_COMM_NAMES='claude|agent|codex|gemini'
WAITING_PATTERN='esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'

# Find the WAITING pane
find_waiting_pane() {
  local sess=$1
  while IFS=$'\t' read -r pane_pid pane_id; do
    [ -z "$pane_pid" ] && continue

    local has_ai
    has_ai=$(ps -o pid=,ppid=,comm= -ax 2>/dev/null | awk -v root="$pane_pid" -v pat="$AI_COMM_NAMES" '
      BEGIN { queue[root]=1 }
      { pid[NR]=$1; ppid[NR]=$2; comm[NR]=$3 }
      END {
        changed=1
        while (changed) {
          changed=0
          for (i=1; i<=NR; i++) {
            if ((ppid[i] in queue) && !(pid[i] in queue)) {
              queue[pid[i]]=1; changed=1
            }
          }
        }
        for (i=1; i<=NR; i++) {
          if (pid[i] in queue) {
            n=split(comm[i], parts, "/")
            base=tolower(parts[n])
            if (base ~ "^(" pat ")$") { print pid[i]; exit }
          }
        }
      }
    ') || true

    if [ -z "$has_ai" ]; then
      continue
    fi

    local pane_output
    pane_output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -30) || true

    if echo "$pane_output" | grep -qiE "$WAITING_PATTERN"; then
      echo "$pane_id"
      return
    fi
  done < <(tmux list-panes -t "$sess" -F "#{pane_pid}	#{pane_id}" 2>/dev/null)
}

pane_id=$(find_waiting_pane "$session_name")

if [ -z "$pane_id" ]; then
  exit 0
fi

# ペイン出力をキャプチャ
pane_output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null) || exit 0

# 質問テキストを抽出
# 1. ☐ がある場合: ☐ と ❯ の間のテキスト（AskUserQuestion）
# 2. ☐ がない場合: ❯ の直前の非空行（Do you want ... ? など）
question=$(echo "$pane_output" | awk '
  { lines[NR]=$0 }
  /☐/ { header=NR }
  END {
    if (header) {
      # ☐ の後の最初の ❯ を探す
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
      # ☐ なし: 最後の ❯ の前の非空行を探す
      last_sel=0
      for (i=NR; i>=1; i--) {
        if (lines[i] ~ /❯/) { last_sel=i; break }
      }
      if (!last_sel) exit
      for (i=last_sel-1; i>=1; i--) {
        if (lines[i] ~ /^[[:space:]]*$/) continue
        if (lines[i] ~ /^──/) continue
        if (lines[i] ~ /^╌/) continue
        # 質問行を見つけた
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
    # ❯プレフィックスと先頭空白を除去
    gsub(/^[[:space:]]*❯[[:space:]]*/, "", line)
    gsub(/^[[:space:]]*/, "", line)
    if (line ~ /^[0-9]+\./) {
      # 番号行: そのまま出力
      if (NR > 1 && item != "") print item
      item = line
    } else if (line ~ /^[^─╌]/ && line != "" && line !~ /^Enter to/ && line !~ /to navigate/ && line !~ /^Esc to/) {
      # 説明行: 番号行の後にタブ区切りで付加（ヘルプ行は除外）
      if (item != "") item = item "\t" line
    }
  }
  END { if (item != "") print item }
')

if [ -z "$choices" ]; then
  exit 0
fi

# fzf で選択（質問テキストを header に表示）
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

# 選択された行から番号を抽出して送信
option_number=$(echo "$selected" | cut -f1 | grep -oE '^\d+' | head -1)

if [ -n "$option_number" ]; then
  "$CC_RESPOND" "$session_name" "$option_number"
fi
