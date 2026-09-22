#!/usr/bin/env bash
# Install dependencies for this Hyprland rice on Fedora.
# Fonts, cursor theme and packages needed by hypr/, quickshell/, kitty/, rofi/,
# dunst/ and scripts/. Run this BEFORE ./install.sh.
set -euo pipefail

echo "==> Enabling the solopasha/hyprland COPR (Hyprland + ecosystem)"
sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y solopasha/hyprland

echo "==> Updating and installing packages"
sudo dnf install -y \
    hyprland hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland \
    kitty rofi dunst fastfetch \
    nautilus firefox \
    NetworkManager NetworkManager-wifi network-manager-applet \
    bluez bluez-tools blueman \
    wireplumber pavucontrol playerctl brightnessctl \
    wl-clipboard grim slurp wf-recorder jq \
    xdg-user-dirs polkit git golang cmake ninja-build gcc-c++ \
    jetbrains-mono-fonts-all

echo "==> Enabling NetworkManager and Bluetooth"
sudo systemctl enable --now NetworkManager.service bluetooth.service

# JetBrains Mono NERD font patch isn't in Fedora's package, fetch it directly
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

# cliphist (clipboard history used by keybinds) - no Fedora package, build with Go
if ! command -v cliphist >/dev/null; then
    echo "==> Installing cliphist via go install"
    go install github.com/sentriz/cliphist@latest
    echo "   -> add \$HOME/go/bin to your PATH if it isn't already"
fi

# Bibata cursor theme - no Fedora package, fetch the prebuilt release
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

NOTE: two pieces of this rice have no Fedora package and aren't auto-built here:

  - quickshell (the top bar / control panel) - build from source, see the
    project's own install docs for the Qt6/cmake/ninja build steps.
  - awww (the animated wallpaper daemon used by scripts/wallpaper.sh) - if you
    have your own fork/build, put its "awww"/"awww-daemon" binaries on PATH.
    Alternative: "swww" (build from source), adjusting scripts/wallpaper.sh.

Done. Next steps:
  1. Log into a Hyprland session.
  2. Run ./install.sh from this repo to symlink the configs into ~/.config.
EOF
