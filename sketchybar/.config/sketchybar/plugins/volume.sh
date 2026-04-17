#!/bin/bash

# Volume Plugin for SketchyBar
# Bar: icon only / Popup: volume % / output device on click

source "$CONFIG_DIR/colors.sh"

VOLUME_100=󰕾
VOLUME_66=󰖀
VOLUME_33=󰕿
VOLUME_0=󰖁

get_volume() {
	osascript -e 'output volume of (get volume settings)'
}

get_muted() {
	osascript -e 'output muted of (get volume settings)'
}

get_output_device() {
	/usr/sbin/system_profiler SPAudioDataType 2>/dev/null |
		awk '/:$/ && /^        / {candidate=$0; gsub(/:$/,"",candidate); gsub(/^ +/,"",candidate)}
		     /Default Output Device: Yes/ {print candidate; exit}'
}

get_icon() {
	local vol=$1
	local muted=$2
	if [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then
		echo $VOLUME_0
	elif [ "$vol" -lt 33 ]; then
		echo $VOLUME_33
	elif [ "$vol" -lt 66 ]; then
		echo $VOLUME_66
	else
		echo $VOLUME_100
	fi
}

update_bar() {
	local vol muted icon color
	vol=$(get_volume)
	muted=$(get_muted)
	icon=$(get_icon "$vol" "$muted")
	if [ "$muted" = "true" ]; then
		color="$RED"
	else
		color="$GREEN"
	fi
	sketchybar --set "$NAME" icon="$icon" icon.color="$color"
}

update_popup() {
	local vol muted device status
	vol=$(get_volume)
	muted=$(get_muted)
	device=$(get_output_device)
	[ -z "$device" ] && device="-"

	if [ "$muted" = "true" ]; then
		status="${vol}% (muted)"
	else
		status="${vol}%"
	fi

	sketchybar --set volume.1 icon="󰕾" label="Volume: $status" drawing=on \
		--set volume.2 icon="󰓃" label="Device: $device" drawing=on
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
