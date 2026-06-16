#!/bin/bash

# Catppuccin Macchiato Color Palette (FelixKratz style)
# https://github.com/FelixKratz/dotfiles

# Basic colors
export BLACK=0xff181926
export WHITE=0xffcad3f5
export RED=0xffed8796
export GREEN=0xffa6da95
export BLUE=0xff8aadf4
export YELLOW=0xffeed49f
export ORANGE=0xfff5a97f
export MAGENTA=0xffc6a0f6
export GREY=0xff939ab7
export TRANSPARENT=0x00000000

# Bar and UI colors
export BAR_COLOR=0xa024273a # Semi-transparent dark
export ICON_COLOR=$WHITE
export LABEL_COLOR=$WHITE
export BACKGROUND=0xff24273a

# Background variants (with transparency)
export BACKGROUND_1=0x90363a4f
export BACKGROUND_2=0x90494d64

# Popup colors
export POPUP_BACKGROUND_COLOR=0xff24273a
export POPUP_BORDER_COLOR=$WHITE

# Workspace states
export ACTIVE_COLOR=$MAGENTA # Magenta for active
export INACTIVE_COLOR=$GREY
export EMPTY_COLOR=0xff494d64 # Surface color

# Accent colors (aliases)
export ACCENT_BLUE=$BLUE
export ACCENT_GREEN=$GREEN
export ACCENT_YELLOW=$YELLOW
export ACCENT_RED=$RED
export ACCENT_TEAL=0xff8bd5ca
export ACCENT_PEACH=$ORANGE
export ACCENT_PINK=0xfff5bde6
export ACCENT_LAVENDER=0xffb7bdf8
# Catppuccin Macchiato accent colors used for asdf workspaces
export ACCENT_SKY=0xff91d7e3
export ACCENT_SAPPHIRE=0xff7dc4e4
export ACCENT_FLAMINGO=0xfff0c6c6
export ACCENT_MAROON=0xffee99a0

# Surface colors
export SURFACE0=0xff363a4f
export SURFACE1=0xff494d64
export SURFACE2=0xff5b6078

# App icon color (white for visibility)
export APP_ICON_COLOR=$WHITE

# Workspace colors (per keyboard row, 3-tier saturation)
# Row 12345: ★★★ Vivid (S=85% L=65%)
export WS_COLOR_1=0xfff25a70
export WS_COLOR_2=0xff7ff25a
export WS_COLOR_3=0xff5a8cf2
export WS_COLOR_4=0xfff2c05a
export WS_COLOR_5=0xff9d5af2
# Row QWERT: ★★ Bright (S=70% L=70%)
export WS_COLOR_Q=0xffe8a37d
export WS_COLOR_W=0xff7de8d8
export WS_COLOR_E=0xffe87dcb
export WS_COLOR_R=0xff7d87e8
export WS_COLOR_T=0xff7d93e8
# Row ASDF: ★ Muted (S=50% L=74%)
export WS_COLOR_A=0xff9cd4de
export WS_COLOR_S=0xff9cc9de
export WS_COLOR_D=0xffde9c9c
export WS_COLOR_F=0xffde9ca1
