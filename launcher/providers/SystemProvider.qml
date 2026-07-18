import QtQuick
import Quickshell

Item {
    id: root
    visible: false

    property string prefix: "@ "
    property string name: "System"
    property string placeholderText: "System action..."

    property var _actions: [
        { id: "shutdown", cmd: "systemctl poweroff" },
        { id: "reboot",   cmd: "systemctl reboot" },
        { id: "logout",   cmd: "loginctl terminate-user $USER" },
        { id: "lock",     cmd: "swaylock -f" },
        { id: "performance", cmd: "powerprofile performance" },
        { id: "balanced",    cmd: "powerprofile balanced" },
        { id: "powersave",   cmd: "powerprofile power-saver" }
    ]

    function query(text) {
        if (!text || !text.trim())
            return _actions.slice()

        var lower = text.toLowerCase()
        return _actions.filter(function(a) {
            return a.id.toLowerCase().indexOf(lower) !== -1
        })
    }

    function textFor(entry) { return entry ? entry.id : "" }

    function activate(entry) {
        if (entry && entry.cmd)
            Quickshell.execDetached(["bash", "-c", entry.cmd])
    }

    property Component itemComponent: Component {
        MouseArea {
            id: rootItem
            required property var modelData
            required property bool selected
            required property var colors
            required property real uiScale
            property var launcher: null
            property int itemIndex: -1

            height: Math.round(44 * uiScale)
            hoverEnabled: true
            onClicked: {
                if (launcher && itemIndex >= 0) {
                    launcher.currentIndex = itemIndex
                    launcher.selectCurrent()
                }
            }
            onEntered: {
                if (launcher && itemIndex >= 0) {
                    launcher.currentIndex = itemIndex
                }
            }

            Rectangle {
                anchors.fill: parent
                color: selected ? colors.highlighted : "transparent"
                radius: Math.round(6 * uiScale)
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                text: modelData ? ("@ " + modelData.id) : ""
                color: colors.text
                font.pointSize: 10
                font.family: "monospace"
            }
        }
    }
}
