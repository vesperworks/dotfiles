#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# nvim が書き出すアクティブタスク名
NVIM_ACTIVE="/tmp/sketchybar_focus_active"
# focus.sh 独自のセッション開始時刻（タスク切替でもリセットしない）
SESSION_FILE="/tmp/sketchybar_focus_session"
# Raycast Focus の起動済みフラグ
RAYCAST_TRACK="/tmp/sketchybar_focus_raycast"
# 手動モード用
MANUAL_FILE="/tmp/sketchybar_focus_manual"
# 一時停止状態
PAUSE_FILE="/tmp/sketchybar_focus_paused"

MAX_TASK_CHARS=20
WORK_DURATION=1500
BREAK_DURATION=300
CYCLE_DURATION=1800

format_time() {
	local seconds="$1"
	printf "%d:%02d" $((seconds / 60)) $((seconds % 60))
}

extract_task_name() {
	echo "$1" |
		sed -E 's/^[[:space:]]*//' |
		sed -E 's/^-[[:space:]]*\[.\][[:space:]]*//' |
		sed -E 's/[[:space:]]*\[[^]]+\][[:space:]]*$//g' |
		sed -E 's/[[:space:]]*$//'
}

truncate_text() {
	local text="$1" max_len="$2"
	if [[ ${#text} -gt $max_len ]]; then
		echo "${text:0:$((max_len - 1))}…"
	else
		echo "$text"
	fi
}

start_raycast() {
	local goal="$1"
	local url="raycast://focus/start?duration=$WORK_DURATION"
	if [[ -n "$goal" ]]; then
		local encoded
		encoded=$(jq -rn --arg s "$goal" '$s|@uri' 2>/dev/null)
		[[ -n "$encoded" ]] && url="$url&goal=$encoded"
	fi
	open "$url" 2>/dev/null &
}

show_idle() {
	sketchybar --set "$NAME" icon="󱎫" icon.color="$SURFACE2" label.drawing=off
}

cleanup_all() {
	rm -f "$SESSION_FILE" "$RAYCAST_TRACK" "$MANUAL_FILE" "$PAUSE_FILE"
	open "raycast://focus/complete" 2>/dev/null &
}

main() {
	# --- nvim タスク検出 ---
	if [[ -f "$NVIM_ACTIVE" ]]; then
		local task_content
		task_content=$(cut -d'|' -f2- <"$NVIM_ACTIVE" 2>/dev/null)

		if [[ -n "$task_content" ]]; then
			local task_name display_name
			task_name=$(extract_task_name "$task_content")
			display_name=$(truncate_text "$task_name" "$MAX_TASK_CHARS")

			# セッション開始（初回のみ）
			if [[ ! -f "$SESSION_FILE" ]]; then
				date +%s >"$SESSION_FILE"
			fi

			# Raycast Focus 開始（初回のみ）
			if [[ ! -f "$RAYCAST_TRACK" ]]; then
				echo "nvim" >"$RAYCAST_TRACK"
				start_raycast "$task_name"
			fi

			local session_start now elapsed cycle_pos
			session_start=$(cat "$SESSION_FILE")
			now=$(date +%s)
			elapsed=$((now - session_start))
			cycle_pos=$((elapsed % CYCLE_DURATION))

			if [[ $cycle_pos -lt $WORK_DURATION ]]; then
				local remaining=$((WORK_DURATION - cycle_pos))
				local pct=$((remaining * 100 / WORK_DURATION))
				local color
				if [[ $pct -gt 40 ]]; then
					color="$ORANGE"
				elif [[ $pct -gt 15 ]]; then
					color="$YELLOW"
				else color="$RED"; fi

				sketchybar --set "$NAME" drawing=on \
					icon="󱎫" icon.color="$color" \
					label="$display_name $(format_time "$remaining")" \
					label.drawing=on label.color="$color"
			else
				local break_remaining=$((CYCLE_DURATION - cycle_pos))
				sketchybar --set "$NAME" drawing=on \
					icon="󰒲" icon.color="$YELLOW" \
					label="BREAK $(format_time "$break_remaining")" \
					label.drawing=on label.color="$YELLOW"
			fi
			return
		fi
	fi

	# nvim タスクが消えた → セッション終了
	if [[ -f "$SESSION_FILE" ]] && [[ ! -f "$MANUAL_FILE" ]]; then
		cleanup_all
	fi

	# --- 手動モード ---
	if [[ "$SENDER" == "mouse.clicked" ]]; then
		if [[ -f "$MANUAL_FILE" ]]; then
			cleanup_all
			show_idle
			return
		else
			local now=$(($(date +%s)))
			echo "$now" >"$SESSION_FILE"
			echo "$((now + WORK_DURATION))" >"$MANUAL_FILE"
			echo "manual" >"$RAYCAST_TRACK"
			start_raycast
		fi
	fi

	if [[ -f "$MANUAL_FILE" ]]; then
		local end_time now remaining
		end_time=$(cat "$MANUAL_FILE")
		now=$(date +%s)
		remaining=$((end_time - now))
		if [[ $remaining -le 0 ]]; then
			cleanup_all
			show_idle
			return
		fi
		local pct=$((remaining * 100 / WORK_DURATION))
		local color
		if [[ $pct -gt 40 ]]; then
			color="$ORANGE"
		elif [[ $pct -gt 15 ]]; then
			color="$YELLOW"
		else color="$RED"; fi
		sketchybar --set "$NAME" drawing=on \
			icon="󱎫" icon.color="$color" \
			label="$(format_time "$remaining")" \
			label.drawing=on label.color="$color"
		return
	fi

	show_idle
}

main
