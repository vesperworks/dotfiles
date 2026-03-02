#!/bin/bash

# Pomodoro Timer Plugin for SketchyBar
# Reads nvim task timer and displays as pomodoro countdown

source "$CONFIG_DIR/colors.sh"

TIMER_FILE="$HOME/.local/share/nvim/task_timers.json"
PAUSE_STATE_FILE="/tmp/sketchybar_pomodoro_paused"
MAX_TASK_CHARS=20

WORK_DURATION=1500   # 25 minutes in seconds
BREAK_DURATION=300   # 5 minutes in seconds
CYCLE_DURATION=1800  # 30 minutes total

# Toggle pause state (called on click)
toggle_pause() {
  if [[ -f "$PAUSE_STATE_FILE" ]]; then
    rm -f "$PAUSE_STATE_FILE"
  else
    echo "1" > "$PAUSE_STATE_FILE"
  fi
}

# Check if paused
is_paused() {
  [[ -f "$PAUSE_STATE_FILE" ]]
}

# Get the most recently started timer
get_latest_timer() {
  if [[ ! -f "$TIMER_FILE" ]]; then
    return 1
  fi

  # Find timer with the largest (most recent) start_time
  jq -r '
    to_entries
    | map(select(.value.start_time != null))
    | sort_by(.value.start_time)
    | last
    | if . then
        "\(.value.start_time)|\(.value.task_content)"
      else
        empty
      end
  ' "$TIMER_FILE" 2>/dev/null
}

# Extract task name from task content (remove checkbox markup and tags)
extract_task_name() {
  local content="$1"
  # Remove leading/trailing whitespace, "- [>] " or "- [/] " prefix, and trailing tags
  echo "$content" \
    | sed -E 's/^[[:space:]]*//' \
    | sed -E 's/^-[[:space:]]*\[.\][[:space:]]*//' \
    | sed -E 's/[[:space:]]*\[[^]]+\][[:space:]]*$//g' \
    | sed -E 's/[[:space:]]*$//'
}

# Calculate pomodoro state and remaining time
calculate_pomodoro() {
  local start_time="$1"
  local now
  now=$(date +%s)
  local elapsed=$((now - start_time))

  # Calculate position in current cycle
  local cycle_position=$((elapsed % CYCLE_DURATION))

  if [[ $cycle_position -lt $WORK_DURATION ]]; then
    # Work phase
    local remaining=$((WORK_DURATION - cycle_position))
    echo "work|$remaining"
  else
    # Break phase
    local break_elapsed=$((cycle_position - WORK_DURATION))
    local remaining=$((BREAK_DURATION - break_elapsed))
    echo "break|$remaining"
  fi
}

# Format seconds as MM:SS
format_time() {
  local seconds="$1"
  printf "%d:%02d" $((seconds / 60)) $((seconds % 60))
}

# Truncate text with ellipsis
truncate_text() {
  local text="$1"
  local max_len="$2"
  if [[ ${#text} -gt $max_len ]]; then
    echo "${text:0:$((max_len - 1))}…"
  else
    echo "$text"
  fi
}

# Main logic
main() {
  # Handle click event
  if [[ "$SENDER" == "mouse.clicked" ]]; then
    toggle_pause
  fi

  # Check pause state first
  if is_paused; then
    sketchybar --set "$NAME" \
      drawing=on \
      icon="󰏤" \
      icon.color="$GREY" \
      label=""
    return
  fi

  local timer_data
  timer_data=$(get_latest_timer)

  if [[ -z "$timer_data" ]]; then
    # No active timer
    sketchybar --set "$NAME" label="" icon="" drawing=off
    return
  fi

  local start_time
  local task_content
  start_time=$(echo "$timer_data" | cut -d'|' -f1)
  task_content=$(echo "$timer_data" | cut -d'|' -f2-)

  local task_name
  task_name=$(extract_task_name "$task_content")

  local pomodoro_state
  pomodoro_state=$(calculate_pomodoro "$start_time")

  local phase
  local remaining
  phase=$(echo "$pomodoro_state" | cut -d'|' -f1)
  remaining=$(echo "$pomodoro_state" | cut -d'|' -f2)

  local time_display
  time_display=$(format_time "$remaining")

  local icon
  local icon_color
  local label_text
  local display_name
  display_name=$(truncate_text "$task_name" "$MAX_TASK_CHARS")

  if [[ "$phase" == "work" ]]; then
    icon="󰔟"  # timer icon
    icon_color="$GREEN"
    label_text="$display_name $time_display"
  else
    icon="󰒲"  # coffee/break icon
    icon_color="$YELLOW"
    label_text="BREAK $time_display"
  fi

  sketchybar --set "$NAME" \
    drawing=on \
    icon="$icon" \
    icon.color="$icon_color" \
    label="$label_text"
}

main
