import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.lib

MonitorCard {
    id: root

    property string temp: "N/A"
    property int cores: 1
    property var topApps: []

    expandedContent: ColumnLayout {
        spacing: Math.round(2)

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text { text: "Temp:"; color: root.colors.subtext0; font.pointSize: 9 }
            Text { text: root.temp; color: root.colors.text; font.pointSize: 9 }
        }

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
        id: cpuTempReader
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*/temp; do cat \"$z\" 2>/dev/null; done"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseCpuTemp(text) }
    }

    Process {
        id: cpuCoresReader
        command: ["nproc"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.cores = parseInt(text.trim()) || 1 }
    }

    Process {
        id: topCpuReader
        command: ["sh", "-c", "ps aux --sort=-%cpu | head -4 | tail -3"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.topApps = parseTopApps(text) }
    }

    function parseCpuTemp(text) {
        const lines = text.trim().split("\n")
        let total = 0, count = 0
        for (const line of lines) {
            const val = parseInt(line.trim())
            if (!isNaN(val) && val > 0) { total += val; count++ }
        }
        if (count > 0) root.temp = Math.round(total / count / 1000) + "\u00B0C"
    }

    function parseTopApps(text) {
        const lines = text.trim().split("\n")
        const apps = []
        for (const line of lines) {
            const p = line.trim().split(/\s+/)
            if (p.length < 11) continue
            const rawName = p[10]
            const rawPct = parseFloat(p[2])
            if (!isNaN(rawPct) && rawPct > 0) {
                const pct = (rawPct / root.cores).toFixed(1)
                apps.push({ name: rawName, pct: pct + "%" })
            }
        }
        return apps.slice(0, 3)
    }

    function refresh() {
        cpuTempReader.running = false
        cpuTempReader.running = true
        cpuCoresReader.running = false
        cpuCoresReader.running = true
        topCpuReader.running = false
        topCpuReader.running = true
    }
}
