#!/bin/bash

# Volume Plugin for SketchyBar
# Bar: icon only / Popup: volume % / output device on click.

source "$CONFIG_DIR/colors.sh"

ICON_VOL_100="󰕾"
ICON_VOL_66="󰖀"
ICON_VOL_33="󰕿"
ICON_VOL_0="󰖁"

get_volume() { osascript -e 'output volume of (get volume settings)'; }
get_muted() { osascript -e 'output muted of (get volume settings)'; }

# Default output device. system_profiler places 'Default Output Device: Yes'
# *inside* the chosen device block, so we remember the most recent device
# header (indent 8, trailing ':') and print it when the flag appears.
get_output_device() {
  /usr/sbin/system_profiler SPAudioDataType 2>/dev/null |
    awk '/:$/ && /^        / {candidate=$0; gsub(/:$/,"",candidate); gsub(/^ +/,"",candidate)}
         /Default Output Device: Yes/ {print candidate; exit}'
}

get_icon() {
  local vol="$1" muted="$2"
  if [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then
    printf '%s' "$ICON_VOL_0"
  elif [ "$vol" -lt 33 ]; then
    printf '%s' "$ICON_VOL_33"
  elif [ "$vol" -lt 66 ]; then
    printf '%s' "$ICON_VOL_66"
  else
    printf '%s' "$ICON_VOL_100"
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

source "$CONFIG_DIR/plugins/lib/popup_dispatch.sh"
