#!/bin/bash
# tmux status-right widget: WAIT + NEW セッション数を表示
# Output:
#   "◐ N WAIT" (yellow)   when WAIT > 0
#   "◇ M NEW"  (magenta)  when NEW > 0
#   empty                  when both = 0
#
# 設計: picker (sesh-sessions.sh) のキャッシュを参照して数を集計する。
# これにより「右下バー」と「C-t picker」のステータスが完全一致する。
# picker が開かれるたびにキャッシュは更新される（bg 再計算）。
# キャッシュが存在しない初回はフォールバックで自前計算する。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cc-common.sh
source "$SCRIPT_DIR/cc-common.sh"

# === picker キャッシュから集計 ===
# キャッシュキーは sesh-sessions.sh と同じ算出ルール (cache_key_for_args)。
# sesh-picker.sh が "-t" 引数で呼ぶので、ここも "-t" で算出すれば picker と必ず一致する。
CACHE_FILE="${TMPDIR:-/tmp}/sesh-state/$(cache_key_for_args "-t").cache"

wait_count=0
new_count=0

if [ -f "$CACHE_FILE" ]; then
	# WAIT と NEW の行数を集計。ANSI 色コードに影響されず grep 可能
	# `grep -c || echo 0` だとマッチ無し時に "0\n0" の改行付き 2 値になり後続の数値比較が壊れる
	# `|| var=0` パターンで grep の exit 1 を吸収しつつ stdout を 1 行に保つ
	wait_count=$(grep -c "◐ WAIT" "$CACHE_FILE" 2>/dev/null) || wait_count=0
	new_count=$(grep -c "◇ NEW " "$CACHE_FILE" 2>/dev/null) || new_count=0
else
	# キャッシュ無し（初回）→ WAIT のみリアルタイム計算してフォールバック
	for sess in $(tmux list-sessions -F "#{session_name}" 2>/dev/null); do
		if find_waiting_pane "$sess" >/dev/null 2>&1; then
			wait_count=$((wait_count + 1))
		fi
	done
	# キャッシュ作成を bg で促す（次回以降反映）
	("$SCRIPT_DIR/sesh-sessions.sh" -t >/dev/null 2>&1) </dev/null >/dev/null 2>&1 &
	disown 2>/dev/null || true
fi

# === 出力組み立て ===
out=""
if [ "$wait_count" -gt 0 ] 2>/dev/null; then
	# Tokyo Night yellow: #e0af68
	out="#[fg=#e0af68,bold]◐ ${wait_count} WAIT#[default]"
fi
if [ "$new_count" -gt 0 ] 2>/dev/null; then
	if [ -n "$out" ]; then out="$out "; fi
	# Tokyo Night magenta: #bb9af7
	out="${out}#[fg=#bb9af7,bold]◇ ${new_count} NEW#[default]"
fi
if [ -n "$out" ]; then
	echo "$out "
fi
