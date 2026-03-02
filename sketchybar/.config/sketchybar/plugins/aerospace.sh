#!/bin/bash

# AeroSpace workspace change handler for SketchyBar
# Triggered by: aerospace_workspace_change event
# Animation inspired by FelixKratz/dotfiles

CONFIG_DIR="$HOME/.config/sketchybar"
PLUGIN_DIR="$CONFIG_DIR/plugins"

# Load colors
source "$CONFIG_DIR/colors.sh"

# Workspace color map
declare -A WS_COLORS=(
  [1]=$WS_COLOR_1
  [2]=$WS_COLOR_2
  [3]=$WS_COLOR_3
  [4]=$WS_COLOR_4
  [5]=$WS_COLOR_5
  [Q]=$WS_COLOR_Q
  [W]=$WS_COLOR_W
  [E]=$WS_COLOR_E
  [R]=$WS_COLOR_R
  [T]=$WS_COLOR_T
)

# Get app icons for a workspace
get_app_icons() {
    local workspace="$1"
    local icons=""

    # Get app names in this workspace
    while IFS= read -r app; do
        [ -z "$app" ] && continue
        icon=$("$PLUGIN_DIR/icon_map.sh" "$app")
        icons+="$icon "
    done < <(aerospace list-windows --workspace "$workspace" --format '%{app-name}' 2>/dev/null)

    echo "$icons"
}

if [ "$SENDER" = "aerospace_workspace_change" ] || [ "$SENDER" = "forced" ]; then
    # Get focused workspace
    FOCUSED=$(aerospace list-workspaces --focused)
    # Get all visible workspaces (one per monitor)
    VISIBLE=$(aerospace list-workspaces --monitor all --visible)

    # Update each workspace item
    for workspace in 1 2 3 4 5 Q W E R T; do
        # Get app icons for this workspace
        APP_ICONS=$(get_app_icons "$workspace")

        # Check if workspace has windows
        WINDOWS=$(aerospace list-windows --workspace "$workspace" 2>/dev/null | wc -l | tr -d ' ')

        # Determine label width (dynamic or 0)
        if [ "$workspace" = "$FOCUSED" ] || [ "$WINDOWS" -gt 0 ]; then
            WIDTH="dynamic"
        else
            WIDTH="0"
        fi

        # Get workspace color and create alpha version for background
        WS_COLOR=${WS_COLORS[$workspace]}
        # Use full color for active workspace (no alpha)
        WS_BG_COLOR=$WS_COLOR

        # Check if workspace is visible on any monitor
        IS_VISIBLE=$(echo "$VISIBLE" | grep -x "$workspace")

        if [ -n "$IS_VISIBLE" ]; then
            # Visible workspace (on any monitor): colored background with alpha, dark icon
            sketchybar --animate tanh 20 --set "space.$workspace" \
                background.drawing=on \
                background.border_width=0 \
                background.color=$WS_BG_COLOR \
                icon.color=$BLACK \
                icon.highlight=off \
                label="" \
                label.width=0 \
                label.color=$BLACK \
                drawing=on
            # Hide bracket for visible workspace
            sketchybar --set "space_bracket.$workspace" background.drawing=off
        elif [ "$WINDOWS" -gt 0 ]; then
            # Has windows but not focused: alpha background, no border
            sketchybar --animate tanh 20 --set "space.$workspace" \
                background.drawing=on \
                background.color=0x25363a4f \
                background.border_width=0 \
                icon.background.drawing=on \
                icon.background.color=0x60363a4f \
                icon.background.corner_radius=5 \
                icon.background.height=26 \
                icon.color=$WHITE \
                icon.highlight=off \
                label="$APP_ICONS" \
                label.width=$WIDTH \
                label.color=$WHITE \
                drawing=on
            # Hide bracket
            sketchybar --set "space_bracket.$workspace" background.drawing=off
        else
            # Empty workspace - hide
            sketchybar --animate tanh 20 --set "space.$workspace" \
                background.drawing=off \
                background.border_width=0 \
                icon.color=$EMPTY_COLOR \
                icon.highlight=off \
                label="" \
                label.width=0 \
                label.color=$EMPTY_COLOR \
                drawing=off
            # Hide bracket
            sketchybar --set "space_bracket.$workspace" background.drawing=off
        fi
    done
fi
