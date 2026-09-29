#!/usr/bin/env bash
# Animated wallpaper picker (awww: animated transitions + GIF wallpapers)
# usage: wallpaper.sh [--pick|--random|--restore]
DIRS=("$HOME/Imagens")
STATE=~/.cache/10hour-wallpaper
THEME="$(dirname "$(readlink -f "$0")")/../rofi/wallpaper.rasi"
TRANS=(grow wipe wave outer center any)

daemon() { pgrep -x awww-daemon >/dev/null || { setsid awww-daemon >/dev/null 2>&1 & sleep 0.6; }; }

is_video() { case "$1" in *.mp4|*.MP4|*.mkv|*.MKV|*.webm|*.WEBM) return 0 ;; *) return 1 ;; esac }

set_wp() {
    if is_video "$1"; then
        pkill -x mpvpaper 2>/dev/null
        pkill -x awww-daemon 2>/dev/null
        echo "$1" > "$STATE"
        mpvpaper -f -p -o "no-audio loop-playlist" ALL "$1" >/dev/null 2>&1
    elif command -v awww >/dev/null; then
        pkill -x mpvpaper 2>/dev/null
        pkill -x hyprpaper 2>/dev/null
        daemon
        echo "$1" > "$STATE"
        awww img "$1" --transition-type "${TRANS[RANDOM % ${#TRANS[@]}]}" \
            --transition-duration 1.2 --transition-fps 144 --transition-step 60
    else
        # fallback: hyprpaper (no transitions)
        pkill -x mpvpaper 2>/dev/null
        pgrep -x hyprpaper >/dev/null || { setsid hyprpaper >/dev/null 2>&1 & sleep 0.6; }
        echo "$1" > "$STATE"
        for m in $(hyprctl monitors | awk '/^Monitor/{print $2}'); do
            hyprctl hyprpaper wallpaper "$m,$1" >/dev/null
        done
    fi
}

files() { find "${DIRS[@]}" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) 2>/dev/null | sort; }

case ${1:---pick} in
    --restore) daemon; [[ -f $STATE ]] && set_wp "$(<"$STATE")" ;;
    --random)  f=$(files | shuf -n1); [[ $f ]] && set_wp "$f" ;;
    --pick)
        pkill -x rofi && exit
        sel=$(files | while read -r f; do printf '%s\0icon\x1f%s\n' "$(basename "$f")" "$f"; done \
              | rofi -dmenu -i -show-icons -theme "$THEME" -p "wallpaper" -format i) || exit
        [[ -n $sel ]] && set_wp "$(files | sed -n "$((sel+1))p")" ;;
esac
