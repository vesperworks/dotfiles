#!/bin/bash

# CodexBar Usage Plugin for SketchyBar
# Bar: icon colored by max usage% (polled every update_freq=300s)
# Popup: per-provider session/week/opus usage, served from cache for zero-lag click
#
# Design: sketchybar polls this script on a 5-minute cadence (matching CodexBar's
# own refresh rate). Each poll fetches codex+claude, writes the normalized JSON
# to a cache dir, and repaints the bar. A click reads the cache only — it does
# not call codexbar, so the popup appears instantly even if the CLI is slow or
# rate-limited.
#
# Requires CodexBar.app running (for keychain access) and codexbar CLI in PATH.
# Cursor provider is skipped because it crashes the CLI on v0.20.

source "$CONFIG_DIR/colors.sh"

export PATH="$HOME/.nodebrew/current/bin:$HOME/.local/bin:$HOME/.bun/bin:/opt/homebrew/bin:$PATH"

CACHE_DIR="${TMPDIR:-/tmp}/sketchybar_codex_usage"
CODEX_CACHE="$CACHE_DIR/codex.json"
CLAUDE_CACHE="$CACHE_DIR/claude.json"
mkdir -p "$CACHE_DIR"

ICON_AI="󰧑" # nf-md-robot

get_color() {
	local pct=$1
	if [ -z "$pct" ] || [ "$pct" = "null" ] || [ "$pct" = "-" ]; then
		echo "$GREY"
		return
	fi
	if [ "$pct" -ge 80 ]; then
		echo "$RED"
	elif [ "$pct" -ge 50 ]; then
		echo "$ORANGE"
	elif [ "$pct" -ge 25 ]; then
		echo "$YELLOW"
	else
		echo "$GREEN"
	fi
}

# Fetch and normalize one provider. 10s timeout guards against rate-limit
# hangs. Returns a single JSON object ({} on any error or empty response).
fetch_provider() {
	local provider="$1" raw
	raw=$(timeout 10 codexbar usage --provider "$provider" --format json --no-color 2>/dev/null)
	[ -z "$raw" ] && {
		echo "{}"
		return
	}
	echo "$raw" | jq -s -r '
    [.[] | if type=="array" then .[] else . end]
    | map(select(.error | not))
    | (.[0] // {})
  ' 2>/dev/null || echo "{}"
}

read_cache() {
	local path="$1"
	[ -s "$path" ] && cat "$path" || echo "{}"
}

format_reset() {
	# Claude style:   "Resets1pm(Asia/Tokyo)" → "1pm"
	#                 "ResetsApr24at8am(Asia/Tokyo)" → "Apr24 8am"
	# Codex style:    "2026年4月24日 11:54" → keep as-is
	echo "$1" | sed -E 's/^Resets//; s/at/ /; s/\(Asia\/Tokyo\)//; s/ +$//'
}

pct_or_zero() { echo "$1" | jq -r "$2 // 0"; }
pct_or_dash() { echo "$1" | jq -r "$2 // \"-\""; }
str_or_dash() { echo "$1" | jq -r "$2 // \"-\""; }

# Called on timer / forced / custom refresh events.
poll_and_paint_bar() {
	local codex_json claude_json
	codex_json=$(fetch_provider codex)
	claude_json=$(fetch_provider claude)
	echo "$codex_json" >"$CODEX_CACHE"
	echo "$claude_json" >"$CLAUDE_CACHE"

	local codex_pri claude_pri claude_sec claude_ter max_pct color
	codex_pri=$(pct_or_zero "$codex_json" '.usage.primary.usedPercent')
	claude_pri=$(pct_or_zero "$claude_json" '.usage.primary.usedPercent')
	claude_sec=$(pct_or_zero "$claude_json" '.usage.secondary.usedPercent')
	claude_ter=$(pct_or_zero "$claude_json" '.usage.tertiary.usedPercent')

	max_pct=$(printf '%s\n' "$codex_pri" "$claude_pri" "$claude_sec" "$claude_ter" |
		awk '{if ($1+0 > max) max=$1+0} END {print max+0}')
	color=$(get_color "$max_pct")

	sketchybar --set "$NAME" icon="$ICON_AI" icon.color="$color" label="${max_pct}%"
}

# Called on mouse.clicked. Reads only the cache, so it is instant.
paint_popup_from_cache() {
	local codex_json claude_json
	codex_json=$(read_cache "$CODEX_CACHE")
	claude_json=$(read_cache "$CLAUDE_CACHE")

	local codex_pri codex_sec codex_pri_reset codex_sec_reset
	codex_pri=$(pct_or_dash "$codex_json" '.usage.primary.usedPercent')
	codex_sec=$(pct_or_dash "$codex_json" '.usage.secondary.usedPercent')
	codex_pri_reset=$(format_reset "$(str_or_dash "$codex_json" '.usage.primary.resetDescription')")
	codex_sec_reset=$(format_reset "$(str_or_dash "$codex_json" '.usage.secondary.resetDescription')")

	local claude_pri claude_sec claude_ter claude_pri_reset claude_sec_reset claude_ter_reset
	claude_pri=$(pct_or_dash "$claude_json" '.usage.primary.usedPercent')
	claude_sec=$(pct_or_dash "$claude_json" '.usage.secondary.usedPercent')
	claude_ter=$(pct_or_dash "$claude_json" '.usage.tertiary.usedPercent')
	claude_pri_reset=$(format_reset "$(str_or_dash "$claude_json" '.usage.primary.resetDescription')")
	claude_sec_reset=$(format_reset "$(str_or_dash "$claude_json" '.usage.secondary.resetDescription')")
	claude_ter_reset=$(format_reset "$(str_or_dash "$claude_json" '.usage.tertiary.resetDescription')")

	sketchybar \
		--set codex_usage.1 icon="󱙷" icon.color="$(get_color "$codex_pri")" \
		label="Codex 5h: ${codex_pri}% (reset ${codex_pri_reset})" drawing=on \
		--set codex_usage.2 icon="󰸗" icon.color="$(get_color "$codex_sec")" \
		label="Codex wk: ${codex_sec}% (reset ${codex_sec_reset})" drawing=on \
		--set codex_usage.3 icon="󱙷" icon.color="$(get_color "$claude_pri")" \
		label="Claude 5h: ${claude_pri}% (reset ${claude_pri_reset})" drawing=on \
		--set codex_usage.4 icon="󰸗" icon.color="$(get_color "$claude_sec")" \
		label="Claude wk: ${claude_sec}% (reset ${claude_sec_reset})" drawing=on \
		--set codex_usage.5 icon="󰓎" icon.color="$(get_color "$claude_ter")" \
		label="Claude Opus: ${claude_ter}% (reset ${claude_ter_reset})" drawing=on
}

case "$SENDER" in
"mouse.clicked")
	paint_popup_from_cache
	sketchybar --set "$NAME" popup.drawing=toggle
	;;
"mouse.exited.global")
	sketchybar --set "$NAME" popup.drawing=off
	;;
*)
	poll_and_paint_bar
	;;
esac
