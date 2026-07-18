import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.lib

MonitorCard {
    id: root

    property var partitions: []

    expandedContent: ColumnLayout {
        spacing: Math.round(2)

        Item { Layout.preferredHeight: Math.round(4) }

        Repeater {
            model: root.partitions
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: modelData.name; color: root.colors.subtext1; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideLeft; horizontalAlignment: Text.AlignLeft; maximumLineCount: 1 }
                Text { text: modelData.size; color: root.colors.text; font.pointSize: 9 }
                Text { text: modelData.fstype; color: root.colors.subtext0; font.pointSize: 9 }
                Text { text: modelData.mount; color: root.colors.blue; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideLeft; horizontalAlignment: Text.AlignLeft; maximumLineCount: 1 }
            }
        }

        Item { Layout.fillHeight: true }
    }

    Process {
        id: diskPartReader
        command: ["sh", "-c", "lsblk -b -J -o NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE 2>/dev/null || lsblk -b -o NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE --pairs 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t.startsWith("{")) parseJson(t)
                else parsePairs(t)
            }
        }
    }

    function parseJson(text) {
        const parts = []
        try {
            const data = JSON.parse(text)
            function walk(devices) {
                for (const d of devices) {
                    if (d.type === "part" && d.name) {
                        const sizeGB = (Number(d.size) / 1073741824).toFixed(0)
                        parts.push({ name: d.name, size: sizeGB + "G", fstype: d.fstype || "\u2014", mount: d.mountpoint || "\u2014" })
                    }
                    if (d.children) walk(d.children)
                }
            }
            if (data.blockdevices) walk(data.blockdevices)
        } catch (e) {}
        root.partitions = parts
    }

    function parsePairs(text) {
        const lines = text.trim().split("\n")
        const parts = []
        for (const line of lines) {
            const nameM = line.match(/NAME="([^"]*)"/)
            const sizeM = line.match(/SIZE="([^"]*)"/)
            const fsM = line.match(/FSTYPE="([^"]*)"/)
            const mountM = line.match(/MOUNTPOINT="([^"]*)"/)
            const typeM = line.match(/TYPE="([^"]*)"/)
            if (typeM && typeM[1] === "part" && nameM && sizeM) {
                const sizeGB = (Number(sizeM[1]) / 1073741824).toFixed(0)
                parts.push({ name: nameM[1], size: sizeGB + "G", fstype: fsM ? fsM[1] || "\u2014" : "\u2014", mount: mountM ? mountM[1] || "\u2014" : "\u2014" })
            }
        }
        root.partitions = parts
    }

    function refresh() {
        diskPartReader.running = false
        diskPartReader.running = true
    }
}
