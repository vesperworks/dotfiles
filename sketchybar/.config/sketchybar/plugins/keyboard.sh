#!/bin/bash

# IME/Keyboard Layout indicator for SketchyBar
# Triggered by: AppleSelectedInputSourcesChangedNotification

CONFIG_DIR="$HOME/.config/sketchybar"
source "$CONFIG_DIR/colors.sh"

# Get current input source
LAYOUT="$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -E 'KeyboardLayout Name|Input Mode')"

# Determine short label based on input source
case "$LAYOUT" in
  *"ABC"*|*"U.S."*|*"US"*)
    SHORT="A"
    ;;
  *"Hiragana"*|*"Japanese"*|*"com.apple.inputmethod.Kotoeri"*)
    SHORT="あ"
    ;;
  *"Katakana"*)
    SHORT="ア"
    ;;
  *)
    SHORT="??"
    ;;
esac

sketchybar --set keyboard label="$SHORT"
