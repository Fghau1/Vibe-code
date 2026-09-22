#!/usr/bin/env bash
# Rofi menu: jump to a running AI coding agent session (Claude Code, Codex, ...),
# or launch a new one if none are running. (SUPER + M -> AI agents)
THEME="$(dirname "$(readlink -f "$0")")/../rofi/10hour.rasi"
AGENTS='claude|codex|aider|opencode|cursor-agent|amp|gemini|goose'

# pid -> "address<TAB>title" for every Hyprland window
declare -A win
while IFS=$'\t' read -r pid addr title; do
    [[ -n $pid ]] && win["$pid"]="$addr"$'\t'"$title"
done < <(hyprctl clients -j | jq -r '.[] | "\(.pid)\t\(.address)\t\(.title)"' 2>/dev/null)

# walk up the process tree from an agent pid to find the window that owns it
find_window() {
    local p=$1 hops=0
    while [[ -n $p && $p != 0 && $hops -lt 10 ]]; do
        [[ -n ${win[$p]:-} ]] && { printf '%s' "$p"; return 0; }
        p=$(awk '{print $4}' "/proc/$p/stat" 2>/dev/null)
        ((hops++))
    done
    return 1
}

entries=() addrs=()
declare -A done_pid
while read -r pid; do
    [[ -n ${done_pid[$pid]:-} ]] && continue
    done_pid[$pid]=1
    name=$(ps -o comm= -p "$pid" 2>/dev/null) || continue
    wpid=$(find_window "$pid") || continue
    IFS=$'\t' read -r addr title <<< "${win[$wpid]}"
    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null)
    entries+=("󰚩  $name  ·  ${cwd##*/}")
    addrs+=("$addr")
done < <(pgrep -f "(^|/)($AGENTS)( |\$)" 2>/dev/null)

if [[ ${#entries[@]} -eq 0 ]]; then
    c=$(printf '%s\n' "Nenhum agente em execução" "󰐊  Lançar Claude Code" \
        | rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 340px;}' -p "󰚩") || exit
    [[ $c == *"Lançar"* ]] && exec kitty --title scratchpad claude
    exit
fi

choice=$(printf '%s\n' "${entries[@]}" \
    | rofi -dmenu -i -theme "$THEME" -theme-str 'window {width: 380px;}' -p "󰚩") || exit
[[ -z $choice ]] && exit

for i in "${!entries[@]}"; do
    if [[ ${entries[$i]} == "$choice" ]]; then
        hyprctl dispatch focuswindow "address:${addrs[$i]}" >/dev/null
        exit
    fi
done
