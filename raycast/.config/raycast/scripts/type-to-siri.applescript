#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Type to Siri
# @raycast.mode silent

# Optional parameters:
# @raycast.icon siri-icon.png
# @raycast.packageName System
# @raycast.argument1 { "type": "text", "placeholder": "Siri に伝える内容（空欄でSiri起動のみ）", "optional": true }
# @raycast.description Siri にテキストを渡す（日本語対応：クリップボード経由ペースト方式）

on run argv
    set promptText to ""
    if (count of argv) >= 1 then
        set promptText to item 1 of argv
    end if

    set previousClipboard to ""
    try
        set previousClipboard to (the clipboard as text)
    end try

    tell application "System Events"
        tell the front menu bar of process "SystemUIServer"
            try
                tell (first menu bar item whose description is "Siri")
                    perform action "AXPress"
                end tell
            on error errMsg
                display notification "メニューバーに Siri アイコンが必要です" with title "Type to Siri 失敗"
                return
            end try
        end tell
    end tell

    if promptText is "" then
        return
    end if

    delay 0.5

    set the clipboard to promptText
    delay 0.1

    tell application "System Events"
        keystroke "v" using command down
        delay 0.2
        key code 36
    end tell

    delay 0.4
    try
        set the clipboard to previousClipboard
    end try
end run
