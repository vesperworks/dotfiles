#!/bin/bash

# App name to sketchybar-app-font icon mapping
# Font: https://github.com/kvndrsslr/sketchybar-app-font

icon_map() {
  case "$1" in
    "Arc") echo ":arc:" ;;
    "Google Chrome" | "Chrome") echo ":google_chrome:" ;;
    "Safari") echo ":safari:" ;;
    "Firefox") echo ":firefox:" ;;
    "Code" | "Visual Studio Code") echo ":code:" ;;
    "Cursor") echo ":cursor:" ;;
    "Ghostty") echo ":ghostty:" ;;
    "Alacritty") echo ":alacritty:" ;;
    "WezTerm") echo ":wezterm:" ;;
    "iTerm2" | "iTerm") echo ":iterm:" ;;
    "Terminal") echo ":terminal:" ;;
    "Finder") echo ":finder:" ;;
    "Slack") echo ":slack:" ;;
    "Discord") echo ":discord:" ;;
    "Spotify") echo ":spotify:" ;;
    "Music") echo ":music:" ;;
    "Notes") echo ":notes:" ;;
    "Notion") echo ":notion:" ;;
    "Obsidian") echo ":obsidian:" ;;
    "Calendar") echo ":calendar:" ;;
    "Mail") echo ":mail:" ;;
    "Messages") echo ":messages:" ;;
    "FaceTime") echo ":facetime:" ;;
    "Zoom" | "zoom.us") echo ":zoom:" ;;
    "Preview") echo ":preview:" ;;
    "Photos") echo ":photos:" ;;
    "System Preferences" | "System Settings") echo ":gear:" ;;
    "Activity Monitor") echo ":activity_monitor:" ;;
    "App Store") echo ":app_store:" ;;
    "Raycast") echo ":raycast:" ;;
    "1Password") echo ":one_password:" ;;
    "Figma") echo ":figma:" ;;
    "Docker" | "Docker Desktop") echo ":docker:" ;;
    "TablePlus") echo ":tableplus:" ;;
    "Postman") echo ":postman:" ;;
    "Transmit") echo ":transmit:" ;;
    "Linear") echo ":linear:" ;;
    "GitHub Desktop") echo ":github:" ;;
    "Xcode") echo ":xcode:" ;;
    "Simulator") echo ":simulator:" ;;
    "ChatGPT") echo ":openai:" ;;
    "Claude") echo ":claude:" ;;
    "Antigravity") echo ":default:" ;;
    "Warp") echo ":warp:" ;;
    "Kitty" | "kitty") echo ":kitty:" ;;
    "Brave Browser") echo ":brave_browser:" ;;
    "Microsoft Edge") echo ":microsoft_edge:" ;;
    "Vivaldi") echo ":vivaldi:" ;;
    "Orion") echo ":orion:" ;;
    *) echo ":default:" ;;
  esac
}

icon_map "$1"
