#!/bin/bash
# save-pane-hash.sh — sesh picker の既読管理用ペインハッシュ保存
#
# tmux の client-detached / client-session-changed hook から呼ばれる。
# 指定セッションの全ペインの capture-pane 結果を結合して SHA を計算し、
# $TMPDIR/sesh-pane-hash/<session> に保存する。
#
# 次回 sesh-sessions.sh 起動時にこの保存値と現在のペイン内容ハッシュを比較し、
# 変わっていれば「detach 後に新しい出力があった = 未読」と判定する。
#
# Usage: save-pane-hash.sh <session_name>

set -euo pipefail

session=${1:-}
[ -z "$session" ] && exit 0

# tmux セッション存在確認（detach 直前は存在するはず）
if ! tmux has-session -t "$session" 2>/dev/null; then
	exit 0
fi

hash_dir="${TMPDIR:-/tmp}/sesh-pane-hash"
mkdir -p "$hash_dir"

# session 名を安全なファイル名に変換（英数・ハイフン・アンダースコア・ドット以外を _ に）
safe_name=$(printf '%s' "$session" | tr -c 'A-Za-z0-9._-' '_')
hash_file="$hash_dir/$safe_name"

# 全ペインの可視内容を結合して shasum
# capture-pane -p (stdout 出力)、スクロールバックは含めない（attach 時の表示と一致させる）
{
	tmux list-panes -t "$session" -F '#{pane_id}' 2>/dev/null | while IFS= read -r pid; do
		[ -z "$pid" ] && continue
		# pane_id をマーカーとして含める（pane 構成変化も hash 差分に反映）
		printf '=== %s ===\n' "$pid"
		tmux capture-pane -p -t "$pid" 2>/dev/null || true
	done
} | shasum 2>/dev/null | awk '{print $1}' >"$hash_file"
