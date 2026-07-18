import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.lib

MonitorCard {
    id: root

    property bool available: false
    property string temp: "N/A"
    property string memUsed: ""
    property string memTotal: ""
    property var topApps: []

    expandedContent: ColumnLayout {
        spacing: Math.round(2)

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.available
            Text { text: "Temp:"; color: root.colors.subtext0; font.pointSize: 9 }
            Text { text: root.temp; color: root.colors.text; font.pointSize: 9 }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.available && root.memUsed !== ""
            Text { text: "VRAM:"; color: root.colors.subtext0; font.pointSize: 9 }
            Text { text: root.memUsed + " / " + root.memTotal; color: root.colors.text; font.pointSize: 9 }
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
        id: gpuReader
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1"]
        running: false
        stdout: StdioCollector { onStreamFinished: parseOutput(text) }
    }

    Process {
        id: gpuTempReader
        command: ["sh", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || { f=$(find /sys/class/drm/card*/device/hwmon/*/temp1_input 2>/dev/null | head -1); [ -n \"$f\" ] && cat \"$f\"; }"]
        running: false
        stdout: StdioCollector { onStreamFinished: parseTemp(text) }
    }

    Process {
        id: gpuTopReader
        command: ["sh", "-c", "nvidia-smi pmon -c 1 -s um 2>/dev/null || nvidia-smi --query-compute-apps=pid,used_memory,name --format=csv,noheader,nounits 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (t.startsWith("#")) parsePmon(t)
                else parseQuery(t)
            }
        }
    }

    function parseOutput(text) {
        const t = text.trim()
        if (!t) return
        if (t.includes(",")) {
            const p = t.split(/[,\s]+/)
            if (p.length >= 3) {
                root.available = true
                root.cardValue = (parseInt(p[0]) || 0) + "%"
                root.progressValue = parseInt(p[0]) || 0
                root.memUsed = p[1] + "MB"
                root.memTotal = p[2] + "MB"
            }
        } else {
            const val = parseInt(t)
            if (!isNaN(val)) {
                root.available = true
                root.cardValue = val + "%"
                root.progressValue = val
            }
        }
    }

    function parseTemp(text) {
        const val = parseInt(text.trim())
        if (!isNaN(val) && val > 0) root.temp = val + "\u00B0C"
    }

    function parsePmon(text) {
        const lines = text.trim().split("\n")
        const apps = []
        for (const line of lines) {
            if (line.startsWith("#") || line.trim() === "") continue
            const p = line.trim().split(/\s+/)
            if (p.length < 7) continue
            const fbKB = parseInt(p[4])
            const name = p[p.length - 1]
            if (!isNaN(fbKB) && fbKB > 0) {
                const mb = Math.round(fbKB / 1024)
                apps.push({ name: name, pct: mb + "MB" })
            }
        }
        root.topApps = apps.slice(0, 3)
    }

    function parseQuery(text) {
        const lines = text.trim().split("\n")
        const apps = []
        for (const line of lines) {
            const p = line.split(",")
            if (p.length < 3) continue
            const memMB = parseInt(p[1].trim())
            const name = p[2].trim()
            if (!isNaN(memMB) && memMB > 0)
                apps.push({ name: name, pct: memMB + "MB" })
        }
        root.topApps = apps.slice(0, 3)
    }

    function refresh() {
        gpuReader.running = false
        gpuReader.running = true
        gpuTempReader.running = false
        gpuTempReader.running = true
        gpuTopReader.running = false
        gpuTopReader.running = true
    }
}
