#!/bin/bash

# Battery Plugin for SketchyBar
# Bar: SF Symbols frame-style gauge / Popup: %, time remaining, power source on click

source "$CONFIG_DIR/colors.sh"

get_batt() {
	pmset -g batt
}

update_bar() {
	local info percentage charging icon color
	info=$(get_batt)
	percentage=$(echo "$info" | grep -Eo "\d+%" | cut -d% -f1)
	charging=$(echo "$info" | grep 'AC Power')

	[ -z "$percentage" ] && exit 0

	if [ -n "$charging" ]; then
		icon="􀢋"
		color="$GREEN"
	else
		case "${percentage}" in
		9[0-9] | 100)
			icon="􀛨"
			color="$GREEN"
			;;
		[7-8][0-9])
			icon="􀺸"
			color="$GREEN"
			;;
		[4-6][0-9])
			icon="􀺶"
			color="$YELLOW"
			;;
		[2-3][0-9])
			icon="􀛩"
			color="$ORANGE"
			;;
		*)
			icon="􀛪"
			color="$RED"
			;;
		esac
	fi

	sketchybar --set "$NAME" icon="$icon" icon.color="$color"
}

update_popup() {
	local info percentage charging source time_remaining status_label
	info=$(get_batt)
	percentage=$(echo "$info" | grep -Eo "\d+%" | cut -d% -f1)
	charging=$(echo "$info" | grep 'AC Power')
	charged=$(echo "$info" | grep 'charged')
	time_remaining=$(echo "$info" | awk -F';' '/InternalBattery/{gsub(/^[ \t]+/, "", $3); print $3}' | awk '{print $1}')

	if [ -n "$charged" ]; then
		source="AC Power"
		status_label="Charged"
		time_remaining="Full"
	elif [ -n "$charging" ]; then
		source="AC Power"
		status_label="Charging"
		[ -z "$time_remaining" ] || [ "$time_remaining" = "(no" ] && time_remaining="calculating"
	else
		source="Battery"
		status_label="Discharging"
		[ -z "$time_remaining" ] || [ "$time_remaining" = "(no" ] && time_remaining="calculating"
	fi

	sketchybar --set battery.1 icon="󱐋" label="Level: ${percentage}%" drawing=on \
		--set battery.2 icon="󰔛" label="Time: $time_remaining" drawing=on \
		--set battery.3 icon="󰚥" label="$source ($status_label)" drawing=on
}

case "$SENDER" in
"mouse.clicked")
	update_popup
	sketchybar --set "$NAME" popup.drawing=toggle
	;;
"mouse.exited.global")
	sketchybar --set "$NAME" popup.drawing=off
	;;
*)
	update_bar
	;;
esac
