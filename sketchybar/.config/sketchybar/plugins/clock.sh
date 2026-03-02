#!/bin/sh

# The $NAME variable is passed from sketchybar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

# Format: 1.13.TUE 02:06
DATE=$(date '+%-m.%-d.')
DAY=$(LC_TIME=C date '+%a' | tr '[:lower:]' '[:upper:]')
TIME=$(date '+%H:%M')

sketchybar --set "$NAME" label="${DATE}${DAY} ${TIME}"

