#!/usr/bin/env bash
# Rofi main menu (SUPER + M): Wi-Fi, Bluetooth, shortcuts, AI agents, bar theme
D="$(dirname "$(readlink -f "$0")")"
THEME="$D/../rofi/10hour.rasi"
pkill -x rofi && exit

c=$(printf '%s\n' \
    "󰤨  Wi-Fi" \
    "󰂯  Bluetooth" \
    "󰌌  Shortcuts" \
    "󰚩  AI agents" \
    "󰸌  Bar theme" \
    | rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 300px;}' -p "") || exit

case "$c" in
    *Wi-Fi)       exec "$D/wifi-menu.sh" ;;
    *Bluetooth)   exec "$D/bluetooth-menu.sh" ;;
    *Shortcuts)   exec "$D/shortcuts.sh" ;;
    *"AI agents") exec "$D/ai-agents.sh" ;;
    *"Bar theme") exec "$D/bar-theme.sh" ;;
esac
