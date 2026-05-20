#!/bin/bash

# stop-send-notification.sh - Claude Code停止時に通知を送信
# Stop hook - sends compact macOS/Moshi notification
# Format: CC｜project-name + last message

set -euo pipefail
# 通知は best-effort: 予期せぬエラーでも exit 0 で抜ける
trap 'exit 0' ERR

input=$(cat)

PROJECT_DIR=$(echo "$input" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
	PROJECT_DIR=$(pwd)
fi
PROJECT_NAME=$(basename "$PROJECT_DIR")

TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // empty')

# Extract last assistant text message from JSONL transcript
extract_last_message() {
	local transcript="$1"

	if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
		echo ""
		return
	fi

	# JSONL: {"type":"assistant","message":{"content":[{"type":"text","text":"..."}]}}
	local last_msg
	# pipefail 下では grep が 1 件もマッチしないと exit 1 になるため || true で吸収
	last_msg=$(tail -500 "$transcript" 2>/dev/null |
		jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty' 2>/dev/null |
		grep -v '^$' |
		tail -1 |
		head -c 200) || last_msg=""

	if [ -n "$last_msg" ]; then
		last_msg=$(echo "$last_msg" | tr '\n' ' ' | sed 's/\\n/ /g' | sed 's/  */ /g' | head -c 150)
		if [ ${#last_msg} -ge 150 ]; then
			last_msg="${last_msg}..."
		fi
	fi

	echo "$last_msg"
}

LAST_MESSAGE=$(extract_last_message "$TRANSCRIPT_PATH")
if [ -z "$LAST_MESSAGE" ]; then
	LAST_MESSAGE="作業完了"
fi

TITLE="🤖CC｜${PROJECT_NAME}"

# macOS デスクトップ通知は無効化（Moshi スマホ通知で代替）

# Moshi通知（スマホ）
if [ -n "${MOSHI_TOKEN:-}" ]; then
	MOSHI_MSG=${LAST_MESSAGE//\"/\\\"}
	curl -sS -X POST https://api.getmoshi.app/api/webhook \
		-H "Content-Type: application/json" \
		-d "{
            \"token\": \"${MOSHI_TOKEN}\",
            \"title\": \"${TITLE}\",
            \"message\": \"${MOSHI_MSG}\"
        }" >/dev/null 2>&1 &
fi

exit 0
