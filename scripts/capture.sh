#!/usr/bin/env bash
set -euo pipefail
notify() { notify-send -a 'Screen Capture' -i "$1" "$2" "${3:-}" || true; }
fail() { notify dialog-error 'Capture failed' "$1"; exit 1; }
mode=${1:-screenshot}
unit=hypr-screen-recorder.service
exec 9>"${XDG_RUNTIME_DIR:?}/hypr-capture.lock"
flock -n 9 || exit 0
case "$mode" in
    screenshot)
        geometry=$(slurp) || exit 0
        [[ -n "$geometry" ]] || exit 0
        dir="$(xdg-user-dir PICTURES)/Screenshots"
        mkdir -p "$dir"
        file="$dir/Screenshot-$(date +%Y-%m-%d_%H-%M-%S-%N).png"
        grim -g "$geometry" "$file" || fail 'Could not save screenshot.'
        wl-copy --type image/png < "$file" || fail "Saved to $file, but clipboard copy failed."
        notify hypr-screenshot 'Screenshot saved and copied' "$file"
        ;;
    record)
        if systemctl --user is-active --quiet "$unit"; then
            systemctl --user stop "$unit" || fail 'Could not stop the recorder.'
            notify hypr-screen-recorder 'Recording saved' "$(xdg-user-dir VIDEOS)/Recordings"
            exit 0
        fi
        command -v wf-recorder >/dev/null || fail 'Install the recorder: sudo pacman -S --needed wf-recorder'
        geometry=$(slurp) || exit 0
        [[ -n "$geometry" ]] || exit 0
        dir="$(xdg-user-dir VIDEOS)/Recordings"
        mkdir -p "$dir"
        file="$dir/Recording-$(date +%Y-%m-%d_%H-%M-%S-%N).mp4"
        systemd-run --user --collect --unit="$unit" --property=Type=exec \
            --property=KillSignal=SIGINT --property=TimeoutStopSec=30 \
            /usr/bin/wf-recorder -g "$geometry" -f "$file" || fail 'Could not start recorder.'
        sleep 1
        systemctl --user is-active --quiet "$unit" || fail 'Recorder exited. See journalctl --user -u hypr-screen-recorder.'
        notify hypr-screen-recorder 'Recording started' 'Press Super+Shift+R or launch Screen Recorder again to stop.'
        ;;
    *) fail 'Unknown capture action.' ;;
esac
