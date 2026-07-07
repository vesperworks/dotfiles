#!/bin/bash
# herdr-picker.sh — zoxide 履歴 + herdr workspace を横断する fzf picker
#
# sesh picker (sesh-picker.sh) と同じ操作感で herdr workspace に接続する。
# herdr の [[keys.command]] type="pane" から呼ばれる想定（素の fzf を使用、
# fzf-tmux は herdr の一時ペイン内で動かないため不可）。zsh からも直接呼べる。
#
# 使い方:
#   herdr-picker.sh              # picker を起動
#   herdr-picker.sh --list-all   # 内部用: 全ソースの行を出力（fzf reload 用）
#   herdr-picker.sh --list-ws    # 内部用: workspace 行のみ
#   herdr-picker.sh --list-tses  # 内部用: tmux セッション行のみ
#   herdr-picker.sh --list-dirs  # 内部用: zoxide 行のみ
#
# 行フォーマット: "表示テキスト<TAB>種別:データ[<TAB>cwd]"
#   workspace 行:      " label [status]<TAB>ws:<workspace_id>"
#   tmux セッション行: " name<TAB>tses:<name><TAB>/abs/cwd"（label=セッション名で移植）
#   zoxide 行:         " ~/path/to/dir<TAB>dir:/abs/path/to/dir"
#
# label=basename の契約と共通関数は herdr-common.sh を参照。
# 例外: tmux セッションの移植は label=セッション名（R1 は herdr でも R1 で出す）。

set -euo pipefail

# herdr の [[keys.command]] pane はログインシェルを経由しないことがあるため PATH を防御
export PATH="/opt/homebrew/bin:$PATH"

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=herdr-common.sh
source "$SCRIPT_DIR/herdr-common.sh"

PICKER_LIMIT="${HERDR_PICKER_LIMIT:-50}"

# --- ソース生成 -------------------------------------------------------------

ws_lines() {
	printf '%s\n' "$1" |
		jq -r '.result.workspaces[]? | " \(.label) [\(.agent_status)]\tws:\(.workspace_id)"' 2>/dev/null || true
}

# $1: 既存 workspace の label 一覧（改行区切り）。label と重複する zoxide 候補はスキップ。
# ループ内 fork を避けるため awk 1 プロセスで basename 抽出・照合・~ 置換まで行う
# （awk 内の basename 抽出は label_for_dir と同じ規則）。
list_dirs() {
	zoxide query -l 2>/dev/null | head -n "$PICKER_LIMIT" |
		awk -v home="$HOME" -v labels="$(labels_for_awk "$1")" '
      BEGIN {
        n = split(labels, a, "\037")
        for (i = 1; i <= n; i++) if (a[i] != "") seen[a[i]] = 1
      }
      {
        base = $0
        sub(".*/", "", base)
        if (base in seen) next
        display = $0
        if (index($0, home) == 1) display = "~" substr($0, length(home) + 1)
        printf " %s\tdir:%s\n", display, $0
      }'
}

# BSD awk は -v に改行入り文字列を渡せないため、label 一覧は \037 区切りに変換して渡す
labels_for_awk() {
	printf '%s' "$1" | tr '\n' '\037'
}

# $1: 既存 workspace の label 一覧。移植済み（label 一致）と herdr セッション自体は除外。
# sesh が見せる「今の tmux セッション」を herdr へ移植するための本命ソース
list_tmux_sessions() {
	tmux list-sessions -F $'#{session_name}\t#{pane_current_path}' 2>/dev/null |
		awk -F'\t' -v labels="$(labels_for_awk "$1")" '
      BEGIN {
        n = split(labels, a, "\037")
        for (i = 1; i <= n; i++) if (a[i] != "") seen[a[i]] = 1
      }
      $1 == "herdr" { next }
      $1 in seen { next }
      { printf " %s\ttses:%s\t%s\n", $1, $1, $2 }'
}

# 各モードとも herdr workspace list（ソケット RPC）は 1 回だけ呼ぶ
list_all() {
	local json labels
	json="$(ws_json)"
	labels="$(ws_labels "$json")"
	ws_lines "$json"
	list_tmux_sessions "$labels"
	list_dirs "$labels"
}

# --- 内部モード（fzf reload から再帰呼び出しされる） -------------------------

case "${1:-}" in
--list-all)
	list_all
	exit 0
	;;
--list-ws)
	ws_lines "$(ws_json)"
	exit 0
	;;
--list-tses)
	list_tmux_sessions "$(ws_labels "$(ws_json)")"
	exit 0
	;;
--list-dirs)
	json="$(ws_json)"
	list_dirs "$(ws_labels "$json")"
	exit 0
	;;
esac

# --- picker 本体 -------------------------------------------------------------

# サーバー未接続は早期に明示エラー（reload 中の断は ws_json の || true が吸収する）。
# ここで取得した JSON を初期リストに使い回すため、起動時の RPC は 1 回のまま
if ! initial_json="$(herdr workspace list 2>/dev/null)"; then
	echo "Error: herdr サーバーに接続できません（先に herdr を起動してください）" >&2
	exit 1
fi

# ^t は tmux 層（sesh picker）が横取りするため使えない → セッション絞り込みは ^s
HEADER='^a all  ^s sessions  ^w workspaces  ^x zoxide  ^d close ws'

close_ws_bind="ctrl-d:execute-silent(printf '%s' {2} | sed -n 's/^ws:\\(.*\\)/\\1/p' | xargs -I% herdr workspace close %)+reload(\"$SCRIPT_PATH\" --list-all)"

result="$(
	{
		ws_lines "$initial_json"
		list_dirs "$(ws_labels "$initial_json")"
	} | fzf \
		--ansi \
		--delimiter='\t' \
		--with-nth=1 \
		--print-query \
		--layout=reverse \
		--no-sort \
		--border \
		--border-label '  herdr ' \
		--padding 0,1 \
		--header="$HEADER" \
		--header-first \
		--prompt='  ' \
		--bind='tab:down,btab:up' \
		--bind="ctrl-a:reload(\"$SCRIPT_PATH\" --list-all)" \
		--bind="ctrl-s:reload(\"$SCRIPT_PATH\" --list-tses)" \
		--bind="ctrl-w:reload(\"$SCRIPT_PATH\" --list-ws)" \
		--bind="ctrl-x:reload(\"$SCRIPT_PATH\" --list-dirs)" \
		--bind="$close_ws_bind" ||
		true
)"

# fzf 出力: 1行目=query、2行目=選択行（選択なしなら query のみ）
query="$(printf '%s\n' "$result" | sed -n '1p')"
selection="$(printf '%s\n' "$result" | sed -n '2p')"

# --- 選択後の分岐 -------------------------------------------------------------

if [[ -n "$selection" ]]; then
	meta="$(printf '%s' "$selection" | cut -f2)"
	kind="${meta%%:*}"
	data="${meta#*:}"

	case "$kind" in
	ws)
		herdr workspace focus "$data"
		;;
	tses)
		# tmux セッションの移植: label=セッション名、cwd はそのアクティブペインの値（f3）。
		# 同名 label の workspace が既に存在すれば focus、無ければ create（重複 create の穴を防ぐ）
		tses_cwd="$(printf '%s' "$selection" | cut -f3)"
		if [[ -d "$tses_cwd" ]]; then
			tses_json="$(ws_json)"
			if ws_labels "$tses_json" | grep -Fxq "$data"; then
				tses_ws_id="$(printf '%s\n' "$tses_json" | jq -r --arg l "$data" \
					'.result.workspaces[]? | select(.label == $l) | .workspace_id' 2>/dev/null | head -1)"
				if [[ -n "$tses_ws_id" ]]; then
					herdr workspace focus "$tses_ws_id"
				fi
			else
				herdr workspace create --cwd "$tses_cwd" --label "$data" --focus
			fi
		fi
		;;
	dir)
		herdr workspace create --cwd "$data" --label "$(label_for_dir "$data")" --focus
		;;
	esac
	exit 0
fi

# --- 自由入力（リストにマッチせず Enter） -------------------------------------

if [[ -n "$query" ]]; then
	# チルダ展開（先頭の ~ のみ）
	expanded="${query/#\~/$HOME}"
	if [[ -d "$expanded" ]]; then
		herdr workspace create --cwd "$expanded" --label "$(label_for_dir "$expanded")" --focus
	fi
fi

exit 0
