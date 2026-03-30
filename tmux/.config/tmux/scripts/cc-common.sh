#!/bin/bash
# cc-common.sh — CC (Claude Code) 関連スクリプト共通定義
# sesh-sessions.sh, cc-question-preview.sh, cc-wait-answer.sh, cc-wait-respond.sh から source される

# === ANSI Colors (Tokyo Night) ===
COLOR_YELLOW=$'\033[38;2;224;175;104m'  # #e0af68 (WAITING)
COLOR_BLUE=$'\033[38;2;122;162;247m'    # #7aa2f7 (IDLE)
COLOR_GREEN=$'\033[38;2;115;218;202m'   # #73daca (BUSY)
COLOR_MAGENTA=$'\033[38;2;187;154;247m' # #bb9af7 (DONE)
COLOR_DIM=$'\033[38;2;86;95;137m'       # #565f89
COLOR_RESET=$'\033[0m'

# === AI CLI 検出パターン ===
AI_COMM_NAMES='claude|agent|codex|gemini'
WAITING_PATTERN='esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'
BUSY_PATTERN='esc to interrupt|ctrl\+c to interrupt'

# === trim_blank_lines ===
# capture-pane 出力の先頭・末尾の空白行を除去（ANSI エスケープ対応）
trim_blank_lines() {
  awk '
  {
    plain = $0
    gsub(/\033\[[0-9;]*m/, "", plain)
    gsub(/[[:space:]]/, "", plain)
    if (plain != "") {
      for (i = 0; i < blanks; i++) print blank_lines[i]
      blanks = 0
      print
      found = 1
    } else if (found) {
      blank_lines[blanks++] = $0
    }
  }'
}

# === find_waiting_pane ===
# セッション内の WAITING 状態のペインIDを返す
# Usage: pane_id=$(find_waiting_pane "session_name")
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

    [ -z "$has_ai" ] && continue

    local output
    output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -30) || true
    if echo "$output" | grep -qiE "$WAITING_PATTERN"; then
      echo "$pane_id"
      return 0
    fi
  done < <(tmux list-panes -t "$sess" -F "#{pane_pid}	#{pane_id}" 2>/dev/null)

  return 1
}
