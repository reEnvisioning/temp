import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.lib

Item {
    id: root

    required property var notif
    required property var colors
    required property real uiScale

    signal dismissed()

    property bool dismissing: false
    property bool isReusable: false
    property bool reused: false
    property bool showActions: false
    property bool actionInvoked: false
    property bool actionBtnPressed: false

    function updateFrom(notification) {
        reused = true
        actionInvoked = false
        try {
            var n = notification
            notifSummary = n.summary || ""
            notifBody = n.body || ""
            notifAppName = n.appName || ""
            notifUrgency = typeof n.urgency === "number" ? n.urgency : 1
            notifExpireTimeout = typeof n.expireTimeout === "number" ? n.expireTimeout : -1
            notifHasImage = !!n.image
            if (n.actions) notifActions = n.actions
        } catch (e) {
            console.log("NotifCard: update error", e)
        }
        dismissTimer.restart()
    }

    property string notifSummary: ""
    property string notifBody: ""
    property string notifAppName: ""
    property int notifUrgency: 1
    property var notifActions: []
    property bool notifHasImage: false
    property int notifExpireTimeout: -1

    width: parent ? parent.width : 380
    height: card.height

    x: 0
    opacity: 0
    property real cardScale: 0.5

    transform: [
        Scale { origin.x: width; origin.y: 0; xScale: root.cardScale; yScale: root.cardScale }
    ]

    Anim { id: cardScaleAnim; target: root; property: "cardScale" }
    Anim { id: slideAnim; target: root; property: "x" }
    Anim { id: opacityAnim; target: root; property: "opacity" }

    Component.onCompleted: {
        cardScaleAnim.stop()
        cardScaleAnim.from = 0.5
        cardScaleAnim.to = 1.0
        cardScaleAnim.type = Anim.Emphasized
        cardScaleAnim.start()

        slideAnim.stop()
        slideAnim.from = 40
        slideAnim.to = 0
        slideAnim.type = Anim.SpatialDefault
        slideAnim.start()

        opacityAnim.stop()
        opacityAnim.from = 0
        opacityAnim.to = 1
        opacityAnim.type = Anim.EffectsSlow
        opacityAnim.start()
        try {
            var n = root.notif
            notifSummary = n.summary || ""
            notifBody = n.body || ""
            notifAppName = n.appName || ""
            notifUrgency = typeof n.urgency === "number" ? n.urgency : 1
            notifExpireTimeout = typeof n.expireTimeout === "number" ? n.expireTimeout : -1
            notifHasImage = !!n.image
            if (n.actions) notifActions = n.actions
        } catch (e) {
            console.log("NotifCard: copy error", e)
        }
    }

    function startExit(direction) {
        if (root.dismissing) return
        root.dismissing = true

        var dir = direction !== undefined ? (direction > 0 ? 1 : -1) : 1

        cardScaleAnim.stop()
        cardScaleAnim.from = root.cardScale
        cardScaleAnim.to = 0.3
        cardScaleAnim.type = Anim.StandardAccel
        cardScaleAnim.start()

        slideAnim.stop()
        slideAnim.from = root.x
        slideAnim.to = root.width * 1.2 * dir
        slideAnim.type = Anim.StandardAccel
        slideAnim.start()

        opacityAnim.stop()
        opacityAnim.from = root.opacity
        opacityAnim.to = 0
        opacityAnim.type = Anim.StandardAccel
        opacityAnim.start()

        exitTimer.start()
        try { root.notif.dismiss() } catch (e) {}
    }

    Timer {
        id: exitTimer
        interval: 500
        onTriggered: {
            root.visible = false
            root.dismissed()
        }
    }

    Rectangle {
        id: card
        width: parent.width
        height: innerLayout.height + Math.round(16 * root.uiScale)
        radius: Math.round(6 * root.uiScale)
        color: root.colors.background
        border.color: root.colors.border
        border.width: 1
        clip: true

        Behavior on color { CAnim {} }

        // Critical urgency subtle tint
        Rectangle {
            anchors.fill: parent
            radius: Math.round(6 * root.uiScale)
            color: root.colors.red
            opacity: root.notifUrgency === 2 ? 0.08 : 0
            Behavior on opacity { Anim { type: Anim.EffectsDefault } }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            preventStealing: true
            cursorShape: root.notifActions.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

            property point startScene: Qt.point(0, 0)

            onEntered: {
                if (!root.actionInvoked)
                    dismissTimer.stop()
            }
            onExited: {
                if (!pressed)
                    dismissTimer.restart()
            }

            onPressed: event => {
                slideAnim.stop()
                cardScaleAnim.stop()
                opacityAnim.stop()
                dismissTimer.stop()
                startScene = mouseArea.mapToItem(null, event.x, event.y)
            }

            onReleased: event => {
                if (root.dismissing) return

                if (!containsMouse)
                    dismissTimer.restart()

                var scene = mouseArea.mapToItem(null, event.x, event.y)
                var dx = scene.x - startScene.x
                if (Math.abs(dx) > root.width * 0.3) {
                    root.startExit(dx)
                } else {
                    cardScaleAnim.stop()
                    cardScaleAnim.from = root.cardScale
                    cardScaleAnim.to = 1.0
                    cardScaleAnim.type = Anim.EmphasizedDecel
                    cardScaleAnim.start()
                    opacityAnim.stop()
                    opacityAnim.from = root.opacity
                    opacityAnim.to = 1
                    opacityAnim.type = Anim.EffectsDefault
                    opacityAnim.start()
                    slideAnim.stop()
                    slideAnim.from = root.x
                    slideAnim.to = 0
                    slideAnim.type = Anim.EmphasizedDecel
                    slideAnim.start()
                }
            }

            onPositionChanged: event => {
                if (pressed && !root.dismissing) {
                    slideAnim.stop()
                    var scene = mouseArea.mapToItem(null, event.x, event.y)
                    root.x = scene.x - startScene.x
                    var progress = Math.abs(scene.x - startScene.x) / (root.width * 0.7)
                    root.cardScale = 1 - progress * 0.2
                    root.opacity = Math.max(0.2, 1 - progress * 0.8)
                }
            }

            onClicked: event => {
                if (root.dismissing) return

                if (event.button === Qt.LeftButton && root.notifActions.length > 0 && !root.actionBtnPressed) {
                    root.actionInvoked = true
                    try { root.notifActions[0].invoke() } catch (e) {}
                    dismissTimer.restart()
                } else if (event.button === Qt.MiddleButton) {
                    root.startExit()
                } else if (event.button === Qt.RightButton) {
                    root.showActions = !root.showActions
                }
                root.actionBtnPressed = false
            }
        }

        ColumnLayout {
            id: innerLayout
            x: Math.round(12 * root.uiScale); y: Math.round(8 * root.uiScale)
            width: parent.width - Math.round(24 * root.uiScale)
            spacing: Math.round(4 * root.uiScale)

            Text {
                Layout.fillWidth: true
                text: root.notifSummary
                color: root.colors.text
                font.pointSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.notifBody
                color: root.colors.subtext1
                font.pointSize: 9
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                visible: root.notifBody !== ""
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.maximumHeight: Math.round(180 * root.uiScale)
                radius: Math.round(6 * root.uiScale)
                color: root.colors.surface
                clip: true
                visible: notifImg.status === Image.Ready

                Image {
                    id: notifImg
                    anchors.fill: parent
                    source: root.notif.image
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }

            Row {
                Layout.fillWidth: true
                spacing: 6
                visible: root.notifActions.length > 0 && root.showActions
                layoutDirection: Qt.RightToLeft

                Repeater {
                    model: root.notifActions

                    delegate: Rectangle {
                        required property var modelData

                        id: actionBtn
                        height: Math.round(26 * root.uiScale)
                        radius: Math.round(3 * root.uiScale)
                        color: actionBtnMouse.containsMouse ? root.colors.highlighted : root.colors.surface
                        implicitWidth: actionLabel.width + Math.round(14 * root.uiScale)

                        Behavior on color { CAnim {} }

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: root.colors.text
                            font.pointSize: 9
                        }

                        MouseArea {
                            id: actionBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: { root.actionBtnPressed = true }
                            onClicked: {
                                try { modelData.invoke() } catch (e) {}
                            }
                        }
                    }
                }
            }
        }

        Timer {
            id: dismissTimer
            interval: root.actionInvoked ? 3000 : root.notifExpireTimeout > 0
                ? root.notifExpireTimeout
                : root.notifUrgency === 0 ? 5000
                : root.notifUrgency === 2 ? 0
                : 7000
            running: interval > 0 && !root.dismissing
            repeat: false
            onTriggered: root.startExit()
        }
    }
}
