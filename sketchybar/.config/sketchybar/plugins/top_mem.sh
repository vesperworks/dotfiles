#!/bin/bash

# Top memory process plugin for SketchyBar
# Bar: top 1 process / Popup: top 5 processes on click

source "$CONFIG_DIR/colors.sh"

# Nerd Font: nf-md-memory (U+F035B)
ICON=$(printf '\xf3\xb0\x8d\x9b')

get_color() {
  local pct=$1
  if [ "$pct" -ge 30 ]; then
    echo "$RED"
  elif [ "$pct" -ge 15 ]; then
    echo "$ORANGE"
  elif [ "$pct" -ge 8 ]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

format_rss() {
  local kb=$1
  if [ "$kb" -ge 1048576 ]; then
    awk "BEGIN {printf \"%.1fG\", $kb/1048576}"
  elif [ "$kb" -ge 1024 ]; then
    awk "BEGIN {printf \"%.0fM\", $kb/1024}"
  else
    echo "${kb}K"
  fi
}

update_bar() {
  read -r MEM_PCT RSS_KB PROC_NAME <<< "$(ps -eo pmem=,rss=,comm= -m \
    | grep -v 'kernel_task' \
    | head -1 \
    | awk '{pct=$1; rss=$2; cmd=$3; sub(/.*\//, "", cmd); printf "%.0f %s %s", pct, rss, cmd}')"

  if [ -z "$MEM_PCT" ]; then
    exit 0
  fi

  PROC_NAME="${PROC_NAME:0:12}"
  RSS_DISPLAY=$(format_rss "${RSS_KB%%.*}")
  COLOR=$(get_color "$MEM_PCT")

  if [ "$MEM_PCT" -ge 15 ]; then
    LABEL="${RSS_DISPLAY} ${PROC_NAME}"
  else
    LABEL="${RSS_DISPLAY}"
  fi

  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$LABEL"
}

update_popup() {
  local i=1
  local args=()

  while IFS= read -r line; do
    read -r pct rss cmd <<< "$line"
    local pct_int
    pct_int=$(printf '%.0f' "$pct")
    cmd="${cmd##*/}"
    cmd="${cmd:0:16}"
    local rss_display
    rss_display=$(format_rss "$rss")
    local color
    color=$(get_color "$pct_int")

    args+=(--set "top_mem.$i" icon="$rss_display" icon.color="$color" label="$cmd")
    i=$((i + 1))
  done <<< "$(ps -eo pmem=,rss=,comm= -m \
    | grep -v 'kernel_task' \
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
