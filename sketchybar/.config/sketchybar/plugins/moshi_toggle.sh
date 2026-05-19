#!/bin/bash

# Moshi Hook Toggle for SketchyBar
# Click to start/stop the homebrew.mxcl.moshi-hook LaunchAgent. The service
# intercepts approval prompts from CLIs like Codex/Cursor; keep it OFF during
# focused work (so the native approval UI stays usable) and flip ON when
# stepping away. Color: ORANGE = running, SURFACE2 = stopped.

source "$CONFIG_DIR/colors.sh"

SERVICE_LABEL="homebrew.mxcl.moshi-hook"
PLIST="$HOME/Library/LaunchAgents/${SERVICE_LABEL}.plist"
TARGET="gui/$(id -u)/${SERVICE_LABEL}"

# pgrep is faster and more reliable than `launchctl print` for hot-path
# state checks; launchctl can lag a few hundred ms after bootstrap/bootout.
is_running() {
	/usr/bin/pgrep -f "moshi-hook serve" >/dev/null 2>&1
}

apply_color() {
	if is_running; then
		sketchybar --set "$NAME" icon.color="$ORANGE"
	else
		sketchybar --set "$NAME" icon.color="$SURFACE2"
	fi
}

# Invocation:
#   - As `script` (routine update_freq tick or first-render): no args, just
#     reflect the current state in the icon color.
#   - As `click_script` with arg "toggle": flip the LaunchAgent on/off.
# We use click_script instead of `--subscribe mouse.clicked` because the
# latter has been unreliable for this item on this machine.
case "${1:-update}" in
toggle)
	if is_running; then
		launchctl bootout "$TARGET" >/dev/null 2>&1 || true
	else
		launchctl bootstrap "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
	fi
	# Wait briefly so the post-toggle state reflects in the same script run
	# (bootstrap/bootout return before the daemon's process state settles).
	sleep 0.3
	apply_color
	;;
update | *)
	apply_color
	;;
esac
