#!/bin/bash

# command-logger.sh - Bashコマンド実行前のロギングスクリプト
# 実行されるコマンドを記録し、監査証跡を残す

# ログファイルのパス
LOG_FILE="$HOME/.claude/logs/command-history.log"
LOG_DIR=$(dirname "$LOG_FILE")

# ログディレクトリが存在しない場合は作成
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# タイムスタンプ
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Claudeから渡される引数を取得
TOOL_NAME="$1"
shift # 最初の引数（ツール名）を除去

# コマンドを抽出する関数
extract_command() {
    local args="$@"
    
    # Bashツールの場合、commandパラメータを探す
    if [[ "$args" =~ \"command\":[[:space:]]*\"([^\"]+)\" ]]; then
        # エスケープされた引用符を元に戻す
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
    # セッションIDを生成（環境変数から取得、なければPIDを使用）
    SESSION_ID="${CLAUDE_SESSION_ID:-$$}"
    
    # ログエントリをフォーマット
    LOG_ENTRY="[$TIMESTAMP] [Session: $SESSION_ID] [Dir: $WORKING_DIR] Command: $COMMAND"
    
    # ログファイルに書き込み
    echo "$LOG_ENTRY" >> "$LOG_FILE"
    
    # デバッグ用：標準エラー出力にも表示（本番環境では削除可能）
    echo "[command-logger] $LOG_ENTRY" >&2
fi

# 常に成功を返す（Bashコマンドの実行を妨げない）
exit 0