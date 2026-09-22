#!/usr/bin/env bash
# Install dependencies for this Hyprland rice on Debian / Ubuntu (and derivatives).
# Fonts, cursor theme and packages needed by hypr/, quickshell/, kitty/, rofi/,
# dunst/ and scripts/. Run this BEFORE ./install.sh.
#
# Hyprland moves fast and isn't packaged in Debian/Ubuntu stable repos, so
# this script installs everything that IS packaged and clearly flags what
# you'll need to build yourself.
set -euo pipefail

echo "==> Updating apt"
sudo apt update

echo "==> Installing packages available in Debian/Ubuntu repos"
sudo apt install -y \
    kitty rofi dunst fastfetch \
    nautilus firefox \
    network-manager network-manager-gnome \
    bluez blueman \
    wireplumber pavucontrol playerctl brightnessctl \
    wl-clipboard grim slurp wf-recorder jq \
    xdg-user-dirs policykit-1 git build-essential \
    golang cmake ninja-build qt6-base-dev qt6-declarative-dev \
    curl unzip fontconfig

echo "==> Enabling NetworkManager and Bluetooth"
sudo systemctl enable --now NetworkManager.service bluetooth.service

# JetBrainsMono Nerd Font
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
if [[ ! -d "$FONT_DIR" ]]; then
    echo "==> Installing JetBrainsMono Nerd Font"
    mkdir -p "$FONT_DIR"
    tmpzip=$(mktemp)
    curl -fL -o "$tmpzip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
    unzip -oq "$tmpzip" -d "$FONT_DIR"
    rm -f "$tmpzip"
    fc-cache -f "$FONT_DIR"
fi

# cliphist
if ! command -v cliphist >/dev/null; then
    echo "==> Installing cliphist via go install"
    go install github.com/sentriz/cliphist@latest
    echo "   -> add \$HOME/go/bin to your PATH if it isn't already"
fi

# Bibata cursor theme
CURSOR_DIR="$HOME/.local/share/icons/Bibata-Modern-Ice"
if [[ ! -d "$CURSOR_DIR" ]]; then
    echo "==> Installing Bibata-Modern-Ice cursor theme"
    tmptar=$(mktemp --suffix=.tar.xz)
    curl -fL -o "$tmptar" \
        https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz
    mkdir -p "$HOME/.local/share/icons"
    tar -xf "$tmptar" -C "$HOME/.local/share/icons"
    rm -f "$tmptar"
fi
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' 2>/dev/null || true

cat <<'EOF'

NOT installed by this script (no Debian/Ubuntu package - build from source):

  - Hyprland, hyprlock, hypridle, hyprpolkitagent, xdg-desktop-portal-hyprland
    See the official Hyprland wiki for the manual build steps on Debian/Ubuntu.
  - quickshell (the top bar / control panel) - Qt6 dev packages above are
    installed as build dependencies; see the project's own install docs for
    the cmake/ninja build steps.
  - awww (the animated wallpaper daemon used by scripts/wallpaper.sh) - if you
    have your own fork/build, put its "awww"/"awww-daemon" binaries on PATH.
    Alternative: "swww" (build from source), adjusting scripts/wallpaper.sh.

Done. Next steps:
  1. Build/install the pieces listed above, then log into a Hyprland session.
  2. Run ./install.sh from this repo to symlink the configs into ~/.config.
EOF
