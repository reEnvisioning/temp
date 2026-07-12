import QtQuick
import Quickshell
import Quickshell.Io
import "../scripts/fuzzy.js" as Fuzzy

QtObject {
    id: root

    property string prefix: "^ "
    property string name: "Share"
    property string placeholderText: "Share a file..."
    property int refreshKey: 0
    property string currentDir: "."

    property var _files: []

    Process {
        id: fileScanner
        command: ["bash", "-c",
            "cd ~ && find Documents Downloads Pictures Videos Music . " +
            "-maxdepth 3 -not -path '*/.*' -type f " +
            "-printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -100 | cut -f2-"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._files = []
                var raw = text.trim()
                if (raw === "") return
                var lines = raw.split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('/')
                    var name = parts.pop()
                    var dir = parts.join('/')
                    var displayPath = dir.length > 25
                        ? ".." + dir.slice(-22) + "/" + name
                        : lines[i]
                    root._files.push({
                        relPath: lines[i],
                        name: name,
                        displayPath: displayPath,
                        parentDir: dir
                    })
                }
                root.refreshKey++
            }
        }
    }

    Process {
        id: dirRestorer
        command: ["bash", "-c", "cat /tmp/last-share-dir 2>/dev/null || echo \".\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var dir = text.trim()
                if (dir.length > 0)
                    root.currentDir = dir
                root.refreshKey++
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            fileScanner.running = false
            fileScanner.running = true
        }
    }

    function query(text) {
        if (root._files.length === 0) return []

        if (!text || !text.trim())
            return root._files.filter(function(f) { return f.parentDir === root.currentDir })

        var results = Fuzzy.go(text, root._files, {
            key: "relPath",
            limit: 100,
            threshold: -10000
        })
        if (results.length > 0)
            return results.map(function(r) { return r.obj })

        var lower = text.toLowerCase()
        var fallback = []
        for (var i = 0; i < root._files.length; i++) {
            if (root._files[i].name.toLowerCase().indexOf(lower) !== -1)
                fallback.push(root._files[i])
        }
        return fallback
    }

    function textFor(entry) { return entry ? entry.relPath : "" }

    function activate(entry) {
        if (!entry) return
        Quickshell.execDetached(["bash", "-c",
            "localsend_app send \"$HOME/$1\"",
            "shareFile", entry.relPath])
        root.currentDir = entry.parentDir
        Quickshell.execDetached(["bash", "-c",
            "echo \"$1\" > /tmp/last-share-dir",
            "writeDir", entry.parentDir])
        root.refreshKey++
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
                text: "^ " + modelData.displayPath
                color: colors.text
                font.pointSize: 9
                font.family: "monospace"
                elide: Text.ElideLeft
            }
        }
    }
}
