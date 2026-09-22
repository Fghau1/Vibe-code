#!/usr/bin/env bash
# Link the 10Hour configs into ~/.config (existing dirs are moved to *.bak)
cd "$(dirname "$(readlink -f "$0")")"
for d in hypr kitty rofi quickshell dunst fastfetch; do
    t=~/.config/$d
    [[ -e $t || -L $t ]] && mv "$t" "$t.bak-$(date +%s)"
    ln -s "$PWD/$d" "$t"
done
pkill -USR1 kitty; pkill dunst; (dunst &) ; pkill -x quickshell; (quickshell &>/dev/null &)
