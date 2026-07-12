import QtQuick
import Quickshell

Item {
    id: root
    visible: false

    property string prefix: "= "
    property string name: "Calc"
    property string placeholderText: "Calculate..."
    property bool closeOnActivate: false

    property var _history: []

    function query(text) {
        if (!text || !text.trim()) return _history.slice()

        var result = evaluate(text)
        var lower = text.toLowerCase()
        var results = []

        if (result !== null)
            results.push({ expression: text, result: result, isCurrent: true })

        for (var i = 0; i < _history.length; i++) {
            if (_history[i].expression.toLowerCase().indexOf(lower) !== -1 &&
                (result === null || _history[i].expression !== text))
                results.push(_history[i])
        }

        return results
    }

    function evaluate(expr) {
        try {
            var result = Function('"use strict"; return (' + expr + ')')()
            return result !== undefined ? String(result) : null
        } catch (e) {
            return null
        }
    }

    function textFor(entry) { return entry ? entry.result : "" }

    function activate(entry) {
        if (entry && entry.result) {
            addToHistory(entry.expression, entry.result)
            Quickshell.execDetached(["wl-copy", entry.result])
        }
    }

    function remove(entry) {
        var idx = _history.indexOf(entry)
        if (idx >= 0) _history.splice(idx, 1)
    }

    function removeAll() {
        _history = []
    }

    function addToHistory(expr, res) {
        for (var i = 0; i < _history.length; i++) {
            if (_history[i].expression === expr) {
                _history.splice(i, 1)
                break
            }
        }
        _history.unshift({ expression: expr, result: res })
        if (_history.length > 100) _history.length = 100
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

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                text: modelData ? ("= " + modelData.expression) : ""
                color: modelData && modelData.isCurrent ? colors.text : colors.subtext0
                font.pointSize: 10
                font.family: "monospace"
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                text: modelData ? ("= " + modelData.result) : ""
                color: colors.green || colors.subtext0
                font.pointSize: 10
                font.family: "monospace"
            }
        }
    }
}
