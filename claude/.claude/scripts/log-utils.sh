#!/bin/bash
set -euo pipefail

# log-utils.sh - ログ出力ユーティリティ関数
# タイムスタンプ付きのログ出力機能を提供

# logWithTimestamp - タイムスタンプ付きでメッセージを出力
# Usage: logWithTimestamp "message"
# Output format: [YYYY-MM-DD HH:MM:SS] message
logWithTimestamp() {
  local message="${1:-}"

  if [[ -z "$message" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] (empty message)" >&2
    return 1
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message"
  return 0
}

# 直接実行時のテスト用
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  logWithTimestamp "$@"
fi
