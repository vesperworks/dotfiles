#!/bin/bash

# command-logger.sh - PreToolUse hook for Bash tool
# 実行される Bash コマンドをログファイルに記録する
#
# Input: stdin JSON with tool_input.command, cwd, session_id
# Output: exit 0 (never block)

LOG_FILE="$HOME/.claude/logs/command-history.log"
LOG_DIR=$(dirname "$LOG_FILE")

# ログディレクトリが存在しない場合は作成
if [[ ! -d "$LOG_DIR" ]]; then
	mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
fi

# security-utils.sh をロード
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=security-utils.sh
source "$SCRIPT_DIR/security-utils.sh" || exit 0

# stdin から JSON を読み取り
INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
	exit 0
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# サニタイズ + マスク
SAFE_COMMAND=$(sanitize_log "$COMMAND")
SAFE_DIR=$(sanitize_log "${CWD:-$(pwd)}")
SAFE_SESSION=$(sanitize_log "${SESSION_ID:-$$}")
MASKED_COMMAND=$(mask_sensitive "$SAFE_COMMAND")

LOG_ENTRY="[$TIMESTAMP] [Session: $SAFE_SESSION] [Dir: $SAFE_DIR] Command: $MASKED_COMMAND"

echo "$LOG_ENTRY" >>"$LOG_FILE" 2>/dev/null || true

exit 0
