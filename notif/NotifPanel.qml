import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.lib

PanelWindow {
    id: root

    required property var colors

    required property real uiScale

    function activeCount() {
        var c = 0
        for (var i = 0; i < notifColumn.children.length; i++)
            if (!notifColumn.children[i].dismissing) c++
        return c
    }

    anchors.top: true
    anchors.right: true
    margins { top: Math.round(8 * root.uiScale); right: 0 }

    implicitWidth: Math.round(880 * root.uiScale)
    implicitHeight: notifColumn.height

    color: "transparent"
    focusable: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "notifications"

    Column {
        id: notifColumn
        width: Math.round(380 * root.uiScale)
        anchors.right: parent.right
        anchors.rightMargin: Math.round(8 * root.uiScale)
        spacing: Math.round(6 * root.uiScale)
    }

    Component {
        id: notifCardComponent
        NotifCard {}
    }

    NotificationServer {
        id: notifServer
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        keepOnReload: false

        onNotification: (notification) => {
            notification.tracked = true

            // Replaceable indicators (Volume, DnD, etc.) bypass DnD blocking
            // so they can show their state even when DnD is active
            if (root.replaceableAppNames.indexOf(notification.appName) >= 0) {
                for (var i = 0; i < notifColumn.children.length; i++) {
                    var child = notifColumn.children[i]
                    if (!child.dismissing && child.isReusable && child.notifAppName === notification.appName) {
                        child.updateFrom(notification)
                        notification.dismiss()
                        return
                    }
                }
                var card = notifCardComponent.createObject(notifColumn, {
                    notif: notification,
                    colors: root.colors,
                    uiScale: root.uiScale,
                    isReusable: true
                })
                card.dismissed.connect(function() { card.destroy() })
                return
            }

            if (root.dndActive) return

            while (root.activeCount() >= 4) {
                for (var i = 0; i < notifColumn.children.length; i++) {
                    if (!notifColumn.children[i].dismissing) {
                        notifColumn.children[i].startExit()
                        break
                    }
                }
            }

            var card = notifCardComponent.createObject(notifColumn, {
                notif: notification,
                colors: root.colors,
                uiScale: root.uiScale,
                isReusable: false
            })

            card.dismissed.connect(function() {
                card.destroy()
            })
        }
    }

    property var replaceableAppNames: [
        "Volume Indicator",
        "Brightness Indicator",
        "DnD Indicator",
        "Hypridle Indicator",
        "Theme Indicator",
        "Mic Indicator",
        "Battery Indicator",
        "Power Profile Indicator",
        "Wallpaper Indicator",
        "Proxy",
        "Proxy Control"
    ]

    property bool dndActive: false

    onDndActiveChanged: {
        if (root.dndActive) root.dismissAll()
    }

    function dismissAll() {
        var children = notifColumn.children
        for (var i = children.length - 1; i >= 0; i--)
            children[i].startExit()
    }

    Connections {
        target: Qt.application
        function onStateChanged(state) {
            if (state === Qt.ApplicationInactive) {
                root.dismissAll()
            }
        }
    }
}
