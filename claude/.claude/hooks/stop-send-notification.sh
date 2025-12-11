#!/bin/bash

# stop-send-notification.sh - Claude Code停止時に詳細通知を送信
# Stop hook - sends macOS notification with context summary
#
# Features:
# - Shows project name and status
# - Extracts last assistant message summary
# - Includes what was being worked on

# Read JSON input from stdin
input=$(cat)

# Get project info
PROJECT_DIR=$(echo "$input" | jq -r '.cwd // empty')
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR=$(pwd)
fi
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Get transcript path for context extraction
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // empty')

# Convert path to ~ notation for display
HOME_PATH="${HOME}"
DISPLAY_PATH="${PROJECT_DIR/#$HOME_PATH/~}"

# Extract last assistant message from transcript
extract_last_message() {
    local transcript="$1"

    if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
        echo ""
        return
    fi

    # Get last assistant message from JSONL transcript
    # Transcript format: each line is a JSON object with role and content
    local last_msg=$(tail -100 "$transcript" 2>/dev/null | \
        grep -o '"role":"assistant"' -A 1000 | \
        tac | \
        grep -m 1 -B 1000 '"role":"assistant"' | \
        tac | \
        head -1 | \
        jq -r '.content[0].text // .content // empty' 2>/dev/null | \
        head -c 200)

    # If jq parsing failed, try simpler extraction
    if [ -z "$last_msg" ]; then
        last_msg=$(tail -50 "$transcript" 2>/dev/null | \
            grep '"assistant"' | \
            tail -1 | \
            sed 's/.*"text":"\([^"]*\)".*/\1/' | \
            head -c 200)
    fi

    # Clean up and truncate
    if [ -n "$last_msg" ]; then
        # Remove both actual newlines and escaped \n from JSON, then normalize spaces
        last_msg=$(echo "$last_msg" | tr '\n' ' ' | sed 's/\\n/ /g' | sed 's/  */ /g' | head -c 150)

        # Add ellipsis if truncated
        if [ ${#last_msg} -ge 150 ]; then
            last_msg="${last_msg}..."
        fi
    fi

    echo "$last_msg"
}

# Extract what was being worked on (from recent tool calls)
extract_work_summary() {
    local transcript="$1"

    if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
        echo "作業完了"
        return
    fi

    # Look for recent tool uses to understand context
    local recent_tools=$(tail -200 "$transcript" 2>/dev/null | \
        grep -o '"tool_name":"[^"]*"' | \
        sed 's/"tool_name":"//g' | \
        sed 's/"//g' | \
        tail -5 | \
        sort -u | \
        tr '\n' ',' | \
        sed 's/,$//')

    # Look for recent file paths
    local recent_files=$(tail -200 "$transcript" 2>/dev/null | \
        grep -o '"file_path":"[^"]*"' | \
        sed 's/"file_path":"//g' | \
        sed 's/"//g' | \
        xargs -I {} basename {} 2>/dev/null | \
        tail -3 | \
        sort -u | \
        tr '\n' ',' | \
        sed 's/,$//')

    # Build summary
    local summary=""

    if [ -n "$recent_files" ]; then
        summary="📁 $recent_files"
    fi

    if [ -n "$recent_tools" ]; then
        if [ -n "$summary" ]; then
            summary="$summary | 🔧 $recent_tools"
        else
            summary="🔧 $recent_tools"
        fi
    fi

    if [ -z "$summary" ]; then
        summary="作業完了"
    fi

    echo "$summary"
}

# Get last message and work summary
LAST_MESSAGE=$(extract_last_message "$TRANSCRIPT_PATH")
WORK_SUMMARY=$(extract_work_summary "$TRANSCRIPT_PATH")

# Build notification message
# Use ANSI-C quoting ($'...') for proper newline handling in terminal-notifier
if [ -n "$LAST_MESSAGE" ]; then
    NOTIFICATION_MESSAGE="${WORK_SUMMARY}"$'\n\n'"💬 ${LAST_MESSAGE}"
else
    NOTIFICATION_MESSAGE="$WORK_SUMMARY"
fi

# Determine status emoji (could be enhanced with actual exit code check)
STATUS_EMOJI="✅"

# Check if terminal-notifier is installed
if command -v terminal-notifier &> /dev/null; then
    # Use terminal-notifier with click action to open VSCode
    terminal-notifier \
        -title "🤖 Claude Code" \
        -subtitle "$STATUS_EMOJI $PROJECT_NAME" \
        -message "$NOTIFICATION_MESSAGE" \
        -sound Glass \
        -timeout 10 \
        -activate "com.microsoft.VSCode" \
        -execute "open -a 'Visual Studio Code' '${PROJECT_DIR}'"
else
    # Fallback to osascript if terminal-notifier is not installed
    # Note: osascript has limited message length
    SHORT_MSG=$(echo "$NOTIFICATION_MESSAGE" | head -c 100)
    osascript -e "display notification \"$SHORT_MSG\" with title \"🤖 Claude Code\" subtitle \"$STATUS_EMOJI $PROJECT_NAME\" sound name \"Glass\""
fi

exit 0
