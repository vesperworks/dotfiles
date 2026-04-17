#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open in Neovim/Yazi
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.description Finder の選択項目を Neovim（テキスト）or Yazi（ディレクトリ/その他）で開く

set -euo pipefail

ALACRITTY="/Applications/Alacritty.app/Contents/MacOS/alacritty"
GHOSTTY="/Applications/Ghostty.app/Contents/MacOS/ghostty"

TARGET=$(
	osascript <<'EOF'
on posixPathOf(aFinderItem)
  return POSIX path of (aFinderItem as alias)
end posixPathOf

tell application "Finder"
  if not (exists Finder window 1) then
    return (POSIX path of (desktop as alias))
  end if

  -- selection を優先
  try
    set sel to selection
    if sel is not {} then
      return my posixPathOf(item 1 of sel)
    end if
  end try

  -- selection が取れない/空なら前面フォルダ
  try
    return (POSIX path of (target of Finder window 1 as alias))
  on error
    return (POSIX path of (desktop as alias))
  end try
end tell
EOF
)

[ -z "$TARGET" ] && exit 0

# ディレクトリなら yazi (Ghostty)
if [ -d "$TARGET" ]; then
	"$GHOSTTY" -e yazi "$TARGET"
	exit 0
fi

# テキストなら nvim (Alacritty)
if file "$TARGET" | grep -qi text; then
	"$ALACRITTY" -e nvim "$TARGET"
else
	# それ以外のファイルなら yazi (Ghostty)
	"$GHOSTTY" -e yazi "$TARGET"
fi
