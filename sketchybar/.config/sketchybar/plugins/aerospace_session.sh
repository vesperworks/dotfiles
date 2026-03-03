#!/bin/bash

# AeroSpace Session Widget for SketchyBar
# Shows relative time since last layout save, click to show snapshot menu

source "$CONFIG_DIR/colors.sh"

LAYOUTS_FILE="$HOME/.config/aerospace/layouts.json"
RESTORE_CMD="$HOME/.local/bin/aerospace-restore-layout"
MAX_POPUP_ROWS=12
MAX_SNAPSHOTS=10

# Calculate relative time from a file's modification time
get_file_relative_time() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "--"
    return
  fi

  local mod_time now elapsed
  mod_time=$(stat -f %m "$file" 2>/dev/null) || { echo "--"; return; }
  now=$(date +%s)
  elapsed=$((now - mod_time))

  if [[ $elapsed -lt 60 ]]; then
    echo "${elapsed}s"
  elif [[ $elapsed -lt 3600 ]]; then
    echo "$((elapsed / 60))m"
  elif [[ $elapsed -lt 86400 ]]; then
    echo "$((elapsed / 3600))h"
  else
    echo "$((elapsed / 86400))d"
  fi
}

# Wrapper for default layouts file (backward compat)
get_relative_time() {
  get_file_relative_time "$LAYOUTS_FILE"
}

# Get snapshot file path by index (0=latest, 1=1gen ago, 2=2gen ago)
get_snapshot_file() {
  local index="$1"
  if [[ "$index" -eq 0 ]]; then
    echo "$LAYOUTS_FILE"
  else
    echo "${LAYOUTS_FILE%.json}.${index}.json"
  fi
}

# Reset all popup rows to hidden
reset_popup() {
  local args=()
  for i in $(seq 1 "$MAX_POPUP_ROWS"); do
    args+=(--set "aerospace_session.$i" drawing=off label="" icon="" click_script="")
  done
  sketchybar "${args[@]}"
}

# Set a popup row content
set_popup_row() {
  local row="$1" icon="$2" icon_color="$3" label="$4"
  sketchybar --set "aerospace_session.$row" \
    drawing=on \
    icon="$icon" \
    icon.color="$icon_color" \
    label="$label"
}

# Extract app name from bundleId (e.g. com.apple.Safari → Safari)
extract_app_name() {
  local bid="$1"
  echo "$bid" | awk -F. '{print $NF}'
}

# Show snapshot selection menu
show_snapshot_menu() {
  reset_popup
  sketchybar --set "$NAME" popup.drawing=on

  # Title row
  set_popup_row 1 "󰑓" "$YELLOW" "Select snapshot"

  local row=2
  for i in $(seq 0 $((MAX_SNAPSHOTS - 1))); do
    local file
    file=$(get_snapshot_file "$i")
    [[ ! -f "$file" ]] && continue
    [[ $row -gt $MAX_POPUP_ROWS ]] && break

    local rel_time
    rel_time=$(get_file_relative_time "$file")

    local icon icon_color label
    if [[ "$i" -eq 0 ]]; then
      icon="●"
      icon_color="$YELLOW"
      label="${rel_time} ago (latest)"
    else
      icon="○"
      icon_color="$GREY"
      label="${rel_time} ago"
    fi

    sketchybar --set "aerospace_session.$row" \
      drawing=on \
      icon="$icon" \
      icon.color="$icon_color" \
      label="$label" \
      click_script="SENDER=restore_snapshot NAME=aerospace_session SNAPSHOT_INDEX=$i $CONFIG_DIR/plugins/aerospace_session.sh"

    row=$((row + 1))
  done

  # No snapshots found
  if [[ $row -eq 2 ]]; then
    set_popup_row 2 "✗" "$RED" "No snapshots"
  fi
}

# Restore layout and show progress in popup
restore_layout() {
  local input_file="${1:-$LAYOUTS_FILE}"

  # Open popup and reset rows
  reset_popup
  sketchybar --set "$NAME" popup.drawing=on icon.color="$MAGENTA"
  set_popup_row 1 "󰑓" "$YELLOW" "Restoring..."

  # Check command exists
  if [[ ! -x "$RESTORE_CMD" ]]; then
    set_popup_row 1 "✗" "$RED" "Command not found"
    sketchybar --set "$NAME" icon.color="$RED"
    sleep 3
    sketchybar --set "$NAME" icon.color="$YELLOW" popup.drawing=off
    return
  fi

  # Check layouts file
  if [[ ! -f "$input_file" ]]; then
    set_popup_row 1 "✗" "$RED" "Snapshot not found"
    sketchybar --set "$NAME" icon.color="$RED"
    sleep 3
    sketchybar --set "$NAME" icon.color="$YELLOW" popup.drawing=off
    return
  fi

  # Dry-run to get move plan
  local dry_output
  dry_output=$("$RESTORE_CMD" --input "$input_file" --dry-run 2>&1) || true

  local row=2
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" != *"Would move window"* ]] && continue
    [[ $row -gt $MAX_POPUP_ROWS ]] && break

    # Parse: [dry-run] Would move window ID (bundleId: title) from WS1 to WS2
    local bid title from_ws to_ws
    bid=$(echo "$line" | sed -E 's/.*\(([^:]+):.*/\1/')
    title=$(echo "$line" | sed -E 's/.*\([^:]+: ([^)]*)\).*/\1/')
    from_ws=$(echo "$line" | sed -E 's/.*from ([^ ]+) to.*/\1/')
    to_ws=$(echo "$line" | sed -E 's/.*to ([^ ]+)$/\1/')

    local app_name
    app_name=$(extract_app_name "$bid")
    # Truncate title
    [[ ${#title} -gt 20 ]] && title="${title:0:19}…"

    set_popup_row "$row" "→" "$BLUE" "$app_name  $from_ws→$to_ws"
    row=$((row + 1))
  done <<< "$dry_output"

  # No windows to move
  if [[ $row -eq 2 ]]; then
    set_popup_row 1 "✓" "$GREEN" "No windows to move"
    sketchybar --set "$NAME" icon.color="$GREEN"
    sleep 3
    sketchybar --set "$NAME" icon.color="$YELLOW" popup.drawing=off
    return
  fi

  # Execute restore
  local result exit_code
  result=$("$RESTORE_CMD" --input "$input_file" 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    local moved_count
    moved_count=$(echo "$result" | grep -oE '[0-9]+' | head -1)
    set_popup_row 1 "✓" "$GREEN" "Done: ${moved_count:-0} window(s) moved"
    sketchybar --set "$NAME" icon.color="$GREEN"
  else
    set_popup_row 1 "✗" "$RED" "${result:0:40}"
    sketchybar --set "$NAME" icon.color="$RED"
  fi

  # Revert icon color after delay (popup stays until mouse exits)
  sleep 3
  sketchybar --set "$NAME" icon.color="$YELLOW"
}

case "$SENDER" in
  "mouse.clicked")
    show_snapshot_menu
    ;;
  "restore_snapshot")
    snapshot_file=$(get_snapshot_file "${SNAPSHOT_INDEX:-0}")
    restore_layout "$snapshot_file" &
    ;;
  "mouse.exited.global")
    sketchybar --set "$NAME" popup.drawing=off
    ;;
  *)
    LABEL=$(get_relative_time)
    sketchybar --set "$NAME" label="$LABEL"
    ;;
esac
