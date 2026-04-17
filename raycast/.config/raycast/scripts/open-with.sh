#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open With
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📂
# @raycast.packageName File Utils
# @raycast.argument1 { "type": "text", "placeholder": "File path" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "App", "optional": true, "data": [{"title": "Finder (Reveal)", "value": "finder"}, {"title": "Default App", "value": "default"}, {"title": "VS Code", "value": "Visual Studio Code"}, {"title": "Preview", "value": "Preview"}, {"title": "Safari", "value": "Safari"}, {"title": "Chrome", "value": "Google Chrome"}] }

set -euo pipefail

FILE_PATH="$1"
APP="${2:-finder}"

if [ ! -e "$FILE_PATH" ]; then
	echo "File not found: $FILE_PATH"
	exit 1
fi

case "$APP" in
"default")
	open "$FILE_PATH"
	;;
"finder")
	open -R "$FILE_PATH"
	;;
*)
	open -a "$APP" "$FILE_PATH"
	;;
esac
