#!/bin/bash
set -euo pipefail
# herdr-migrate.sh — tmux セッションを herdr workspace へ「真の移植」する（PRP-027 Phase 2）
#
# 使い方:
#   herdr-migrate.sh <tmux-session-name>
#
# pane で走行中の Claude Code 対話セッションがあれば /exit → resume 案内から
# session id をパースし、herdr workspace 側で `claude --resume <id>` として引き継ぐ。
# claude が走っていなければ Phase 1（herdr-open.sh のラベル継承のみ）にフォールバックする。
# 詳細フローは .brain/dotfiles/prp/PRP-027-sesh-herdr-true-migration.md の
# 「🎯 E2E 成功フロー」を参照。
#
# 呼び出し元: sesh picker (sesh-picker.sh) の ^h（tmux セッション行）

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=herdr-common.sh
source "$SCRIPT_DIR/herdr-common.sh"

HERDR_OPEN="$SCRIPT_DIR/herdr-open.sh"
# pane_current_command は Claude Code が process.title を上書きしてバージョン番号
# （例: 2.1.118）になることがある（claude-sleep.sh と同じ判定規則）
CLAUDE_VERSION_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+$'
BUSY_MARKER='esc to interrupt'
EXIT_POLL_MAX=15

WS_ID=""
ROOT_PANE_ID=""

# 診断ログ（picker の run-shell 文脈では stderr が見えないため必須）
MIGRATE_LOG="$HOME/.cache/herdr-migrate.log"

log() {
	mkdir -p "$(dirname "$MIGRATE_LOG")" 2>/dev/null || true
	printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >>"$MIGRATE_LOG" 2>/dev/null || true
}

# claude の実行ファイルパス（--resume 起動に使う）
claude_bin() {
	command -v claude 2>/dev/null || printf '%s\n' "$HOME/.local/bin/claude"
}

# pane_dead が 1 になる、または pane_current_command が $2 から変化するまで
# 最大 EXIT_POLL_MAX 秒（1 秒刻み）ポーリングする。$1: session, $2: 判定前の cmd
# 戻り値: 0=exit 検知, 1=タイムアウト
wait_for_pane_exit() {
	local session="$1" prev_cmd="$2" i dead cmd
	i=0
	while [ "$i" -lt "$EXIT_POLL_MAX" ]; do
		dead=""
		dead="$(tmux display-message -p -t "$session:" '#{pane_dead}' 2>/dev/null)" || dead=""
		if [ "$dead" = "1" ]; then
			return 0
		fi
		cmd=""
		cmd="$(tmux display-message -p -t "$session:" '#{pane_current_command}' 2>/dev/null)" || cmd=""
		if [ -n "$cmd" ] && [ "$cmd" != "$prev_cmd" ]; then
			return 0
		fi
		sleep 1
		i=$((i + 1))
	done
	return 1
}

# capture-pane -S -30 の履歴から「claude --resume <uuid>」の最後の出現をパースする
# （/exit 時に Claude Code 自身が正確な session id を出力する。PRP-027 実測の本命メカニズム）
parse_resume_uuid() {
	local session="$1"
	tmux capture-pane -p -t "$session:" -S -30 2>/dev/null |
		grep -oE 'claude --resume [0-9a-f-]{36}' |
		tail -1 |
		awk '{print $3}'
}

# workspace を focus-or-create（既存 label なら再利用、無ければ --no-focus で create）。
# WS_ID / ROOT_PANE_ID をグローバルに設定する。ROOT_PANE_ID は create 時のみ埋まる
# （既存 workspace 再利用時は pane_list_first で別途取得する）
ensure_workspace() {
	local dir="$1" label="$2" json existing_id create_json
	json="$(ws_json)"
	if ws_labels "$json" | grep -Fxq "$label"; then
		existing_id="$(printf '%s\n' "$json" | jq -r --arg l "$label" \
			'.result.workspaces[]? | select(.label == $l) | .workspace_id' 2>/dev/null | head -1)"
		WS_ID="$existing_id"
		ROOT_PANE_ID=""
	else
		create_json="$(herdr workspace create --cwd "$dir" --label "$label" --no-focus)"
		WS_ID="$(printf '%s\n' "$create_json" | jq -r '.result.workspace.workspace_id' 2>/dev/null)"
		ROOT_PANE_ID="$(printf '%s\n' "$create_json" | jq -r '.result.root_pane.pane_id // empty' 2>/dev/null)"
	fi
}

# 既存 workspace 再利用時に root pane id を引く（bg アタッチ誘導の分岐でのみ必要）
pane_list_first() {
	local ws_id="$1"
	herdr pane list --workspace "$ws_id" 2>/dev/null |
		jq -r '.result.panes[0].pane_id // empty' 2>/dev/null
}

# remain-on-exit を元に戻す（unset）。set -e 経由の中断でも trap から呼ばれる
restore_remain_on_exit() {
	local session="$1"
	tmux set-option -u -t "$session:" remain-on-exit 2>/dev/null || true
}

# 理由をユーザーに通知して中止する（何も破壊しない）
abort_migration() {
	local reason="$1"
	log "ABORT: $reason"
	tmux display-message "herdr 移植中止: $reason" 2>/dev/null || true
	exit 1
}

main() {
	if [ $# -ne 1 ] || [ -z "${1:-}" ]; then
		echo "Usage: herdr-migrate.sh <tmux-session-name>" >&2
		exit 1
	fi
	local session="$1"

	if ! command -v tmux >/dev/null 2>&1; then
		echo "Error: tmux が見つかりません" >&2
		exit 1
	fi

	if ! tmux has-session -t "=$session" 2>/dev/null; then
		echo "Error: tmux セッションが見つかりません: $session" >&2
		exit 1
	fi

	local cwd cmd
	cwd="$(tmux display-message -p -t "$session:" '#{pane_current_path}' 2>/dev/null)" || cwd=""
	cmd="$(tmux display-message -p -t "$session:" '#{pane_current_command}' 2>/dev/null)" || cmd=""

	# claude 判定: pane_current_command が "claude" 直接名、またはバージョン番号形式
	if [ "$cmd" != "claude" ] && ! [[ "$cmd" =~ $CLAUDE_VERSION_PATTERN ]]; then
		# claude 以外は Phase 1 動作（ラベル継承のみ）にフォールバック
		exec "$HERDR_OPEN" "$cwd" "$session"
	fi

	# busy ガード: working 中なら何も触らず中止
	local pane_output=""
	pane_output="$(tmux capture-pane -p -t "$session:" 2>/dev/null)" || pane_output=""
	if printf '%s' "$pane_output" | grep -qi "$BUSY_MARKER"; then
		abort_migration "working 中のため移植できません"
	fi

	# ID 取り逃し防止: pane の根本プロセスが exit すると同時に pane が消えると
	# resume 案内が読めなくなる。remain-on-exit で dead pane として capture 可能に保つ
	tmux set-option -t "$session:" remain-on-exit on
	# 注意: bash 3.2 では単一引用符（遅延展開）の EXIT trap は local 変数を見失う
	# （trap 発火時に $session が空になる、実機検証済み）。二重引用符で登録時に値を確定させる
	# shellcheck disable=SC2064
	trap "restore_remain_on_exit '$session'" EXIT

	tmux send-keys -t "$session:" "/exit" Enter || true

	if ! wait_for_pane_exit "$session" "$cmd"; then
		# bg アタッチビュー等の picker UI 対策: Escape ×2 → /exit をもう 1 回だけ再試行
		tmux send-keys -t "$session:" Escape || true
		tmux send-keys -t "$session:" Escape || true
		tmux send-keys -t "$session:" "/exit" Enter || true
		if ! wait_for_pane_exit "$session" "$cmd"; then
			abort_migration "/exit がタイムアウトしました"
		fi
	fi

	local uuid=""
	uuid="$(parse_resume_uuid "$session")"
	log "session=$session cmd=$cmd cwd=$cwd uuid=${uuid:-<empty>}"

	ensure_workspace "$cwd" "$session"
	log "WS_ID=${WS_ID:-<empty>} ROOT_PANE_ID=${ROOT_PANE_ID:-<empty>}"
	if [ -z "$WS_ID" ]; then
		log "ERROR: workspace 確保失敗"
		echo "Error: herdr workspace の確保に失敗しました" >&2
		exit 1
	fi

	local claude_path=""
	local start_json=""
	if [ -n "$uuid" ]; then
		claude_path="$(claude_bin)"
		start_json="$(herdr agent start "$session" --cwd "$cwd" --workspace "$WS_ID" --no-focus \
			-- "$claude_path" --resume "$uuid" 2>&1)" || {
			log "ERROR: agent start 失敗: $start_json"
			abort_migration "herdr agent start が失敗しました（詳細: $MIGRATE_LOG）"
		}
		log "agent start OK: $start_json"
	else
		# claude は終了したが resume 案内が出なかった = bg アタッチビュー等。
		# 自動 attach は CLI 非対応のため、agent view を開いて attach 誘導する
		if [ -z "$ROOT_PANE_ID" ]; then
			ROOT_PANE_ID="$(pane_list_first "$WS_ID")"
		fi
		if [ -n "$ROOT_PANE_ID" ]; then
			# 作成直後の pane は zsh 起動中で入力を取りこぼすため、少し待ってから送る
			sleep 2
			herdr pane run "$ROOT_PANE_ID" "claude agents" >/dev/null || log "WARN: pane run 失敗"
			log "bg 誘導: pane run 'claude agents' → $ROOT_PANE_ID"
		else
			log "WARN: bg 誘導先の pane が見つからない"
		fi
	fi

	# tmux 側の後始末: pane が死骸(remain-on-exit)なら畳む。シェルが残った場合はセッションを残す
	local dead=""
	dead="$(tmux display-message -p -t "$session:" '#{pane_dead}' 2>/dev/null)" || dead=""
	if [ "$dead" = "1" ]; then
		tmux kill-session -t "=$session" 2>/dev/null || true
	else
		restore_remain_on_exit "$session"
	fi

	# herdr セッションへスイッチ（workspace 操作は済んでいるので引数なし呼び出し = スイッチのみ）
	exec "$HERDR_OPEN"
}

main "$@"
