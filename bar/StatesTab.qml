import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.lib

Item {
    id: root

    required property var colors

    property bool dndActive: false
    property string proxyStatus: "disabled"
    property string idleStatus: "unknown"
    property string powerProfile: "--"

    function dndText(): string {
        return root.dndActive ? "Active" : "Off"
    }

    function dndColor(): color {
        return root.dndActive ? root.colors.green : root.colors.red
    }

    function idleText(): string {
        if (root.idleStatus === "enabled") return "Active"
        if (root.idleStatus === "disabled") return "Off"
        return "Unknown"
    }

    function idleColor(): color {
        if (root.idleStatus === "enabled") return root.colors.green
        if (root.idleStatus === "disabled") return root.colors.red
        return root.colors.subtext0
    }

    function proxyText(): string {
        if (root.proxyStatus === "connected" || root.proxyStatus === "up") return "Connected"
        if (root.proxyStatus === "pending") return "Pending"
        if (root.proxyStatus === "down" || root.proxyStatus === "disabled") return "Off"
        if (root.proxyStatus === "unknown") return "Unknown"
        return "N/A"
    }

    function proxyColor(): color {
        if (root.proxyStatus === "connected" || root.proxyStatus === "up") return root.colors.green
        if (root.proxyStatus === "pending") return root.colors.yellow
        if (root.proxyStatus === "down" || root.proxyStatus === "disabled") return root.colors.red
        return root.colors.subtext0
    }

    function refreshProfile(): void {
        profileReader.running = false
        profileReader.running = true
    }

    Process {
        id: profileReader
        command: ["powerprofilesctl", "get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                root.powerProfile = p.length > 0 ? p.charAt(0).toUpperCase() + p.slice(1) : "--"
            }
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: root.refreshProfile()
    }

    readonly property real gridMargin: Math.round(4)
    readonly property real gap: gridMargin
    readonly property real compactH: Math.round((root.height - gridMargin * 2 - gap) / 2)

    GridLayout {
        anchors.fill: parent
        anchors.margins: root.gridMargin
        columns: 2
        rowSpacing: root.gap
        columnSpacing: root.gap

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compactH
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            RowLayout {
                anchors.centerIn: parent
                spacing: Math.round(8)

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "DND"
                        color: root.colors.subtext0
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        text: root.dndText()
                        color: root.dndColor()
                        font.pointSize: 9
                        Behavior on color { CAnim {} }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compactH
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            RowLayout {
                anchors.centerIn: parent
                spacing: Math.round(8)

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Idle"
                        color: root.colors.subtext0
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        text: root.idleText()
                        color: root.idleColor()
                        font.pointSize: 9
                        Behavior on color { CAnim {} }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compactH
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            RowLayout {
                anchors.centerIn: parent
                spacing: Math.round(8)

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Proxy"
                        color: root.colors.subtext0
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        text: root.proxyText()
                        color: root.proxyColor()
                        font.pointSize: 9
                        Behavior on color { CAnim {} }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compactH
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            RowLayout {
                anchors.centerIn: parent
                spacing: Math.round(8)

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Profile"
                        color: root.colors.subtext0
                        font.pointSize: 10
                        font.weight: Font.DemiBold
                        Behavior on color { CAnim {} }
                    }
                    Text {
                        text: root.powerProfile
                        color: root.colors.text
                        font.pointSize: 9
                        Behavior on color { CAnim {} }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
