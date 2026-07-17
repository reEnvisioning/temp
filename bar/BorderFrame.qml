import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.lib

PanelWindow {
    id: root

    property var colors: ({})
    property real uiScale: 1
    property bool barExpanded: false
    property bool launcherOpen: false

    readonly property real thickness: Math.max(2, Math.round((settings.border.thickness || 10) * root.uiScale))
    readonly property real moduleWidth: Math.round(520 * root.uiScale)
    readonly property real moduleX: (root.screen.width - root.moduleWidth) / 2
    readonly property real curveRadius: Math.round(root.thickness * 1.5)

    readonly property Settings settings: Settings {}

    property real _topGapHalf: 0
    property real _bottomGapHalf: 0
    property real _topCurve: 0
    property real _bottomCurve: 0

    implicitWidth: root.screen.width
    implicitHeight: root.screen.height
    color: "transparent"
    focusable: false
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onBarExpandedChanged: {
        topGapAnim.stop()
        topGapAnim.from = root._topGapHalf
        topGapAnim.to = root.barExpanded ? root.moduleWidth / 2 : 0
        topGapAnim.type = root.barExpanded ? Anim.SpatialDefault : Anim.SpatialFast
        topGapAnim.start()

        topCurveAnim.stop()
        topCurveAnim.from = root._topCurve
        topCurveAnim.to = root.barExpanded ? root.curveRadius : 0
        topCurveAnim.type = root.barExpanded ? Anim.SpatialDefault : Anim.SpatialFast
        topCurveAnim.start()
    }

    onLauncherOpenChanged: {
        bottomGapAnim.stop()
        bottomGapAnim.from = root._bottomGapHalf
        bottomGapAnim.to = root.launcherOpen ? root.moduleWidth / 2 : 0
        bottomGapAnim.type = root.launcherOpen ? Anim.SpatialDefault : Anim.SpatialFast
        bottomGapAnim.start()

        bottomCurveAnim.stop()
        bottomCurveAnim.from = root._bottomCurve
        bottomCurveAnim.to = root.launcherOpen ? root.curveRadius : 0
        bottomCurveAnim.type = root.launcherOpen ? Anim.SpatialDefault : Anim.SpatialFast
        bottomCurveAnim.start()
    }

    Anim { id: topGapAnim; target: root; property: "_topGapHalf"; type: Anim.SpatialDefault }
    Anim { id: bottomGapAnim; target: root; property: "_bottomGapHalf"; type: Anim.SpatialDefault }
    Anim { id: topCurveAnim; target: root; property: "_topCurve"; type: Anim.SpatialDefault }
    Anim { id: bottomCurveAnim; target: root; property: "_bottomCurve"; type: Anim.SpatialDefault }

    // ── Top border (splits for bar) ─────────────────────────────────────
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.thickness

        Rectangle {
            x: 0
            width: Math.max(0, root.moduleX - root._topGapHalf)
            height: root.thickness
            radius: root._topCurve
            color: root.colors.surface
            Behavior on color { CAnim {} }
        }

        Rectangle {
            x: root.moduleX + root.moduleWidth + root._topGapHalf
            width: Math.max(0, root.screen.width - root.moduleX - root.moduleWidth - root._topGapHalf)
            height: root.thickness
            radius: root._topCurve
            color: root.colors.surface
            Behavior on color { CAnim {} }
        }
    }

    // ── Bottom border (splits for launcher) ─────────────────────────────
    Item {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.thickness

        Rectangle {
            x: 0
            width: Math.max(0, root.moduleX - root._bottomGapHalf)
            height: root.thickness
            radius: root._bottomCurve
            color: root.colors.surface
            Behavior on color { CAnim {} }
        }

        Rectangle {
            x: root.moduleX + root.moduleWidth + root._bottomGapHalf
            width: Math.max(0, root.screen.width - root.moduleX - root.moduleWidth - root._bottomGapHalf)
            height: root.thickness
            radius: root._bottomCurve
            color: root.colors.surface
            Behavior on color { CAnim {} }
        }
    }

    // ── Left border ─────────────────────────────────────────────────────
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.thickness
        color: root.colors.surface
        Behavior on color { CAnim {} }
    }

    // ── Right border ────────────────────────────────────────────────────
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.thickness
        color: root.colors.surface
        Behavior on color { CAnim {} }
    }
}
