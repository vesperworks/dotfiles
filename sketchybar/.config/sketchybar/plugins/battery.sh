#!/bin/bash

# Battery Plugin for SketchyBar
# Bar: SF Symbols frame-style gauge / Popup: %, time remaining, power source.

source "$CONFIG_DIR/colors.sh"

get_batt() { pmset -g batt; }

# Reads percentage, charging/charged state, and pmset's time-remaining field
# from a single `pmset -g batt` call to avoid racing the hardware state.
parse_batt() {
  local info
  info=$(get_batt)
  PCT=$(echo "$info" | grep -Eo '[0-9]+%' | cut -d% -f1)
  CHARGING=$(echo "$info" | grep 'AC Power')
  CHARGED=$(echo "$info" | grep 'charged')
  TIME_REMAINING=$(echo "$info" | awk -F';' '/InternalBattery/{gsub(/^[ \t]+/, "", $3); print $3}' | awk '{print $1}')
}

update_bar() {
  local PCT CHARGING CHARGED TIME_REMAINING icon color
  parse_batt
  [ -z "$PCT" ] && exit 0

  if [ -n "$CHARGING" ]; then
    icon="􀢋"
    color="$GREEN"
  else
    case "${PCT}" in
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
  local PCT CHARGING CHARGED TIME_REMAINING source status_label time_label
  parse_batt

  if [ -n "$CHARGED" ]; then
    source="AC Power"
    status_label="Charged"
    time_label="Full"
  elif [ -n "$CHARGING" ]; then
    source="AC Power"
    status_label="Charging"
    time_label="${TIME_REMAINING:-calculating}"
    [ "$time_label" = "(no" ] && time_label="calculating"
  else
    source="Battery"
    status_label="Discharging"
    time_label="${TIME_REMAINING:-calculating}"
    [ "$time_label" = "(no" ] && time_label="calculating"
  fi

  sketchybar --set battery.1 icon="󱐋" label="Level: ${PCT}%" drawing=on \
    --set battery.2 icon="󰔛" label="Time: $time_label" drawing=on \
    --set battery.3 icon="󰚥" label="$source ($status_label)" drawing=on
}

source "$CONFIG_DIR/plugins/lib/popup_dispatch.sh"
