#!/bin/bash

# block-dangerous-commands.sh - PreToolUse hook for Bash tool
# permissions.deny でカバーできない複合的な危険パターンをブロックする
#
# Note: rm, dd, sudo, chmod 777, curl, wget 等の単純パターンは
#       settings.json の permissions.deny で既にブロック済み。
#       このスクリプトは deny では検出困難なパターンのみ担当する。
#
# Input: stdin JSON with tool_input.command
# Exit codes:
#   0 - Allow command execution
#   2 - Block command (dangerous pattern detected)

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [[ -z "$command" ]]; then
	exit 0
fi

# deny でカバーできない危険パターン
dangerous_patterns=(
	# Fork bomb (various forms)
	':\(\)\s*\{'
	':\s*\(\s*\)\s*\{'

	# Disk device direct write (dd は deny だが of=/dev は複合パターン)
	'>\s*/dev/sd[a-z]'
	'mkfs\.'

	# System shutdown/reboot
	'shutdown\s+-h'
	'reboot'
	'init\s+0'

	# History manipulation (covering tracks)
	'history\s+-c'
	'rm\s+.*\.bash_history'
	'rm\s+.*\.zsh_history'
)

for pattern in "${dangerous_patterns[@]}"; do
	if echo "$command" | grep -qE "$pattern"; then
		echo "Blocked: dangerous pattern detected: $pattern" >&2
		echo "Command: $command" >&2
		exit 2
	fi
done

exit 0
