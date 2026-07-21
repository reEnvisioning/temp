import QtQuick
import Quickshell
import Quickshell.Io
import qs.lib

Item {
    id: root
    visible: false

    readonly property Settings settings: Settings {}

    property string prefix: "ssh "
    property string name: "SSH"
    property string placeholderText: "user@host"

    property var _history: []

    Process {
        id: historyLoader
        command: ["sh", "-c", "cat " + settings.dataFile("ssh-history.json") + " 2>/dev/null || echo '[]'"]
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
        var tmpFile = settings.dataFile("ssh-history.json.tmp")
        var targetFile = settings.dataFile("ssh-history.json")
        historySaver.command = ["sh", "-c",
            "mkdir -p \"" + settings.dataFile("") + "\" && " +
            "printf '%s' '" + json.replace(/'/g, "'\\''") + "' > \"" + tmpFile + "\" && " +
            "mv \"" + tmpFile + "\" \"" + targetFile + "\""]
        historySaver.running = false
        historySaver.running = true
    }

    Process {
        id: historySaver
        command: ["true"]
        running: false
    }

    function textFor(entry) { return entry ? entry.input : "" }

    function query(text) {
        if (!text || !text.trim())
            return _history.slice()

        var lower = text.toLowerCase()
        var results = [{ input: text }]
        for (var i = 0; i < _history.length; i++) {
            var entry = _history[i].input
            if (entry.toLowerCase().indexOf(lower) !== -1 && entry !== text)
                results.push(_history[i])
        }
        return results
    }

    function activate(entry) {
        if (entry && entry.input) {
            addToHistory(entry.input)
            Quickshell.execDetached({ command: ["kitty", "-e", "bash", "-c", "ssh -v " + entry.input + "; exec bash -i"] })
        }
    }

    function altActivate(entry) {
        if (entry && entry.input) {
            addToHistory(entry.input)
            var host = entry.input
            var atIdx = host.indexOf("@")
            if (atIdx >= 0) host = host.substring(atIdx + 1)
            Quickshell.execDetached({ command: ["kitty", "-e", "sh", "-c", "ping " + host] })
        }
    }

    function remove(entry) {
        var idx = _history.indexOf(entry)
        if (idx >= 0) { _history.splice(idx, 1); save() }
    }

    function removeAll() {
        _history = []; save()
    }

    function addToHistory(input) {
        for (var i = 0; i < _history.length; i++) {
            if (_history[i].input === input) {
                _history.splice(i, 1)
                break
            }
        }
        _history.unshift({ input: input })
        save()
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
                text: modelData ? ("ssh " + (modelData.input || "")) : ""
                color: colors.text
                font.pointSize: 10
                font.family: "monospace"
                elide: Text.ElideRight
                width: parent.width - Math.round(20 * uiScale)
            }
        }
    }
}
