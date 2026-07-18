import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.lib

MonitorCard {
    id: root

    property var topApps: []

    expandedContent: ColumnLayout {
        spacing: Math.round(2)

        Item { Layout.preferredHeight: Math.round(4) }

        Repeater {
            model: root.topApps
            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: modelData.name; color: root.colors.subtext1; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideLeft; horizontalAlignment: Text.AlignLeft; maximumLineCount: 1 }
                Text { text: modelData.pct; color: root.colors.text; font.pointSize: 9 }
            }
        }

        Item { Layout.fillHeight: true }
    }

    Process {
        id: topMemReader
        command: ["sh", "-c", "ps aux --sort=-%mem | head -4 | tail -3"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.topApps = parseTopApps(text, "mem") }
    }

    function parseTopApps(text, sortBy) {
        const lines = text.trim().split("\n")
        const apps = []
        for (const line of lines) {
            const p = line.trim().split(/\s+/)
            if (p.length < 11) continue
            const rawName = p[10]
            const rssKB = parseInt(p[5])
            if (!isNaN(rssKB) && rssKB > 0) {
                const gb = rssKB / 1048576
                const display = gb >= 1 ? gb.toFixed(1) + "G" : (rssKB / 1024).toFixed(0) + "M"
                apps.push({ name: rawName, pct: display })
            }
        }
        return apps.slice(0, 3)
    }

    function refresh() {
        topMemReader.running = false
        topMemReader.running = true
    }
}
