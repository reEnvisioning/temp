import QtQuick
import Quickshell
import Quickshell.Io
import qs.lib

QtObject {
    id: root

    readonly property Settings settings: Settings {}

    property string prefix: "# "
    property string name: "Theme"
    property string placeholderText: "Switch theme..."

    property var _themes: []

    Process {
        id: themeLoader
        command: ["bash", "-c",
            "dir=\"" + settings.themePath + "/themes\";" +
            "[ -d \"$dir\" ] || exit 0;" +
            "for d in \"$dir\"/*/; do" +
            "  [ -d \"$d\" ] || continue;" +
            "  name=$(basename \"$d\");" +
            "  theme_file=\"$d/theme.json\";" +
            "  mode=$(jq -r '.mode // \"\"' \"$theme_file\" 2>/dev/null || echo \"\");" +
            "  printf '%s\\t%s\\n' \"$name\" \"$mode\";" +
            "done | sort -u"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._themes = []
                var raw = text.trim()
                if (raw === "") return
                var lines = raw.split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('\t')
                    if (parts.length >= 1 && parts[0]) {
                        root._themes.push({
                            id: parts[0],
                            mode: parts[1] || ""
                        })
                    }
                }
            }
        }
    }

    function query(text) {
        if (root._themes.length === 0) return []

        if (!text || !text.trim())
            return _themes.slice()

        var lower = text.toLowerCase()
        return _themes.filter(function(t) {
            return t.id.toLowerCase().indexOf(lower) !== -1 ||
                   t.mode.toLowerCase().indexOf(lower) !== -1
        })
    }

    function textFor(entry) { return entry ? entry.id : "" }

    function activate(entry) {
        if (entry && entry.id)
            Quickshell.execDetached(["sh", "-c", "command -v switch-theme >/dev/null 2>&1 && switch-theme " + entry.id])
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

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(8 * uiScale)

                Text {
                    text: modelData ? ("# " + modelData.id) : ""
                    color: colors.text
                    font.pointSize: 10
                    font.family: "monospace"
                }

                Text {
                    text: modelData && modelData.mode ? ("(" + modelData.mode + ")") : ""
                    color: colors.subtext0
                    font.pointSize: 8
                    visible: text !== ""
                }
            }
        }
    }
}
