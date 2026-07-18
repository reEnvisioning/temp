import QtQuick
import QtQuick.Layouts
import qs.lib

Item {
    id: root

    required property var colors
    required property real uiScale
    required property string cardId
    required property string cardTitle
    required property string cardValue
    required property real progressValue
    required property color progressColor
    property bool isExpanded: false
    property bool isHidden: false
    property var expandedContent: null

    signal clicked()

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
            onClicked: root.clicked()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(8)
            spacing: Math.round(4)

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                Text { text: root.cardTitle; color: root.colors.subtext0; font.pointSize: 10; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
                Text { text: root.cardValue; color: root.colors.text; font.pointSize: 10 }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: root.colors.bar
                visible: root.progressValue >= 0
                Rectangle {
                    width: parent.width * root.progressValue / 100
                    height: parent.height
                    radius: 3
                    color: root.progressColor
                    Behavior on width { Anim { type: Anim.Progress } }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: root.isExpanded && root.expandedContent !== null
                sourceComponent: root.expandedContent
            }

            Item { Layout.fillHeight: true; visible: !root.isExpanded }
        }
    }
}
