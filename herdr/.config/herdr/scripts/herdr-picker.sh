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
#   herdr-picker.sh --list-dirs  # 内部用: zoxide 行のみ
#
# 行フォーマット: "表示テキスト<TAB>種別:データ"
#   workspace 行: "● label [status]<TAB>ws:<workspace_id>"
#   zoxide 行:    "~/path/to/dir<TAB>dir:/abs/path/to/dir"
#
# 契約: workspace の同一性判定キーは「label = ディレクトリ basename」（label_for_dir）。
# herdr API (v0.7.1) の workspace list が cwd を返さないための制約で、
# herdr-sync.sh と共有する規則。既知の制限: 同名 basename の別ディレクトリは
# 既存 workspace 扱いになり一覧から除外される。

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]}"
PICKER_LIMIT="${HERDR_PICKER_LIMIT:-50}"

# --- ソース生成 -------------------------------------------------------------

# workspace の label はディレクトリ basename を規則とする（herdr-sync.sh と同じ規則）
label_for_dir() {
	printf '%s\n' "${1##*/}"
}

ws_json() {
	herdr workspace list 2>/dev/null || true
}

ws_lines() {
	printf '%s\n' "$1" |
		jq -r '.result.workspaces[]? | "● \(.label) [\(.agent_status)]\tws:\(.workspace_id)"' 2>/dev/null || true
}

ws_labels() {
	printf '%s\n' "$1" |
		jq -r '.result.workspaces[]?.label' 2>/dev/null || true
}

# $1: 既存 workspace の label 一覧（改行区切り）。label と重複する zoxide 候補はスキップ。
# ループ内 fork を避けるため awk 1 プロセスで basename 抽出・照合・~ 置換まで行う
# （awk 内の basename 抽出は label_for_dir と同じ規則）。
list_dirs() {
	zoxide query -l 2>/dev/null | head -n "$PICKER_LIMIT" |
		awk -v home="$HOME" -v labels="$1" '
      BEGIN {
        n = split(labels, a, "\n")
        for (i = 1; i <= n; i++) if (a[i] != "") seen[a[i]] = 1
      }
      {
        base = $0
        sub(".*/", "", base)
        if (base in seen) next
        display = $0
        if (index($0, home) == 1) display = "~" substr($0, length(home) + 1)
        printf "%s\tdir:%s\n", display, $0
      }'
}

# 各モードとも herdr workspace list（ソケット RPC）は 1 回だけ呼ぶ
list_all() {
	local json
	json="$(ws_json)"
	ws_lines "$json"
	list_dirs "$(ws_labels "$json")"
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

HEADER='enter: connect | ctrl-a: all | ctrl-w: workspaces | ctrl-x: zoxide | ctrl-d: close ws'

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
		--header="$HEADER" \
		--prompt='herdr> ' \
		--bind="ctrl-a:reload(\"$SCRIPT_PATH\" --list-all)" \
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
