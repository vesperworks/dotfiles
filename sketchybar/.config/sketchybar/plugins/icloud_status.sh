#!/bin/bash

# iCloud Sync Indicator for SketchyBar
# Driven by update_freq routine: runs `icloud-doctor check` every cycle
# (the find scan takes ~2-3s but sketchybar runs plugins async).
# Hidden when healthy; yellow + count when dataless files exist (their
# reads hang and can block rg-style full scans); red when bird /
# fileproviderd is missing or stuck in state=U.
#
# Click behavior: opens a 3-row popup
#   1. Latest check summary
#   2. Copy `icloud-doctor download` (click row to pbcopy)
#   3. Copy `icloud-doctor nudge` (click row to pbcopy)

source "$CONFIG_DIR/colors.sh"

DOCTOR="$HOME/.local/bin/icloud-doctor"
LAST_CHECK="${TMPDIR:-/tmp}/icloud-doctor/last-check"

update_indicator() {
	local line dataless bird fp
	line=$("$DOCTOR" check 2>/dev/null) || line=""
	dataless=$(printf '%s' "$line" | sed -nE 's/.*DATALESS=([0-9]+).*/\1/p')
	bird=$(printf '%s' "$line" | sed -nE 's/.*BIRD=([^ ]+).*/\1/p')
	fp=$(printf '%s' "$line" | sed -nE 's/.*FP=([^ ]+).*/\1/p')

	# デーモン異常（missing / state=U）= 赤、dataless あり = 黄 + 件数、健全 = 非表示
	if [[ "$bird" == missing || "$fp" == missing || "$bird" == U* || "$fp" == U* ]]; then
		sketchybar --set icloud_status drawing=on icon.color="$RED" label.drawing=off
	elif [[ -n "$dataless" && "$dataless" -gt 0 ]]; then
		sketchybar --set icloud_status drawing=on icon.color="$YELLOW" \
			label.drawing=on label="$dataless"
	else
		sketchybar --set icloud_status drawing=off popup.drawing=off
	fi
}

update_popup() {
	local summary self
	summary=$(cat "$LAST_CHECK" 2>/dev/null || echo "no check yet")
	self="$CONFIG_DIR/plugins/icloud_status.sh"

	sketchybar --set icloud_status.1 \
		drawing=on \
		icon= \
		icon.color="$YELLOW" \
		label="$summary" \
		click_script=""

	sketchybar --set icloud_status.2 \
		drawing=on \
		icon=󰆏 \
		icon.color="$GREEN" \
		label="icloud-doctor download" \
		click_script="SENDER=copy_download NAME=icloud_status.2 $self"

	sketchybar --set icloud_status.3 \
		drawing=on \
		icon=󰆏 \
		icon.color="$BLUE" \
		label="icloud-doctor nudge" \
		click_script="SENDER=copy_nudge NAME=icloud_status.3 $self"
}

copy_to_clipboard() {
	local row=$1 cmd=$2
	printf '%s' "$cmd" | pbcopy
	sketchybar --set "$row" label="copied ✓ — paste in shell"
	sleep 1
	sketchybar --set "$row" label="$cmd"
	sketchybar --set icloud_status popup.drawing=off
}

case "$SENDER" in
routine | forced)
	update_indicator
	;;
mouse.clicked)
	update_popup
	sketchybar --set icloud_status popup.drawing=toggle
	;;
copy_download)
	copy_to_clipboard icloud_status.2 "icloud-doctor download"
	;;
copy_nudge)
	copy_to_clipboard icloud_status.3 "icloud-doctor nudge"
	;;
mouse.exited.global)
	sketchybar --set icloud_status popup.drawing=off
	;;
esac
