#!/bin/bash

# CodexBar Usage Plugin for SketchyBar
#
# Why the split: a click must feel instant. Calling `codexbar usage` on click
# blocks the popup for up to $TIMEOUT_SEC. Instead the timer tick polls both
# providers, writes normalized JSON to a cache dir, and the click path only
# reads the cache. $UPDATE_SEC matches CodexBar.app's own poll cadence.
#
# Requires CodexBar.app running (keychain access) and codexbar CLI in PATH.
# Cursor provider is disabled upstream (~/.codexbar/config.json) because
# CodexBar v0.20 crashes in CursorStatusProbe on fetch.

source "$CONFIG_DIR/colors.sh"

# PATH augmentation: GUI-launched sketchybar does not inherit the login
# shell's PATH, so node / bun / local bin must be surfaced explicitly.
export PATH="$HOME/.nodebrew/current/bin:$HOME/.local/bin:$HOME/.bun/bin:/opt/homebrew/bin:$PATH"

TIMEOUT_SEC=10
CACHE_DIR="${TMPDIR:-/tmp}/sketchybar_codex_usage"
CODEX_CACHE="$CACHE_DIR/codex.json"
CLAUDE_CACHE="$CACHE_DIR/claude.json"
mkdir -p "$CACHE_DIR"

ICON_AI="󰧑"        # nf-md-robot
ICON_PRIMARY="󱙷"   # nf-md-timer_sand (session window)
ICON_SECONDARY="󰸗" # nf-md-calendar_week
ICON_OPUS="󰓎"      # nf-md-star

# Color by REMAINING percent. Low remaining = warning.
get_color() {
	local pct=$1
	if [ -z "$pct" ] || [ "$pct" = "null" ] || [ "$pct" = "-" ]; then
		echo "$GREY"
		return
	fi
	if [ "$pct" -le 20 ]; then
		echo "$RED"
	elif [ "$pct" -le 50 ]; then
		echo "$ORANGE"
	elif [ "$pct" -le 75 ]; then
		echo "$YELLOW"
	else
		echo "$GREEN"
	fi
}

to_remaining() {
	case "$1" in
	"-" | "null" | "") echo "-" ;;
	*)
		local r=$((100 - $1))
		((r < 0)) && r=0
		echo "$r"
		;;
	esac
}

# Fetch one provider with a bounded wall-clock budget.
#
# Output contract (single JSON object on stdout):
#   {usage: {...}}                           — success
#   {"__err":"timeout"}                      — killed by `timeout`
#   {"__err":"rate_limited"}                 — upstream rate limit
#   {"__err":"no_data"}                      — empty / non-JSON output
#
# The __err marker is preserved in the cache so the popup can show "why"
# instead of silent dashes.
fetch_provider() {
	local provider="$1" raw rc obj
	raw=$(timeout "$TIMEOUT_SEC" codexbar usage --provider "$provider" --format json --no-color 2>/dev/null)
	rc=$?
	if [ "$rc" = 124 ]; then
		echo '{"__err":"timeout"}'
		return
	fi
	if [ -z "$raw" ]; then
		echo '{"__err":"no_data"}'
		return
	fi
	# The CLI emits one JSON value per attempted source (auto + cli fallback).
	# Keep the first one without an `error` field; fall back to __err with the
	# upstream's hint if all failed.
	obj=$(echo "$raw" | jq -s -r '
    [.[] | if type=="array" then .[] else . end] as $all
    | ($all | map(select(.error | not)) | .[0]) as $ok
    | if $ok then $ok
      else (
        ($all[0].error.message // "unknown") as $msg
        | if ($msg | ascii_downcase | contains("rate limit")) then
            {"__err":"rate_limited"}
          else {"__err":"no_data","__msg":$msg} end
      ) end
  ' 2>/dev/null) || obj='{"__err":"no_data"}'
	echo "$obj"
}

read_cache() {
	local path="$1"
	[ -s "$path" ] && cat "$path" || echo '{"__err":"no_cache"}'
}

# Maps an __err marker to a short label shown in place of "X%".
err_label() {
	case "$1" in
	timeout) echo "timeout" ;;
	rate_limited) echo "rate-limited" ;;
	no_data | no_cache) echo "no data" ;;
	*) echo "-" ;;
	esac
}

# Claude resetDescription comes as a single smashed string; Codex's is
# already human-friendly.
format_reset() {
	echo "$1" | sed -E 's/^Resets//; s/at/ /; s/\(Asia\/Tokyo\)//; s/ +$//'
}

pct_or_zero() { echo "$1" | jq -r "$2 // 0"; }
pct_or_dash() { echo "$1" | jq -r "$2 // \"-\""; }
str_or_dash() { echo "$1" | jq -r "$2 // \"-\""; }
err_code() { echo "$1" | jq -r '.__err // ""'; }

# Paints the bar from already-loaded JSON (no I/O). Providers with an __err
# are skipped so one broken upstream doesn't push the whole bar into red or
# show an inflated (0% used → 100% left) remaining.
paint_bar_from_json() {
	local codex_json=$1 claude_json=$2
	local -a candidates=()

	if [ "$(err_code "$codex_json")" = "" ]; then
		candidates+=("$(pct_or_zero "$codex_json" '.usage.primary.usedPercent')")
	fi
	if [ "$(err_code "$claude_json")" = "" ]; then
		candidates+=(
			"$(pct_or_zero "$claude_json" '.usage.primary.usedPercent')"
			"$(pct_or_zero "$claude_json" '.usage.secondary.usedPercent')"
			"$(pct_or_zero "$claude_json" '.usage.tertiary.usedPercent')"
		)
	fi

	if [ ${#candidates[@]} -eq 0 ]; then
		sketchybar --set "$NAME" icon="$ICON_AI" icon.color="$GREY" label="err"
		return
	fi

	local min_remaining color
	min_remaining=$(printf '%s\n' "${candidates[@]}" |
		awk 'BEGIN {min=100} {r=100-($1+0); if (r<0) r=0; if (r<min) min=r} END {print min}')
	color=$(get_color "$min_remaining")

	sketchybar --set "$NAME" icon="$ICON_AI" icon.color="$color" label="${min_remaining}%"
}

# Writes one popup row, picking remaining % or an error label.
set_row() {
	local item=$1 icon=$2 prefix=$3 remaining=$4 reset=$5 err=$6
	local label color
	if [ -n "$err" ]; then
		label="$prefix: $(err_label "$err")"
		color="$GREY"
	else
		label="$prefix: ${remaining}% left (reset ${reset})"
		color="$(get_color "$remaining")"
	fi
	sketchybar --set "$item" icon="$icon" icon.color="$color" label="$label" drawing=on
}

paint_popup_from_cache() {
	local codex_json claude_json
	codex_json=$(read_cache "$CODEX_CACHE")
	claude_json=$(read_cache "$CLAUDE_CACHE")

	local codex_err claude_err
	codex_err=$(err_code "$codex_json")
	claude_err=$(err_code "$claude_json")

	local codex_pri_rem codex_sec_rem codex_pri_reset codex_sec_reset
	codex_pri_rem=$(to_remaining "$(pct_or_dash "$codex_json" '.usage.primary.usedPercent')")
	codex_sec_rem=$(to_remaining "$(pct_or_dash "$codex_json" '.usage.secondary.usedPercent')")
	codex_pri_reset=$(format_reset "$(str_or_dash "$codex_json" '.usage.primary.resetDescription')")
	codex_sec_reset=$(format_reset "$(str_or_dash "$codex_json" '.usage.secondary.resetDescription')")

	local claude_pri_rem claude_sec_rem claude_ter_rem
	local claude_pri_reset claude_sec_reset claude_ter_reset
	claude_pri_rem=$(to_remaining "$(pct_or_dash "$claude_json" '.usage.primary.usedPercent')")
	claude_sec_rem=$(to_remaining "$(pct_or_dash "$claude_json" '.usage.secondary.usedPercent')")
	claude_ter_rem=$(to_remaining "$(pct_or_dash "$claude_json" '.usage.tertiary.usedPercent')")
	claude_pri_reset=$(format_reset "$(str_or_dash "$claude_json" '.usage.primary.resetDescription')")
	claude_sec_reset=$(format_reset "$(str_or_dash "$claude_json" '.usage.secondary.resetDescription')")
	claude_ter_reset=$(format_reset "$(str_or_dash "$claude_json" '.usage.tertiary.resetDescription')")

	set_row codex_usage.1 "$ICON_PRIMARY" "Codex 5h" "$codex_pri_rem" "$codex_pri_reset" "$codex_err"
	set_row codex_usage.2 "$ICON_SECONDARY" "Codex wk" "$codex_sec_rem" "$codex_sec_reset" "$codex_err"
	set_row codex_usage.3 "$ICON_PRIMARY" "Claude 5h" "$claude_pri_rem" "$claude_pri_reset" "$claude_err"
	set_row codex_usage.4 "$ICON_SECONDARY" "Claude wk" "$claude_sec_rem" "$claude_sec_reset" "$claude_err"
	set_row codex_usage.5 "$ICON_OPUS" "Claude Opus" "$claude_ter_rem" "$claude_ter_reset" "$claude_err"
}

CACHE_TTL_SEC=300

cache_is_fresh() {
	[ -s "$CODEX_CACHE" ] && [ -s "$CLAUDE_CACHE" ] || return 1
	local now mtime
	now=$(date +%s)
	mtime=$(stat -f %m "$CODEX_CACHE" 2>/dev/null || echo 0)
	[ $((now - mtime)) -lt "$CACHE_TTL_SEC" ]
}

update_bar() {
	# The item ticks at update_freq=60 so reload renders quickly, but actual
	# CLI calls are amortized: fetch only when the cache is older than
	# CACHE_TTL_SEC (5 min, matching CodexBar.app's own cadence).
	local codex_json claude_json
	if cache_is_fresh; then
		codex_json=$(cat "$CODEX_CACHE")
		claude_json=$(cat "$CLAUDE_CACHE")
	else
		codex_json=$(fetch_provider codex)
		claude_json=$(fetch_provider claude)
		printf '%s\n' "$codex_json" >"$CODEX_CACHE"
		printf '%s\n' "$claude_json" >"$CLAUDE_CACHE"
	fi
	paint_bar_from_json "$codex_json" "$claude_json"
}

update_popup() {
	paint_popup_from_cache
}

source "$CONFIG_DIR/plugins/lib/popup_dispatch.sh"
