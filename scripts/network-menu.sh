#!/usr/bin/env bash
# Rofi menu: Wi-Fi or Bluetooth
D="$(dirname "$(readlink -f "$0")")"
pkill -x rofi && exit
c=$(printf '%s\n' "󰤨  Wi-Fi" "󰂯  Bluetooth" \
    | rofi -dmenu -i -theme "$D/../rofi/10hour.rasi" -theme-str 'window {width: 300px;}' -p "") || exit
case $c in
    *Wi-Fi)     exec "$D/wifi-menu.sh" ;;
    *Bluetooth) exec "$D/bluetooth-menu.sh" ;;
esac
