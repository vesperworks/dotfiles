#!/bin/bash
# cc-common.sh — CC (Claude Code) 関連スクリプト共通定義
# sesh-sessions.sh, cc-question-preview.sh, cc-wait-answer.sh, cc-wait-respond.sh から source される

# === ANSI Colors (Tokyo Night) ===
COLOR_YELLOW=$'\033[38;2;224;175;104m'  # #e0af68 (WAIT = 返答待ち)
COLOR_BLUE=$'\033[38;2;122;162;247m'    # #7aa2f7 (PROMPT = 入力欄が空)
COLOR_GREEN=$'\033[38;2;115;218;202m'   # #73daca (BUSY = 動作中)
COLOR_MAGENTA=$'\033[38;2;187;154;247m' # #bb9af7 (NEW = 未読の応答)
COLOR_DIM=$'\033[38;2;86;95;137m'       # #565f89 (DONE = 既読 / その他)
COLOR_RESET=$'\033[0m'

# === AI CLI 検出パターン ===
AI_COMM_NAMES='claude|agent|codex|gemini'
WAITING_PATTERN='esc to cancel|enter to select|Do you want|Would you like|allow command|Allow execution|\[y/n\]|ready to submit'
BUSY_PATTERN='esc to interrupt|ctrl\+c to interrupt|[0-9]+s · ↓|· ↑ [0-9]+|tokens\)$|^[[:space:]]*[✶✻✽✢❉✷⋆*][[:space:]]+[^[:space:]].*\([0-9]+'

# === 共有ディレクトリ・Tunables ===
SESH_STATE_DIR="${TMPDIR:-/tmp}/sesh-state"
SESH_PANE_HASH_DIR="${TMPDIR:-/tmp}/sesh-pane-hash"
PS_SNAPSHOT_TTL_SEC=2 # ps スナップショットの再利用 TTL（秒）

# === セッション名 → 安全なファイル名 ===
# 英数・ハイフン・アンダースコア・ドット以外を _ に変換。
# 保存名（save-pane-hash.sh）と照合名（sesh-sessions.sh / cc-question-preview.sh）が
# ズレると NEW 判定がサイレントに壊れるため、必ずこの関数を共用する。
sanitize_name() {
	printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

# === ps スナップショット（TTL 付き共有） ===
# ps -ax の fork は重いので、結果を共有ファイルに保存して短い TTL で再利用する。
# picker / fzf preview / status-right が同じスナップショットを参照することで、
# preview のキーストローク毎に ps -ax が走るのを防ぐ。
# フィールド: $1=pid, $2=ppid, $3=%cpu, $4=rss, $5=comm
# Usage: snap=$(ensure_ps_snapshot)
ensure_ps_snapshot() {
	local snap="$SESH_STATE_DIR/ps-snapshot"
	mkdir -p "$SESH_STATE_DIR"
	if [ -f "$snap" ]; then
		local now mtime age
		now=$(date +%s)
		mtime=$(stat -f %m "$snap" 2>/dev/null) || mtime=0
		age=$((now - mtime))
		if [ "$age" -ge 0 ] && [ "$age" -le "$PS_SNAPSHOT_TTL_SEC" ]; then
			echo "$snap"
			return 0
		fi
	fi
	local tmp="$snap.tmp.$$"
	ps -ax -o pid=,ppid=,%cpu=,rss=,comm= 2>/dev/null >"$tmp" || true
	mv "$tmp" "$snap" 2>/dev/null || rm -f "$tmp"
	echo "$snap"
}

# === セッションの全ペイン内容を結合して shasum を計算 ===
# pane_id をマーカーとして含める（pane 構成変化も hash 差分に反映）。
# capture-pane -p は可視領域のみ（attach 時の表示と一致させる）。
# 保存側（save-pane-hash.sh）と照合側（cc-question-preview.sh）の両方がこれを使う。
compute_pane_hash() {
	local session_name=$1
	{
		tmux list-panes -t "$session_name" -F '#{pane_id}' 2>/dev/null | while IFS= read -r pid; do
			[ -z "$pid" ] && continue
			printf '=== %s ===\n' "$pid"
			tmux capture-pane -p -t "$pid" 2>/dev/null || true
		done
	} | shasum 2>/dev/null | awk '{print $1}'
}

# === 保存されたペインハッシュを読み込み（無ければ空文字） ===
load_saved_pane_hash() {
	local session_name=$1
	local hash_file
	hash_file="$SESH_PANE_HASH_DIR/$(sanitize_name "$session_name")"
	[ -f "$hash_file" ] || return 0
	cat "$hash_file" 2>/dev/null || true
}

# === キャッシュキー生成（sesh-sessions.sh と cc-wait-count.sh で共有） ===
# 引数列を ASCII 安全な文字列に変換。空なら "default"。
# Why: cache file path のハードコードと動的算出の暗黙合意を解消。
#      引数仕様を変えるとき、この 1 箇所だけ直せば両方追従する。
cache_key_for_args() {
	local key
	key=$(printf '%s' "$*" | tr -c 'A-Za-z0-9' '_')
	[ -z "$key" ] && key="default"
	echo "$key"
}

# === world state fingerprint ===
# tmux 全体の状態を 1 つの hash に縮約する軽量フィンガープリント。
# session_activity（入力で更新）+ history_size（出力で更新）の両方を見るので、
# 「前回 picker 計算後に世界が変わったか」を 2 IPC + shasum (~15-30ms) で判定できる。
# Why: bg 再計算 (~3秒) を変化なし時に skip し、tmux server lock 占有を回避するため。
world_state_fingerprint() {
	{
		tmux list-sessions -F '#{session_name}:#{session_activity}' 2>/dev/null
		tmux list-panes -a -F '#{pane_id}:#{history_size}' 2>/dev/null
	} | shasum 2>/dev/null | awk '{print $1}'
}

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
# ps -ax は毎回 fork せず TTL 付き共有スナップショットを参照する
# （fzf preview のキーストローク毎に呼ばれてもプロセス走査は TTL に 1 回）
# Usage: pane_id=$(find_waiting_pane "session_name")
find_waiting_pane() {
	local sess=$1
	local snap
	snap=$(ensure_ps_snapshot)
	while IFS=$'\t' read -r pane_pid pane_id; do
		[ -z "$pane_pid" ] && continue

		local has_ai
		has_ai=$(awk -v root="$pane_pid" -v pat="$AI_COMM_NAMES" '
      BEGIN { queue[root]=1 }
      { pid[NR]=$1; ppid[NR]=$2; comm[NR]=$5 }
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
    ' "$snap") || true

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
