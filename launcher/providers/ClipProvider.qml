import QtQuick
import Quickshell

Item {
    id: root
    visible: false

    property string prefix: "% "
    property string name: "Clipboard"
    property string placeholderText: "Search clipboard..."
    property bool closeOnActivate: true

    property var clipMon: null
    property int refreshKey: 0

    Connections {
        target: root.clipMon
        function onEntriesChanged() {
            root.refreshKey++
        }
    }

    function _findIndex(content) {
        if (!root.clipMon) return -1
        for (var i = 0; i < root.clipMon.entries.length; i++) {
            if (root.clipMon.entries[i].content === content) return i
        }
        return -1
    }

    function query(text) {
        if (!root.clipMon || !root.clipMon.entries) return []

        var entries = root.clipMon.entries
        if (!text || !text.trim()) {
            return entries.map(function(e) {
                return { entry: e }
            })
        }

        var lower = text.toLowerCase()
        var results = []
        for (var i = 0; i < entries.length; i++) {
            var c = entries[i].content
            if (c && c.toLowerCase().indexOf(lower) !== -1)
                results.push({ entry: entries[i] })
        }
        return results
    }

    function textFor(result) {
        if (!result || !result.entry) return ""
        return result.entry.mimeType === "image/png"
            ? result.entry.content
            : result.entry.preview
    }

    function activate(result) {
        if (!result || !root.clipMon) return
        var idx = root._findIndex(result.entry.content)
        if (idx !== -1) root.clipMon.copyAt(idx)
    }

    function altActivate(result) {
        if (!result || !root.clipMon) return
        var idx = root._findIndex(result.entry.content)
        if (idx !== -1) root.clipMon.togglePin(idx)
    }

    function remove(result) {
        if (!result || !root.clipMon) return
        var idx = root._findIndex(result.entry.content)
        if (idx !== -1) root.clipMon.removeAt(idx)
    }

    function removeAll() {
        if (root.clipMon) root.clipMon.clearAll()
    }

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

            Row {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(8 * uiScale)

                Text {
                    text: {
                        if (!modelData || !modelData.entry) return ""
                        var e = modelData.entry
                        if (e.mimeType === "image/png") return "[image] " + e.content
                        return e.truncated
                            ? e.preview + "\u2026 (" + e.charCount + ")"
                            : e.preview
                    }
                    color: colors.text
                    font.pointSize: 10
                    elide: Text.ElideRight
                    width: rootItem.width - Math.round(40 * uiScale)
                }

                Text {
                    text: {
                        if (!modelData || !modelData.entry) return ""
                        return modelData.entry.pinned ? "\u2605" : "\u2606"
                    }
                    color: colors.text
                    font.pointSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
