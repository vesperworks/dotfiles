#!/bin/bash
# auto-restore.sh — continuum-restore のフォールバック
# continuum が複数プロセス誤検出で restore をスキップした場合に補完する
# continuum-restore 'on' と共存し、2重実行はロックファイルで防止
set -euo pipefail

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LAST_FILE="$RESURRECT_DIR/last"
LOCK_FILE="$RESURRECT_DIR/.restore-done"
LOCK_TIMEOUT=30 # 秒

# continuum_restore.sh (sleep 1) より後に実行されるよう待つ
sleep 2

# lastファイルが存在しなければ何もしない
[[ -L "$LAST_FILE" ]] || exit 0

# ロックファイルが30秒以内に作られていたらスキップ（continuum or 自前が既に実行済み）
if [[ -f "$LOCK_FILE" ]]; then
	lock_age=$(($(date +%s) - $(stat -f %m "$LOCK_FILE")))
	[[ "$lock_age" -lt "$LOCK_TIMEOUT" ]] && exit 0
fi

# セッション数が1以下 = continuum が restore をスキップした
session_count=$(tmux list-sessions 2>/dev/null | wc -l | tr -d ' ')
if [ "$session_count" -le 1 ]; then
	touch "$LOCK_FILE"
	~/.config/tmux/plugins/tmux-resurrect/scripts/restore.sh
fi
