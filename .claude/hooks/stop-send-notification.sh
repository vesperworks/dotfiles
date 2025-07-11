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

osascript -e "display notification \"${STATUS_EMOJI} ${PROJECT_NAME}\" with title \"Claude Code - ${DISPLAY_PATH}\" sound name \"Glass\""