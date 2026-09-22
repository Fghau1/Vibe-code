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
- `install.sh` — symlinks the configs above into `~/.config`
- `install-arch.sh` / `install-debian.sh` / `install-fedora.sh` — install the system dependencies (Hyprland ecosystem, bar/launcher/notifications, fonts, cursor theme)

## Install

1. Install the dependencies for your distro:

   ```sh
   ./install-arch.sh     # Arch / Arch-based
   ./install-fedora.sh   # Fedora
   ./install-debian.sh   # Debian / Ubuntu
   ```

   Each script installs, per distro:
   - **Hyprland ecosystem**: `hyprland`, `hyprlock`, `hypridle`, `hyprpolkitagent`, `xdg-desktop-portal-hyprland` (Arch: official repos; Fedora: `solopasha/hyprland` COPR; Debian/Ubuntu: not packaged upstream, the script flags this so you can build from source)
   - **Bar / launcher / notifications**: `quickshell` (Arch via AUR; Fedora/Debian: build from source, flagged by the script), `rofi`, `dunst`, `kitty`, `fastfetch`
   - **System tools**: NetworkManager + applet, `bluez`/`blueman`, `wireplumber`, `pavucontrol`, `playerctl`, `brightnessctl`, `wl-clipboard`, `cliphist`, `grim`, `slurp`, `wf-recorder`, `jq`, `xdg-user-dirs`, `polkit`
   - **Apps**: `nautilus`, `firefox`
   - **Fonts**: JetBrainsMono Nerd Font
   - **Cursor theme**: Bibata-Modern-Ice
   - **"Extensions"**: none required — the rice has no GNOME Shell/browser extension dependency, everything above is a standalone package

   `awww` (the animated wallpaper daemon behind `scripts/wallpaper.sh`) has no
   distro package anywhere; the scripts just remind you to put your own
   build's `awww`/`awww-daemon` binaries on `PATH`, or swap in `swww`.

2. Log into a Hyprland session, then link the configs:

   ```sh
   ./install.sh
   ```
