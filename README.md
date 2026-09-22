# Vibe-code — Hyprland desktop

Backup of my current Arch + Hyprland desktop (Lua-based `hyprland.lua` config). This is a snapshot of what's actually running, taken from `~/.config/*` (symlinked to `~/10Hour`) on 2026-09-22.

## Layout

- `hypr/` — Hyprland config (`hyprland.lua`) and `hyprlock.conf`
- `quickshell/` — top bar and control panel (QML)
- `kitty/` — terminal config and theme
- `rofi/` — launcher themes (10hour, tokyo, wallpaper picker)
- `dunst/` — notification daemon config
- `fastfetch/` — system info config
- `scripts/` — helper scripts wired into Hyprland keybinds (powermenu, wifi/bluetooth menus, wallpaper switcher, OSD, AI-agent launcher, etc.)
- `wallpapers/` — wallpaper thumbnail(s)
- `install.sh` — installer script

## Install

```sh
./install.sh
```
