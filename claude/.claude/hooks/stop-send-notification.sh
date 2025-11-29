#!/bin/bash

# Claude Code Stop Hook - Send macOS notification when a command completes
COMMAND="${CLAUDE_LAST_COMMAND:-Task}"

# Get project name and directory
PROJECT_DIR=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_DIR")

# Convert path to ~ notation
HOME_PATH="${HOME}"
DISPLAY_PATH="${PROJECT_DIR/#$HOME_PATH/~}"

# Determine status emoji based on exit code
if [ "${CLAUDE_LAST_EXIT_CODE:-0}" -eq 0 ]; then
    STATUS_EMOJI="✅"
else
    STATUS_EMOJI="❌"
fi

# Check if terminal-notifier is installed
if command -v terminal-notifier &> /dev/null; then
    # Use terminal-notifier with click action to open VSCode
    terminal-notifier -message "${STATUS_EMOJI} ${PROJECT_NAME}" \
                     -title "🤖 ${PROJECT_NAME}" \
                     -sound Glass \
                     -activate "com.microsoft.VSCode" \
                     -execute "open -a 'Visual Studio Code' '${PROJECT_DIR}'"
else
    # Fallback to osascript if terminal-notifier is not installed
    osascript -e "display notification \"${STATUS_EMOJI} ${PROJECT_NAME}\" with title \"🤖 ${PROJECT_NAME}\" sound name \"Glass\""
fi
