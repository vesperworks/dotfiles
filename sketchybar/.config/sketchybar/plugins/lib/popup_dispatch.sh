#!/bin/bash
# Shared SENDER dispatch for plugins with a click-to-toggle popup.
#
# Caller contract: define `update_bar` and `update_popup` before sourcing.
#   update_bar    — paints the bar item (timer / forced update path)
#   update_popup  — paints the popup subitems (runs only on click)
#
# The popup toggle itself is handled here so plugins don't rewrite it.

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
