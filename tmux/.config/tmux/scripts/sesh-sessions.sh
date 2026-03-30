#!/bin/bash
set -euo pipefail

# sesh list のドロップイン代替
# tmuxセッションにAI CLIステータス + CPU/MEM情報を付加する

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cc-common.sh
source "$SCRIPT_DIR/cc-common.sh"

# === 一時ディレクトリ・スナップショット（init で遅延初期化） ===
TMPDIR_WORK=""
PS_SNAPSHOT=""

_init_snapshot() {
  if [ -n "$TMPDIR_WORK" ]; then return; fi
  TMPDIR_WORK=$(mktemp -d)
  trap 'rm -rf "$TMPDIR_WORK"' EXIT
  # プロセスツリーの一括スナップショット
  # ps -ax を一度だけ呼び、親子関係・リソース・コマンド名をファイルに保存
  # commは最後に配置（切り詰め防止のため）
  # フィールド: $1=pid, $2=ppid, $3=%cpu, $4=rss, $5=comm
  PS_SNAPSHOT="$TMPDIR_WORK/ps_snapshot"
  ps -ax -o pid=,ppid=,%cpu=,rss=,comm= 2>/dev/null > "$PS_SNAPSHOT" || true
}

# === AI CLI検出パターン ===
# basenameで完全一致させるため、awkでは別ロジックを使用
AI_COMM_NAMES='claude|agent|codex|gemini'

# === スナップショットから子孫PIDを取得（再帰なし・awk一発） ===
get_descendant_pids() {
  local root_pid=$1
  awk -v root="$root_pid" '
    BEGIN { queue[root]=1; found=0 }
    { pid[NR]=$1; ppid[NR]=$2 }
    END {
      changed=1
      while (changed) {
        changed=0
        for (i=1; i<=NR; i++) {
          if ((ppid[i] in queue) && !(pid[i] in queue)) {
            queue[pid[i]]=1
            changed=1
          }
        }
      }
      for (p in queue) {
        if (p != root) print p
      }
    }
  ' "$PS_SNAPSHOT"
}

# === スナップショットから指定PIDリストのCPU/RSS合計を取得 ===
get_resources_for_pids() {
  local pid_file=$1
  awk '
    NR==FNR { pids[$1]=1; next }
    ($1 in pids) { cpu+=$3; rss+=$4 }
    END { printf "%.1f %d\n", cpu+0, rss+0 }
  ' "$pid_file" "$PS_SNAPSHOT"
}

# === スナップショットからAIプロセスの有無をチェック ===
has_ai_process() {
  local pid_file=$1
  awk -v pat="$AI_COMM_NAMES" '
    NR==FNR { pids[$1]=1; next }
    ($1 in pids) {
      # commフィールド($5)からbasenameを抽出して完全一致
      n = split($5, parts, "/")
      basename = tolower(parts[n])
      if (basename ~ "^(" pat ")$") { found=1; exit }
    }
    END { exit !found }
  ' "$pid_file" "$PS_SNAPSHOT"
}

# === AI CLIステータス検出 ===
detect_ai_status() {
  _init_snapshot
  local session_name=$1
  local best_status=""

  while IFS=$'\t' read -r pane_pid pane_id; do
    [ -z "$pane_pid" ] && continue

    # 子孫PIDを取得
    local desc_file="$TMPDIR_WORK/desc_$$_${pane_pid}"
    echo "$pane_pid" > "$desc_file"
    get_descendant_pids "$pane_pid" >> "$desc_file"

    # AI CLIプロセスがあるか確認
    if ! has_ai_process "$desc_file"; then
      continue
    fi

    # ペイン出力からパターンマッチ
    local pane_output
    pane_output=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null | tail -30) || true

    if echo "$pane_output" | grep -qiE 'esc to interrupt|ctrl\+c to interrupt'; then
      echo "BUSY"
      return
    elif echo "$pane_output" | grep -qiE 'esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'; then
      if [ "$best_status" != "WAITING" ]; then
        best_status="WAITING"
      fi
    elif echo "$pane_output" | grep -qE -- '-- INSERT --|⏎'; then
      # プロンプトにカーソルがある = 入力待ち
      if [ -z "$best_status" ]; then
        best_status="IDLE"
      fi
    else
      # AIプロセスはあるが入力プロンプトなし = 応答完了・放置
      if [ -z "$best_status" ]; then
        best_status="DONE"
      fi
    fi
  done < <(tmux list-panes -t "$session_name" -F "#{pane_pid}	#{pane_id}" 2>/dev/null)

  if [ -n "$best_status" ]; then
    echo "$best_status"
  fi
}

# === セッションリソース取得 ===
get_session_resources() {
  _init_snapshot
  local session_name=$1
  local pid_file="$TMPDIR_WORK/res_$$_${session_name}"

  # 全ペインPIDとその子孫を収集
  local pane_pids
  pane_pids=$(tmux list-panes -t "$session_name" -F '#{pane_pid}' 2>/dev/null) || true

  : > "$pid_file"
  local ppid
  for ppid in $pane_pids; do
    [ -z "$ppid" ] && continue
    echo "$ppid" >> "$pid_file"
    get_descendant_pids "$ppid" >> "$pid_file"
  done

  if [ ! -s "$pid_file" ]; then
    echo "0.0 0"
    return
  fi

  get_resources_for_pids "$pid_file"
}

# === リソース値フォーマット ===
format_mem() {
  local rss_kb=${1:-0}
  [[ "$rss_kb" =~ ^[0-9]+$ ]] || rss_kb=0
  local rss_mb=$(( rss_kb / 1024 ))
  if [ "$rss_mb" -ge 1024 ]; then
    awk "BEGIN { printf \"%.1fG\", $rss_mb/1024 }"
  else
    echo "${rss_mb}M"
  fi
}

# === ステータスアイコン+色を取得 ===
format_status() {
  local status=$1
  case "$status" in
    BUSY)    echo "${COLOR_GREEN}● BUSY${COLOR_RESET}" ;;
    WAITING) echo "${COLOR_YELLOW}◐ WAIT${COLOR_RESET}" ;;
    IDLE)    echo "${COLOR_BLUE}○ IDLE${COLOR_RESET}" ;;
    DONE)    echo "${COLOR_MAGENTA}◇ DONE${COLOR_RESET}" ;;
    *)       echo "" ;;
  esac
}

# === 1セッション分の情報を取得してファイルに書き出す ===
process_session() {
  local line=$1
  local session_name=$2
  local outfile=$3
  local max_name_len=$4

  local ai_status resources cpu_pct rss_kb mem_str status_str

  ai_status=$(detect_ai_status "$session_name")
  resources=$(get_session_resources "$session_name")
  cpu_pct=$(echo "$resources" | awk '{print $1}')
  rss_kb=$(echo "$resources" | awk '{print $2}')
  mem_str=$(format_mem "$rss_kb")
  status_str=$(format_status "$ai_status")

  # セッション名の後にパディングを挿入して列を揃える
  local pad_len=$(( max_name_len - ${#session_name} ))
  local padding=""
  if [ "$pad_len" -gt 0 ]; then
    padding=$(printf '%*s' "$pad_len" '')
  fi

  # ステータス列: " ● BUSY  " = 1+6+2 = 9表示幅
  local suffix=""
  if [ -n "$status_str" ]; then
    suffix=$(printf " %b  ${COLOR_DIM}%5s%%  %4s${COLOR_RESET}" "$status_str" "$cpu_pct" "$mem_str")
  else
    suffix=$(printf "         ${COLOR_DIM}%5s%%  %4s${COLOR_RESET}" "$cpu_pct" "$mem_str")
  fi

  echo "${line}${padding}${suffix}" > "$outfile"
}

# === メイン処理 ===
main() {
  _init_snapshot
  local tmpdir=$TMPDIR_WORK

  # sesh listで基本リスト取得
  local sesh_output
  sesh_output=$(sesh list "$@" -i 2>/dev/null) || true

  if [ -z "$sesh_output" ]; then
    return
  fi

  # tmuxセッション一覧をキャッシュ
  local tmux_sessions
  tmux_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null) || true

  # セッション名の最大長を計算（列揃え用）
  local max_name_len=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local name
    name=$(echo "$line" | awk '{print $2}')
    if [ ${#name} -gt "$max_name_len" ]; then
      max_name_len=${#name}
    fi
  done <<< "$sesh_output"

  local idx=0
  local pids=()

  while IFS= read -r line; do
    [ -z "$line" ] && continue

    local session_name
    session_name=$(echo "$line" | awk '{print $2}')

    if echo "$tmux_sessions" | grep -qxF "$session_name"; then
      process_session "$line" "$session_name" "$tmpdir/$idx" "$max_name_len" &
      pids+=($!)
    else
      # tmuxセッション以外もパディングして列を揃える
      local pad_len=$(( max_name_len - ${#session_name} ))
      local padding=""
      if [ "$pad_len" -gt 0 ]; then
        padding=$(printf '%*s' "$pad_len" '')
      fi
      echo "${line}${padding}" > "$tmpdir/$idx"
    fi

    idx=$((idx + 1))
  done <<< "$sesh_output"

  # 全バックグラウンドジョブを待つ
  for pid in "${pids[@]+"${pids[@]}"}"; do
    wait "$pid" 2>/dev/null || true
  done

  # 1パスでステータス分類 → グループ別に出力（セパレータ付き）
  local -a wait_items=() busy_items=() done_items=() idle_items=() other_items=()
  for ((i=0; i<idx; i++)); do
    [ -f "$tmpdir/$i" ] || continue
    local content
    content=$(cat "$tmpdir/$i")
    case "$content" in
      *"◐ WAIT"*) wait_items+=("$content") ;;
      *"● BUSY"*) busy_items+=("$content") ;;
      *"◇ DONE"*) done_items+=("$content") ;;
      *"○ IDLE"*) idle_items+=("$content") ;;
      *)          other_items+=("$content") ;;
    esac
  done

  local sep="${COLOR_DIM}──${COLOR_RESET}"
  local has_output=false
  for group in wait busy "done" idle other; do
    local count_var="${group}_items[@]"
    local items=("${!count_var+"${!count_var}"}")
    if [ "${#items[@]}" -gt 0 ] && [ -n "${items[0]:-}" ]; then
      if $has_output; then echo "$sep"; fi
      printf '%s\n' "${items[@]}"
      has_output=true
    fi
  done
}

# source時はmain()を実行しない（関数のみ公開）
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
