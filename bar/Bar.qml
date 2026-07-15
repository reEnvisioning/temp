import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.lib

PanelWindow {
    id: root

    property var colors: ({})

    property real uiScale: 1

    property real collapsedHeight: Math.round(2 * root.uiScale)
    property real expandedHeight: Math.round(180 * root.uiScale)
    property real panelWidth: Math.round(520 * root.uiScale)
    property bool isExpanded: false
    property int activeTab: 0
    property int _prevTab: 0
    property real animHeight: root.collapsedHeight
    property real widthScaleAnim: 1.0
    property real glowAlpha: 0
    property real tab0Slide: 0
    property real tab1Slide: 0
    property real tab2Slide: 0
    property bool dndActive: false
    property string proxyStatus: "disabled"
    property string idleStatus: "unknown"

    onIsExpandedChanged: {
        expandAnim.stop()
        expandAnim.from = root.animHeight
        expandAnim.to = root.isExpanded ? root.expandedHeight : root.collapsedHeight
        expandAnim.type = root.isExpanded ? Anim.SpatialDefault : Anim.SpatialFast
        expandAnim.start()

        widthTaperAnim.stop()
        if (root.isExpanded) {
            widthTaperAnim.from = 0.92
            widthTaperAnim.to = 1.0
            widthTaperAnim.type = Anim.SpatialDefault
        } else {
            widthTaperAnim.from = root.widthScaleAnim
            widthTaperAnim.to = 1.0
            widthTaperAnim.type = Anim.StandardAccel
        }
        widthTaperAnim.start()

        glowAnim.stop()
        glowAnim.from = root.glowAlpha
        glowAnim.to = root.isExpanded ? 1 : 0
        glowAnim.type = root.isExpanded ? Anim.EffectsDefault : Anim.EffectsFast
        glowAnim.start()
    }

    onActiveTabChanged: {
        if (root.activeTab !== root._prevTab) {
            var dir = root.activeTab > root._prevTab ? 1 : -1
            var offset = Math.round(20 * root.uiScale)

            var oldTab = root._prevTab
            var oldAnims = [tab0SlideAnim, tab1SlideAnim, tab2SlideAnim]
            oldAnims[oldTab].stop()
            oldAnims[oldTab].from = 0
            oldAnims[oldTab].to = -dir * offset
            oldAnims[oldTab].type = Anim.EffectsFast
            oldAnims[oldTab].start()

            var newTab = root.activeTab
            var newAnims = [tab0SlideAnim, tab1SlideAnim, tab2SlideAnim]
            newAnims[newTab].stop()
            newAnims[newTab].from = dir * offset
            newAnims[newTab].to = 0
            newAnims[newTab].type = Anim.EmphasizedDecel
            newAnims[newTab].start()

            root._prevTab = root.activeTab
        }
    }

    Anim { id: expandAnim; target: root; property: "animHeight"; type: Anim.SpatialDefault }
    Anim { id: widthTaperAnim; target: root; property: "widthScaleAnim"; type: Anim.SpatialDefault }
    Anim { id: glowAnim; target: root; property: "glowAlpha"; type: Anim.EffectsDefault }
    Anim { id: tab0SlideAnim; target: root; property: "tab0Slide"; type: Anim.EmphasizedDecel }
    Anim { id: tab1SlideAnim; target: root; property: "tab1Slide"; type: Anim.EmphasizedDecel }
    Anim { id: tab2SlideAnim; target: root; property: "tab2Slide"; type: Anim.EmphasizedDecel }

    anchors.top: true
    anchors.left: true
    anchors.right: true
    margins {
        left: (root.screen.width - root.panelWidth) / 2
        right: (root.screen.width - root.panelWidth) / 2
    }

    color: "transparent"
    focusable: false
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    implicitHeight: root.animHeight

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
        width: parent.width * (1.2 + root.glowAlpha * 0.4)
        height: parent.height * 1.5 + Math.round(12 * root.uiScale)
        radius: width * 0.5
        color: Qt.rgba(1, 1, 1, 0.035 * root.glowAlpha)
        visible: root.glowAlpha > 0.01
    }

    Rectangle {
        id: bg
        y: Math.round(-12 * root.uiScale)
        width: parent.width
        height: parent.height + Math.round(12 * root.uiScale)
        radius: Math.round(6 * root.uiScale)
        color: root.colors.background
        border.color: root.colors.border
        border.width: 1

        transform: Scale {
            origin.x: root.panelWidth / 2
            xScale: root.widthScaleAnim
        }

        Behavior on color {
            CAnim {}
        }
    }

    Item {
        id: contentRoot
        anchors.fill: parent
        visible: root.isExpanded
        clip: true

        Item {
            id: tabRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.round(26 * root.uiScale)

            Rectangle {
                id: tabIndicator
                anchors.bottom: parent.bottom
                width: parent.width / 3 * 0.4
                height: Math.round(2 * root.uiScale)
                radius: Math.round(1 * root.uiScale)
                color: root.colors.accent

                readonly property real tabW: parent.width / 3
                x: root.activeTab * tabW + (tabW - width) / 2

                Behavior on x { Anim { type: Anim.SpatialFast } }
                Behavior on color { CAnim {} }
            }

            Row {
                anchors.fill: parent

                Repeater {
                    model: ["States", "Home", "Monitor"]

                    delegate: Item {
                        required property int index
                        required property string modelData

                        width: tabRow.width / 3
                        height: tabRow.height

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: root.activeTab === index ? root.colors.text : root.colors.subtext0
                            font.family: root.colors.fontFamily
                            font.pointSize: 10
                            font.weight: root.activeTab === index ? Font.DemiBold : Font.Normal

                            Behavior on color {
                                CAnim {}
                            }
                        }

                        Item { implicitWidth: 1; implicitHeight: 1 }
                    }
                }
            }
        }

        Rectangle {
            anchors.top: tabRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.round(1 * root.uiScale)
            color: root.colors.divider
        }

        Item {
            anchors.top: tabRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(1 * root.uiScale)

            StatesTab {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.uiScale)
                opacity: root.activeTab === 0 ? 1 : 0
                colors: root.colors
                dndActive: root.dndActive
                proxyStatus: root.proxyStatus
                idleStatus: root.idleStatus
                transform: Translate { x: root.tab0Slide }
                Behavior on opacity { Anim { type: Anim.EffectsDefault } }
            }

            HomeTab {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.uiScale)
                opacity: root.activeTab === 1 ? 1 : 0
                colors: root.colors
                transform: Translate { x: root.tab1Slide }
                Behavior on opacity { Anim { type: Anim.EffectsDefault } }
            }

            MonitorTab {
                anchors.fill: parent
                anchors.margins: Math.round(8 * root.uiScale)
                opacity: root.activeTab === 2 ? 1 : 0
                colors: root.colors
                transform: Translate { x: root.tab2Slide }
                Behavior on opacity { Anim { type: Anim.EffectsDefault } }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            autoCollapseTimer.stop()
            collapseTimer.stop()
            root.activeTab = Math.floor(mouseX / width * 3)
            root.isExpanded = true
        }

        onPositionChanged: {
            collapseTimer.stop()
            if (root.isExpanded && mouseY < tabRow.height)
                root.activeTab = Math.floor(mouseX / width * 3)
        }

        onExited: {
            collapseTimer.restart()
        }
    }

    Timer {
        id: collapseTimer
        interval: 400
        onTriggered: {
            if (!hoverArea.containsMouse)
                root.isExpanded = false
        }
    }

    Timer {
        id: autoCollapseTimer
        interval: 3000
        onTriggered: root.isExpanded = false
    }

    function activateTab(index: int): void {
        if (index >= 0 && index <= 2) {
            root.activeTab = index
            root.isExpanded = true
            autoCollapseTimer.restart()
        }
    }
}
