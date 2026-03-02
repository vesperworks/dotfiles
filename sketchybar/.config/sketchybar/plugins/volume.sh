#!/bin/bash

# Simple volume plugin for SketchyBar

source "$CONFIG_DIR/colors.sh"

# Volume icons
VOLUME_100=󰕾
VOLUME_66=󰖀
VOLUME_33=󰕿
VOLUME_0=󰖁

# Get current volume
get_volume() {
  osascript -e 'output volume of (get volume settings)'
}

# Get volume icon based on level
get_icon() {
  local vol=$1
  if [[ "$vol" -eq 0 ]]; then
    echo $VOLUME_0
  elif [[ "$vol" -lt 33 ]]; then
    echo $VOLUME_33
  elif [[ "$vol" -lt 66 ]]; then
    echo $VOLUME_66
  else
    echo $VOLUME_100
  fi
}

# Update volume display
update_volume() {
  local vol
  vol=$(get_volume)
  local icon
  icon=$(get_icon "$vol")

  sketchybar --set "$NAME" icon="$icon" label="${vol}%"
}

case "$SENDER" in
  "volume_change" | "forced")
    update_volume
    ;;
esac
