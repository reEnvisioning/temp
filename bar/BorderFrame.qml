import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick.Shapes
import qs.lib

PanelWindow {
    id: root

    property var colors: ({})
    property real uiScale: 1
    property bool barExpanded: false
    property real barHeight: 0
    property real barWidth: Math.round(520 * root.uiScale)
    property real barX: (root.screen.width - root.barWidth) / 2
    property bool launcherOpen: false
    property real launcherHeight: 0
    property real launcherWidth: Math.round(520 * root.uiScale)
    property real launcherX: (root.screen.width - root.launcherWidth) / 2

    // Notifications (right side)
    property real notifHeight: 0
    property real notifWidth: Math.round(880 * root.uiScale)
    property real notifX: root.screen.width - root.notifWidth - Math.round(8 * root.uiScale)
    property real notifY: Math.round(8 * root.uiScale)

    // Launcher
    property real launcherMargin: Math.round(8 * root.uiScale)

    required property Settings settings
    readonly property real borderWidth: Math.max(1, Math.round((settings.border?.thickness ?? 1) * root.uiScale))
    readonly property color borderColor: root.colors.surface
    readonly property real earBulge: Math.round(28 * root.uiScale)
    readonly property real earCurveDepth: Math.round(40 * root.uiScale)

    property real _barEarHeight: 0
    property real _launcherEarHeight: 0
    property real _notifEarHeight: 0

    // Track actual visual heights for ears
    readonly property real barVisualHeight: root.barHeight + Math.round(12 * root.uiScale)
    readonly property real launcherVisualHeight: root.launcherHeight + root.launcherMargin
    readonly property real notifVisualHeight: root.notifHeight

    implicitWidth: root.screen.width
    implicitHeight: root.screen.height
    color: "transparent"
    focusable: false
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onBarExpandedChanged: {
        barEarAnim.stop()
        barEarAnim.from = root._barEarHeight
        barEarAnim.to = root.barExpanded ? root.barVisualHeight : 0
        barEarAnim.type = root.barExpanded ? Anim.SpatialDefault : Anim.SpatialFast
        barEarAnim.start()
    }

    onBarHeightChanged: {
        if (root.barExpanded) {
            barEarAnim.stop()
            barEarAnim.from = root._barEarHeight
            barEarAnim.to = root.barVisualHeight
            barEarAnim.type = Anim.SpatialDefault
            barEarAnim.start()
        }
    }

onLauncherOpenChanged: {
        launcherEarAnim.stop()
        launcherEarAnim.from = root._launcherEarHeight
        launcherEarAnim.to = root.launcherOpen ? root.launcherVisualHeight : 0
        launcherEarAnim.type = root.launcherOpen ? Anim.SpatialDefault : Anim.SpatialFast
        launcherEarAnim.start()
    }

onLauncherHeightChanged: {
        if (root.launcherOpen) {
            launcherEarAnim.stop()
            launcherEarAnim.from = root._launcherEarHeight
            launcherEarAnim.to = root.launcherVisualHeight
            launcherEarAnim.type = Anim.SpatialDefault
            launcherEarAnim.start()
        }
    }

    onNotifHeightChanged: {
        notifEarAnim.stop()
        notifEarAnim.from = root._notifEarHeight
        notifEarAnim.to = root.notifVisualHeight
        notifEarAnim.type = Anim.SpatialDefault
        notifEarAnim.start()
    }

    Anim { id: barEarAnim; target: root; property: "_barEarHeight"; type: Anim.SpatialDefault }
    Anim { id: launcherEarAnim; target: root; property: "_launcherEarHeight"; type: Anim.SpatialDefault }
    Anim { id: notifEarAnim; target: root; property: "_notifEarHeight"; type: Anim.SpatialDefault }

    // ═══════════════════════════════════════════════════════════════════════
    // BASE BORDER — 4 thin rectangles (1px)
    // ═══════════════════════════════════════════════════════════════════════

    // Top border
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.borderWidth
        color: root.borderColor
        Behavior on color { CAnim {} }
    }

    // Bottom border
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.borderWidth
        color: root.borderColor
        Behavior on color { CAnim {} }
    }

    // Left border
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.borderWidth
        color: root.borderColor
        Behavior on color { CAnim {} }
    }

    // Right border
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.borderWidth
        color: root.borderColor
        Behavior on color { CAnim {} }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BAR EARS — extend down from top border along bar sides (outward bulge)
    // ═══════════════════════════════════════════════════════════════════════

    // Left ear — attaches at bar left edge, curves outward then down
    Shape {
        id: barLeftEar
        x: root.barX
        y: root.borderWidth
        width: root.borderWidth + root.earBulge
        height: root._barEarHeight
        visible: root._barEarHeight > 1

        ShapePath {
            fillColor: root.borderColor
            strokeColor: "transparent"

            // Start at top-left corner of ear (on top border)
            startX: 0; startY: 0

            // Line down the inner edge (along bar left side)
            PathLine { x: 0; y: root._barEarHeight }

            // Cubic curve outward (bulge) then back to border
PathCubic {
                x: root.borderWidth + root.earBulge
                y: root._barEarHeight
                control1X: root.earBulge * 0.6
                control1Y: root._barEarHeight - root.earCurveDepth
                control2X: root.earBulge * 0.6
                control2Y: root._barEarHeight - root.earCurveDepth
            }

            // Line back up the outer edge (the bulge)
            PathLine { x: root.borderWidth + root.earBulge; y: 0 }

            // Close path
            PathLine { x: 0; y: 0 }
        }
    }

    // Right ear — attaches at bar right edge, curves outward then down
    Shape {
        id: barRightEar
        x: root.barX + root.barWidth - root.borderWidth - root.earBulge
        y: root.borderWidth
        width: root.borderWidth + root.earBulge
        height: root._barEarHeight
        visible: root._barEarHeight > 1

        ShapePath {
            fillColor: root.borderColor
            strokeColor: "transparent"

            // Start at top-right corner of ear (on top border)
            startX: root.borderWidth + root.earBulge; startY: 0

            // Line down the inner edge (along bar right side)
            PathLine { x: root.earBulge; y: root._barEarHeight }

            // Cubic curve outward (bulge) then back to border
PathCubic {
                x: 0
                y: root._barEarHeight
                control1X: root.earBulge * 0.4
                control1Y: root._barEarHeight - root.earCurveDepth
                control2X: root.earBulge * 0.4
                control2Y: root._barEarHeight - root.earCurveDepth
            }

            // Line back up the outer edge
            PathLine { x: 0; y: 0 }

            // Close path
            PathLine { x: root.borderWidth + root.earBulge; y: 0 }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LAUNCHER EARS — extend up from bottom border along launcher sides
    // ═══════════════════════════════════════════════════════════════════════

    // Left ear — attaches at launcher left edge, curves outward then up
    Shape {
        id: launcherLeftEar
        x: root.launcherX
        y: root.screen.height - root.borderWidth - root.launcherMargin - root._launcherEarHeight
        width: root.borderWidth + root.earBulge
        height: root._launcherEarHeight
        visible: root._launcherEarHeight > 1

        ShapePath {
            fillColor: root.borderColor
            strokeColor: "transparent"

            // Start at bottom-left corner of ear (on bottom border)
            startX: 0; startY: root._launcherEarHeight

            // Line up the inner edge (along launcher left side)
            PathLine { x: 0; y: 0 }

            // Cubic curve outward (bulge)
            PathCubic {
                x: root.borderWidth + root.earBulge
                y: 0
                control1X: root.earBulge * 0.6
                control1Y: root.earCurveDepth
                control2X: root.earBulge * 0.6
                control2Y: root.earCurveDepth
            }

            // Line back down the outer edge
            PathLine { x: root.borderWidth + root.earBulge; y: root._launcherEarHeight }

            // Close path
            PathLine { x: 0; y: root._launcherEarHeight }
        }
    }

    // Right ear — attaches at launcher right edge, curves outward then up
    Shape {
        id: launcherRightEar
        x: root.launcherX + root.launcherWidth - root.borderWidth - root.earBulge
        y: root.screen.height - root.borderWidth - root.launcherMargin - root._launcherEarHeight
        width: root.borderWidth + root.earBulge
        height: root._launcherEarHeight
        visible: root._launcherEarHeight > 1

        ShapePath {
            fillColor: root.borderColor
            strokeColor: "transparent"

            // Start at bottom-right corner of ear (on bottom border)
            startX: root.borderWidth + root.earBulge; startY: root._launcherEarHeight

            // Line up the inner edge (along launcher right side)
            PathLine { x: root.earBulge; y: 0 }

            // Cubic curve outward (bulge)
            PathCubic {
                x: 0
                y: 0
                control1X: root.earBulge * 0.4
                control1Y: root.earCurveDepth
                control2X: root.earBulge * 0.4
                control2Y: root.earCurveDepth
            }

            // Line back down the outer edge
            PathLine { x: 0; y: root._launcherEarHeight }

            // Close path
            PathLine { x: root.borderWidth + root.earBulge; y: root._launcherEarHeight }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // NOTIFICATION EARS — extend left from right border along notif edges
    // ═══════════════════════════════════════════════════════════════════════

    // Top ear — attaches at notification top edge, curves outward then left
    Shape {
        id: notifTopEar
        x: root.screen.width - root.borderWidth - root.earBulge
        y: root.notifY
        width: root.earBulge + root.borderWidth
        height: root._notifEarHeight
        visible: root._notifEarHeight > 1

        ShapePath {
            fillColor: root.borderColor
            strokeColor: "transparent"

            // Start at top-right corner of ear (on right border)
            startX: root.earBulge + root.borderWidth; startY: 0

            // Line left the inner edge (along notification top)
            PathLine { x: root.earBulge; y: 0 }

            // Cubic curve outward (bulge)
            PathCubic {
                x: 0
                y: root._notifEarHeight
                control1X: root.earBulge * 0.4
                control1Y: root._notifEarHeight * 0.3
                control2X: root.earBulge * 0.4
                control2Y: root._notifEarHeight - root.earCurveDepth
            }

            // Line back right the outer edge
            PathLine { x: root.earBulge + root.borderWidth; y: root._notifEarHeight }

            // Close path
            PathLine { x: root.earBulge + root.borderWidth; y: 0 }
        }
    }

    // Bottom ear — attaches at notification bottom edge, curves outward then left
    Shape {
        id: notifBottomEar
        x: root.screen.width - root.borderWidth - root.earBulge
        y: root.notifY + root._notifEarHeight - root.earBulge
        width: root.earBulge + root.borderWidth
        height: root._notifEarHeight
        visible: root._notifEarHeight > 1

        ShapePath {
            fillColor: root.borderColor
            strokeColor: "transparent"

            // Start at bottom-right corner of ear (on right border)
            startX: root.earBulge + root.borderWidth; startY: root._notifEarHeight

            // Line left the inner edge (along notification bottom)
            PathLine { x: root.earBulge; y: root._notifEarHeight }

            // Cubic curve outward (bulge)
            PathCubic {
                x: 0
                y: 0
                control1X: root.earBulge * 0.4
                control1Y: root.earCurveDepth
                control2X: root.earBulge * 0.4
                control2Y: root.earCurveDepth
            }

            // Line back right the outer edge
            PathLine { x: root.earBulge + root.borderWidth; y: 0 }

            // Close path
            PathLine { x: root.earBulge + root.borderWidth; y: root._notifEarHeight }
        }
    }
}