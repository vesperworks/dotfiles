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
	ps -ax -o pid=,ppid=,%cpu=,rss=,comm= 2>/dev/null >"$PS_SNAPSHOT" || true
}

# === tmux pane 一覧の一括スナップショット ===
# tmux list-panes -t <session> を 26 セッション × 3 関数で叩いていたのを
# tmux list-panes -a 1 回に集約。tmux IPC を ~78 回 → 1 回に削減。
# フィールド: $1=session_name, $2=pane_id (%N), $3=pane_pid
PANES_SNAPSHOT=""
_init_panes_snapshot() {
	if [ -n "$PANES_SNAPSHOT" ]; then return; fi
	_init_snapshot
	PANES_SNAPSHOT="$TMPDIR_WORK/panes_snapshot"
	tmux list-panes -a -F '#{session_name}	#{pane_id}	#{pane_pid}' 2>/dev/null >"$PANES_SNAPSHOT" || true
}

# === pane capture の一括スナップショット ===
# detect_ai_status と get_current_pane_hash の両方が tmux capture-pane を呼ぶのを
# 1 回に集約。pane capture × 32 ペイン × 2 関数 = 64 IPC → 32 IPC に半減。
# pane_id ("%N" 固定形式) の "%" だけ "_" に置換してファイル名にする（fork 回避）。
# capture は subshell で並列実行（IPC 待ち時間の重複を最小化）。
PANE_CAP_DIR=""
_init_pane_captures() {
	if [ -n "$PANE_CAP_DIR" ]; then return; fi
	_init_panes_snapshot
	PANE_CAP_DIR="$TMPDIR_WORK/captures"
	mkdir -p "$PANE_CAP_DIR"
	local _sess pid _ppid safe
	local cap_pids=()
	while IFS=$'\t' read -r _sess pid _ppid; do
		[ -z "$pid" ] && continue
		safe="${pid//%/_}"
		(tmux capture-pane -p -t "$pid" 2>/dev/null >"$PANE_CAP_DIR/$safe" || true) &
		cap_pids+=($!)
	done <"$PANES_SNAPSHOT"
	local cap_pid
	for cap_pid in "${cap_pids[@]+"${cap_pids[@]}"}"; do
		wait "$cap_pid" 2>/dev/null || true
	done
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
	_init_panes_snapshot
	_init_pane_captures
	local session_name=$1
	local best_status=""

	while IFS=$'\t' read -r pane_pid pane_id; do
		[ -z "$pane_pid" ] && continue

		# 子孫PIDを取得
		local desc_file="$TMPDIR_WORK/desc_$$_${pane_pid}"
		echo "$pane_pid" >"$desc_file"
		get_descendant_pids "$pane_pid" >>"$desc_file"

		# AI CLIプロセスがあるか確認
		if ! has_ai_process "$desc_file"; then
			continue
		fi

		# ペイン出力からパターンマッチ（共有 capture を tail）
		local pane_output cap_file
		cap_file="$PANE_CAP_DIR/${pane_id//%/_}"
		pane_output=$(tail -30 "$cap_file" 2>/dev/null) || true

		# WAIT 検出（最優先 - ユーザーの操作が必要なので絶対に見落とさない）
		# 許可プロンプト中も裏で spinner が動いているので BUSY パターンと両方マッチするが、
		# 意味的にはユーザー判断が必要な WAIT を優先する
		# パターンは cc-common.sh で一元管理（cc-wait-count.sh と同期）
		if echo "$pane_output" | grep -qiE "$WAITING_PATTERN"; then
			echo "WAITING"
			return
		elif echo "$pane_output" | grep -qiE "$BUSY_PATTERN"; then
			echo "BUSY"
			return
		else
			# AI プロセスはあるが BUSY/WAITING パターンが見えない = 応答完了 or 入力待ち
			# Claude Code はアイドル時も入力欄を表示するので、IDLE と DONE を区別せず
			# すべて DONE 扱いとし、hash 比較で NEW（未読）/ DONE（既読）に分岐させる
			if [ -z "$best_status" ]; then
				best_status="DONE"
			fi
		fi
	done < <(awk -F'\t' -v s="$session_name" '$1==s {print $3"\t"$2}' "$PANES_SNAPSHOT" 2>/dev/null)

	if [ -n "$best_status" ]; then
		echo "$best_status"
	fi
}

# === セッションリソース取得 ===
get_session_resources() {
	_init_snapshot
	_init_panes_snapshot
	local session_name=$1
	local pid_file="$TMPDIR_WORK/res_$$_${session_name}"

	# 全ペインPIDとその子孫を収集（snapshot から awk フィルタ）
	local pane_pids
	pane_pids=$(awk -F'\t' -v s="$session_name" '$1==s {print $3}' "$PANES_SNAPSHOT" 2>/dev/null) || true

	: >"$pid_file"
	local ppid
	for ppid in $pane_pids; do
		[ -z "$ppid" ] && continue
		echo "$ppid" >>"$pid_file"
		get_descendant_pids "$ppid" >>"$pid_file"
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
	local rss_mb=$((rss_kb / 1024))
	if [ "$rss_mb" -ge 1024 ]; then
		awk "BEGIN { printf \"%.1fG\", $rss_mb/1024 }"
	else
		echo "${rss_mb}M"
	fi
}

# === 最終アクセスからの経過時間を 4 文字幅でフォーマット ===
#   " 30s" / " 12m" / "  3h" / "  2d" / "   -" (未アクセス)
format_age() {
	local last_at=${1:-0}
	local now=${2:-0}
	if [ -z "$last_at" ] || [ "$last_at" = "0" ] || [ "$now" = "0" ]; then
		echo "   -"
		return
	fi
	local diff=$((now - last_at))
	if [ "$diff" -lt 0 ]; then
		echo " now"
	elif [ "$diff" -lt 60 ]; then
		printf "%3ds" "$diff"
	elif [ "$diff" -lt 3600 ]; then
		printf "%3dm" $((diff / 60))
	elif [ "$diff" -lt 86400 ]; then
		printf "%3dh" $((diff / 3600))
	else
		printf "%3dd" $((diff / 86400))
	fi
}

# === ハッシュ保存ディレクトリ ===
HASH_DIR="${TMPDIR:-/tmp}/sesh-pane-hash"

# === セッション名 → 安全なファイル名 ===
sanitize_name() {
	printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

# === 現在のペイン内容ハッシュ（save-pane-hash.sh と同じロジック） ===
# pane 順序: list-panes -a も list-panes -t と同じく tmux 内部 linked list 順なので、
# session でフィルタした結果は -t と同一（Phase 0 で実機検証済み）。
# capture 内容: _init_pane_captures が事前に取った同じバイト列を使うので、
# save-pane-hash.sh が `tmux capture-pane -p -t "$pid"` で取るものと一致。
get_current_pane_hash() {
	_init_panes_snapshot
	_init_pane_captures
	local session_name=$1
	{
		awk -F'\t' -v s="$session_name" '$1==s {print $2}' "$PANES_SNAPSHOT" 2>/dev/null | while IFS= read -r pid; do
			[ -z "$pid" ] && continue
			printf '=== %s ===\n' "$pid"
			cat "$PANE_CAP_DIR/${pid//%/_}" 2>/dev/null || true
		done
	} | shasum 2>/dev/null | awk '{print $1}'
}

# === 保存ハッシュ取得（無ければ空文字） ===
get_saved_pane_hash() {
	local session_name=$1
	local safe_name hash_file
	safe_name=$(sanitize_name "$session_name")
	hash_file="$HASH_DIR/$safe_name"
	[ -f "$hash_file" ] || return 0
	cat "$hash_file" 2>/dev/null || true
}

# === 未読判定（return 0 = unread, 1 = read） ===
# 「最後に detach/switch した時のペイン内容」と「今のペイン内容」を比較。
# 保存ハッシュ無し（まだ一度も detach 経験がない）→ 既読扱い（誤検出抑制）。
is_unread() {
	local current_hash=$1
	local saved_hash=$2
	[ -z "$saved_hash" ] && return 1
	[ -z "$current_hash" ] && return 1
	[ "$current_hash" != "$saved_hash" ]
}

# === ステータスアイコン+色を取得（表示幅 9 で統一） ===
# 絵文字 (💤 💡) は 2 cells、他のアイコン (● ◐ ◇) は 1 cell なので、
# テキスト部分のパディングで全体を 9 cells 幅に揃える
format_status() {
	local status=$1
	case "$status" in
	BUSY) echo "${COLOR_GREEN}● BUSY   ${COLOR_RESET}" ;;
	WAIT) echo "${COLOR_YELLOW}◐ WAIT   ${COLOR_RESET}" ;;
	NEW) echo "${COLOR_MAGENTA}◇ NEW    ${COLOR_RESET}" ;;
	SLEEPY) echo "${COLOR_YELLOW}💡 SLEEPY${COLOR_RESET}" ;;
	SLEEP) echo "${COLOR_DIM}💤 SLEEP ${COLOR_RESET}" ;;
	DONE) echo "${COLOR_DIM}◇ DONE   ${COLOR_RESET}" ;;
	*) echo "" ;;
	esac
}

# === 1セッション分の情報を取得してファイルに書き出す ===
process_session() {
	local line=$1
	local session_name=$2
	local outfile=$3
	local max_name_len=$4
	local last_attached=${5:-0}
	local now=${6:-0}
	local is_today=${7:-0}

	local ai_status display_status bucket
	local resources cpu_pct rss_kb mem_str status_str age_str
	local cur_hash saved_hash

	# SLEEP/SLEEPY は最優先（AI ステータス検出より先に判定）
	# SLEEPING / CANDIDATE はピッカー側から共有ファイル経由で渡される改行区切りリスト
	if [ -n "${SLEEPING_LIST:-}" ] && echo "$SLEEPING_LIST" | grep -qxF "$session_name" 2>/dev/null; then
		display_status="SLEEP"
	elif [ -n "${CANDIDATE_LIST:-}" ] && echo "$CANDIDATE_LIST" | grep -qxF "$session_name" 2>/dev/null; then
		display_status="SLEEPY"
	else
		ai_status=$(detect_ai_status "$session_name")
		# 内部 AI ステータス → 表示ステータス変換
		# DONE は「detach 後に内容が変わったか」で NEW か DONE に分岐
		case "$ai_status" in
		BUSY) display_status="BUSY" ;;
		WAITING) display_status="WAIT" ;;
		DONE)
			cur_hash=$(get_current_pane_hash "$session_name")
			saved_hash=$(get_saved_pane_hash "$session_name")
			if is_unread "$cur_hash" "$saved_hash"; then
				display_status="NEW"
			else
				display_status="DONE"
			fi
			;;
		*) display_status="" ;;
		esac
	fi

	# Bucket 決定: アクション必要度の高い順
	#   1=WAIT (自分の返答要)
	#   2=BUSY (動作中)
	#   3=NEW (未読の応答)
	#   4=今日 attach (アクティブ)
	#   ── separator ──
	#   5=未 attach (アーカイブ)
	#   6=SLEEPY (2h+ idle、sleep 候補)
	#   7=SLEEP (sleep 済み)
	case "$display_status" in
	WAIT) bucket=1 ;;
	BUSY) bucket=2 ;;
	NEW) bucket=3 ;;
	SLEEPY) bucket=6 ;;
	SLEEP) bucket=7 ;;
	*)
		if [ "$is_today" = "1" ]; then
			bucket=4
		else
			bucket=5
		fi
		;;
	esac
	echo "$bucket" >"$outfile.bucket"

	resources=$(get_session_resources "$session_name")
	cpu_pct=$(echo "$resources" | awk '{print $1}')
	rss_kb=$(echo "$resources" | awk '{print $2}')
	mem_str=$(format_mem "$rss_kb")
	status_str=$(format_status "$display_status")
	age_str=$(format_age "$last_attached" "$now")

	# セッション名の後にパディングを挿入して列を揃える
	local pad_len=$((max_name_len - ${#session_name}))
	local padding=""
	if [ "$pad_len" -gt 0 ]; then
		padding=$(printf '%*s' "$pad_len" '')
	fi

	# ステータス列: " %b  " = 1+9+2 = 12 表示幅
	local suffix=""
	if [ -n "$status_str" ]; then
		suffix=$(printf " %b  ${COLOR_DIM}%s  %5s%%  %4s${COLOR_RESET}" "$status_str" "$age_str" "$cpu_pct" "$mem_str")
	else
		suffix=$(printf "            ${COLOR_DIM}%s  %5s%%  %4s${COLOR_RESET}" "$age_str" "$cpu_pct" "$mem_str")
	fi

	echo "${line}${padding}${suffix}" >"$outfile"
}

# === メイン処理 ===
main() {
	_init_snapshot
	_init_panes_snapshot
	_init_pane_captures
	local tmpdir=$TMPDIR_WORK

	# SLEEP/SLEEPY 情報読み込み: env > 共有ファイル の優先順
	# picker bind での reload では env が引き継がれないため、ファイル fallback で一貫性を保つ
	local sleep_info_dir="${TMPDIR:-/tmp}/sesh-state"
	if [ -n "${SLEEPING:-}" ]; then
		SLEEPING_LIST="$SLEEPING"
	elif [ -f "$sleep_info_dir/sleeping" ]; then
		SLEEPING_LIST=$(cat "$sleep_info_dir/sleeping" 2>/dev/null)
	else
		SLEEPING_LIST=""
	fi
	if [ -n "${CANDIDATE:-}" ]; then
		CANDIDATE_LIST="$CANDIDATE"
	elif [ -f "$sleep_info_dir/candidate" ]; then
		CANDIDATE_LIST=$(cat "$sleep_info_dir/candidate" 2>/dev/null)
	else
		CANDIDATE_LIST=""
	fi
	export SLEEPING_LIST CANDIDATE_LIST

	# sesh listで基本リスト取得
	local sesh_output
	sesh_output=$(sesh list "$@" -i 2>/dev/null) || true

	if [ -z "$sesh_output" ]; then
		return
	fi

	# tmuxセッション一覧をキャッシュ（最終アクセス時刻 / activity / 接続中フラグ付き）
	# session_last_attached だけだと「昨日 attach して今日もずっと接続中」のセッションが
	# 今日扱いから漏れるので、session_attached（接続中なら 1+）と session_activity（最終
	# アクティビティ時刻、入力で更新される）も取って OR 判定する
	local tmux_sessions tmux_sessions_with_time today_start now
	tmux_sessions=$(tmux list-sessions -F '#{session_name}' 2>/dev/null) || true
	tmux_sessions_with_time=$(tmux list-sessions -F '#{session_name}	#{session_last_attached}	#{session_activity}	#{session_attached}' 2>/dev/null) || true
	today_start=$(date -j -v0H -v0M -v0S +%s 2>/dev/null) || today_start=$(date -d 'today 00:00:00' +%s 2>/dev/null) || today_start=0
	now=$(date +%s)

	# セッション名の最大長を計算（列揃え用）
	local max_name_len=0
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		local name
		name=$(echo "$line" | awk '{print $2}')
		if [ ${#name} -gt "$max_name_len" ]; then
			max_name_len=${#name}
		fi
	done <<<"$sesh_output"

	local idx=0
	local pids=()

	while IFS= read -r line; do
		[ -z "$line" ] && continue

		local session_name
		session_name=$(echo "$line" | awk '{print $2}')

		# 今日アクティブかを判定: 接続中 OR 今日 activity あり OR 今日 last_attached
		# session_last_attached は「最後に attach した瞬間」しか更新されないので、
		# ずっと attach 中のセッションは何日経っても初回 attach 時刻のまま。
		# 接続中フラグと session_activity（キー入力等で更新）でカバーする。
		# age 列の表示値はこれまで通り session_last_attached を使う。
		local meta last_attached activity attached is_today
		meta=$(echo "$tmux_sessions_with_time" | awk -F'\t' -v s="$session_name" '$1==s {print; exit}')
		last_attached=$(echo "$meta" | awk -F'\t' '{print $2}')
		activity=$(echo "$meta" | awk -F'\t' '{print $3}')
		attached=$(echo "$meta" | awk -F'\t' '{print $4}')
		is_today=0
		if [ -n "$attached" ] && [ "$attached" -gt 0 ] 2>/dev/null; then
			is_today=1
		elif [ -n "$activity" ] && [ "$activity" -ge "$today_start" ] 2>/dev/null; then
			is_today=1
		elif [ -n "$last_attached" ] && [ "$last_attached" -ge "$today_start" ] 2>/dev/null; then
			is_today=1
		fi

		if echo "$tmux_sessions" | grep -qxF "$session_name"; then
			process_session "$line" "$session_name" "$tmpdir/$idx" "$max_name_len" "$last_attached" "$now" "$is_today" &
			pids+=($!)
		else
			# tmuxセッション以外もパディングして列を揃える
			local pad_len=$((max_name_len - ${#session_name}))
			local padding=""
			if [ "$pad_len" -gt 0 ]; then
				padding=$(printf '%*s' "$pad_len" '')
			fi
			echo "${line}${padding}" >"$tmpdir/$idx"
			# tmux 外セッションは未 attach 扱い（bucket 6）
			echo "6" >"$tmpdir/${idx}.bucket"
		fi

		idx=$((idx + 1))
	done <<<"$sesh_output"

	# 全バックグラウンドジョブを待つ
	for pid in "${pids[@]+"${pids[@]}"}"; do
		wait "$pid" 2>/dev/null || true
	done

	# bucket: 1=WAIT 2=BUSY 3=NEW 4=今日 attach 5=未 attach 6=SLEEPY 7=SLEEP
	local -a bucket1 bucket2 bucket3 bucket4 bucket5 bucket6 bucket7
	bucket1=()
	bucket2=()
	bucket3=()
	bucket4=()
	bucket5=()
	bucket6=()
	bucket7=()
	for ((i = 0; i < idx; i++)); do
		[ -f "$tmpdir/$i" ] || continue
		local content bucket
		content=$(cat "$tmpdir/$i")
		bucket=$(cat "$tmpdir/${i}.bucket" 2>/dev/null) || bucket=6
		case "$bucket" in
		1) bucket1+=("$content") ;;
		2) bucket2+=("$content") ;;
		3) bucket3+=("$content") ;;
		4) bucket4+=("$content") ;;
		5) bucket5+=("$content") ;;
		6) bucket6+=("$content") ;;
		7) bucket7+=("$content") ;;
		*) bucket6+=("$content") ;;
		esac
	done

	local sep="${COLOR_DIM}──${COLOR_RESET}"
	local has_top=false
	local has_archive=false
	# 1: WAIT（自分の返答待ち、最優先）
	if [ "${#bucket1[@]}" -gt 0 ]; then
		printf '%s\n' "${bucket1[@]}"
		has_top=true
	fi
	# 2: BUSY（動作中）
	if [ "${#bucket2[@]}" -gt 0 ]; then
		printf '%s\n' "${bucket2[@]}"
		has_top=true
	fi
	# 3: NEW（未読の応答、age 問わず）
	if [ "${#bucket3[@]}" -gt 0 ]; then
		printf '%s\n' "${bucket3[@]}"
		has_top=true
	fi
	# 4: 今日アクセス済み（アクティブ）
	if [ "${#bucket4[@]}" -gt 0 ]; then
		printf '%s\n' "${bucket4[@]}"
		has_top=true
	fi
	# ── separator ── (アクティブとアーカイブの境界)
	# 5: 未 attach（アーカイブ）
	if [ "${#bucket5[@]}" -gt 0 ]; then
		if $has_top; then echo "$sep"; fi
		printf '%s\n' "${bucket5[@]}"
		has_archive=true
	fi
	# 6: SLEEPY（sleep 候補、アーカイブの下部）
	if [ "${#bucket6[@]}" -gt 0 ]; then
		if ! $has_archive && $has_top; then echo "$sep"; fi
		printf '%s\n' "${bucket6[@]}"
		has_archive=true
	fi
	# 7: SLEEP（sleep 済み、最下部）
	if [ "${#bucket7[@]}" -gt 0 ]; then
		if ! $has_archive && $has_top; then echo "$sep"; fi
		printf '%s\n' "${bucket7[@]}"
	fi
}

# === キャッシュ + 非同期更新ラッパー ===
# C-t 押下時の体感速度向上のため、前回の出力結果を即表示し、
# バックグラウンドで再計算する。次回呼び出しで最新が見える。
#
# キャッシュキー: 引数 ($@) のハッシュ ("sesh list -t" と "sesh list -z" を区別)
# キャッシュTTL: なし（常に表示 + 常にバックグラウンドで再計算）
# 環境変数:
#   SESH_SESSIONS_NO_CACHE=1 でキャッシュを無視して同期実行（デバッグ用）
#   SLEEPING / CANDIDATE はキャッシュキーに含めない（picker 側で都度渡される）
run_with_cache() {
	local cache_dir="${TMPDIR:-/tmp}/sesh-state"
	mkdir -p "$cache_dir"

	# キャッシュキー: 引数のみ
	# sleep info は共有ファイル経由で main 側が読むので、env マーカーは不要
	# これにより cc-wait-count.sh と picker が同じキャッシュを参照（ステータス完全一致）
	# 生成ロジックは cc-common.sh の cache_key_for_args() に集約
	local key cache_file fp_file
	key=$(cache_key_for_args "$@")
	cache_file="$cache_dir/$key.cache"
	fp_file="$cache_dir/$key.fp"

	# キャッシュなし or NO_CACHE 指定時 → 同期実行 + fingerprint 保存
	if [ ! -f "$cache_file" ] || [ "${SESH_SESSIONS_NO_CACHE:-0}" = "1" ]; then
		main "$@" | tee "$cache_file"
		world_state_fingerprint >"$fp_file" 2>/dev/null || true
		return
	fi

	# キャッシュ即表示
	cat "$cache_file"

	# バックグラウンドで再計算（次回呼び出し用）
	# fingerprint 比較で「世界が変わっていない」場合は recalc を skip
	# Why: 3 秒の bg 再計算が走ると tmux server lock が占有され、status-right
	#      の WAIT カウント表示も遅延する。変化なしなら 30ms で完了させる。
	(
		current_fp=$(world_state_fingerprint)
		saved_fp=$(cat "$fp_file" 2>/dev/null || true)
		if [ -n "$current_fp" ] && [ "$current_fp" = "$saved_fp" ]; then
			exit 0
		fi
		# 同じ条件で再実行、結果をアトミックに置換
		tmp_file="$cache_file.tmp.$$"
		if main "$@" >"$tmp_file" 2>/dev/null; then
			mv "$tmp_file" "$cache_file" 2>/dev/null
			printf '%s\n' "$current_fp" >"$fp_file"
		else
			rm -f "$tmp_file"
		fi
	) </dev/null >/dev/null 2>&1 &
	disown 2>/dev/null || true
}

# source時はmain()を実行しない（関数のみ公開）
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	run_with_cache "$@"
fi
