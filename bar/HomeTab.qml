import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.lib

Item {
    id: root

    required property var colors

    property string userName: ""
    property string hostName: ""
    property string timeString: ""
    property string dateString: ""
    readonly property Settings settings: Settings {}
    property int avatarRefreshCounter: 0
    property string batteryPct: "--"
    property string batteryStatus: ""

    Process {
        id: userReader
        command: ["sh", "-c", "echo $USER"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.userName = text.trim()
        }
    }

    Process {
        id: infoReader
        command: ["sh", "-c", "echo host=$(hostname)"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const data = text.trim()
                const lines = data.split("\n")
                for (const line of lines) {
                    const idx = line.indexOf("=")
                    if (idx < 0) continue
                    const key = line.slice(0, idx)
                    const val = line.slice(idx + 1)
                    if (key === "host") root.hostName = val
                }
            }
        }
    }

    Timer {
        interval: 60000; running: true; repeat: true
        onTriggered: {
            infoReader.running = false
            infoReader.running = true
        }
    }

    function updateClock(): void {
        const d = new Date()
        const hh = d.getHours().toString().padStart(2, "0")
        const mm = d.getMinutes().toString().padStart(2, "0")
        timeString = hh + ":" + mm

        const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        dateString = days[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()] + " " + d.getFullYear()
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: root.updateClock()
    }

    function refreshBattery(): void {
        batteryReader.running = false
        batteryReader.running = true
    }

    Process {
        id: batteryReader
        command: ["sh", "-c", "c=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo --); s=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null); echo \"$c $s\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                root.batteryPct = parts[0] || "--"
                root.batteryStatus = parts.length > 1 ? parts[1] : ""
            }
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: root.refreshBattery()
    }

    Timer {
        interval: 30000; running: true; repeat: true
        onTriggered: root.avatarRefreshCounter++
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.round(4)
        spacing: Math.round(4)

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.userName + "@" + (root.hostName.length > 0 ? root.hostName : "...")
            color: root.colors.subtext0
            font.pointSize: 10
            font.weight: Font.DemiBold
            Behavior on color { CAnim {} }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: Math.round(6)
            columnSpacing: Math.round(6)

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rowSpan: 2
                Layout.preferredWidth: Math.round(300)
                radius: Math.round(8)
                color: root.colors.element_background
                Behavior on color { CAnim {} }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.round(80)
                    height: Math.round(80)
                    radius: Math.round(40)
                    clip: true
                    color: "transparent"
                    border.width: 2
                    border.color: root.colors.border
                    Behavior on border.color { CAnim {} }

                    Image {
                        anchors.centerIn: parent
                        width: Math.round(76)
                        height: Math.round(76)
                        sourceSize { width: 76; height: 76 }
                        source: root.userName ? "file://" + root.settings.dataFile("user/" + root.userName + ".png") + "?t=" + root.avatarRefreshCounter : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(200)
                Layout.preferredHeight: Math.round(60)
                radius: Math.round(8)
                color: root.colors.element_background
                Behavior on color { CAnim {} }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Math.round(3)

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.timeString
                        color: root.colors.text
                        font.pointSize: 22
                        font.family: "Monospace"
                        font.weight: Font.Light
                        Behavior on color { CAnim {} }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.dateString
                        color: root.colors.subtext0
                        font.pointSize: 10
                        Behavior on color { CAnim {} }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.round(200)
                Layout.preferredHeight: Math.round(30)
                radius: Math.round(8)
                color: root.colors.element_background
                Behavior on color { CAnim {} }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Math.round(6)

                    Text {
                        text: root.batteryPct + "%"
                        color: root.colors.text
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        Behavior on color { CAnim {} }
                    }

                    Text {
                        text: root.batteryStatus
                        color: root.colors.subtext0
                        font.pointSize: 8
                        visible: root.batteryStatus.length > 0
                        Behavior on color { CAnim {} }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
