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
    property real fullHeight: Math.round(500 * root.uiScale)
    property bool isOpen: false
    property real animHeight: 0
    property real widthScaleAnim: 1.0
    property real contentOpacity: 0
    property real glowAlpha: 0
    property bool _pendingCleanup: false
    property var _pendingActivate: null

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

    implicitWidth: root.panelWidth
    implicitHeight: root.fullHeight
    visible: root.animHeight > 0
    color: "transparent"
    focusable: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "launcher"
    anchors.bottom: true
    margins {
        bottom: Math.round(8 * root.uiScale)
        left: Math.round((root.screen.width - root.panelWidth) / 2)
        right: Math.round((root.screen.width - root.panelWidth) / 2)
    }

    Anim { id: heightAnim; target: root; property: "animHeight"; type: Anim.SpatialDefault }
    Anim { id: widthAnim; target: root; property: "widthScaleAnim"; type: Anim.SpatialDefault }
    Anim { id: contentFadeAnim; target: root; property: "contentOpacity"; type: Anim.EffectsDefault }
    Anim { id: glowAnim; target: root; property: "glowAlpha"; type: Anim.EffectsDefault }

    Connections {
        target: heightAnim
        function onFinished() {
            if (root._pendingActivate) {
                var pending = root._pendingActivate
                root._pendingActivate = null
                pending.provider.activate(pending.entry)
            }
        }
    }

    function animateTo(h, type) {
        if (h === heightAnim.to && heightAnim.running) return
        heightAnim.stop()
        heightAnim.from = root.animHeight
        heightAnim.to = h
        heightAnim.type = type
        heightAnim.start()
    }

    function animateWidthTo(from, to, type) {
        widthAnim.stop()
        widthAnim.from = from
        widthAnim.to = to
        widthAnim.type = type
        widthAnim.start()
    }

    function animateGlowTo(to, type) {
        glowAnim.stop()
        glowAnim.from = root.glowAlpha
        glowAnim.to = to
        glowAnim.type = type
        glowAnim.start()
    }

    function animateContentTo(to, type, delay) {
        contentFadeAnim.stop()
        contentFadeAnim.from = root.contentOpacity
        contentFadeAnim.to = to
        contentFadeAnim.type = type
        if (delay > 0) {
            restartTimer.interval = delay
            restartTimer.triggered.connect(function() {
                contentFadeAnim.start()
                restartTimer.triggered.disconnect(arguments.callee)
            })
            restartTimer.start()
        } else {
            contentFadeAnim.start()
        }
    }

    Timer { id: restartTimer }

    function computeMaxListHeight() {
        return Math.round(root.screen.height / 3) - root.inputHeight - Math.round(13 * root.uiScale)
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
        if (!root.isOpen)
            root.isOpen = true
        resetState()
        Qt.callLater(function() { inputField.forceActiveFocus() })
    }

    function openWithPrefix(pre) {
        if (!root.isOpen)
            root.isOpen = true
        resetState()
        inputField.text = pre
        Qt.callLater(function() { inputField.forceActiveFocus() })
    }

    function close() {
        root.isOpen = false
        root.activeProvider = null
        root.results = []
        root.currentIndex = 0
        root._pendingCleanup = false
        rebuildItems()
        animateTo(0, Anim.StandardAccel)
        animateWidthTo(root.widthScaleAnim, 1.0, Anim.StandardAccel)
        animateGlowTo(0, Anim.EffectsFast)
        animateContentTo(0, Anim.EffectsFast, 0)
    }

    function resetState() {
        root._pendingActivate = null
        root._pendingCleanup = false
        root.activeProvider = null
        root.queryText = ""
        root.results = []
        root.currentIndex = 0
        inputField.text = ""
        rebuildItems()
        var targetH = root.inputHeight + root.computeListHeight()
        animateTo(targetH, Anim.SpatialDefault)
        animateWidthTo(0.92, 1.0, Anim.SpatialDefault)
        animateGlowTo(1, Anim.EffectsDefault)
        animateContentTo(1, Anim.EffectsSlow, 300)
    }

    function processInput(text) {
        if (!root.isOpen) return
        for (var i = 0; i < root.providers.length; i++) {
            var p = root.providers[i]
            var plen = p.prefix.length
            if (text.length >= plen && text.substring(0, plen) === p.prefix) {
                if (root.activeProvider !== p) {
                    root.activeProvider = p
                    root.currentIndex = 0
                    if (root._wp) root._wp._browsingMode = false
                }
                root.queryText = text.substring(plen)
                root.results = p.query(root.queryText)
                root._pendingCleanup = false
                rebuildItems()
                updateTargetHeight()
                return
            }
        }

        if (root.activeProvider !== null || root.results.length > 0) {
            root.activeProvider = null
            root.results = []
            root._pendingCleanup = false
            rebuildItems()
            updateTargetHeight()
        }
    }

    function updateTargetHeight() {
        var h = root.inputHeight + root.computeListHeight()
        if (h === root.animHeight) return
        animateTo(h, Anim.EmphasizedDecel)
    }

    function selectCurrent() {
        root._pendingActivate = null
        if (root.activeProvider && root.currentIndex >= 0 && root.currentIndex < root.results.length) {
            var provider = root.activeProvider
            var entry = root.results[root.currentIndex]

            if (provider.closeOnActivate !== false) {
                root._pendingActivate = { provider: provider, entry: entry }
                close()
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
        id: contentWrapper
        anchors.bottom: parent.bottom
        width: parent.width
        height: root.animHeight
        clip: true

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: parent.width * (1.2 + root.glowAlpha * 0.3)
            height: parent.height * 1.2
            radius: width * 0.5
            color: Qt.rgba(1, 1, 1, 0.03 * root.glowAlpha)
            visible: root.glowAlpha > 0.01
        }

        Rectangle {
            anchors.fill: parent
            radius: Math.round(12 * root.uiScale)
            color: root.colors.background

            transform: Scale {
                origin.y: contentWrapper.height
                origin.x: root.panelWidth / 2
                xScale: root.widthScaleAnim
            }

            Behavior on color { CAnim {} }
        }

        Item {
            id: resultArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: Math.round(4 * root.uiScale)
            anchors.bottom: inputBar.top
            anchors.bottomMargin: Math.round(1 * root.uiScale)
            clip: true
            opacity: root.contentOpacity

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
            }
        }

        Item {
            id: inputBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.inputHeight
            opacity: root.contentOpacity

            Rectangle {
                anchors.fill: parent
                anchors.margins: Math.round(4 * root.uiScale)
                radius: Math.round(8 * root.uiScale)
                color: root.colors.element_background
            }

            TextInput {
                id: inputField
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Math.round(12 * root.uiScale)
                anchors.right: providerLabel.left
                anchors.rightMargin: Math.round(6 * root.uiScale)
                color: root.colors.text
                font.pointSize: 10
                clip: true
                cursorVisible: true

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
    }

    function refreshWallpapers() {
        if (root._wp) root._wp.refreshWallpapers()
    }

    function rebuildItems() {
        resultFlick.contentY = 0
        var children = resultCol.children
        for (var i = children.length - 1; i >= 0; i--)
            children[i].destroy()

        if (!root.activeProvider || root.results.length === 0) return

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
        for (var i = 0; i < resultCol.children.length; i++) {
            var child = resultCol.children[i]
            if (child && child.hasOwnProperty("selected"))
                child.selected = (i === root.currentIndex)
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
