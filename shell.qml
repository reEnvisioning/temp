//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

import Quickshell
import QtQuick
import Quickshell.Io
import qs.lib
import "bar"
import "notif"
import "launcher"

ShellRoot {
    id: root

    property real uiScale: 1
    property string proxyStatus: "disabled"
    property string idleStatus: "unknown"

    // ── Settings ───────────────────────────────────────────────────────────
    Settings {
        id: settings
    }

    // ── Unified runtime theme file (always watched for updates) ────────────
    readonly property string configPath: settings.themeRuntimeFile()

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: applyConfig()
        onAdapterUpdated: applyConfig()

        JsonAdapter {
            id: config
            property real uiScale: 1
            property var colors: ({})
            property string themeName: ""
            property string mode: "dark"
        }
    }

    function applyConfig() {
        if (config.uiScale !== undefined) root.uiScale = config.uiScale
        colors.parse(config.colors)
    }

    // ── Always-on components ───────────────────────────────────────────────
    Colors {
        id: colors
        defaults: settings.defaults
    }

    // Re-apply colors if settings.defaults changes at runtime (hot reload).
    Connections {
        target: settings
        function onDefaultsChanged() {
            colors.parse(config.colors)
        }
    }

    BatteryMonitor {}

    // ── Toggleable modules (controlled by settings.modules.*) ──────────────
    Loader {
        id: clipMonLoader
        active: settings.moduleEnabled("clipboard")
        sourceComponent: clipComp
    }
    Component {
        id: clipComp
        ClipMon {}
    }

    Loader {
        id: barLoader
        active: settings.moduleEnabled("bar")
        sourceComponent: barComp
        onLoaded: {
            item.colors = colors
            item.uiScale = Qt.binding(function() { return root.uiScale })
            item.dndActive = Qt.binding(function() { return ipc.dndActive })
            item.proxyStatus = Qt.binding(function() { return root.proxyStatus })
            item.idleStatus = Qt.binding(function() { return root.idleStatus })
        }
    }
    Component {
        id: barComp
        Bar {}
    }

    Loader {
        id: notifLoader
        active: settings.moduleEnabled("notifications")
        sourceComponent: notifComp
        onLoaded: {
            item.colors = colors
            item.uiScale = Qt.binding(function() { return root.uiScale })
            item.dndActive = Qt.binding(function() { return ipc.dndActive })
        }
    }
    Component {
        id: notifComp
        NotifPanel {}
    }

    Loader {
        id: launcherLoader
        active: settings.moduleEnabled("launcher")
        sourceComponent: launcherComp
        onLoaded: {
            item.colors = colors
            item.uiScale = Qt.binding(function() { return root.uiScale })
            item.clipMon = Qt.binding(function() { return clipMonLoader.item })
        }
    }
    Component {
        id: launcherComp
        Launcher {}
    }

// ── Screen border frame (curves open when modules expand) ────────────
    BorderFrame {
        id: borderFrame
        colors: colors
        uiScale: root.uiScale
        barExpanded: barLoader.item ? barLoader.item.isExpanded : false
        barHeight: barLoader.item ? barLoader.item.animHeight : 0
        launcherOpen: launcherLoader.item ? launcherLoader.item.isOpen : false
        launcherHeight: launcherLoader.item ? launcherLoader.item.animHeight : 0
        notifHeight: notifLoader.item ? notifLoader.item.implicitHeight : 0
    }

    // ── Proxy / VPN status reader ──────────────────────────────────────────
    Process {
        id: proxyReader
        command: ["sh", "-c", "cat /run/wireguard-monitor/wg-vpn-status 2>/dev/null || { s=$(cat /sys/class/net/wg*/operstate 2>/dev/null); [ -n \"$s\" ] && echo \"$s\" | head -1 || echo unavailable; }"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.proxyStatus = text.trim()
        }
    }

    // ── Idle status reader (generic: reads whatever state backend exists) ───
    Process {
        id: idleReader
        command: ["sh", "-c", "state get idle-inhibit 2>/dev/null || echo unknown"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.idleStatus = text.trim()
        }
    }

    Timer {
        interval: 5000; running: true; repeat: true
        onTriggered: {
            proxyReader.running = false; proxyReader.running = true
            idleReader.running = false; idleReader.running = true
        }
    }

    // ── IPC handler (replaces all $XDG_RUNTIME_DIR file watchers) ──────────
    IpcHandler {
        id: ipc
        target: "panel"

        property bool dndActive: false
        property int activeTab: -1
        property bool launcherOpen: false

        onDndActiveChanged: {
            if (notifLoader.item) notifLoader.item.dndActive = dndActive
        }
        onActiveTabChanged: {
            if (activeTab >= 0 && activeTab <= 2 && barLoader.item)
                barLoader.item.activateTab(activeTab)
        }
        onLauncherOpenChanged: {
            if (!launcherLoader.item) return
            if (launcherOpen) {
                if (!launcherLoader.item.isOpen) launcherLoader.item.open()
            } else {
                if (launcherLoader.item.isOpen) launcherLoader.item.close()
            }
        }

        function toggleDnd(force: string) {
            if (force === "1" || force === true || force === 1)
                dndActive = true
            else if (force === "0" || force === false || force === 0)
                dndActive = false
            else
                dndActive = !dndActive
        }
        function dismissNotifications() {
            if (notifLoader.item) notifLoader.item.dismissAll()
        }
        function toggleLauncher() {
            if (!launcherLoader.item) return
            if (launcherLoader.item.isOpen) {
                launcherLoader.item.close()
                launcherOpen = false
            } else {
                launcherLoader.item.open()
                launcherOpen = true
            }
        }
        function toggleClipboard() {
            if (!launcherLoader.item) return
            if (launcherLoader.item.isOpen &&
                launcherLoader.item.activeProvider &&
                launcherLoader.item.activeProvider.name === "Clipboard") {
                launcherLoader.item.close()
                launcherOpen = false
            } else {
                launcherLoader.item.openWithPrefix("% ")
                launcherOpen = true
            }
        }
        function setTab(index: string) {
            activeTab = parseInt(index)
        }
        function showStartupNotif(app: string, summary: string, body: string) {
            Quickshell.execDetached(["notify-send",
                "--app-name=" + app, "--expire-time=4000", summary, body])
        }
        function configReloaded() {
            configFile.reload()
            if (launcherLoader.item) launcherLoader.item.refreshWallpapers()
        }
        function pushTextClip() {
            if (clipMonLoader.item) clipMonLoader.item.readTextClip()
        }
        function pushImageClip(name: string) {
            if (clipMonLoader.item) clipMonLoader.item.addImageClip(name)
        }
    }
}
