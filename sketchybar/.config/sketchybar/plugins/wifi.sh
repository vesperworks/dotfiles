#!/bin/bash

# WiFi Plugin for SketchyBar
# Bar: icon only / Popup: SSID / IP / RSSI on click
# Compatible with macOS Sequoia (airport deprecated).

source "$CONFIG_DIR/colors.sh"

ICON_WIFI_OFF="󰤭"
ICON_WIFI_CONNECTED="󰤨"
INTERFACE="en0"
SSID_CACHE="${TMPDIR:-/tmp}/sketchybar_wifi_ssid"
SSID_CACHE_AGE=60

# system_profiler SPAirPortDataType is slow (~1s). Cache the SSID between
# calls so the 30s-tick bar update stays cheap. The cache is only consulted
# while the interface is active — callers are responsible for checking the
# connection state first, so we never print a stale SSID after disconnect.
get_ssid() {
	local age=$((SSID_CACHE_AGE + 1)) mtime ssid
	if [ -s "$SSID_CACHE" ]; then
		mtime=$(stat -f %m "$SSID_CACHE" 2>/dev/null || echo 0)
		age=$(($(date +%s) - mtime))
	fi

	if [ "$age" -le "$SSID_CACHE_AGE" ]; then
		cat "$SSID_CACHE"
		return
	fi

	# Cache expired: re-scan. Only touch the cache when we get a real SSID so
	# transient system_profiler failures don't reset the TTL.
	ssid=$(/usr/sbin/system_profiler SPAirPortDataType 2>/dev/null |
		awk '/Current Network Information:/{found=1; next} found && /^ +[^ ]/{gsub(/:$/, ""); print $1; exit}')
	if [ -n "$ssid" ]; then
		printf '%s' "$ssid" >"$SSID_CACHE"
		printf '%s' "$ssid"
	elif [ -s "$SSID_CACHE" ]; then
		cat "$SSID_CACHE"
	fi
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

source "$CONFIG_DIR/plugins/lib/popup_dispatch.sh"
