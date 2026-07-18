import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.lib

Item {
    id: root

    required property var colors

    property string userName: ""
    property string timeString: ""
    property string dateString: ""
    readonly property Settings settings: Settings {}
    property int avatarRefreshCounter: 0
    property string batteryPct: "--"
    property string batteryStatus: ""

    readonly property real gridMargin: Math.round(4)
    readonly property real gap: Math.round(gridMargin / 2)
    readonly property real sideRowH: Math.round((contentH - gap) / 2)
    readonly property real contentW: root.width - gridMargin * 2
    readonly property real contentH: root.height - gridMargin * 2
    readonly property real avatarW: Math.round((contentW - gap) * 2 / 3)
    readonly property real sideW: contentW - gap - avatarW
    readonly property real sideRowH: Math.round((contentH - gap) / 2)

    Process {
        id: userReader
        command: ["sh", "-c", "echo $USER"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.userName = text.trim()
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

    GridLayout {
        anchors.fill: parent
        anchors.margins: root.gridMargin
        columns: 2
        rows: 2
        rowSpacing: root.gap
        columnSpacing: root.gap

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: root.avatarW
            Layout.rowSpan: 2
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height) * 0.6
                height: width
                radius: width / 2
                clip: true
                color: "transparent"
                border.width: 2
                border.color: root.colors.border
                Behavior on border.color { CAnim {} }

                Image {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    height: parent.height - 4
                    sourceSize { width: 128; height: 128 }
                    source: root.userName ? "file://" + root.settings.dataFile("user/" + root.userName + ".png") + "?t=" + root.avatarRefreshCounter : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: root.sideW
            Layout.preferredHeight: root.sideRowH
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
            Layout.preferredWidth: root.sideW
            Layout.preferredHeight: root.sideRowH
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
