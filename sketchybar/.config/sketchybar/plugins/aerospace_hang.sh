#!/bin/bash

# AeroSpace Hang Indicator for SketchyBar
# Driven by `aerospace-process-watchdog` (and `aerospace-hang-diag`) via the
# `aerospace_hang_state` custom event. STATE=normal hides the indicator;
# degraded shows yellow; hung shows red.

source "$CONFIG_DIR/colors.sh"

LOG_DIR="$HOME/Library/Logs/aerospace-hang"
WATCHDOG_LOG_DIR="$HOME/Library/Logs/aerospace-watchdog"

case "$SENDER" in
aerospace_hang_state)
	case "$STATE" in
	normal)
		sketchybar --set "$NAME" drawing=off
		;;
	degraded)
		sketchybar --set "$NAME" drawing=on icon.color="$YELLOW"
		;;
	hung)
		sketchybar --set "$NAME" drawing=on icon.color="$RED"
		;;
	esac
	;;
mouse.clicked)
	if [[ -d "$WATCHDOG_LOG_DIR" ]]; then
		/usr/bin/open "$WATCHDOG_LOG_DIR" 2>/dev/null || true
	else
		/usr/bin/open "$LOG_DIR" 2>/dev/null || true
	fi
	;;
esac
