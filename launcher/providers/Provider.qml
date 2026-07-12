import QtQuick

Item {
    id: root
    visible: false

    property string prefix: ""
    property string name: ""
    property string placeholderText: ""

    function query(text) { return []; }

    function activate(entry) {}

    property bool closeOnActivate: true

    property Component itemComponent: Component {
        MouseArea {
            id: rootItem
            required property var modelData
            required property bool selected
            required property var colors
            required property real uiScale
            property var launcher: null
            property int itemIndex: -1

            height: Math.round(44 * uiScale)
            hoverEnabled: true
            onClicked: {
                if (launcher && itemIndex >= 0) {
                    launcher.currentIndex = itemIndex
                    launcher.selectCurrent()
                }
            }
            onEntered: {
                if (launcher && itemIndex >= 0) {
                    launcher.currentIndex = itemIndex
                }
            }

            Rectangle {
                anchors.fill: parent
                color: selected ? colors.highlighted : "transparent"
                radius: Math.round(6 * uiScale)

            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                text: modelData ? (modelData.name || modelData.toString()) : ""
                color: colors.text
                font.pointSize: 10
                elide: Text.ElideRight
                width: parent.width - Math.round(20 * uiScale)
            }
        }
    }
}
