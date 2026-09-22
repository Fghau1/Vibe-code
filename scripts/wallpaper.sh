#!/usr/bin/env bash
# Animated wallpaper picker (awww: animated transitions + GIF wallpapers)
# usage: wallpaper.sh [--pick|--random|--restore]
DIRS=("$HOME/10Hour/wallpapers" "$HOME/Imagens/wallpaper" "$HOME/hyprland-setup/wallpapers")
STATE=~/.cache/10hour-wallpaper
THEME="$(dirname "$(readlink -f "$0")")/../rofi/wallpaper.rasi"
TRANS=(grow wipe wave outer center any)

daemon() { pgrep -x awww-daemon >/dev/null || { setsid awww-daemon >/dev/null 2>&1 & sleep 0.6; }; }

set_wp() {
    daemon
    echo "$1" > "$STATE"
    awww img "$1" --transition-type "${TRANS[RANDOM % ${#TRANS[@]}]}" \
        --transition-duration 1.2 --transition-fps 144 --transition-step 60
}

files() { find "${DIRS[@]}" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' \) 2>/dev/null | sort; }

case ${1:---pick} in
    --restore) daemon; [[ -f $STATE ]] && set_wp "$(<"$STATE")" ;;
    --random)  f=$(files | shuf -n1); [[ $f ]] && set_wp "$f" ;;
    --pick)
        pkill -x rofi && exit
        sel=$(files | while read -r f; do printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"; done \
              | rofi -dmenu -i -show-icons -theme "$THEME" -p "wallpaper" -format i) || exit
        [[ -n $sel ]] && set_wp "$(files | sed -n "$((sel+1))p")" ;;
esac
