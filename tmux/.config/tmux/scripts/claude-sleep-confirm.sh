#!/bin/bash
# claude-sleep-confirm.sh — tmux popup で sleep 候補確認 → 一斉スリープ
#
# sesh-picker.sh の ^s から呼び出される。候補リストを表示して y/N 確認、
# y で `claude-sleep.sh --all` を実行する。

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"
SLEEP_SCRIPT="$SCRIPT_DIR/claude-sleep.sh"

echo "=== Claude Sleep Candidates ==="
echo ""
"$SLEEP_SCRIPT" --list
echo ""

# 0件なら早期リターン
count=$("$SLEEP_SCRIPT" --count 2>/dev/null || echo 0)
if [ "$count" = 0 ]; then
	echo "Nothing to sleep."
	read -r -p "Press Enter to close..."
	exit 0
fi

read -r -p "Sleep all $count idle Claudes? [y/N] " ans
case "$ans" in
y | Y | yes)
	echo ""
	"$SLEEP_SCRIPT" --all
	# キャッシュ無効化（次回 picker で 0 表示に）
	rm -f "${HOME}/.cache/claude-sleep-count"
	echo ""
	echo "Done. Resume: Enter on 💤 session in sesh picker"
	read -r -p "Press Enter to close..."
	;;
*)
	echo "Cancelled."
	sleep 1
	;;
esac
