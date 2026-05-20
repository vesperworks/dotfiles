#!/bin/bash

# remove-index-lock.sh - PreToolUse hook for Bash tool
# jj/git コマンド実行前に .git/index.lock を自動削除する
#
# colocate モードで jj と git が .git を共有するため、
# IDE の並列 git 操作により index.lock が残留することがある。
#
# Input: stdin JSON with tool_input.command, cwd
# Output: exit 0 (never block)

set -euo pipefail
# never block 契約: 予期せぬエラーでも exit 0 で抜ける
trap 'exit 0' ERR

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ -z "$command" ]]; then
	exit 0
fi

# jj または git コマンドの場合のみ実行
if echo "$command" | grep -qE '(^|\s|&&|\|\||;)(jj|git)\s'; then
	cwd=$(echo "$input" | jq -r '.cwd // empty')
	lock_file="${cwd:-.}/.git/index.lock"

	if [[ -f "$lock_file" ]]; then
		# 実行中の正当な git 操作の lock を消さないよう、60 秒以上古い残留 lock のみ削除
		lock_mtime=$(stat -f %m "$lock_file" 2>/dev/null || echo 0)
		if (($(date +%s) - lock_mtime > 60)); then
			rm -f "$lock_file"
		fi
	fi
fi

exit 0
