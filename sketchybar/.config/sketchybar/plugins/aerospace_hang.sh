#!/bin/bash

# AeroSpace Hang Indicator for SketchyBar
# Driven by `aerospace-process-watchdog` (and `aerospace-hang-diag`) via the
# `aerospace_hang_state` custom event. STATE=normal hides the indicator;
# degraded shows yellow; hung shows red.
#
# Click behavior: opens a 3-row popup
#   1. Summary of the latest watchdog verdict (time + state + reasons)
#   2. Suggested kill command (click row to pbcopy — execute it in a shell)
#   3. Open watchdog log folder in Finder

source "$CONFIG_DIR/colors.sh"

LOG_FILE="$HOME/Library/Logs/aerospace-watchdog/watchdog.log"
WATCHDOG_LOG_DIR="$HOME/Library/Logs/aerospace-watchdog"
HANGDIAG_LOG_DIR="$HOME/Library/Logs/aerospace-hang"

# Convert one reason token (e.g. "chronod:cpu=124", "fantastical2.mac.helper:state=U")
# into the kill command that addresses it. We prefer killall by process name
# so the user can paste-and-go without looking up PIDs.
reason_to_kill_cmd() {
	local token="$1"
	local svc="${token%%:*}"
	case "$svc" in
	aerospace)
		echo 'killall AeroSpace && open -a AeroSpace'
		;;
	fantastical2.mac.helper)
		# Real process name has a space; quote it.
		echo 'killall "Fantastical helper"'
		;;
	"iPhone Mirroring")
		echo 'killall "iPhone Mirroring"'
		;;
	*)
		# IntelliJ / WebStorm / GoLand / Emacs / zoom.us / ChatGPT /
		# chronod / replicatord / WindowServer / etc.
		echo "killall $svc"
		;;
	esac
}

# Read the latest watchdog log line and join per-reason kill commands with `; `.
build_kill_cmd() {
	local line reasons
	line=$(tail -1 "$LOG_FILE" 2>/dev/null)
	reasons=$(printf '%s\n' "$line" | sed -nE 's/.*reasons=\[([^]]*)\].*/\1/p')
	[[ -z "$reasons" ]] && {
		echo ""
		return
	}
	local IFS=','
	local cmds=()
	local token
	for token in $reasons; do
		[[ -z "$token" ]] && continue
		cmds+=("$(reason_to_kill_cmd "$token")")
	done
	if [[ ${#cmds[@]} -eq 0 ]]; then
		echo ""
		return
	fi
	local joined="" first=true c
	for c in "${cmds[@]}"; do
		if $first; then
			joined="$c"
			first=false
		else
			joined="$joined; $c"
		fi
	done
	printf '%s' "$joined"
}

# Build a single-line summary "HH:MM state — reasons" from the last log line.
build_summary() {
	local line ts_full ts state reasons
	line=$(tail -1 "$LOG_FILE" 2>/dev/null)
	[[ -z "$line" ]] && {
		echo "no log yet"
		return
	}
	ts_full=$(printf '%s' "$line" | awk '{print $1}')
	ts=$(printf '%s' "$ts_full" | awk -F'T' '{print $2}' | cut -c1-5)
	state=$(printf '%s' "$line" | sed -nE 's/.*state=([a-z]+).*/\1/p')
	reasons=$(printf '%s' "$line" | sed -nE 's/.*reasons=\[([^]]*)\].*/\1/p')
	if [[ -z "$reasons" ]]; then
		printf '%s %s' "$ts" "$state"
	else
		printf '%s %s — %s' "$ts" "$state" "$reasons"
	fi
}

# Refresh popup rows with current verdict + kill cmd.
update_popup() {
	local summary kill_cmd self
	summary=$(build_summary)
	kill_cmd=$(build_kill_cmd)
	self="$CONFIG_DIR/plugins/aerospace_hang.sh"

	sketchybar --set aerospace_hang.1 \
		drawing=on \
		icon=󰀦 \
		icon.color="$YELLOW" \
		label="$summary" \
		click_script=""

	if [[ -n "$kill_cmd" ]]; then
		sketchybar --set aerospace_hang.2 \
			drawing=on \
			icon=󰆏 \
			icon.color="$GREEN" \
			label="$kill_cmd" \
			click_script="SENDER=copy_kill_cmd NAME=aerospace_hang.2 $self"
	else
		sketchybar --set aerospace_hang.2 drawing=off
	fi

	sketchybar --set aerospace_hang.3 \
		drawing=on \
		icon=󰈙 \
		icon.color="$BLUE" \
		label="Open watchdog log" \
		click_script="SENDER=open_log NAME=aerospace_hang.3 $self"
}

case "$SENDER" in
aerospace_hang_state)
	case "$STATE" in
	normal)
		sketchybar --set aerospace_hang drawing=off popup.drawing=off
		;;
	degraded)
		sketchybar --set aerospace_hang drawing=on icon.color="$YELLOW"
		;;
	hung)
		sketchybar --set aerospace_hang drawing=on icon.color="$RED"
		;;
	esac
	;;
mouse.clicked)
	update_popup
	sketchybar --set aerospace_hang popup.drawing=toggle
	;;
copy_kill_cmd)
	kill_cmd=$(build_kill_cmd)
	if [[ -n "$kill_cmd" ]]; then
		printf '%s' "$kill_cmd" | pbcopy
		sketchybar --set aerospace_hang.2 label="copied ✓ — paste in shell" icon.color="$GREEN"
		sleep 1
		sketchybar --set aerospace_hang.2 label="$kill_cmd" icon.color="$GREEN"
	fi
	sketchybar --set aerospace_hang popup.drawing=off
	;;
open_log)
	if [[ -d "$WATCHDOG_LOG_DIR" ]]; then
		/usr/bin/open "$WATCHDOG_LOG_DIR" 2>/dev/null || true
	else
		/usr/bin/open "$HANGDIAG_LOG_DIR" 2>/dev/null || true
	fi
	sketchybar --set aerospace_hang popup.drawing=off
	;;
mouse.exited.global)
	sketchybar --set aerospace_hang popup.drawing=off
	;;
esac
