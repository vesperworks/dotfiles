#!/bin/bash

# Battery plugin using SF Symbols (frame-style gauge icons)

source "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

# SF Symbols battery icons (frame-style with gauge)
# 􀛨 battery.100  􀺸 battery.75  􀺶 battery.50  􀛩 battery.25  􀛪 battery.0
# 􀢋 battery.100.bolt (charging)

if [[ "$CHARGING" != "" ]]; then
  ICON="􀢋"
  COLOR="$GREEN"
else
  case "${PERCENTAGE}" in
    9[0-9]|100) ICON="􀛨"; COLOR="$GREEN" ;;
    [7-8][0-9]) ICON="􀺸"; COLOR="$GREEN" ;;
    [4-6][0-9]) ICON="􀺶"; COLOR="$YELLOW" ;;
    [2-3][0-9]) ICON="􀛩"; COLOR="$ORANGE" ;;
    *)          ICON="􀛪"; COLOR="$RED" ;;
  esac
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR"
