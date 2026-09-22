#!/usr/bin/env bash
# Toggle the quickshell control panel (Wi-Fi, Bluetooth, volume, brightness)
# and expand/collapse the dock alongside it.
quickshell ipc call dock toggle
pkill -f 'quickshell.*-c controlpanel' && exit
exec quickshell -c controlpanel
