#!/bin/bash

# command-logger.sh - Bashコマンド実行前のロギングスクリプト
# 実行されるコマンドを記録し、監査証跡を残す

# ログファイルのパス
LOG_FILE="$HOME/.claude/logs/command-history.log"
LOG_DIR=$(dirname "$LOG_FILE")

# Load security utilities (required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=security-utils.sh
source "$SCRIPT_DIR/security-utils.sh" || {
  echo "[command-logger] Error: security-utils.sh not found" >&2
  exit 0  # Don't block command execution
}

# ログディレクトリが存在しない場合は作成
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR" 2>/dev/null || exit 0
fi

# タイムスタンプ
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Claudeから渡される引数を取得
TOOL_NAME="$1"
shift

# コマンドを抽出する関数
extract_command() {
    local args="$*"

    if [[ "$args" =~ \"command\":[[:space:]]*\"([^\"]+)\" ]]; then
        local cmd="${BASH_REMATCH[1]}"
        cmd="${cmd//\\\"/\"}"
        echo "$cmd"
        return 0
    fi

    return 1
}

# 作業ディレクトリを取得
WORKING_DIR=$(pwd)

# コマンドを抽出
COMMAND=$(extract_command "$@")

# ログエントリを作成
if [ -n "$COMMAND" ]; then
    SESSION_ID="${CLAUDE_SESSION_ID:-$$}"

    # Sanitize and mask sensitive data
    SAFE_COMMAND=$(sanitize_log "$COMMAND")
    SAFE_DIR=$(sanitize_log "$WORKING_DIR")
    SAFE_SESSION=$(sanitize_log "$SESSION_ID")
    MASKED_COMMAND=$(mask_sensitive "$SAFE_COMMAND")

    LOG_ENTRY="[$TIMESTAMP] [Session: $SAFE_SESSION] [Dir: $SAFE_DIR] Command: $MASKED_COMMAND"

    echo "$LOG_ENTRY" >> "$LOG_FILE" 2>/dev/null || true
    echo "[command-logger] $LOG_ENTRY" >&2 2>/dev/null || true
fi

exit 0
