#!/bin/bash

# AeroSpace workspace change handler for SketchyBar
# Triggered by: aerospace_workspace_change event
# Animation inspired by FelixKratz/dotfiles
#
# Perf: aerospace CLI / sketchybar / icon_map are each invoked a constant
# number of times (not per workspace) so workspace switching stays snappy.

CONFIG_DIR="$HOME/.config/sketchybar"
PLUGIN_DIR="$CONFIG_DIR/plugins"

# Load colors
source "$CONFIG_DIR/colors.sh"

# Load icon_map() as a function (no subprocess per app)
source "$PLUGIN_DIR/icon_map.sh"

if [ "$SENDER" = "aerospace_workspace_change" ] || [ "$SENDER" = "forced" ]; then
	# Get focused workspace
	FOCUSED=$(aerospace list-workspaces --focused)
	# Get all visible workspaces (one per monitor)
	VISIBLE=$(aerospace list-workspaces --monitor all --visible)
	# All windows across all workspaces in one call
	ALL_WINDOWS=$(aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null)

	args=()
	for workspace in 1 2 3 4 5 A S D F Q W E R T; do
		# Collect app icons and window count for this workspace
		APP_ICONS=""
		WINDOWS=0
		while IFS='|' read -r ws app; do
			[ "$ws" = "$workspace" ] || continue
			WINDOWS=$((WINDOWS + 1))
			APP_ICONS+="$(icon_map "$app") "
		done <<<"$ALL_WINDOWS"

		# Determine label width (dynamic or 0)
		if [ "$workspace" = "$FOCUSED" ] || [ "$WINDOWS" -gt 0 ]; then
			WIDTH="dynamic"
		else
			WIDTH="0"
		fi

		# Workspace color via indirection (bash 3.2 has no associative arrays)
		color_var="WS_COLOR_$workspace"
		WS_BG_COLOR="${!color_var}"

		if [[ $'\n'"$VISIBLE"$'\n' == *$'\n'"$workspace"$'\n'* ]]; then
			# Visible workspace (on any monitor): colored background, dark icon
			args+=(--set "space.$workspace"
				background.drawing=on
				background.border_width=0
				"background.color=$WS_BG_COLOR"
				"icon.color=$BLACK"
				icon.highlight=off
				label=""
				label.width=0
				"label.color=$BLACK"
				drawing=on)
			# Hide bracket for visible workspace
			args+=(--set "space_bracket.$workspace" background.drawing=off)
		elif [ "$WINDOWS" -gt 0 ]; then
			# Has windows but not focused: alpha background, no border
			args+=(--set "space.$workspace"
				background.drawing=on
				background.color=0x70363a4f
				background.border_width=0
				icon.background.drawing=on
				icon.background.color=0x90363a4f
				icon.background.corner_radius=5
				icon.background.height=26
				"icon.color=$WHITE"
				icon.highlight=off
				"label=$APP_ICONS"
				"label.width=$WIDTH"
				"label.color=$WHITE"
				drawing=on)
			args+=(--set "space_bracket.$workspace" background.drawing=off)
		else
			# Empty workspace - hide
			args+=(--set "space.$workspace"
				background.drawing=off
				background.border_width=0
				"icon.color=$EMPTY_COLOR"
				icon.highlight=off
				label=""
				label.width=0
				"label.color=$EMPTY_COLOR"
				drawing=off)
			args+=(--set "space_bracket.$workspace" background.drawing=off)
		fi
	done

	# Single sketchybar invocation for all workspaces
	sketchybar --animate tanh 20 "${args[@]}"
fi
