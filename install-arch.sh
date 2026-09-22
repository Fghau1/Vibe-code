#!/usr/bin/env bash
# Install dependencies for this Hyprland rice on Arch Linux (and derivatives).
# Fonts, cursor theme and packages needed by hypr/, quickshell/, kitty/, rofi/,
# dunst/ and scripts/. Run this BEFORE ./install.sh.
set -euo pipefail

echo "==> Updating pacman database"
sudo pacman -Syu --needed --noconfirm

echo "==> Official repo packages"
sudo pacman -S --needed --noconfirm \
    hyprland hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland \
    kitty rofi dunst fastfetch \
    nautilus firefox \
    networkmanager network-manager-applet \
    bluez bluez-utils blueman \
    wireplumber pavucontrol playerctl brightnessctl \
    wl-clipboard grim slurp wf-recorder jq \
    xdg-user-dirs polkit git base-devel \
    ttf-jetbrains-mono-nerd

echo "==> Enabling NetworkManager and Bluetooth"
sudo systemctl enable --now NetworkManager.service bluetooth.service

# AUR helper (needed for quickshell, awww, cliphist, bibata cursor theme)
if ! command -v yay >/dev/null && ! command -v paru >/dev/null; then
    echo "==> No AUR helper found, building yay"
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
    (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmpdir"
fi
AUR=$(command -v yay || command -v paru)

echo "==> AUR packages (bar shell, wallpaper daemon, clipboard history, cursor theme)"
"$AUR" -S --needed --noconfirm \
    quickshell-git \
    cliphist \
    bibata-cursor-theme-bin

if ! command -v awww >/dev/null; then
    cat <<'EOF'

NOTE: "awww" (the animated wallpaper daemon used by scripts/wallpaper.sh)
is not in the official repos or AUR under that exact name. If you have your
own fork/build of it, install it manually and make sure the "awww" and
"awww-daemon" binaries are on your PATH. As a drop-in alternative you can
use "swww" (AUR/official: swww) and adjust scripts/wallpaper.sh accordingly.
EOF
fi

echo "==> Setting cursor theme"
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true

cat <<'EOF'

Done. Next steps:
  1. Log into a Hyprland session.
  2. Run ./install.sh from this repo to symlink the configs into ~/.config.
EOF
