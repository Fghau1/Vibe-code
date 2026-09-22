#!/usr/bin/env bash
# Volume / brightness OSD via dunst progress bar.
# usage: osd.sh vol-up|vol-down|vol-mute|mic-mute|bri-up|bri-down
tag() { dunstify -a osd -u low -t 1200 -h string:x-dunst-stack-tag:"$1" -h int:value:"$2" "$3" "$4"; }

vol() {
    read -r _ v m < <(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    v=$(awk -v v="$v" 'BEGIN{printf "%d", v*100+0.5}')
    if [[ $m == *MUTED* ]]; then tag volume 0 "󰝟  Muted" ""
    else tag volume "$v" "󰕾  Volume" ""; fi
}
bri() {
    v=$(( $(brightnessctl g) * 100 / $(brightnessctl m) ))
    tag brightness "$v" "󰃟  Brightness" ""
}

case $1 in
    vol-up)   wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+; vol ;;
    vol-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; vol ;;
    vol-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; vol ;;
    mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
              wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED \
                  && tag mic 0 "󰍭  Mic muted" "" || tag mic 100 "󰍬  Mic on" "" ;;
    bri-up)   brightnessctl -q set 5%+; bri ;;
    bri-down) brightnessctl -q set 5%-; bri ;;
    *) echo "usage: $0 vol-up|vol-down|vol-mute|mic-mute|bri-up|bri-down" >&2; exit 1 ;;
esac
