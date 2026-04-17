#!/bin/bash

# WiFi Plugin for SketchyBar
# Bar: icon only / Popup: SSID / IP / RSSI on click
# Compatible with macOS Sequoia (airport deprecated)

source "$CONFIG_DIR/colors.sh"

ICON_WIFI_OFF="󰤭"
ICON_WIFI_CONNECTED="󰤨"
INTERFACE="en0"

get_ssid() {
	local cache_file="/tmp/sketchybar_wifi_ssid"
	local cache_age=60
	local age

	if [ -f "$cache_file" ]; then
		local mtime
		mtime=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
		age=$(($(date +%s) - mtime))
	else
		age=$((cache_age + 1))
	fi

	if [ "$age" -gt "$cache_age" ]; then
		local ssid
		ssid=$(/usr/sbin/system_profiler SPAirPortDataType 2>/dev/null |
			awk '/Current Network Information:/{found=1; next} found && /^ +[^ ]/{gsub(/:$/, ""); print $1; exit}')
		if [ -n "$ssid" ]; then
			echo "$ssid" >"$cache_file"
			echo "$ssid"
			return
		fi
	fi
	cat "$cache_file" 2>/dev/null
}

get_rssi() {
	/usr/sbin/system_profiler SPAirPortDataType 2>/dev/null |
		awk '/Signal \/ Noise:/ {print $4, $5, $6, $7; exit}'
}

update_bar() {
	local status
	status=$(/sbin/ifconfig "$INTERFACE" 2>/dev/null | awk '/status:/ {print $2}')

	if [ "$status" = "active" ]; then
		sketchybar --set "$NAME" icon="$ICON_WIFI_CONNECTED" icon.color="$GREEN"
	else
		sketchybar --set "$NAME" icon="$ICON_WIFI_OFF" icon.color="$RED"
	fi
}

update_popup() {
	local status ssid ip rssi
	status=$(/sbin/ifconfig "$INTERFACE" 2>/dev/null | awk '/status:/ {print $2}')

	if [ "$status" = "active" ]; then
		ssid=$(get_ssid)
		[ -z "$ssid" ] && ssid="Connected"
		ip=$(/sbin/ifconfig "$INTERFACE" 2>/dev/null | awk '/inet /{print $2; exit}')
		[ -z "$ip" ] && ip="-"
		rssi=$(get_rssi)
		[ -z "$rssi" ] && rssi="-"
	else
		ssid="Disconnected"
		ip="-"
		rssi="-"
	fi

	sketchybar --set wifi.1 icon="󰖩" label="SSID: $ssid" drawing=on \
		--set wifi.2 icon="󰩟" label="IP: $ip" drawing=on \
		--set wifi.3 icon="󰠁" label="RSSI: $rssi" drawing=on
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
