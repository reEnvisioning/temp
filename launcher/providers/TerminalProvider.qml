import QtQuick
import Quickshell
import Quickshell.Io
import qs.lib

QtObject {
    id: root

    readonly property Settings settings: Settings {}

    property string prefix: ">> "
    property string name: "Terminal"
    property string placeholderText: "Run in terminal..."

    property var _history: []

    Process {
        id: historyLoader
        command: ["sh", "-c", "cat " + settings.dataFile("terminal-history.json") + " 2>/dev/null || echo '[]'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text.trim())
                    if (Array.isArray(arr))
                        root._history = arr
                } catch (e) {}
            }
        }
    }

    function save() {
        var json = JSON.stringify(root._history)
        var delim = "TS" + Math.random().toString(36).substring(2, 10) + "EOF"
        historySaver.command = ["sh", "-c",
            "mkdir -p " + settings.dataFile("") + " && " +
            "cat > " + settings.dataFile("terminal-history.json") + " << '" + delim + "'\n" +
            json + "\n" +
            delim]
        historySaver.running = false
        historySaver.running = true
    }

    Process {
        id: historySaver
        command: ["true"]
        running: false
    }

    function textFor(entry) { return entry ? entry.command : "" }

    function query(text) {
        if (!text || !text.trim())
            return _history.slice()

        var lower = text.toLowerCase()
        var results = [{ command: text }]
        for (var i = 0; i < _history.length; i++) {
            var cmd = _history[i].command
            if (cmd.toLowerCase().indexOf(lower) !== -1 && cmd !== text)
                results.push(_history[i])
        }
        return results
    }

    function remove(entry) {
        var idx = _history.indexOf(entry)
        if (idx >= 0) { _history.splice(idx, 1); save() }
    }

    function removeAll() {
        _history = []; save()
    }

    function activate(entry) {
        if (entry && entry.command) {
            var idx = -1
            for (var i = 0; i < _history.length; i++) {
                if (_history[i].command === entry.command) { idx = i; break }
            }
            if (idx >= 0) _history.splice(idx, 1)
            _history.unshift({ command: entry.command })
            if (_history.length > 10) _history.length = 10
            save()

            Quickshell.execDetached({ command: ["kitty", "-e", "sh", "-c", entry.command] })
        }
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
                text: modelData ? (">> " + (modelData.command || "")) : ""
                color: colors.text
                font.pointSize: 10
                font.family: "monospace"
                elide: Text.ElideRight
                width: parent.width - Math.round(20 * uiScale)
            }
        }
    }
}
