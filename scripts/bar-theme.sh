#!/usr/bin/env bash
# Switch the quickshell bar's color theme (SUPER + M -> Bar theme).
# Writes the theme name to a state file that shell.qml watches and applies live.
THEME="$(dirname "$(readlink -f "$0")")/../rofi/10hour.rasi"
STATE="$HOME/.local/state/quickshell/bar-theme"
mkdir -p "$(dirname "$STATE")"

choice=$(printf '%s\n' \
    "󰃟  Default" \
    "  Gruvbox vibe" \
    "󰊴  Retro gaming vibe" \
    "  Everforest vibe" \
    "󰆊  Nostalgic vibe" \
    | rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 320px;}' -p "󰸌") || exit

case "$choice" in
    *Default)      name=default ;;
    *Gruvbox*)     name=gruvbox ;;
    *"Retro gaming"*) name=retro ;;
    *Everforest*)  name=everforest ;;
    *Nostalgic*)   name=nostalgic ;;
    *) exit ;;
esac

echo -n "$name" > "$STATE"
notify-send -a osd -t 1500 "󰸌  Bar theme" "$name"
