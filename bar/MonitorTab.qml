import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.lib
import "monitor"

Item {
    id: root

    required property var colors

    property real diskPct: 0
    property string diskUsed: ""
    property string diskTotal: ""
    property real memPct: 0
    property string memUsed: ""
    property string memTotal: ""
    property real cpuPct: 0
    property string expandedCard: ""

    property var prevCpu: ({ idle: 0, total: 0 })

    function parseCpu(line: string): void {
        const parts = line.trim().split(/\s+/)
        if (parts[0] !== "cpu") return
        const idle = parseInt(parts[4])
        const total = parts.slice(1).reduce((a, b) => a + parseInt(b), 0)
        const dIdle = idle - root.prevCpu.idle
        const dTotal = total - root.prevCpu.total
        root.cpuPct = dTotal > 0 ? Math.round((1 - dIdle / dTotal) * 100) : 0
        root.prevCpu = { idle, total }
    }

    function refresh(): void {
        diskReader.running = false; diskReader.running = true
        memReader.running = false; memReader.running = true
        cpuReader.running = false; cpuReader.running = true
        if (root.expandedCard === "disk") diskOverlay.refresh()
        if (root.expandedCard === "ram") ramOverlay.refresh()
        if (root.expandedCard === "cpu") cpuOverlay.refresh()
        if (root.expandedCard === "gpu") gpuOverlay.refresh()
    }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refresh() }

    Process {
        id: diskReader
        command: ["df", "-h", "--output=pcent,used,size", "/"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length < 2) return
                const p = lines[1].trim().split(/\s+/)
                if (p.length >= 3) {
                    root.diskPct = parseInt(p[0]) || 0
                    root.diskUsed = p[1]
                    root.diskTotal = p[2]
                }
            }
        }
    }

    Process {
        id: memReader
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%d %d %d\", t-a, t, (t-a)*100/t}' /proc/meminfo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ")
                if (p.length >= 3) {
                    root.memUsed = (parseInt(p[0]) / 1048576).toFixed(1) + "G"
                    root.memTotal = (parseInt(p[1]) / 1048576).toFixed(1) + "G"
                    root.memPct = parseInt(p[2])
                }
            }
        }
    }

    Process {
        id: cpuReader
        command: ["sh", "-c", "head -n1 /proc/stat"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseCpu(text.trim()) }
    }

    GridLayout {
        anchors.fill: parent
        anchors.margins: Math.round(4)
        columns: 2
        rowSpacing: Math.round(6)
        columnSpacing: Math.round(6)
        visible: root.expandedCard === ""

        DiskCard {
            id: diskCard
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(56)
            colors: root.colors
            uiScale: root.uiScale
            cardId: "disk"
            cardTitle: "Disk"
            cardValue: root.diskUsed + " / " + root.diskTotal
            progressValue: root.diskPct
            progressColor: root.colors.blue
            onClicked: root.expandedCard = "disk"
        }

        RamCard {
            id: ramCard
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(56)
            colors: root.colors
            uiScale: root.uiScale
            cardId: "ram"
            cardTitle: "RAM"
            cardValue: root.memUsed + " / " + root.memTotal
            progressValue: root.memPct
            progressColor: root.colors.green
            onClicked: root.expandedCard = "ram"
        }

        CpuCard {
            id: cpuCard
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(56)
            colors: root.colors
            uiScale: root.uiScale
            cardId: "cpu"
            cardTitle: "CPU"
            cardValue: root.cpuPct + "%"
            progressValue: root.cpuPct
            progressColor: root.colors.magenta
            onClicked: root.expandedCard = "cpu"
        }

        GpuCard {
            id: gpuCard
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(56)
            colors: root.colors
            uiScale: root.uiScale
            cardId: "gpu"
            cardTitle: "GPU"
            cardValue: available ? (progressValue + "%") : "N/A"
            progressValue: 0
            progressColor: root.colors.yellow
            onClicked: root.expandedCard = "gpu"
        }
    }

    DiskCard {
        id: diskOverlay
        visible: root.expandedCard === "disk"
        anchors.fill: parent
        colors: root.colors
        uiScale: root.uiScale
        cardId: "disk"
        cardTitle: "Disk"
        cardValue: root.diskUsed + " / " + root.diskTotal
        progressValue: root.diskPct
        progressColor: root.colors.blue
        isExpanded: true
        z: 10
        onClicked: root.expandedCard = ""
        onVisibleChanged: { if (visible) diskOverlay.refresh() }
    }

    RamCard {
        id: ramOverlay
        visible: root.expandedCard === "ram"
        anchors.fill: parent
        colors: root.colors
        uiScale: root.uiScale
        cardId: "ram"
        cardTitle: "RAM"
        cardValue: root.memUsed + " / " + root.memTotal
        progressValue: root.memPct
        progressColor: root.colors.green
        isExpanded: true
        z: 10
        onClicked: root.expandedCard = ""
        onVisibleChanged: { if (visible) ramOverlay.refresh() }
    }

    CpuCard {
        id: cpuOverlay
        visible: root.expandedCard === "cpu"
        anchors.fill: parent
        colors: root.colors
        uiScale: root.uiScale
        cardId: "cpu"
        cardTitle: "CPU"
        cardValue: root.cpuPct + "%"
        progressValue: root.cpuPct
        progressColor: root.colors.magenta
        isExpanded: true
        z: 10
        onClicked: root.expandedCard = ""
        onVisibleChanged: { if (visible) cpuOverlay.refresh() }
    }

    GpuCard {
        id: gpuOverlay
        visible: root.expandedCard === "gpu"
        anchors.fill: parent
        colors: root.colors
        uiScale: root.uiScale
        cardId: "gpu"
        cardTitle: "GPU"
        cardValue: available ? (progressValue + "%") : "N/A"
        progressValue: 0
        progressColor: root.colors.yellow
        isExpanded: true
        z: 10
        onClicked: root.expandedCard = ""
        onVisibleChanged: { if (visible) gpuOverlay.refresh() }
    }
}
