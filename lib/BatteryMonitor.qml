import QtQuick
import Quickshell.Io

Item {
    id: root

    property int batteryPct: -1
    property bool isCharging: false
    property bool notified10: false
    property bool notified20: false
    property bool notified95: false

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.readBattery()
    }

    Process {
        id: batteryReader
        command: ["sh", "-c",
            "c=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo -1); " +
            "s=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null); " +
            "echo \"$c $s\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ")
                root.batteryPct = parseInt(parts[0]) || -1
                root.isCharging = parts.length > 1 && parts[1] === "Charging"
                root.checkThresholds()
            }
        }
    }

    function readBattery() {
        batteryReader.running = false
        batteryReader.running = true
    }

    function checkThresholds() {
        if (batteryPct < 0) return

        if (isCharging) {
            notified10 = false
            notified20 = false
            if (batteryPct >= 95 && !notified95) {
                notified95 = true
                sendChargedNotification(batteryPct)
            }
            if (batteryPct < 90) notified95 = false
            return
        }

        // Not charging
        notified95 = false

        if (batteryPct > 25) {
            notified10 = false
            notified20 = false
            return
        }

        if (batteryPct <= 10 && !notified10) {
            notified10 = true
            sendNotification(batteryPct, "critical")
            return
        }

        if (batteryPct <= 20 && !notified20) {
            notified20 = true
            sendNotification(batteryPct, "normal")
        }
    }

    function sendNotification(level, urgency) {
        var summary = urgency === "critical" ? "Critical Battery" : "Low Battery"
        notifProcess.command = ["sh", "-c",
            "notify-send --urgency=" + urgency +
            " --app-name=System \"" + summary + "\" \"Battery at " + level + "%\""]
        notifProcess.running = false
        notifProcess.running = true
    }

    function sendChargedNotification(level) {
        notifProcess.command = ["sh", "-c",
            "notify-send --app-name=\"Battery Indicator\" --expire-time=4000 \"Battery Charged\" \"Battery at " + level + "%\""]
        notifProcess.running = false
        notifProcess.running = true
    }

    Process {
        id: notifProcess
        command: ["true"]
        running: false
    }
}
