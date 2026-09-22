import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray
import Quickshell.Widgets

ShellRoot {
    id: root

    property color fg: "#ffffff"
    property color dim: "#555555"
    property color barBg: "#000000"
    property color barBorder: "#333333"
    readonly property string font: "JetBrainsMono Nerd Font"

    // ── bar color themes ──
    readonly property var barThemes: ({
        "default":    { fg: "#ffffff", dim: "#555555", bg: "#000000", border: "#333333" },
        "gruvbox":    { fg: "#ebdbb2", dim: "#a89984", bg: "#282828", border: "#504945" },
        "retro":      { fg: "#39ff14", dim: "#5f5f7a", bg: "#0a0a12", border: "#00e5ff" },
        "everforest": { fg: "#d3c6aa", dim: "#7a8478", bg: "#2b3339", border: "#4a555b" },
        "nostalgic":  { fg: "#e8d5b5", dim: "#8a6d4a", bg: "#2b1d14", border: "#5a4632" }
    })
    function applyBarTheme(name) {
        const t = root.barThemes[name] || root.barThemes["default"]
        root.fg = t.fg; root.dim = t.dim; root.barBg = t.bg; root.barBorder = t.border
    }
    FileView {
        id: barThemeFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/bar-theme"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyBarTheme(text().trim())
        onLoadFailed: root.applyBarTheme("default")
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int volume: audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false
    readonly property var bat: UPower.displayDevice
    readonly property bool hasBat: bat && bat.isLaptopBattery
    property int brightness: -1

    // ── pill / expand state ──
    property bool barPinned: true
    property bool autoExpanded: false
    readonly property bool expanded: barPinned || autoExpanded
    Timer { id: collapseTimer; interval: 900; onTriggered: root.autoExpanded = false }
    function peek() { root.autoExpanded = true; collapseTimer.restart() }

    // ── dock ──
    readonly property var pinned: [
        { cls: "kitty",               icon: "kitty",               cmd: "kitty" },
        { cls: "app.zen_browser.zen", icon: "app.zen_browser.zen", cmd: "flatpak run app.zen_browser.zen" },
        { cls: "firefox",             icon: "firefox",             cmd: "firefox" },
        { cls: "org.gnome.Nautilus",  icon: "org.gnome.Nautilus",  cmd: "nautilus" },
        { cls: "discord",             icon: "discord",             cmd: "discord" },
        { cls: "spotify",             icon: "spotify",             cmd: "spotify" },
        { cls: "steam",               icon: "steam",               cmd: "steam" }
    ]
    property var runningClasses: []
    readonly property var dockItems: {
        const items = pinned.map(p => ({ cls: p.cls, icon: p.icon, cmd: p.cmd, running: runningClasses.indexOf(p.cls) >= 0 }))
        for (const c of runningClasses)
            if (!pinned.some(p => p.cls === c)) items.push({ cls: c, icon: c.toLowerCase(), cmd: "", running: true })
        return items
    }
    function updateRunning() {
        const s = []
        for (const t of Hyprland.toplevels.values) {
            const c = t.lastIpcObject ? t.lastIpcObject.class : ""
            if (c && s.indexOf(c) < 0) s.push(c)
        }
        runningClasses = s
    }
    Component.onCompleted: { Hyprland.refreshToplevels(); dockSync.restart() }
    Timer { id: dockSync; interval: 250; onTriggered: root.updateRunning() }
    Timer { id: dockRefresh; interval: 150; onTriggered: { Hyprland.refreshToplevels(); dockSync.restart() } }
    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "openwindow" || ev.name === "closewindow") dockRefresh.restart()
            if (ev.name === "workspace" || ev.name === "workspacev2") root.peek()
        }
    }

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    SystemClock { id: clock; precision: SystemClock.Minutes }

    // ── media (mpris) ──
    readonly property var activePlayer: {
        const list = Mpris.players.values
        for (const p of list) if (p.isPlaying) return p
        return list.length > 0 ? list[0] : null
    }

    // ── network ──
    property string netKind: ""
    property int netSignal: 0
    Process {
        id: netGet
        command: ["sh", "-c", `
echo "T $(nmcli -t -f TYPE,STATE device status 2>/dev/null | awk -F: '$2=="connected"{print $1; exit}')"
echo "S $(nmcli -t -f active,signal dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}')"
`]
        stdout: StdioCollector {
            onStreamFinished: {
                let kind = "", sig = 0
                for (const line of text.split("\n")) {
                    const t = line.substring(0, 2), v = line.substring(2).trim()
                    if (t === "T ") kind = (v === "wifi" || v === "ethernet") ? v : ""
                    else if (t === "S ") sig = parseInt(v) || 0
                }
                root.netKind = kind
                root.netSignal = sig
            }
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: netGet.running = true }
    function openControlPanel() { Quickshell.execDetached(["sh", "-c", "$HOME/10Hour/scripts/controlpanel.sh"]) }

    // ── battery details ──
    function batteryIcon() {
        if (!root.bat) return "󰂑"
        const p = Math.round(root.bat.percentage * 100)
        if (root.bat.state === UPowerDeviceState.Charging) return "󰂄"
        if (p >= 95) return "󰁹"
        if (p >= 80) return "󰂀"
        if (p >= 60) return "󰁾"
        if (p >= 40) return "󰁼"
        if (p >= 20) return "󰁺"
        return "󰂎"
    }
    readonly property string batStateLabel: {
        if (!root.bat) return ""
        if (root.bat.state === UPowerDeviceState.Charging) return "Charging"
        if (root.bat.state === UPowerDeviceState.FullyCharged) return "Fully charged"
        if (root.bat.state === UPowerDeviceState.Discharging) return "Discharging"
        return ""
    }
    readonly property string batTimeLabel: {
        if (!root.bat) return ""
        const charging = root.bat.state === UPowerDeviceState.Charging
        const sec = charging ? root.bat.timeToFull : root.bat.timeToEmpty
        if (!sec || sec <= 0) return ""
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60)
        return (h > 0 ? h + "h " + m + "m " : m + "m ") + (charging ? "until full" : "remaining")
    }

    Process {
        id: brightGet
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector { onStreamFinished: { const v = parseInt(text); root.brightness = isNaN(v) ? -1 : v } }
    }
    Timer { interval: 2000; running: true; repeat: true; triggeredOnStart: true; onTriggered: brightGet.running = true }
    Timer { id: briNudge; interval: 150; onTriggered: osdBright.running = true }

    // ---- OSD (volume / brightness) ----
    property string osdKind: "volume"
    property int osdValue: 0
    property bool osdMuted: false
    property bool osdShown: false
    property bool osdReady: false

    Timer { id: osdHide; interval: 1400; onTriggered: root.osdShown = false }

    function showOsd(kind, value, muted) {
        osdKind = kind
        osdValue = Math.max(0, Math.min(100, value))
        osdMuted = muted
        osdShown = true
        osdHide.restart()
    }

    Connections {
        target: root.audio
        function onVolumeChanged() { if (root.osdReady) root.showOsd("volume", root.volume, root.muted) }
        function onMutedChanged() { if (root.osdReady) root.showOsd("volume", root.volume, root.muted) }
    }

    Process {
        id: osdBright
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text)
                if (!isNaN(v)) { root.brightness = v; root.showOsd("brightness", v, false) }
            }
        }
    }

    IpcHandler {
        target: "osd"
        function brightness(): void { osdBright.running = true }
    }

    IpcHandler {
        target: "dock"
        function toggle(): void { root.barPinned = !root.barPinned }
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            anchors { bottom: true }
            margins { bottom: 80 }
            implicitWidth: 280
            implicitHeight: 40
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}
            visible: card.opacity > 0

            Rectangle {
                id: card
                anchors.fill: parent
                color: root.barBg
                radius: 8
                border.width: 1
                border.color: root.barBorder
                opacity: root.osdShown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Rectangle {
                    id: track
                    anchors { fill: parent; margins: 8 }
                    radius: 6
                    color: "#222222"
                    readonly property string icon: root.osdKind === "brightness" ? "" : (root.osdMuted || root.osdValue === 0 ? "" : (root.osdValue < 50 ? "" : ""))
                    Txt {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        text: track.icon
                        font.pixelSize: 16
                        color: root.fg
                    }
                    Rectangle {
                        height: parent.height
                        radius: 6
                        clip: true
                        width: parent.width * (root.osdMuted ? 0 : root.osdValue) / 100
                        color: root.fg
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        Txt {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: track.icon
                            font.pixelSize: 16
                            color: "#000000"
                        }
                    }
                }
            }
        }
    }

    component Txt: Text {
        color: root.fg
        font.family: root.font
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
    }

    component Divider: Rectangle {
        width: 1; height: 14
        color: root.dim
        opacity: 0.6
        anchors.verticalCenter: parent.verticalCenter
    }

    Variants {
        model: Quickshell.screens
        delegate: PanelWindow {
            id: barWin
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            margins { top: 6; left: Math.round(modelData.width * 0.25); right: Math.round(modelData.width * 0.25) }
            implicitHeight: 34
            color: "transparent"

            // full-width hover zone: moving the cursor anywhere onto the bar row reveals it
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onEntered: { root.autoExpanded = true; collapseTimer.stop() }
                onExited: collapseTimer.restart()
            }

            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                height: parent.height
                width: root.expanded ? parent.width : (clockTxt.implicitWidth + 40)
                clip: true
                color: root.barBg
                radius: root.expanded ? 8 : height / 2
                border.width: 1
                border.color: root.barBorder
                Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutExpo } }
                Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutExpo } }

                // left: menu button (circle) + workspaces + dock
                Item {
                    id: menuBtn
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 22; height: 22
                    opacity: root.expanded ? 1 : 0
                    visible: opacity > 0.01
                    enabled: root.expanded
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.centerIn: parent
                        width: mbArea.containsMouse ? 14 : 12
                        height: width
                        radius: width / 2
                        color: mbArea.containsMouse ? root.fg : "transparent"
                        border.width: 2
                        border.color: mbArea.containsMouse ? root.fg : root.dim
                        Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        id: mbArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["sh", "-c", "pkill -x rofi || rofi -show drun"])
                    }
                }

                Row {
                    id: leftRow
                    anchors { left: menuBtn.right; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    spacing: 12
                    opacity: root.expanded ? 1 : 0
                    visible: opacity > 0.01
                    enabled: root.expanded
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                    // workspaces
                    Row {
                        id: wsRow
                        spacing: 10
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: 5
                            delegate: Item {
                                id: dot
                                required property int index
                                readonly property int wid: index + 1
                                readonly property bool active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wid
                                width: 16; height: 30
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: dot.active ? 14 : 6
                                    height: 6
                                    radius: 3
                                    color: dot.active ? root.fg : root.dim
                                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + dot.wid + " })")
                                }
                            }
                        }
                    }

                    Divider { visible: root.dockItems.length > 0 }

                    // running-app dock
                    Row {
                        id: dockRow
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: root.dockItems
                            delegate: Item {
                                id: dItem
                                required property var modelData
                                width: 20; height: 30
                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 18
                                    source: Quickshell.iconPath(dItem.modelData.icon, "application-x-executable")
                                    opacity: dItem.modelData.running ? 1 : 0.55
                                    Behavior on opacity { NumberAnimation { duration: 160 } }
                                }
                                Rectangle {
                                    visible: dItem.modelData.running
                                    width: 4; height: 4; radius: 2
                                    color: root.fg
                                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 2 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (dItem.modelData.running)
                                            Hyprland.dispatch('hl.dsp.exec_raw("focuswindow", "class:^(' + dItem.modelData.cls + ')$")')
                                        else if (dItem.modelData.cmd)
                                            Quickshell.execDetached(["sh", "-c", dItem.modelData.cmd]) }
                                }
                            }
                        }
                    }
                }

                // center: clock
                Item {
                    id: clockItem
                    anchors.centerIn: parent
                    width: clockTxt.implicitWidth + 16
                    height: parent.height
                    Txt {
                        id: clockTxt
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                    }
                    HoverHandler { id: clockHover }

                    PopupWindow {
                        id: calPopup
                        anchor.item: clockItem
                        anchor.edges: Edges.Bottom
                        anchor.gravity: Edges.Bottom
                        anchor.margins.top: 6
                        implicitWidth: 240
                        implicitHeight: calCol.implicitHeight + 24
                        color: "transparent"
                        visible: clockHover.hovered

                        Rectangle {
                            anchors.fill: parent
                            color: root.barBg
                            radius: 8
                            border.width: 1
                            border.color: root.barBorder

                            Column {
                                id: calCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 8

                                readonly property date now: clock.date
                                readonly property int year: now.getFullYear()
                                readonly property int month: now.getMonth()
                                readonly property int today: now.getDate()
                                // Monday-first offset of the 1st
                                readonly property int offset: (new Date(year, month, 1).getDay() + 6) % 7
                                readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

                                Txt {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Qt.formatDate(calCol.now, "MMMM yyyy")
                                    font.bold: true
                                }
                                Grid {
                                    columns: 7
                                    width: parent.width
                                    Repeater {
                                        model: ["S", "T", "Q", "Q", "S", "S", "D"]
                                        delegate: Txt {
                                            required property string modelData
                                            width: calCol.width / 7
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData
                                            color: root.dim
                                        }
                                    }
                                    Repeater {
                                        model: 42
                                        delegate: Item {
                                            id: cell
                                            required property int index
                                            readonly property int day: index - calCol.offset + 1
                                            readonly property bool valid: day >= 1 && day <= calCol.daysInMonth
                                            readonly property bool isToday: valid && day === calCol.today
                                            width: calCol.width / 7
                                            height: 26
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 24; height: 24; radius: 12
                                                visible: cell.isToday
                                                color: root.fg
                                            }
                                            Txt {
                                                anchors.centerIn: parent
                                                visible: cell.valid
                                                text: cell.day
                                                color: cell.isToday ? "#000000" : root.fg
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // right: media + tray + network + status + pin + power
                Row {
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    spacing: 10
                    opacity: root.expanded ? 1 : 0
                    visible: opacity > 0.01
                    enabled: root.expanded
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                    // now playing — icons only; hover for track details
                    Row {
                        id: mediaRow
                        visible: root.activePlayer !== null
                        spacing: 6
                        anchors.verticalCenter: parent.verticalCenter
                        Txt {
                            text: "󰒮"
                            font.pixelSize: 13
                            color: (root.activePlayer && root.activePlayer.canGoPrevious) ? root.fg : root.dim
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
                            }
                        }
                        Item {
                            width: playTxt.implicitWidth; height: playTxt.implicitHeight
                            Txt {
                                id: playTxt
                                text: (root.activePlayer && root.activePlayer.isPlaying) ? "󰏤" : "󰐊"
                                font.pixelSize: 13
                            }
                            HoverHandler { id: mediaHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                            }
                            PopupWindow {
                                id: mediaPopup
                                anchor.item: mediaRow
                                anchor.edges: Edges.Bottom
                                anchor.gravity: Edges.Bottom
                                anchor.margins.top: 6
                                implicitWidth: Math.min(280, Math.max(140, medCol.implicitWidth + 24))
                                implicitHeight: medCol.implicitHeight + 24
                                color: "transparent"
                                visible: mediaHover.hovered && root.activePlayer !== null
                                Rectangle {
                                    anchors.fill: parent
                                    color: root.barBg
                                    radius: 8
                                    border.width: 1
                                    border.color: root.barBorder
                                    Column {
                                        id: medCol
                                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                        spacing: 2
                                        Txt {
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
                                            text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown title") : ""
                                        }
                                        Txt {
                                            visible: root.activePlayer && root.activePlayer.trackArtist
                                            elide: Text.ElideRight
                                            width: parent.width
                                            color: root.dim
                                            font.pixelSize: 12
                                            text: root.activePlayer ? root.activePlayer.trackArtist : ""
                                        }
                                    }
                                }
                            }
                        }
                        Txt {
                            text: "󰒭"
                            font.pixelSize: 13
                            color: (root.activePlayer && root.activePlayer.canGoNext) ? root.fg : root.dim
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
                            }
                        }
                    }
                    Divider { visible: root.activePlayer !== null }

                    // system tray
                    Row {
                        id: trayRow
                        visible: SystemTray.items.values.length > 0
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: SystemTray.items
                            delegate: Item {
                                id: trayItem
                                required property var modelData
                                width: 16; height: 16
                                anchors.verticalCenter: parent.verticalCenter
                                IconImage { anchors.fill: parent; implicitSize: 16; source: trayItem.modelData.icon }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (m) => {
                                        if (m.button === Qt.LeftButton) trayItem.modelData.activate()
                                        else trayItem.modelData.secondaryActivate()
                                    }
                                }
                            }
                        }
                    }
                    Divider { visible: trayRow.visible }

                    // network
                    Item {
                        width: netTxt.implicitWidth + 4; height: 22
                        Txt {
                            id: netTxt
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.netKind === "wifi" ? (root.netSignal > 66 ? "󰤨" : root.netSignal > 33 ? "󰤥" : "󰤟")
                                  : root.netKind === "ethernet" ? "󰈀" : "󰤭"
                            color: root.netKind ? root.fg : root.dim
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openControlPanel()
                        }
                    }

                    // brightness
                    Item {
                        visible: root.brightness >= 0
                        width: visible ? briTxt.implicitWidth + 4 : 0; height: 22
                        Txt { id: briTxt; anchors.verticalCenter: parent.verticalCenter; text: "󰃟 " + root.brightness }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openControlPanel()
                            onWheel: (w) => {
                                Quickshell.execDetached(["brightnessctl", "-q", "set", w.angleDelta.y > 0 ? "5%+" : "5%-"])
                                briNudge.restart()
                            }
                        }
                    }

                    // volume
                    Item {
                        width: volTxt.implicitWidth + 4; height: 22
                        Txt {
                            id: volTxt
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.muted ? "󰝟" : (root.volume > 66 ? "󰕾" : root.volume > 33 ? "󰖀" : root.volume > 0 ? "󰕿" : "󰝟")) + " " + root.volume
                            color: root.muted ? root.dim : root.fg
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                            onWheel: (w) => {
                                if (w.angleDelta.y > 0) Quickshell.execDetached(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"])
                                else Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
                            }
                        }
                    }

                    // battery
                    Item {
                        id: batItem
                        visible: root.hasBat
                        width: visible ? batTxt.implicitWidth + 4 : 0; height: 22
                        Txt {
                            id: batTxt
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.batteryIcon() + " " + (root.bat ? Math.round(root.bat.percentage * 100) : 0)
                            color: (root.bat && root.bat.percentage <= 0.2 && root.bat.state !== UPowerDeviceState.Charging) ? "#ff5f5f" : root.fg
                        }
                        HoverHandler { id: batHover }
                        PopupWindow {
                            id: batPopup
                            anchor.item: batItem
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            anchor.margins.top: 6
                            implicitWidth: 190
                            implicitHeight: batCol.implicitHeight + 24
                            color: "transparent"
                            visible: batHover.hovered
                            Rectangle {
                                anchors.fill: parent
                                color: root.barBg
                                radius: 8
                                border.width: 1
                                border.color: root.barBorder
                                Column {
                                    id: batCol
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                    spacing: 4
                                    Txt {
                                        font.bold: true
                                        text: (root.bat ? Math.round(root.bat.percentage * 100) : 0) + "%" + (root.batStateLabel ? "  ·  " + root.batStateLabel : "")
                                    }
                                    Txt { visible: root.batTimeLabel !== ""; text: root.batTimeLabel; color: root.dim; font.pixelSize: 12 }
                                }
                            }
                        }
                    }

                    Divider {}

                    // power menu
                    Item {
                        width: 20; height: 22
                        Txt {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.pixelSize: 14
                            color: pwrArea.containsMouse ? root.fg : root.dim
                        }
                        MouseArea {
                            id: pwrArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Quickshell.execDetached(["sh", "-c", "loginctl terminate-user $USER"])
                        }
                    }
                }
            }
        }
    }
}
