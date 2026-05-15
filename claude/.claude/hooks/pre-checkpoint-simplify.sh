#!/bin/bash
# pre-checkpoint-simplify.sh
#
# checkpoint 系コマンド (commit / main 切替 / push / merge / rebase / squash) の直前に、
# まだ /simplify を実行していなければ「先にレビューを推奨」と Claude にリマインドする。
#
# Why session 1 回:
#   毎回出すとうるさい。1 セッションで一度通知すれば十分（チェックポイント前の注意喚起）。
#   sentinel: $TMPDIR/claude-simplify-checkpoint-<session_id>
#
# 続行は常に可能（exit 0）。リマインドのみ。

set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
session_id=$(printf '%s' "$input" | jq -r '.session_id // "default"')

case "$cmd" in
*"jj commit"* | *"git commit"* | \
	*"jj new main"* | *"git checkout main"* | \
	*"jj git push --bookmark main"* | *"git push origin main"* | \
	*"git merge "* | *"jj rebase "* | *"jj squash "*)
	sentinel="${TMPDIR:-/tmp}/claude-simplify-checkpoint-${session_id}"
	if [[ ! -f "$sentinel" ]]; then
		mkdir -p "$(dirname "$sentinel")" 2>/dev/null || true
		: >"$sentinel"
		cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[checkpoint reminder] このコマンドは commit / main 切替 / push / merge / rebase / squash 系です。まだ /simplify を実行していなければ、先に /simplify でレビューを行うことを強く推奨します（このセッションではこの通知は 1 回のみ）。"
  }
}
JSON
	fi
	;;
esac

exit 0
