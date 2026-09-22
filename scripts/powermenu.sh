#!/usr/bin/env bash
# Rofi power menu
THEME="$(dirname "$(readlink -f "$0")")/../rofi/10hour.rasi"
c=$(printf '%s\n' "󰌾  Lock" "󰒲  Suspend" "󰍃  Logout" "󰜉  Reboot" "󰐥  Shutdown" \
    | rofi -dmenu -i -theme "$THEME" -p "")
case $c in
    *Lock)     hyprlock ;;
    *Suspend)  systemctl suspend ;;
    *Logout)   hyprctl dispatch exit ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
