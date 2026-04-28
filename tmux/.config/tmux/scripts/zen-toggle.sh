#!/bin/bash
# tmux zen mode: 現在ペインの左右に空ペインを挟んで中央寄せする全 TUI 共通の zen mode
#
# - 左右ダミーペインで現ペイン幅を ~target に縮める
# - 全 TUI が SIGWINCH でリフロー → nvim/Claude Code/yazi/lazygit すべて中央寄せ
# - 引数なし: 明示トグル（再実行で OFF）
# - --auto:   client-resized hook から呼ばれる自動切替モード（ヒステリシス）
# - 設定:
#     @zen-target-width    既定 100 列 (zen 時の中央ペイン幅)
#     @zen-auto            既定 on    (off で自動切替を無効化)
#     @zen-auto-on-width   既定 target+60  (これ以上の幅で自動 ON)
#     @zen-auto-off-width  既定 target+20  (これ以下の幅で自動 OFF)
set -euo pipefail

PAD_TITLE="zen-pad"
LOCK_DIR="${TMPDIR:-/tmp}/tmux-zen-${USER:-$(id -un)}.lock"

target_width="$(tmux show -gv '@zen-target-width' 2>/dev/null || echo 100)"
auto_on_width="$(tmux show -gv '@zen-auto-on-width' 2>/dev/null || echo $((target_width + 60)))"
auto_off_width="$(tmux show -gv '@zen-auto-off-width' 2>/dev/null || echo $((target_width + 20)))"
auto_enabled="$(tmux show -gv '@zen-auto' 2>/dev/null || echo 'on')"

mode="${1:-toggle}"

current_pane="$(tmux display -p '#{pane_id}')"
zen_active="$(tmux show -wv '@zen_mode_active' 2>/dev/null || echo 'off')"
client_width="$(tmux display -p '#{client_width}')"

ensure_off() {
	if [ "$zen_active" != "on" ]; then return 0; fi
	tmux list-panes -F '#{pane_id} #{pane_title}' |
		awk -v t="$PAD_TITLE" '$2 == t { print $1 }' |
		while IFS= read -r pid; do
			tmux kill-pane -t "$pid" 2>/dev/null || true
		done
	tmux set -w '@zen_mode_active' 'off'
	[ "$mode" = "toggle" ] && tmux display "Zen Mode: OFF"
	return 0
}

ensure_on() {
	if [ "$zen_active" = "on" ]; then return 0; fi
	if [ "$client_width" -lt "$((target_width + 20))" ]; then
		[ "$mode" = "toggle" ] && tmux display "Zen Mode: window too narrow ($client_width)"
		return 0
	fi
	pad_width=$(((client_width - target_width) / 2))
	dummy_cmd='printf "\033[?25l\033[2J"; exec sleep 2147483647'

	tmux split-window -hb -l "$pad_width" -t "$current_pane" "$dummy_cmd"
	left_pad="$(tmux display -p '#{pane_id}')"
	tmux select-pane -T "$PAD_TITLE" -t "$left_pad"
	tmux select-pane -t "$current_pane"

	tmux split-window -h -l "$pad_width" -t "$current_pane" "$dummy_cmd"
	right_pad="$(tmux display -p '#{pane_id}')"
	tmux select-pane -T "$PAD_TITLE" -t "$right_pad"
	tmux select-pane -t "$current_pane"

	tmux set -w '@zen_mode_active' 'on'
	[ "$mode" = "toggle" ] && tmux display "Zen Mode: ON (target=${target_width})"
	return 0
}

case "$mode" in
--auto)
	[ "$auto_enabled" != "on" ] && exit 0
	# split-window が client-resized を再発火するのでロックでループ防止
	mkdir "$LOCK_DIR" 2>/dev/null || exit 0
	# shellcheck disable=SC2064
	trap "rmdir '$LOCK_DIR' 2>/dev/null || true" EXIT
	if [ "$zen_active" = "off" ] && [ "$client_width" -ge "$auto_on_width" ]; then
		ensure_on
	elif [ "$zen_active" = "on" ] && [ "$client_width" -le "$auto_off_width" ]; then
		ensure_off
	fi
	;;
toggle | "")
	if [ "$zen_active" = "on" ]; then
		ensure_off
	else
		ensure_on
	fi
	;;
*)
	echo "Usage: $0 [--auto]" >&2
	exit 1
	;;
esac
