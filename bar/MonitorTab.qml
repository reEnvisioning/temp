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

    readonly property real gridMargin: Math.round(4)
    readonly property real gap: Math.round(6)
    readonly property real compactW: root.width > gridMargin * 2 + gap ? (root.width - gridMargin * 2 - gap) / 2 : 0
    readonly property real compactH: Math.round(56)

    function cardX(col: real): real { return gridMargin + col * (compactW + gap) }
    function cardY(row: real): real { return gridMargin + row * (compactH + gap) }

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
        if (diskCard.isExpanded) diskCard.refresh()
        if (ramCard.isExpanded) ramCard.refresh()
        if (cpuCard.isExpanded) cpuCard.refresh()
        if (gpuCard.isExpanded) gpuCard.refresh()
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

    DiskCard {
        id: diskCard
        colors: root.colors
        uiScale: root.uiScale
        cardId: "disk"
        cardTitle: "Disk"
        cardValue: root.diskUsed + " / " + root.diskTotal
        progressValue: root.diskPct
        progressColor: root.colors.blue
        isExpanded: root.expandedCard === "disk"
        isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(0)
        y: isExpanded ? 0 : root.cardY(0)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        onClicked: root.expandedCard = isExpanded ? "" : "disk"
        onIsExpandedChanged: { if (isExpanded) refresh() }
    }

    RamCard {
        id: ramCard
        colors: root.colors
        uiScale: root.uiScale
        cardId: "ram"
        cardTitle: "RAM"
        cardValue: root.memUsed + " / " + root.memTotal
        progressValue: root.memPct
        progressColor: root.colors.green
        isExpanded: root.expandedCard === "ram"
        isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(1)
        y: isExpanded ? 0 : root.cardY(0)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        onClicked: root.expandedCard = isExpanded ? "" : "ram"
        onIsExpandedChanged: { if (isExpanded) refresh() }
    }

    CpuCard {
        id: cpuCard
        colors: root.colors
        uiScale: root.uiScale
        cardId: "cpu"
        cardTitle: "CPU"
        cardValue: root.cpuPct + "%"
        progressValue: root.cpuPct
        progressColor: root.colors.magenta
        isExpanded: root.expandedCard === "cpu"
        isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(0)
        y: isExpanded ? 0 : root.cardY(1)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        onClicked: root.expandedCard = isExpanded ? "" : "cpu"
        onIsExpandedChanged: { if (isExpanded) refresh() }
    }

    GpuCard {
        id: gpuCard
        colors: root.colors
        uiScale: root.uiScale
        cardId: "gpu"
        cardTitle: "GPU"
        cardValue: available ? (progressValue + "%") : "N/A"
        progressValue: 0
        progressColor: root.colors.yellow
        isExpanded: root.expandedCard === "gpu"
        isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(1)
        y: isExpanded ? 0 : root.cardY(1)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        onClicked: root.expandedCard = isExpanded ? "" : "gpu"
        onIsExpandedChanged: { if (isExpanded) refresh() }
    }
}
