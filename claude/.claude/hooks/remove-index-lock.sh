#!/bin/bash

# remove-index-lock.sh - jj/git コマンド実行前に .git/index.lock を自動削除
# PreToolUse hook for Bash tool
#
# colocate モードで jj と git が .git を共有するため、
# IDE の並列 git 操作により index.lock が残留することがある。
# jj/git コマンド実行前に自動削除して index.lock エラーを防ぐ。

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# jj または git コマンドの場合のみ実行
if echo "$command" | grep -qE '(^|\s|&&|\|\||;)(jj|git)\s'; then
  lock_file=".git/index.lock"
  if [ -f "$lock_file" ]; then
    rm -f "$lock_file"
  fi
fi

exit 0
