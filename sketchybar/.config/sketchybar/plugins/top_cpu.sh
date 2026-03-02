#!/bin/bash

# Top CPU process plugin for SketchyBar
# Bar: top 1 process / Popup: top 5 processes on click

source "$CONFIG_DIR/colors.sh"

# Nerd Font: nf-oct-cpu (U+F4BC)
ICON=$(printf '\xef\x92\xbc')

get_color() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then
    echo "$RED"
  elif [ "$pct" -ge 50 ]; then
    echo "$ORANGE"
  elif [ "$pct" -ge 25 ]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

update_bar() {
  read -r CPU_PCT PROC_NAME <<< "$(ps -eo pcpu=,comm= -r \
    | grep -v -E 'kernel_task|WindowServer|_hidd' \
    | head -1 \
    | awk '{pct=$1; cmd=$2; sub(/.*\//, "", cmd); printf "%.0f %s", pct, cmd}')"

  if [ -z "$CPU_PCT" ]; then
    exit 0
  fi

  PROC_NAME="${PROC_NAME:0:12}"
  COLOR=$(get_color "$CPU_PCT")

  if [ "$CPU_PCT" -ge 50 ]; then
    LABEL="${CPU_PCT}% ${PROC_NAME}"
  else
    LABEL="${CPU_PCT}%"
  fi

  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
}

update_popup() {
  local i=1
  local args=()

  while IFS= read -r line; do
    read -r pct cmd <<< "$line"
    local pct_int
    pct_int=$(printf '%.0f' "$pct")
    cmd="${cmd##*/}"
    cmd="${cmd:0:16}"
    local color
    color=$(get_color "$pct_int")

    args+=(--set "top_cpu.$i" icon="${pct_int}%" icon.color="$color" label="$cmd")
    i=$((i + 1))
  done <<< "$(ps -eo pcpu=,comm= -r \
    | grep -v -E 'kernel_task|WindowServer|_hidd' \
    | head -5)"

  sketchybar "${args[@]}"
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
