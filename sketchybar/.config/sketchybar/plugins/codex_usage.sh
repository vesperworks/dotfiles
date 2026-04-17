#!/bin/bash

# CodexBar Usage Plugin for SketchyBar
# Bar: icon colored by max usage% / Popup: per-provider session/week/opus usage
#
# Requires CodexBar.app running (for keychain access) and codexbar CLI in PATH.
# Cursor provider is skipped because it crashes the CLI on v0.20.
# Fetches are capped at 10s per provider to avoid blocking when an upstream
# rate-limits (e.g. claude.ai returning "rate limited right now").

source "$CONFIG_DIR/colors.sh"

export PATH="$HOME/.nodebrew/current/bin:$HOME/.local/bin:$HOME/.bun/bin:/opt/homebrew/bin:$PATH"

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

# Runs `codexbar usage --provider <p>` with a 10s timeout.
# Output normalized to a single JSON object (first result, even if the CLI
# emits multiple arrays for auto+cli fallback). Returns "{}" on any failure
# so downstream jq extraction cleanly falls back to "-" / 0.
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

format_reset() {
	# Claude style:   "Resets1pm(Asia/Tokyo)" → "1pm"
	#                 "ResetsApr24at8am(Asia/Tokyo)" → "Apr24 8am"
	# Codex style:    "2026年4月24日 11:54" → keep as-is
	# Fallback dash:  "-" → keep
	echo "$1" | sed -E 's/^Resets//; s/at/ /; s/\(Asia\/Tokyo\)//; s/ +$//'
}

pct_or_zero() { echo "$1" | jq -r "$2 // 0"; }
pct_or_dash() { echo "$1" | jq -r "$2 // \"-\""; }
str_or_dash() { echo "$1" | jq -r "$2 // \"-\""; }

update_bar() {
	local codex_json claude_json codex_pri claude_pri claude_sec claude_ter max_pct color
	codex_json=$(fetch_provider codex)
	claude_json=$(fetch_provider claude)

	codex_pri=$(pct_or_zero "$codex_json" '.usage.primary.usedPercent')
	claude_pri=$(pct_or_zero "$claude_json" '.usage.primary.usedPercent')
	claude_sec=$(pct_or_zero "$claude_json" '.usage.secondary.usedPercent')
	claude_ter=$(pct_or_zero "$claude_json" '.usage.tertiary.usedPercent')

	max_pct=$(printf '%s\n' "$codex_pri" "$claude_pri" "$claude_sec" "$claude_ter" |
		awk '{if ($1+0 > max) max=$1+0} END {print max+0}')
	color=$(get_color "$max_pct")

	sketchybar --set "$NAME" icon="$ICON_AI" icon.color="$color" label="${max_pct}%"
}

update_popup() {
	local codex_json claude_json
	codex_json=$(fetch_provider codex)
	claude_json=$(fetch_provider claude)

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
