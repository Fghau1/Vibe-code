#!/usr/bin/env bash
# Toggle the quickshell control panel (Wi-Fi, Bluetooth, volume, brightness).
#
# Note: quickshell only resolves named configs (-c NAME) under
# ~/.config/quickshell/NAME/ when there is no top-level ~/.config/quickshell/shell.qml.
# Since our main bar IS that top-level shell.qml, -c controlpanel can never be found -
# it must be launched by path (-p) instead.
CP_DIR="$(dirname "$(readlink -f "$0")")/../quickshell/controlpanel"
pkill -f "quickshell -p $CP_DIR" && exit
exec quickshell -p "$CP_DIR"
