#!/bin/bash

# WiFi Plugin for SketchyBar
# Displays current WiFi network name and signal strength
# Compatible with macOS Sequoia (airport deprecated)

source "$CONFIG_DIR/colors.sh"

# Icon settings (Nerd Font)
ICON_WIFI_OFF="󰤭"
ICON_WIFI_CONNECTED="󰤨"

# Check WiFi interface status
INTERFACE="en0"
WIFI_STATUS=$(/sbin/ifconfig "$INTERFACE" 2>/dev/null | awk '/status:/ {print $2}')

if [ "$WIFI_STATUS" = "active" ]; then
  # WiFi is connected - get SSID from system_profiler (cached approach)
  # Use a cache file to avoid slow system_profiler calls
  CACHE_FILE="/tmp/sketchybar_wifi_ssid"
  CACHE_AGE=60  # seconds

  # Check if cache exists and is fresh
  if [ -f "$CACHE_FILE" ]; then
    CACHE_MTIME=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE=$((NOW - CACHE_MTIME))
  else
    AGE=$((CACHE_AGE + 1))  # Force refresh
  fi

  if [ "$AGE" -gt "$CACHE_AGE" ]; then
    # Refresh cache - extract SSID from system_profiler
    SSID=$(/usr/sbin/system_profiler SPAirPortDataType 2>/dev/null | \
           awk '/Current Network Information:/{found=1; next} found && /^ +[^ ]/{gsub(/:$/, ""); print $1; exit}')
    if [ -n "$SSID" ]; then
      echo "$SSID" > "$CACHE_FILE"
    fi
  else
    SSID=$(cat "$CACHE_FILE" 2>/dev/null)
  fi

  # Fallback if SSID is empty
  if [ -z "$SSID" ]; then
    SSID="Connected"
  fi

  ICON="$ICON_WIFI_CONNECTED"
  LABEL="$SSID"
  ICON_CLR="$GREEN"
else
  ICON="$ICON_WIFI_OFF"
  LABEL="Disconnected"
  ICON_CLR="$RED"
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$ICON_CLR" label="$LABEL"
