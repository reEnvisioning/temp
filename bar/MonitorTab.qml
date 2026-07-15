import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.lib

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
    property int cpuCores: 1
    property real gpuPct: 0
    property string gpuMemUsed: ""
    property string gpuMemTotal: ""
    property string gpuTemp: "N/A"
    property string cpuTemp: "N/A"
    property bool gpuAvailable: false

    property var diskPartitions: []
    property var topMemApps: []
    property var topCpuApps: []
    property var gpuTopApps: []

    property string expandedCard: ""

    property var prevCpu: ({ idle: 0, total: 0 })

    readonly property real gap: Math.round(6)
    readonly property real compactW: root.width > gap ? (root.width - gap) / 2 : 0
    readonly property real compactH: Math.round(56)
    readonly property real offsetX: root.width > compactW * 2 + gap ? (root.width - compactW * 2 - gap) / 2 : 0
    readonly property real offsetY: root.height > compactH * 2 + gap ? (root.height - compactH * 2 - gap) / 2 : 0

    function cardX(col: real): real { return offsetX + col * (compactW + gap) }
    function cardY(row: real): real { return offsetY + row * (compactH + gap) }

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

    function parseGpuOutput(text: string): void {
        const t = text.trim()
        if (!t) return
        if (t.includes(",")) {
            const p = t.split(/[,\s]+/)
            if (p.length >= 3) {
                root.gpuPct = parseInt(p[0]) || 0
                root.gpuMemUsed = p[1] + "MB"
                root.gpuMemTotal = p[2] + "MB"
                root.gpuAvailable = true
            }
        } else {
            const val = parseInt(t)
            if (!isNaN(val)) {
                root.gpuPct = val
                root.gpuAvailable = true
            }
        }
    }

    function parseCpuTemp(text: string): void {
        const lines = text.trim().split("\n")
        let total = 0, count = 0
        for (const line of lines) {
            const val = parseInt(line.trim())
            if (!isNaN(val) && val > 0) { total += val; count++ }
        }
        if (count > 0) root.cpuTemp = Math.round(total / count / 1000) + "\u00B0C"
    }

    function parseGpuTemp(text: string): void {
        const val = parseInt(text.trim())
        if (!isNaN(val) && val > 0) root.gpuTemp = val + "\u00B0C"
    }

    function parsePartitions(text: string): void {
        const lines = text.trim().split("\n")
        const parts = []
        for (const line of lines) {
            const nameM = line.match(/NAME="([^"]*)"/)
            const sizeM = line.match(/SIZE="([^"]*)"/)
            const fsM = line.match(/FSTYPE="([^"]*)"/)
            const mountM = line.match(/MOUNTPOINT="([^"]*)"/)
            const typeM = line.match(/TYPE="([^"]*)"/)
            const type = typeM ? typeM[1] : ""
            const name = nameM ? nameM[1] : ""
            const size = sizeM ? sizeM[1] : ""
            if (type === "part" && name && size) {
                const sizeGB = (Number(size) / 1073741824).toFixed(0)
                parts.push({ name: name, size: sizeGB + "G", fstype: fsM ? fsM[1] || "\u2014" : "\u2014", mount: mountM ? mountM[1] || "\u2014" : "\u2014" })
            }
        }
        root.diskPartitions = parts
    }

    function parseTopApps(text: string, sortBy: string): var {
        const lines = text.trim().split("\n")
        const apps = []
        for (const line of lines) {
            const p = line.trim().split(/\s+/)
            if (p.length < 11) continue
            const rawName = p[10]
            const name = rawName.length > 18 ? rawName.substring(0, 18) + "\u2026" : rawName
            if (sortBy === "cpu") {
                const rawPct = parseFloat(p[2])
                if (!isNaN(rawPct) && rawPct > 0) {
                    const pct = (rawPct / root.cpuCores).toFixed(1)
                    apps.push({ name: name, pct: pct + "%" })
                }
            } else {
                const rssKB = parseInt(p[5])
                if (!isNaN(rssKB) && rssKB > 0) {
                    const gb = rssKB / 1048576
                    const display = gb >= 1 ? gb.toFixed(1) + "G" : (rssKB / 1024).toFixed(0) + "M"
                    apps.push({ name: name, pct: display })
                }
            }
        }
        return apps.slice(0, 3)
    }

    function parseGpuTopApps(text: string): void {
        const lines = text.trim().split("\n")
        const apps = []
        for (const line of lines) {
            const p = line.split(",")
            if (p.length < 3) continue
            const pid = p[0].trim()
            const memMB = parseInt(p[1].trim())
            const name = p[2].trim()
            if (!isNaN(memMB) && memMB > 0) {
                const displayName = name.length > 18 ? name.substring(0, 18) + "\u2026" : name
                apps.push({ name: displayName, pct: memMB + "MB" })
            }
        }
        root.gpuTopApps = apps.slice(0, 3)
    }

    function refresh(): void {
        diskReader.running = false; diskReader.running = true
        memReader.running = false; memReader.running = true
        cpuReader.running = false; cpuReader.running = true
        gpuReader.running = false; gpuReader.running = true
        gpuTempReader.running = false; gpuTempReader.running = true
        cpuTempReader.running = false; cpuTempReader.running = true
    }

    function refreshDetail(): void {
        if (expandedCard === "disk") { diskPartReader.running = false; diskPartReader.running = true }
        else if (expandedCard === "ram") { topMemReader.running = false; topMemReader.running = true }
        else if (expandedCard === "cpu") { topCpuReader.running = false; topCpuReader.running = true }
        else if (expandedCard === "gpu") { gpuTopReader.running = false; gpuTopReader.running = true }
    }

    onExpandedCardChanged: { if (expandedCard !== "") refreshDetail() }

    Timer { interval: 3000; running: true; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 2000; running: root.expandedCard !== ""; repeat: true; onTriggered: root.refreshDetail() }

    // ── Compact readers ─────────────────────────────────────────────────────

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

    Process {
        id: gpuReader
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseGpuOutput(text) }
    }

    Process {
        id: cpuTempReader
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*/temp; do cat \"$z\" 2>/dev/null; done"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseCpuTemp(text) }
    }

    Process {
        id: gpuTempReader
        command: ["sh", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || { f=$(find /sys/class/drm/card*/device/hwmon/*/temp1_input 2>/dev/null | head -1); [ -n \"$f\" ] && cat \"$f\"; }"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.parseGpuTemp(text) }
    }

    Process {
        id: cpuCoresReader
        command: ["nproc"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.cpuCores = parseInt(text.trim()) || 1
        }
    }

    // ── Detail readers ──────────────────────────────────────────────────────

    Process {
        id: diskPartReader
        command: ["lsblk", "-b", "-o", "NAME,SIZE,FSTYPE,MOUNTPOINT,TYPE", "--pairs"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.parsePartitions(text) }
    }

    Process {
        id: topMemReader
        command: ["sh", "-c", "ps aux --sort=-%mem | head -4 | tail -3"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.topMemApps = root.parseTopApps(text, "mem") }
    }

    Process {
        id: topCpuReader
        command: ["sh", "-c", "ps aux --sort=-%cpu | head -4 | tail -3"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.topCpuApps = root.parseTopApps(text, "cpu") }
    }

    Process {
        id: gpuTopReader
        command: ["nvidia-smi", "--query-compute-apps=pid,used_memory,name", "--format=csv,noheader,nounits"]
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseGpuTopApps(text) }
    }

    // ── Disk Card ───────────────────────────────────────────────────────────

    Item {
        id: diskCard
        property bool isExpanded: root.expandedCard === "disk"
        property bool isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(0)
        y: isExpanded ? 0 : root.cardY(0)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        Behavior on x { Anim { type: Anim.SpatialDefault } }
        Behavior on y { Anim { type: Anim.SpatialDefault } }
        Behavior on width { Anim { type: Anim.SpatialDefault } }
        Behavior on height { Anim { type: Anim.SpatialDefault } }
        Behavior on opacity { Anim { type: Anim.EffectsDefault } }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            MouseArea {
                anchors.fill: parent
                onClicked: root.expandedCard = diskCard.isExpanded ? "" : "disk"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(8)
                spacing: Math.round(4)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Disk"; color: root.colors.subtext0; font.pointSize: 10; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text { text: root.diskUsed + " / " + root.diskTotal; color: root.colors.text; font.pointSize: 10 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: root.colors.bar
                    Rectangle {
                        width: parent.width * root.diskPct / 100
                        height: parent.height
                        radius: 3
                        color: root.colors.blue
                        Behavior on width { Anim { type: Anim.Progress } }
                    }
                }

                Item { Layout.preferredHeight: Math.round(8); visible: diskCard.isExpanded }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(2)
                    visible: diskCard.isExpanded

                    Repeater {
                        model: root.diskPartitions
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: modelData.name; color: root.colors.subtext1; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 1 }
                            Text { text: modelData.size; color: root.colors.text; font.pointSize: 9; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: modelData.fstype; color: root.colors.subtext0; font.pointSize: 9; Layout.fillWidth: true; horizontalAlignment: Text.AlignRight }
                            Text { text: modelData.mount; color: root.colors.blue; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 1 }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                Item { Layout.fillHeight: true; visible: !diskCard.isExpanded }
            }
        }
    }

    // ── RAM Card ────────────────────────────────────────────────────────────

    Item {
        id: ramCard
        property bool isExpanded: root.expandedCard === "ram"
        property bool isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(1)
        y: isExpanded ? 0 : root.cardY(0)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        Behavior on x { Anim { type: Anim.SpatialDefault } }
        Behavior on y { Anim { type: Anim.SpatialDefault } }
        Behavior on width { Anim { type: Anim.SpatialDefault } }
        Behavior on height { Anim { type: Anim.SpatialDefault } }
        Behavior on opacity { Anim { type: Anim.EffectsDefault } }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            MouseArea {
                anchors.fill: parent
                onClicked: root.expandedCard = ramCard.isExpanded ? "" : "ram"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(8)
                spacing: Math.round(4)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "RAM"; color: root.colors.subtext0; font.pointSize: 10; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text { text: root.memUsed + " / " + root.memTotal; color: root.colors.text; font.pointSize: 10 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: root.colors.bar
                    Rectangle {
                        width: parent.width * root.memPct / 100
                        height: parent.height
                        radius: 3
                        color: root.colors.green
                        Behavior on width { Anim { type: Anim.Progress } }
                    }
                }

                Item { Layout.preferredHeight: Math.round(8); visible: ramCard.isExpanded }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(2)
                    visible: ramCard.isExpanded

                    Repeater {
                        model: root.topMemApps
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: modelData.name; color: root.colors.subtext1; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 1 }
                            Text { text: modelData.pct; color: root.colors.text; font.pointSize: 9 }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                Item { Layout.fillHeight: true; visible: !ramCard.isExpanded }
            }
        }
    }

    // ── CPU Card ────────────────────────────────────────────────────────────

    Item {
        id: cpuCard
        property bool isExpanded: root.expandedCard === "cpu"
        property bool isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(0)
        y: isExpanded ? 0 : root.cardY(1)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        Behavior on x { Anim { type: Anim.SpatialDefault } }
        Behavior on y { Anim { type: Anim.SpatialDefault } }
        Behavior on width { Anim { type: Anim.SpatialDefault } }
        Behavior on height { Anim { type: Anim.SpatialDefault } }
        Behavior on opacity { Anim { type: Anim.EffectsDefault } }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            MouseArea {
                anchors.fill: parent
                onClicked: root.expandedCard = cpuCard.isExpanded ? "" : "cpu"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(8)
                spacing: Math.round(4)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "CPU"; color: root.colors.subtext0; font.pointSize: 10; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text { text: root.cpuPct + "%"; color: root.colors.text; font.pointSize: 10 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: root.colors.bar
                    Rectangle {
                        width: parent.width * root.cpuPct / 100
                        height: parent.height
                        radius: 3
                        color: root.colors.magenta
                        Behavior on width { Anim { type: Anim.Progress } }
                    }
                }

                Item { Layout.preferredHeight: Math.round(8); visible: cpuCard.isExpanded }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(2)
                    visible: cpuCard.isExpanded

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text { text: "Temp:"; color: root.colors.subtext0; font.pointSize: 9 }
                        Text { text: root.cpuTemp; color: root.colors.text; font.pointSize: 9 }
                    }

                    Repeater {
                        model: root.topCpuApps
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: modelData.name; color: root.colors.subtext1; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 1 }
                            Text { text: modelData.pct; color: root.colors.text; font.pointSize: 9 }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                Item { Layout.fillHeight: true; visible: !cpuCard.isExpanded }
            }
        }
    }

    // ── GPU Card ────────────────────────────────────────────────────────────

    Item {
        id: gpuCard
        property bool isExpanded: root.expandedCard === "gpu"
        property bool isHidden: root.expandedCard !== "" && !isExpanded
        x: isExpanded ? 0 : root.cardX(1)
        y: isExpanded ? 0 : root.cardY(1)
        width: isExpanded ? root.width : root.compactW
        height: isExpanded ? root.height : root.compactH
        opacity: isHidden ? 0 : 1
        z: isExpanded ? 10 : 0
        enabled: !isHidden
        Behavior on x { Anim { type: Anim.SpatialDefault } }
        Behavior on y { Anim { type: Anim.SpatialDefault } }
        Behavior on width { Anim { type: Anim.SpatialDefault } }
        Behavior on height { Anim { type: Anim.SpatialDefault } }
        Behavior on opacity { Anim { type: Anim.EffectsDefault } }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(8)
            color: root.colors.element_background
            Behavior on color { CAnim {} }

            MouseArea {
                anchors.fill: parent
                onClicked: root.expandedCard = gpuCard.isExpanded ? "" : "gpu"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Math.round(8)
                spacing: Math.round(4)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "GPU"; color: root.colors.subtext0; font.pointSize: 10; font.weight: Font.DemiBold }
                    Item { Layout.fillWidth: true }
                    Text { text: root.gpuAvailable ? root.gpuPct + "%" : "N/A"; color: root.colors.text; font.pointSize: 10 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: root.colors.bar
                    visible: root.gpuAvailable
                    Rectangle {
                        width: parent.width * root.gpuPct / 100
                        height: parent.height
                        radius: 3
                        color: root.colors.yellow
                        Behavior on width { Anim { type: Anim.Progress } }
                    }
                }

                Item { Layout.preferredHeight: Math.round(8); visible: gpuCard.isExpanded }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Math.round(2)
                    visible: gpuCard.isExpanded

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: root.gpuAvailable
                        Text { text: "Temp:"; color: root.colors.subtext0; font.pointSize: 9 }
                        Text { text: root.gpuTemp; color: root.colors.text; font.pointSize: 9 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        visible: root.gpuAvailable && root.gpuMemUsed !== ""
                        Text { text: "VRAM:"; color: root.colors.subtext0; font.pointSize: 9 }
                        Text { text: root.gpuMemUsed + " / " + root.gpuMemTotal; color: root.colors.text; font.pointSize: 9 }
                    }

                    Repeater {
                        model: root.gpuTopApps
                        delegate: RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text { text: modelData.name; color: root.colors.subtext1; font.pointSize: 9; Layout.fillWidth: true; elide: Text.ElideRight; maximumLineCount: 1 }
                            Text { text: modelData.pct; color: root.colors.text; font.pointSize: 9 }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                Item { Layout.fillHeight: true; visible: !gpuCard.isExpanded }
            }
        }
    }
}
