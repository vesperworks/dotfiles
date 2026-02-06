#!/bin/bash
# focus-alacritty.sh - tmuxセッション名でAlacrittyウィンドウにフォーカス
# 通知クリック時にAerospaceで該当ウィンドウを選択

SESSION_NAME="$1"

if [ -z "$SESSION_NAME" ]; then
  open -a Alacritty
  exit 0
fi

# Aerospaceからウィンドウ一覧を取得し、セッション名でマッチ
WINDOW_ID=$(aerospace list-windows --all 2>/dev/null | \
  awk -F'|' -v name="$SESSION_NAME" '
    /Alacritty/ && $3 ~ name { gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1; exit }
  ')

if [ -n "$WINDOW_ID" ]; then
  aerospace focus --window-id "$WINDOW_ID"
else
  # フォールバック: Alacrittyを開く
  open -a Alacritty
fi
