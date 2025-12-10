#!/bin/bash

# block-dangerous-commands.sh - 危険なBashコマンドをブロック
# PreToolUse hook for Bash tool
#
# Exit codes:
#   0 - Allow command execution
#   2 - Block command (dangerous pattern detected)

# Read JSON input from stdin
input=$(cat)

# Extract command from tool_input
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
    exit 0
fi

# Dangerous patterns to block
# Each pattern is a regex that will be matched against the command
dangerous_patterns=(
    # Destructive file operations
    'rm\s+-rf\s+/'               # rm -rf /
    'rm\s+-rf\s+~'               # rm -rf ~
    'rm\s+-rf\s+\$HOME'          # rm -rf $HOME
    'rm\s+-rf\s+\*'              # rm -rf *

    # Fork bomb (various forms)
    ':\(\)\s*\{'            # :(){ pattern
    ':\s*\(\s*\)\s*\{'      # : ( ) { pattern with spaces

    # Disk operations
    '>\s*/dev/sd[a-z]'           # > /dev/sda
    'mkfs\.'                     # mkfs.ext4, mkfs.ntfs, etc.
    'dd\s+if=.*of=/dev'          # dd to disk

    # Permission escalation
    'chmod\s+-R\s+777\s+/'       # chmod -R 777 /
    'chmod\s+777\s+/'            # chmod 777 /

    # Remote code execution
    'curl\s+.*\|\s*(ba)?sh'      # curl ... | sh
    'wget\s+.*\|\s*(ba)?sh'      # wget ... | sh
    'curl\s+-s.*\|\s*(ba)?sh'    # curl -s ... | sh

    # System shutdown/reboot
    'shutdown\s+-h'              # shutdown -h
    'reboot'                     # reboot
    'init\s+0'                   # init 0

    # History manipulation (potential covering tracks)
    'history\s+-c'               # history -c
    'rm\s+.*\.bash_history'      # rm .bash_history
)

# Check each dangerous pattern
for pattern in "${dangerous_patterns[@]}"; do
    if echo "$command" | grep -qE "$pattern"; then
        echo "⛔ 危険なコマンドをブロックしました" >&2
        echo "   パターン: $pattern" >&2
        echo "   コマンド: $command" >&2
        exit 2
    fi
done

# Command is safe
exit 0
