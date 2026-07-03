#!/bin/bash
set -euo pipefail
# herdr-open.sh — ディレクトリを herdr workspace として開き、herdr 専用 tmux セッションへスイッチする
#
# 使い方:
#   herdr-open.sh          # workspace 操作なしで herdr セッションへスイッチのみ
#   herdr-open.sh <dir>    # dir を workspace 化（同名 label が既存なら focus）してスイッチ
#
# 呼び出し元: sesh picker の ^h（引き継ぎ）と zsh の hd()

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=herdr-common.sh
source "$SCRIPT_DIR/herdr-common.sh"

HERDR_TMUX_SESSION="herdr"

# herdr 専用 tmux セッションを確保（無ければ作成 = herdr サーバー/クライアントが立ち上がる）
ensure_herdr_session() {
	if ! tmux has-session -t "=$HERDR_TMUX_SESSION" 2>/dev/null; then
		tmux new-session -d -s "$HERDR_TMUX_SESSION" herdr
	fi
}

# サーバー起動直後は socket が未準備のことがあるため応答を待つ（最大 2 秒）
wait_for_server() {
	for _ in 1 2 3 4 5 6 7 8 9 10; do
		if herdr workspace list >/dev/null 2>&1; then
			return 0
		fi
		sleep 0.2
	done
	echo "Warning: herdr サーバーの応答を確認できませんでした（workspace 操作をスキップ）" >&2
	return 1
}

open_workspace() {
	local dir="$1" label json ws_id
	label="$(label_for_dir "$dir")"
	json="$(ws_json)"
	if ws_labels "$json" | grep -Fxq "$label"; then
		# 既存 workspace を focus（label → workspace_id 解決）
		ws_id="$(printf '%s\n' "$json" | jq -r --arg l "$label" \
			'.result.workspaces[]? | select(.label == $l) | .workspace_id' 2>/dev/null | head -1)"
		if [[ -n "$ws_id" ]]; then
			herdr workspace focus "$ws_id" >/dev/null
		fi
	else
		herdr workspace create --cwd "$dir" --label "$label" --focus >/dev/null
	fi
}

main() {
	local dir="${1:-}"

	if ! command -v tmux >/dev/null 2>&1; then
		echo "Error: tmux が見つかりません" >&2
		exit 1
	fi

	if [[ -n "$dir" && ! -d "$dir" ]]; then
		echo "Error: ディレクトリが存在しません: $dir" >&2
		exit 1
	fi

	ensure_herdr_session

	if [[ -n "$dir" ]] && wait_for_server; then
		open_workspace "$dir"
	fi

	# herdr セッションへスイッチ（tmux 内なら switch、外なら attach）
	if [[ -n "${TMUX:-}" ]]; then
		tmux switch-client -t "=$HERDR_TMUX_SESSION"
	else
		exec tmux attach -t "=$HERDR_TMUX_SESSION"
	fi
}

main "$@"
