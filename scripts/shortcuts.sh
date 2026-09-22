#!/usr/bin/env bash
# Rofi read-only view of Hyprland keybinds (SUPER + M -> Shortcuts)
# Keep this in sync with hypr/hyprland.lua when binds change.
THEME="$(dirname "$(readlink -f "$0")")/../rofi/10hour.rasi"

printf '%s\n' \
    "SUPER + Return          Terminal" \
    "SUPER + D               Launcher" \
    "SUPER + E               File manager" \
    "SUPER + B               Browser" \
    "SUPER + ,               Wi-Fi menu" \
    "SUPER + C               System menu" \
    "SUPER + M               Main menu" \
    "SUPER + Q               Close window" \
    "SUPER + F               Fullscreen" \
    "SUPER + SPACE           Toggle floating" \
    "SUPER + P               Pseudo-tiling" \
    "SUPER + H/J/K/L         Focus left/down/up/right" \
    "SUPER + SHIFT + HJKL    Move window" \
    "SUPER + 0-9             Switch workspace" \
    "SUPER + SHIFT + 0-9     Move window to workspace" \
    "SUPER + scroll          Next / previous workspace" \
    "SUPER + S               Scratchpad" \
    "SUPER + CTRL + S        Scratchpad terminal" \
    "SUPER + drag (mouse)    Move window" \
    "SUPER + right-drag      Resize window" \
    "Print / SUPER+SHIFT+S   Screenshot" \
    "SUPER + SHIFT + R       Screen recording" \
    "SUPER + W               Wallpaper picker" \
    "SUPER + SHIFT + W       Random wallpaper" \
    "SUPER + CTRL + L        Lock screen" \
    "SUPER + SHIFT + E       Power menu" \
    | rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 520px;} listview {lines: 14;}' -p "󰌌" -no-custom >/dev/null
