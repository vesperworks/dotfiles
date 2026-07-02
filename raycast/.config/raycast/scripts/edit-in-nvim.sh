#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Edit in Neovim
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📝
# @raycast.packageName Editor

set -euo pipefail

# BSD mktemp は XXXXXX がテンプレート末尾にないと展開されないため、
# サフィックスなしで生成してから .md を付与する
TMPFILE=$(mktemp "${TMPDIR:-/tmp}/nvim-clipboard-edit.XXXXXX")
mv "$TMPFILE" "${TMPFILE}.md"
TMPFILE="${TMPFILE}.md"
trap 'rm -f "$TMPFILE"' EXIT
pbpaste >"$TMPFILE"

# フローティング化をバックグラウンドで遅延実行
(
	sleep 0.3
	aerospace layout floating
) &

/Applications/Alacritty.app/Contents/MacOS/alacritty \
	--title "Edit in Neovim" \
	-e sh -c "nvim '$TMPFILE' && pbcopy < '$TMPFILE'"
