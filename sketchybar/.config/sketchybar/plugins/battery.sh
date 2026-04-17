#!/bin/bash

# Battery Plugin for SketchyBar
# Bar: SF Symbols frame-style gauge / Popup: %, time remaining, power source.

source "$CONFIG_DIR/colors.sh"

# Returns "<pct>|<charging>|<charged>|<time>" from a single pmset call so
# callers don't race the hardware state across multiple reads. Empty string
# for any field that can't be extracted.
parse_batt() {
  local info pct charging charged time_remaining
  info=$(pmset -g batt)
  pct=$(echo "$info" | grep -Eo '[0-9]+%' | cut -d% -f1)
  echo "$info" | grep -q 'AC Power' && charging=1
  echo "$info" | grep -q 'charged' && charged=1
  time_remaining=$(echo "$info" |
    awk -F';' '/InternalBattery/{gsub(/^[ \t]+/, "", $3); print $3}' |
    awk '{print $1}')
  printf '%s|%s|%s|%s\n' "$pct" "${charging:-}" "${charged:-}" "$time_remaining"
}

update_bar() {
  local pct charging _charged _time icon color
  IFS='|' read -r pct charging _charged _time <<<"$(parse_batt)"
  [ -z "$pct" ] && exit 0

  if [ -n "$charging" ]; then
    icon="􀢋"
    color="$GREEN"
  else
    case "$pct" in
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
  local pct charging charged time source status_label time_label
  IFS='|' read -r pct charging charged time <<<"$(parse_batt)"

  if [ -n "$charged" ]; then
    source="AC Power"
    status_label="Charged"
    time_label="Full"
  else
    # pmset renders "(no estimate)" during initial sampling; collapse that
    # and any empty value into "calculating" so the popup never shows "(no".
    time_label="${time:-calculating}"
    [ "$time_label" = "(no" ] && time_label="calculating"
    if [ -n "$charging" ]; then
      source="AC Power"
      status_label="Charging"
    else
      source="Battery"
      status_label="Discharging"
    fi
  fi

  sketchybar --set battery.1 icon="󱐋" label="Level: ${pct}%" drawing=on \
    --set battery.2 icon="󰔛" label="Time: $time_label" drawing=on \
    --set battery.3 icon="󰚥" label="$source ($status_label)" drawing=on
}

source "$CONFIG_DIR/plugins/lib/popup_dispatch.sh"
