#!/bin/bash

# Claude Code Stop Hook - Send macOS notification when a command completes
COMMAND="${CLAUDE_LAST_COMMAND:-Task}"
osascript -e "display notification \"${COMMAND} completed\" with title \"Claude Code\" sound name \"Glass\""