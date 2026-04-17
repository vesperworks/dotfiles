#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Clear CC Notifications
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🧹
# @raycast.packageName Developer Tools
# @raycast.description terminal-notifier で送信された通知を全て一括消去（CC 完了通知を含む）

set -euo pipefail

if ! command -v terminal-notifier &>/dev/null; then
	echo "terminal-notifier not found"
	exit 1
fi

terminal-notifier -remove ALL
echo "Cleared"
