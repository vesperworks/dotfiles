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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=cc-common.sh
source "$SCRIPT_DIR/cc-common.sh"

session=${1:-}
[ -z "$session" ] && exit 0

# tmux セッション存在確認（detach 直前は存在するはず）
if ! tmux has-session -t "$session" 2>/dev/null; then
	exit 0
fi

mkdir -p "$SESH_PANE_HASH_DIR"
hash_file="$SESH_PANE_HASH_DIR/$(sanitize_name "$session")"

# 全ペインの可視内容を結合して shasum（ロジックは cc-common.sh に集約）
compute_pane_hash "$session" >"$hash_file"
