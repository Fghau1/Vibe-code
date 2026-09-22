import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Painel de controlo (popup): Wi-Fi, Bluetooth, volume, brilho.
// Abrir/fechar: ~/10Hour/scripts/controlpanel.sh (SUPER+C). Esc ou clique fora fecha.
ShellRoot {
    id: root

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property color fg: "#ffffff"
    readonly property color dim: "#666666"
    readonly property color line: "#2a2a2a"
    readonly property color hover: "#161616"

    property bool wifiOn: false
    property bool btOn: false
    property var nets: []
    property var devs: []
    property var known: []
    property int vol: 0
    property bool muted: false
    property int bri: -1
    property string pwSsid: ""
    property bool btScanning: false
    property double dragUntil: 0

    function sh(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); after.restart() }
    function refresh() { if (!poll.running) poll.running = true }

    function parse(text) {
        const nets = {}, devs = [], known = []
        for (const line of text.split("\n")) {
            const t = line.substring(0, 2), v = line.substring(2)
            if (t === "R ") root.wifiOn = v.trim() === "enabled"
            else if (t === "B ") root.btOn = v.trim() === "yes"
            else if (t === "V " && Date.now() > root.dragUntil) {
                root.muted = v.endsWith("m"); root.vol = parseInt(v) || 0
            } else if (t === "L " && Date.now() > root.dragUntil) {
                const n = parseInt(v); root.bri = isNaN(n) ? -1 : n
            } else if (t === "K ") known.push(v)
            else if (t === "W ") {
                const p = v.split(":")
                const ssid = p.slice(3).join(":").replace(/\\:/g, ":")
                if (!ssid) continue
                const n = { ssid: ssid, active: p[0] === "*", signal: parseInt(p[1]) || 0, secure: p[2] !== "" && p[2] !== "--" }
                const o = nets[ssid]
                if (!o || n.active || (!o.active && n.signal > o.signal)) nets[ssid] = n
            } else if (t === "D ") {
                const p = v.split("|")
                devs.push({ mac: p[0], paired: p[1] === "yes", connected: p[2] === "yes", name: p.slice(3).join("|") })
            }
        }
        root.nets = Object.values(nets).sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
        root.devs = devs.sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
        root.known = known
    }

    function wifiClick(n) {
        if (n.active) { sh("nmcli con down id '" + n.ssid.replace(/'/g, "'\\''") + "'"); return }
        const q = "'" + n.ssid.replace(/'/g, "'\\''") + "'"
        if (!n.secure) sh("nmcli dev wifi connect " + q + " || notify-send Wi-Fi 'Falha ao ligar'")
        else if (root.known.indexOf(n.ssid) >= 0) sh("nmcli con up id " + q + " || notify-send Wi-Fi 'Falha ao ligar'")
        else root.pwSsid = (root.pwSsid === n.ssid) ? "" : n.ssid
    }
    function wifiPass(ssid, pw) {
        const q = s => "'" + s.replace(/'/g, "'\\''") + "'"
        root.pwSsid = ""
        sh("nmcli dev wifi connect " + q(ssid) + " password " + q(pw) + " || notify-send Wi-Fi 'Palavra-passe errada ou falha ao ligar'")
    }
    function btClick(d) {
        if (d.connected) sh("bluetoothctl disconnect " + d.mac)
        else if (d.paired) sh("bluetoothctl connect " + d.mac + " || notify-send Bluetooth 'Falha ao ligar'")
        else sh("bluetoothctl pair " + d.mac + " && bluetoothctl trust " + d.mac + " && bluetoothctl connect " + d.mac + " || notify-send Bluetooth 'Falha ao emparelhar'")
    }

    Process {
        id: poll
        command: ["sh", "-c", `
echo "R $(nmcli radio wifi)"
echo "B $(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')"
echo "V $(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{v=int($2*100+0.5); print v ($3=="[MUTED]"?"m":"")}')"
echo "L $(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d %)"
nmcli -t -f NAME,TYPE con show | awk -F: '$NF=="802-11-wireless"{sub(/:802-11-wireless$/,""); print "K " $0}'
nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list 2>/dev/null | sed 's/^/W /'
bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
  i=$(bluetoothctl info "$mac" 2>/dev/null)
  p=$(echo "$i" | awk '/Paired:/{print $2}'); c=$(echo "$i" | awk '/Connected:/{print $2}')
  echo "D $mac|$p|$c|$name"
done`]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer { interval: 4000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Timer { id: after; interval: 1500; onTriggered: root.refresh() }
    Timer { id: scanEnd; interval: 20000; onTriggered: root.btScanning = false }

    component Txt: Text {
        color: root.fg
        font.family: root.font
        font.pixelSize: 13
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    component Toggle: Rectangle {
        id: tg
        property bool on: false
        signal toggled()
        width: 40; height: 22; radius: 11
        color: on ? "#ffffff" : "#222222"
        Rectangle {
            width: 16; height: 16; radius: 8; y: 3
            x: tg.on ? 21 : 3
            color: tg.on ? "#000000" : "#777777"
            Behavior on x { NumberAnimation { duration: 120 } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.toggled() }
    }

    component Slider: Item {
        id: sl
        property int value: 0
        signal moved(int v)
        height: 22
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2; color: "#222222"
            Rectangle { width: parent.width * sl.value / 100; height: parent.height; radius: 2; color: "#ffffff" }
        }
        Rectangle {
            x: (sl.width - 14) * sl.value / 100
            anchors.verticalCenter: parent.verticalCenter
            width: 14; height: 14; radius: 7; color: "#ffffff"
        }
        MouseArea {
            anchors.fill: parent
            function upd(m) { sl.moved(Math.max(0, Math.min(100, Math.round(m.x / width * 100)))) }
            onPressed: m => upd(m)
            onPositionChanged: m => upd(m)
        }
    }

    component SmallBtn: Rectangle {
        id: sb
        property string label: ""
        signal clicked()
        height: 24; width: t.implicitWidth + 20; radius: 6
        color: ma.containsMouse ? "#222222" : "transparent"
        border.width: 1; border.color: root.line
        Txt { id: t; anchors.centerIn: parent; text: sb.label; font.pixelSize: 11; color: root.dim }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sb.clicked() }
    }

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "controlpanel"

        MouseArea { anchors.fill: parent; onClicked: Qt.quit() }

        Rectangle {
            id: panel
            width: 380
            height: col.implicitHeight + 32
            x: parent.width - width - 12
            y: 44
            color: "#000000"
            radius: 10
            border.width: 1; border.color: "#333333"
            focus: true
            Keys.onEscapePressed: Qt.quit()

            MouseArea { anchors.fill: parent }  // engole cliques dentro do painel

            Column {
                id: col
                x: 16; y: 16
                width: parent.width - 32
                spacing: 14

                // ── Wi-Fi ──
                Column {
                    width: parent.width; spacing: 6
                    Row {
                        width: parent.width; height: 26; spacing: 10
                        Txt { text: "󰖩  Wi-Fi"; font.bold: true; width: parent.width - 40 - 10 - rescan.width - 10; height: parent.height }
                        SmallBtn { id: rescan; label: "procurar"; anchors.verticalCenter: parent.verticalCenter
                            onClicked: root.sh("nmcli dev wifi rescan") }
                        Toggle { anchors.verticalCenter: parent.verticalCenter; on: root.wifiOn
                            onToggled: { root.wifiOn = !root.wifiOn; root.sh("nmcli radio wifi " + (root.wifiOn ? "on" : "off")) } }
                    }
                    Txt { visible: !root.wifiOn; text: "Desligado"; color: root.dim; font.pixelSize: 12 }
                    ListView {
                        visible: root.wifiOn
                        width: parent.width
                        height: Math.min(contentHeight, 190)
                        clip: true
                        interactive: contentHeight > height
                        model: root.nets
                        delegate: Column {
                            required property var modelData
                            width: ListView.view.width
                            Rectangle {
                                width: parent.width; height: 32; radius: 6
                                color: wm.containsMouse ? root.hover : "transparent"
                                Txt {
                                    anchors { left: parent.left; leftMargin: 8; right: st.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    text: (modelData.signal > 66 ? "󰤨" : modelData.signal > 33 ? "󰤥" : "󰤟") + "  " + modelData.ssid
                                    font.bold: modelData.active
                                }
                                Txt {
                                    id: st
                                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                    color: root.dim; font.pixelSize: 11
                                    text: modelData.active ? "ligado" : (modelData.secure ? "󰌾" : "")
                                }
                                MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.wifiClick(modelData) }
                            }
                            Rectangle {
                                visible: root.pwSsid === modelData.ssid
                                width: parent.width; height: visible ? 34 : 0; radius: 6
                                color: "#0d0d0d"; border.width: 1; border.color: root.line
                                TextInput {
                                    id: pw
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: root.fg; font.family: root.font; font.pixelSize: 13
                                    echoMode: TextInput.Password
                                    onVisibleChanged: if (visible) forceActiveFocus()
                                    Keys.onReturnPressed: root.wifiPass(modelData.ssid, text)
                                    Keys.onEnterPressed: root.wifiPass(modelData.ssid, text)
                                    Txt { visible: !pw.text; text: "palavra-passe · Enter"; color: root.dim; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: root.line }

                // ── Bluetooth ──
                Column {
                    width: parent.width; spacing: 6
                    Row {
                        width: parent.width; height: 26; spacing: 10
                        Txt { text: "󰂯  Bluetooth"; font.bold: true; width: parent.width - 40 - 10 - scan.width - 10; height: parent.height }
                        SmallBtn { id: scan; label: root.btScanning ? "a procurar…" : "procurar"; anchors.verticalCenter: parent.verticalCenter
                            onClicked: { root.btScanning = true; scanEnd.restart(); root.sh("bluetoothctl --timeout 20 scan on >/dev/null") } }
                        Toggle { anchors.verticalCenter: parent.verticalCenter; on: root.btOn
                            onToggled: { root.btOn = !root.btOn; root.sh("bluetoothctl power " + (root.btOn ? "on" : "off") + " || rfkill unblock bluetooth") } }
                    }
                    Txt { visible: !root.btOn; text: "Desligado"; color: root.dim; font.pixelSize: 12 }
                    ListView {
                        id: btList
                        visible: root.btOn
                        width: parent.width
                        height: Math.min(contentHeight, 170)
                        clip: true
                        interactive: contentHeight > height
                        model: root.devs.filter(d => d.paired || root.btScanning)
                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width; height: 32; radius: 6
                            color: bm.containsMouse ? root.hover : "transparent"
                            Txt {
                                anchors { left: parent.left; leftMargin: 8; right: bs.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: "󰂱  " + modelData.name
                                font.bold: modelData.connected
                            }
                            Txt {
                                id: bs
                                anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                color: root.dim; font.pixelSize: 11
                                text: modelData.connected ? "ligado" : (modelData.paired ? "emparelhado" : "novo")
                            }
                            MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.btClick(modelData) }
                        }
                    }
                    Txt { visible: root.btOn && btList.count === 0; text: "Sem dispositivos · usa \"procurar\""; color: root.dim; font.pixelSize: 12 }
                }

                Rectangle { width: parent.width; height: 1; color: root.line }

                // ── Volume / brilho ──
                Row {
                    width: parent.width; height: 22; spacing: 10
                    Txt { width: 26; height: parent.height; text: root.muted ? "󰝟" : "󰕾"; font.pixelSize: 16
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.muted = !root.muted; root.sh("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") } } }
                    Slider { width: parent.width - 26 - 44 - 20; value: root.vol
                        onMoved: v => { if (v === root.vol) return; root.vol = v; root.dragUntil = Date.now() + 2500
                            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v + "%"]) } }
                    Txt { width: 44; height: parent.height; text: root.vol + "%"; horizontalAlignment: Text.AlignRight; color: root.dim; font.pixelSize: 12 }
                }
                Row {
                    visible: root.bri >= 0
                    width: parent.width; height: visible ? 22 : 0; spacing: 10
                    Txt { width: 26; height: parent.height; text: "󰃟"; font.pixelSize: 16 }
                    Slider { width: parent.width - 26 - 44 - 20; value: root.bri
                        onMoved: v => { const n = Math.max(1, v); if (n === root.bri) return; root.bri = n; root.dragUntil = Date.now() + 2500
                            Quickshell.execDetached(["brightnessctl", "-q", "set", n + "%"]) } }
                    Txt { width: 44; height: parent.height; text: root.bri + "%"; horizontalAlignment: Text.AlignRight; color: root.dim; font.pixelSize: 12 }
                }

                // ── Atalhos para ferramentas avançadas ──
                Row {
                    spacing: 8
                    SmallBtn { label: "redes…";     onClicked: { Quickshell.execDetached(["nm-connection-editor"]); Qt.quit() } }
                    SmallBtn { label: "áudio…";     onClicked: { Quickshell.execDetached(["pavucontrol"]); Qt.quit() } }
                    SmallBtn { label: "bluetooth…"; onClicked: { Quickshell.execDetached(["sh", "-c", "command -v blueman-manager >/dev/null && exec blueman-manager || exec kitty -e bluetoothctl"]); Qt.quit() } }
                }
            }
        }
    }
}
