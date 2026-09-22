#!/usr/bin/env bash
# Rofi wifi popup (nmcli)
THEME="$(dirname "$(readlink -f "$0")")/../rofi/10hour.rasi"
R=(rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 460px;}' -p "󰤨")

state=$(nmcli -t -f WIFI g)
if [[ $state != enabled ]]; then
    [[ $(printf '%s\n' "󰖩  Turn Wi-Fi on" | "${R[@]}") ]] && nmcli radio wifi on
    exit
fi

nmcli device wifi rescan 2>/dev/null
list=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list | awk -F: '
    $4!="" && !seen[$4]++ { mark=($1=="*")?"󰄬":" "; lock=($3!="")?"":" "; printf "%s  %s  %3s%%  %s\n", mark, lock, $2, $4 }')
choice=$(printf '%s\n%s\n' "$list" "󰖪  Turn Wi-Fi off" | "${R[@]}") || exit
[[ -z $choice ]] && exit

if [[ $choice == *"Turn Wi-Fi off"* ]]; then nmcli radio wifi off; exit; fi
ssid=$(sed -E 's/^.{1}  .{1}  +[0-9]+%  //' <<<"$choice")

if nmcli -t -f NAME connection show | grep -qx "$ssid"; then
    nmcli connection up id "$ssid"
else
    pass=""
    if [[ $choice == *""* ]]; then
        pass=$(rofi -dmenu -password -theme "$THEME" -p "󰌾" -theme-str 'window {width: 460px;} listview {lines: 0;}' </dev/null) || exit
    fi
    nmcli device wifi connect "$ssid" ${pass:+password "$pass"}
fi && notify-send -a osd -t 2000 "󰖩  Wi-Fi" "$ssid"
