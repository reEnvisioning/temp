import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.lib
import "providers"

PanelWindow {
    id: root

    property var colors: ({})
    property real uiScale: 1

    property real panelWidth: Math.round(520 * root.uiScale)
    property real inputHeight: Math.round(40 * root.uiScale)
    property real itemHeight: Math.round(44 * root.uiScale)
    property real emptyListHeight: Math.round(44 * root.uiScale)
    property real resultWidthOffset: Math.round(8 * root.uiScale)
    property bool isOpen: false
    property bool _pendingCleanup: false
    property bool _isClosing: false
    property bool _queryChanged: false
    property real resultAnimHeight: 0
    property real inputAnimOpacity: 1
    property real inputSlideOffset: Math.round(8 * root.uiScale)
    property real inputSlideY: 0

    // Settings drives which providers are active. Keys must match
    // settings.launcherProviders (app, shell, terminal, ssh, theme,
    // wallpaper, system, share, emoji, calc, clipboard).
    readonly property Settings _settings: Settings {}

    property var _wp: null
    property var _sp: null
    property var _cp: null
    property var clipMon: null

    property list<QtObject> providers: []

    Component.onCompleted: rebuildProviders()

    Component { id: appProvCmp; AppProvider {} }
    Component { id: shellProvCmp; ShellProvider {} }
    Component { id: terminalProvCmp; TerminalProvider {} }
    Component { id: sshProvCmp; SSHProvider {} }
    Component { id: themeProvCmp; ThemeProvider {} }
    Component { id: wallpaperProvCmp; WallpaperProvider {} }
    Component { id: systemProvCmp; SystemProvider {} }
    Component { id: shareProvCmp; ShareProvider {} }
    Component { id: emojiProvCmp; EmojiProvider {} }
    Component { id: calcProvCmp; CalcProvider {} }
    Component { id: clipProvCmp; ClipProvider {} }

    Anim { id: resultExpandAnim; target: root; property: "resultAnimHeight"; type: Anim.SpatialDefault }
    Anim { id: resultCloseAnim; target: root; property: "resultAnimHeight"; type: Anim.EffectsFast }
    Anim { id: inputOpacityAnim; target: root; property: "inputAnimOpacity"; type: Anim.SpatialDefault }
    Anim { id: inputSlideAnim; target: root; property: "inputSlideY"; type: Anim.SpatialDefault }

    NumberAnimation {
        id: highlightSlide
        target: highlight
        property: "y"
        duration: 200
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.34, 0.8, 0.34, 1, 1, 1]
    }

    Connections {
        target: resultCloseAnim
        function onFinished() {
            if (root._isClosing) {
                inputSlideAnim.type = Anim.EffectsFast
                inputSlideAnim.from = 0
                inputSlideAnim.to = root.inputSlideOffset
                inputSlideAnim.start()
            }
        }
    }

    Connections {
        target: inputSlideAnim
        function onFinished() {
            if (root._isClosing) {
                root._isClosing = false
                root.isOpen = false
                root.activeProvider = null
                root.results = []
                root._queryChanged = true
                root.currentIndex = 0
                root._pendingCleanup = false
                rebuildItems()
            }
        }
    }

    Connections {
        target: root._wp
        ignoreUnknownSignals: true
        function onRefreshKeyChanged() {
            if (root.activeProvider === root._wp)
                root.processInput(inputField.text)
        }
        function onRequestClose() {
            root.close()
        }
    }

    Connections {
        target: root._sp
        ignoreUnknownSignals: true
        function onRefreshKeyChanged() {
            if (root.activeProvider === root._sp)
                root.processInput(inputField.text)
        }
    }

    Connections {
        target: root._cp
        ignoreUnknownSignals: true
        function onRefreshKeyChanged() {
            if (root.activeProvider === root._cp)
                root.processInput(inputField.text)
        }
    }

    property var activeProvider: null
    property string queryText: ""
    property var results: []
    property int currentIndex: 0

    implicitWidth: root.panelWidth + root.resultWidthOffset
    implicitHeight: root.inputHeight + Math.round(root.screen.height / 3) + Math.round(13 * root.uiScale) + root.inputSlideOffset
    visible: root.isOpen
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "launcher"
    anchors.bottom: true
    margins {
        bottom: 0
        left: Math.round((root.screen.width - (root.panelWidth + root.resultWidthOffset)) / 2)
        right: Math.round((root.screen.width - (root.panelWidth + root.resultWidthOffset)) / 2)
    }

    function computeMaxListHeight() {
        return Math.round(root.screen.height / 3)
    }

    function computeListHeight() {
        if (root.results.length > 0) {
            var spacing = Math.round(2 * root.uiScale)
            var contentH = root.results.length * root.itemHeight + (root.results.length - 1) * spacing
            contentH = Math.min(contentH, root.computeMaxListHeight())
            return Math.round(13 * root.uiScale) + contentH
        }
        if (root.activeProvider && root.queryText)
            return root.emptyListHeight
        return 0
    }

    function rebuildProviders() {
        root.activeProvider = null
        root.results = []
        for (var i = 0; i < root.providers.length; i++)
            root.providers[i].destroy()
        var list = []
        function add(key, obj) {
            if (_settings.providerEnabled(key))
                list.push(obj)
        }
        add("app", appProvCmp.createObject(root))
        add("shell", shellProvCmp.createObject(root))
        add("terminal", terminalProvCmp.createObject(root))
        add("ssh", sshProvCmp.createObject(root))
        add("theme", themeProvCmp.createObject(root))
        root._wp = _settings.providerEnabled("wallpaper") ? wallpaperProvCmp.createObject(root) : null
        if (root._wp) list.push(root._wp)
        add("system", systemProvCmp.createObject(root))
        root._sp = _settings.providerEnabled("share") ? shareProvCmp.createObject(root) : null
        if (root._sp) list.push(root._sp)
        add("emoji", emojiProvCmp.createObject(root))
        add("calc", calcProvCmp.createObject(root))
        root._cp = _settings.providerEnabled("clipboard") ? clipProvCmp.createObject(root) : null
        if (root._cp) {
            root._cp.clipMon = Qt.binding(function() { return root.clipMon })
            list.push(root._cp)
        }
        root.providers = list
    }

    function open() {
        root._isClosing = false
        resultExpandAnim.stop()
        resultCloseAnim.stop()
        inputOpacityAnim.stop()
        inputSlideAnim.stop()
        if (!root.isOpen)
            root.isOpen = true
        root.inputAnimOpacity = 1
        root.inputSlideY = root.inputSlideOffset
        resetState()
        inputSlideAnim.type = Anim.SpatialDefault
        inputSlideAnim.from = root.inputSlideY
        inputSlideAnim.to = 0
        inputSlideAnim.start()
        Qt.callLater(function() { inputField.forceActiveFocus() })
    }

    function openWithPrefix(pre) {
        root._isClosing = false
        resultExpandAnim.stop()
        resultCloseAnim.stop()
        inputOpacityAnim.stop()
        inputSlideAnim.stop()
        if (!root.isOpen)
            root.isOpen = true
        root.inputAnimOpacity = 1
        root.inputSlideY = root.inputSlideOffset
        resetState()
        inputField.text = pre
        inputSlideAnim.type = Anim.SpatialDefault
        inputSlideAnim.from = root.inputSlideY
        inputSlideAnim.to = 0
        inputSlideAnim.start()
        Qt.callLater(function() { inputField.forceActiveFocus() })
    }

    function close() {
        root._isClosing = true
        resultExpandAnim.stop()
        resultCloseAnim.stop()
        inputSlideAnim.stop()
        resultCloseAnim.from = root.resultAnimHeight
        resultCloseAnim.to = 0
        resultCloseAnim.start()
    }

    function resetState() {
        resultExpandAnim.stop()
        resultCloseAnim.stop()
        inputOpacityAnim.stop()
        inputSlideAnim.stop()
        root._isClosing = false
        root.activeProvider = null
        root.queryText = ""
        root.results = []
        root._queryChanged = true
        root.currentIndex = 0
        inputField.text = ""
        rebuildItems()
        root.resultAnimHeight = root.computeListHeight()
    }

    function processInput(text) {
        if (!root.isOpen) return
        for (var i = 0; i < root.providers.length; i++) {
            var p = root.providers[i]
            var plen = p.prefix.length
            if (text.length >= plen && text.substring(0, plen) === p.prefix) {
                if (root.activeProvider !== p) {
                    root.activeProvider = p
                    root._queryChanged = true
                    root.currentIndex = 0
                    if (root._wp) root._wp._browsingMode = false
                }
                root.queryText = text.substring(plen)
                root.results = p.query(root.queryText)
                root._queryChanged = true
                if (root.currentIndex >= root.results.length)
                    root.currentIndex = Math.max(0, root.results.length - 1)
                root._pendingCleanup = false
                rebuildItems()
                updateTargetHeight()
                return
            }
        }

        if (root.activeProvider !== null || root.results.length > 0) {
            root.activeProvider = null
            root.results = []
            root._queryChanged = true
            root.currentIndex = 0
            root._pendingCleanup = false
            rebuildItems()
            updateTargetHeight()
        }
    }

    function updateTargetHeight() {
        var target = root.computeListHeight()
        resultCloseAnim.stop()
        resultExpandAnim.from = root.resultAnimHeight
        resultExpandAnim.to = target
        resultExpandAnim.start()
    }

    function selectCurrent() {
        if (root.activeProvider && root.currentIndex >= 0 && root.currentIndex < root.results.length) {
            var provider = root.activeProvider
            var entry = root.results[root.currentIndex]

            if (provider.closeOnActivate !== false) {
                close()
                provider.activate(entry)
            } else {
                provider.activate(entry)
                inputField.text = provider.prefix
            }
        }
    }

    function moveSel(delta) {
        var len = root.results.length
        if (len === 0) return
        root.currentIndex = (root.currentIndex + delta + len) % len
        ensureVisible()
    }

    function ensureVisible() {
        if (root.results.length === 0) return
        var spacing = Math.round(2 * root.uiScale)
        var y = root.currentIndex * (root.itemHeight + spacing)
        if (y < resultFlick.contentY)
            resultFlick.contentY = y
        else if (y + root.itemHeight > resultFlick.contentY + resultFlick.height)
            resultFlick.contentY = y + root.itemHeight - resultFlick.height
    }

    Item {
        id: resultArea
        anchors.bottom: inputBar.top
        anchors.bottomMargin: -Math.round(6 * root.uiScale)
        anchors.horizontalCenter: inputBar.horizontalCenter
        width: root.panelWidth + root.resultWidthOffset
        height: root.resultAnimHeight
        clip: true

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.uiScale)
            anchors.bottomMargin: 0
            radius: Math.round(6 * root.uiScale)
            color: root.colors.background

            Behavior on color { CAnim {} }
        }

        Text {
            anchors.centerIn: parent
            text: "No results"
            color: root.colors.subtext0
            font.pointSize: 9
            visible: root.activeProvider && root.queryText && root.results.length === 0
        }

        Flickable {
            id: resultFlick
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.uiScale)
            contentHeight: resultCol.height
            boundsBehavior: Flickable.StopAtBounds
            interactive: root.results.length > 0
            clip: true
            visible: root.results.length > 0

            Column {
                id: resultCol
                width: parent.width
                spacing: Math.round(2 * root.uiScale)
            }

            Rectangle {
                id: highlight
                property real itemH: root.itemHeight
                property real colSpacing: root.results.length > 1 ? Math.round(2 * root.uiScale) : 0
                y: 0
                width: resultCol.width
                height: itemH
                radius: Math.round(6 * root.uiScale)
                color: root.colors.highlighted
                opacity: 0.12
                visible: root.results.length > 0
            }
        }
    }

    Item {
        id: inputBar
        x: (parent.width - width) / 2
        y: parent.height - height - root.inputSlideOffset + root.inputSlideY
        width: root.panelWidth + root.resultWidthOffset
        height: root.inputHeight
        opacity: root.inputAnimOpacity

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.uiScale)
            radius: Math.round(6 * root.uiScale)
            color: root.colors.background
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.uiScale)
            radius: Math.round(4 * root.uiScale)
            color: "transparent"
            border.width: 1
            border.color: root.colors.border
        }

        Item {
            id: inputArea
            anchors.fill: parent
            anchors.margins: Math.round(4 * root.uiScale)

            TextInput {
                id: inputField
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Math.round(12 * root.uiScale)
                anchors.right: parent.right
                anchors.rightMargin: Math.round(12 * root.uiScale)
                color: root.colors.text
                font.family: root.colors.fontFamily
                font.pointSize: 10
                clip: true
                cursorVisible: true
                cursorDelegate: Item {}

                onTextChanged: root.processInput(text)

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.selectCurrent()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backspace && inputField.text === "") {
                        root.close()
                        event.accepted = true
                    } else if ((event.key === Qt.Key_Tab || event.key === Qt.Key_Right) && root.activeProvider && root.results.length > 0) {
                        if (event.key === Qt.Key_Right && inputField.cursorPosition < inputField.text.length) {
                            return
                        }
                        var entry = root.results[root.currentIndex]
                        inputField.text = root.activeProvider.prefix + root.activeProvider.textFor(entry)
                        inputField.cursorPosition = inputField.text.length
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        if (root.results.length > 0) {
                            root.moveSel(-1)
                            event.accepted = true
                        }
                    } else if (event.key === Qt.Key_Down) {
                        if (root.results.length > 0) {
                            root.moveSel(1)
                            event.accepted = true
                        }
                    } else if (event.key === Qt.Key_D && (event.modifiers & Qt.ControlModifier) && root.activeProvider && root.results.length > 0) {
                        var prov = root.activeProvider
                        if (typeof prov.remove !== "function") { return }
                        if (event.modifiers & Qt.ShiftModifier) {
                            prov.removeAll()
                        } else {
                            prov.remove(root.results[root.currentIndex])
                        }
                        root.processInput(inputField.text)
                        event.accepted = true
                    } else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier) && root.activeProvider && root.results.length > 0) {
                        var prov = root.activeProvider
                        if (typeof prov.altActivate !== "function") { return }
                        prov.altActivate(root.results[root.currentIndex])
                        root.processInput(inputField.text)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Escape) {
                        if (root.activeProvider || root.results.length > 0 || inputField.text !== "") {
                            root.activeProvider = null
                            root.results = []
                            root._pendingCleanup = false
                            inputField.text = ""
                            rebuildItems()
                            updateTargetHeight()
                        } else {
                            close()
                        }
                        event.accepted = true
                    }
                }
            }

            Rectangle {
                id: blockCursor
                property var cursorRect: inputField.positionToRectangle(inputField.cursorPosition)
                x: inputField.x + cursorRect.x
                y: inputField.y + (inputField.height - height) / 2
                width: Math.round(8 * root.uiScale)
                height: inputField.height
                radius: Math.round(1 * root.uiScale)
                color: root.colors.accent
                opacity: 0
                visible: inputField.activeFocus

                Timer {
                    id: cursorBlinkTimer
                    interval: 530
                    running: inputField.activeFocus
                    repeat: true
                    onTriggered: parent.opacity = (parent.opacity > 0 ? 0 : 0.6)
                }

                Connections {
                    target: inputField
                    function onTextChanged() {
                        cursorBlinkTimer.restart()
                        blockCursor.opacity = 0.6
                    }
                    function onCursorPositionChanged() {
                        cursorBlinkTimer.restart()
                        blockCursor.opacity = 0.6
                    }
                    function onActiveFocusChanged() {
                        if (inputField.activeFocus) {
                            cursorBlinkTimer.restart()
                            blockCursor.opacity = 0.6
                        } else {
                            cursorBlinkTimer.stop()
                            blockCursor.opacity = 0
                        }
                    }
                }
            }
        }

        Text {
            id: providerLabel
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: Math.round(12 * root.uiScale)
            text: root.activeProvider ? root.activeProvider.name : ""
            color: root.colors.subtext0
            font.pointSize: 8
            visible: text !== ""
        }
    }

    function refreshWallpapers() {
        if (root._wp) root._wp.refreshWallpapers()
    }

    function rebuildItems() {
        resultFlick.contentY = 0
        var children = resultCol.children
        for (var i = children.length - 1; i >= 0; i--)
            children[i].destroy()

        if (!root.activeProvider || root.results.length === 0) {
            highlight.visible = false
            return
        }

        highlight.visible = true
        highlight.y = root.currentIndex * (highlight.itemH + highlight.colSpacing)
        root._queryChanged = false

        var comp = root.activeProvider.itemComponent
        if (!comp) return

        for (var i = 0; i < root.results.length; i++) {
            comp.createObject(resultCol, {
                width: resultCol.width,
                modelData: root.results[i],
                selected: i === root.currentIndex,
                colors: root.colors,
                uiScale: root.uiScale,
                launcher: root,
                itemIndex: i
            })
        }
    }

    onCurrentIndexChanged: {
        var targetY = root.currentIndex * (highlight.itemH + highlight.colSpacing)
        if (root._queryChanged) {
            root._queryChanged = false
            highlightSlide.stop()
            highlight.y = targetY
        } else {
            highlightSlide.stop()
            highlightSlide.from = highlight.y
            highlightSlide.to = targetY
            highlightSlide.start()
        }
        ensureVisible()
    }

    Connections {
        target: root._settings
        function onLauncherProvidersChanged() { rebuildProviders() }
    }

    Connections {
        target: Qt.application
        function onStateChanged(state) {
            if (state === Qt.ApplicationInactive && root.isOpen) {
                root.close()
            }
        }
    }
}
