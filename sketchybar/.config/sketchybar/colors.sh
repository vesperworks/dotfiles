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
export BAR_COLOR=0xa024273a           # Semi-transparent dark
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
export ACTIVE_COLOR=$MAGENTA          # Magenta for active
export INACTIVE_COLOR=$GREY
export EMPTY_COLOR=0xff494d64         # Surface color

# Accent colors (aliases)
export ACCENT_BLUE=$BLUE
export ACCENT_GREEN=$GREEN
export ACCENT_YELLOW=$YELLOW
export ACCENT_RED=$RED
export ACCENT_TEAL=0xff8bd5ca
export ACCENT_PEACH=$ORANGE
export ACCENT_PINK=0xfff5bde6
export ACCENT_LAVENDER=0xffb7bdf8

# Surface colors
export SURFACE0=0xff363a4f
export SURFACE1=0xff494d64
export SURFACE2=0xff5b6078

# App icon color (white for visibility)
export APP_ICON_COLOR=$WHITE

# Workspace colors (per workspace number)
export WS_COLOR_1=$RED
export WS_COLOR_2=$GREEN
export WS_COLOR_3=$BLUE
export WS_COLOR_4=$YELLOW
export WS_COLOR_5=$MAGENTA
export WS_COLOR_Q=$ORANGE
export WS_COLOR_W=$ACCENT_TEAL
export WS_COLOR_E=$ACCENT_PINK
export WS_COLOR_R=$ACCENT_LAVENDER
export WS_COLOR_T=$WHITE
