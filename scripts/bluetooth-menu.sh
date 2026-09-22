#!/usr/bin/env bash
# Rofi bluetooth popup (bluetoothctl)
THEME="$(dirname "$(readlink -f "$0")")/../rofi/10hour.rasi"
R=(rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 460px;}' -p "󰂯")

if ! bluetoothctl show | grep -q "Powered: yes"; then
    [[ $(printf '%s\n' "󰂯  Turn Bluetooth on" | "${R[@]}") ]] && bluetoothctl power on
    exit
fi

bluetoothctl --timeout 4 scan on >/dev/null 2>&1 &
sleep 0.2
list=$(bluetoothctl devices | while read -r _ mac name; do
    if bluetoothctl info "$mac" | grep -q "Connected: yes"; then m="󰄬"; else m=" "; fi
    printf '%s  %s  [%s]\n' "$m" "$name" "$mac"
done)
choice=$(printf '%s\n%s\n' "$list" "󰂲  Turn Bluetooth off" | "${R[@]}") || exit
[[ -z $choice ]] && exit

if [[ $choice == *"Turn Bluetooth off"* ]]; then bluetoothctl power off; exit; fi
mac=$(grep -o '\[[0-9A-F:]*\]$' <<<"$choice" | tr -d '[]')
name=$(sed -E 's/^.  (.*)  \[.*$/\1/' <<<"$choice")

if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
    bluetoothctl disconnect "$mac" && notify-send -a osd -t 2000 "󰂲  Bluetooth" "Disconnected $name"
else
    bluetoothctl connect "$mac" && notify-send -a osd -t 2000 "󰂯  Bluetooth" "Connected $name"
fi
