#!/bin/bash

# block-author-attribution.sh - コミットメッセージからAI帰属表記をブロック
# PreToolUse hook for Bash tool (git commit)
#
# Exit codes:
#   0 - Allow command execution
#   2 - Block command (forbidden pattern detected)

# Read JSON input from stdin
input=$(cat)

# Extract command from tool_input
command=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$command" ]; then
  exit 0
fi

# Only check git commit commands
if ! echo "$command" | grep -qE '^git\s+commit'; then
  exit 0
fi

# Forbidden patterns in commit messages
# These patterns should NEVER appear in commit messages
forbidden_patterns=(
  'Co-Authored-By:'
  'Co-authored-by:'
  'co-authored-by:'
  'Generated with Claude'
  'Generated with AI'
  'Claude Code'
  'noreply@anthropic.com'
)

# Check each forbidden pattern
for pattern in "${forbidden_patterns[@]}"; do
  if echo "$command" | grep -qiF "$pattern"; then
    echo "⛔ コミットメッセージに禁止されたパターンが含まれています" >&2
    echo "   検出: $pattern" >&2
    echo "   この行を削除してからコミットしてください" >&2
    exit 2
  fi
done

# Command is safe
exit 0
