#!/bin/bash

# Volume slider plugin for SketchyBar
# Inspired by FelixKratz/dotfiles
# Features: Click to expand slider, auto-collapse after 2s

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"

# Volume icons
VOLUME_100=󰕾
VOLUME_66=󰖀
VOLUME_33=󰕿
VOLUME_10=󰕿
VOLUME_0=󰖁

# Get current volume
get_volume() {
    osascript -e 'output volume of (get volume settings)'
}

# Get volume icon based on level
get_icon() {
    local vol=$1
    if [ "$vol" -eq 0 ]; then
        echo $VOLUME_0
    elif [ "$vol" -lt 10 ]; then
        echo $VOLUME_10
    elif [ "$vol" -lt 33 ]; then
        echo $VOLUME_33
    elif [ "$vol" -lt 66 ]; then
        echo $VOLUME_66
    else
        echo $VOLUME_100
    fi
}

# Update volume display
update_volume() {
    local vol=$(get_volume)
    local icon=$(get_icon $vol)

    sketchybar --set $NAME icon="$icon" label="${vol}%"
}

# Handle slider interaction
slider_change() {
    # Get the percentage from slider
    PERCENTAGE=$(sketchybar --query $NAME | jq -r ".slider.percentage")

    # Set system volume
    osascript -e "set volume output volume $PERCENTAGE"

    # Update icon
    local icon=$(get_icon $PERCENTAGE)
    sketchybar --set $NAME icon="$icon" label="${PERCENTAGE}%"
}

# Expand slider with animation
expand_slider() {
    sketchybar --animate tanh 30 --set $NAME slider.width=100

    # Auto-collapse after 2 seconds
    sleep 2

    # Check if mouse is still over (don't collapse if hovering)
    CURRENT_WIDTH=$(sketchybar --query $NAME | jq -r ".slider.width")
    if [ "$CURRENT_WIDTH" = "100" ]; then
        sketchybar --animate tanh 30 --set $NAME slider.width=0
    fi
}

# Handle mouse events
mouse_entered() {
    sketchybar --set $NAME slider.knob.drawing=on
}

mouse_exited() {
    sketchybar --set $NAME slider.knob.drawing=off
}

mouse_clicked() {
    expand_slider &
}

# Main event handler
case "$SENDER" in
    "volume_change")
        update_volume
        ;;
    "slider_change")
        slider_change
        ;;
    "mouse.entered")
        mouse_entered
        ;;
    "mouse.exited")
        mouse_exited
        ;;
    "mouse.clicked")
        mouse_clicked
        ;;
    "forced")
        update_volume
        sketchybar --set $NAME slider.width=0
        ;;
esac
