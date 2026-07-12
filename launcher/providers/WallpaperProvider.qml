import QtQuick
import Quickshell
import Quickshell.Io
import "../scripts/fuzzy.js" as Fuzzy
import qs.lib

Item {
    id: root
    visible: false

    readonly property Settings settings: Settings {}

    readonly property string wpDir: settings.dataFile("wallpapers")

    property string prefix: "$ "
    property string name: "Wallpaper"
    property string placeholderText: "Switch wallpaper..."

    property var _wallpapers: []
    property int refreshKey: 0
    property var _wallpaperFiles: []
    property bool _browsingMode: false
    on_BrowsingModeChanged: {
        root.name = root._browsingMode ? "Add Wallpaper" : "Wallpaper"
    }
    property bool _pendingAddClose: false
    property bool closeOnActivate: false
    signal requestClose()

    Process {
        id: wallpaperLoader
        command: ["bash", "-c",
            "command -v swaybg >/dev/null 2>&1 || exit 0;" +
            "command -v jq >/dev/null 2>&1 || exit 0;" +
            "THEME=$(state get current-theme 2>/dev/null || true);" +
            "if [ -z \"$THEME\" ]; then exit 0; fi;" +
            "THEME_FILE=\"" + settings.themeDir("$THEME") + "\";" +
            "if [ -f \"$THEME_FILE\" ]; then" +
            "  :;" +
            "else exit 0; fi;" +
            "CURRENT_IDX=$(state get wallpaper-idx:$THEME 2>/dev/null || echo 0);" +
            "WALLPAPER_COUNT=$(jq '.wallpapers | length' \"$THEME_FILE\");" +
            "for ((idx=0; idx<WALLPAPER_COUNT; idx++)); do" +
            "  path=$(jq -r \".wallpapers[$idx]\" \"$THEME_FILE\");" +
            "  name=$(basename \"$path\");" +
            "  cur=\"false\";" +
            "  if [ \"$idx\" = \"$CURRENT_IDX\" ]; then cur=\"true\"; fi;" +
            "  userAdded=\"false\";" +
            "  [[ \"$path\" == \"" + settings.dataFile("wallpapers/") + "\"* ]] && userAdded=\"true\";" +
            "  printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$idx\" \"$name\" \"$path\" \"$cur\" \"$WALLPAPER_COUNT\" \"$userAdded\";" +
            "done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._wallpapers = []
                var raw = text.trim()
                if (raw === "") return
                var lines = raw.split('\n')
                var seen = {}
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('\t')
                    if (parts.length >= 6) {
                        var name = parts[1]
                        if (seen[name]) continue
                        seen[name] = true
                        root._wallpapers.push({
                            index: parseInt(parts[0]),
                            name: name,
                            fullPath: parts[2],
                            current: parts[3] === "true",
                            total: parseInt(parts[4]),
                            userAdded: parts[5] === "true"
                        })
                    }
                }
                root.refreshKey++
            }
        }
    }

    Process {
        id: addProc
        command: ["true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperLoader.running = false
                wallpaperLoader.running = true
                if (root._pendingAddClose) {
                    root._pendingAddClose = false
                    Quickshell.execDetached(["bash", "-c",
                                    "THEME=$(state get current-theme 2>/dev/null || true);" +
                        "if [ -z \"$THEME\" ]; then exit 0; fi;" +
                        "THEME_FILE=\"" + settings.themeDir("$THEME") + "\";" +
                        "if [ ! -f \"$THEME_FILE\" ]; then exit 0; fi;" +
                        "WALLPAPER=$(jq -r '.wallpapers[-1]' \"$THEME_FILE\");" +
                        "if [ -f \"$WALLPAPER\" ]; then" +
                        "  pkill swaybg 2>/dev/null || true;" +
                        "  nohup swaybg -i \"$WALLPAPER\" -m fill >/dev/null 2>&1 & disown;" +
                        "  COUNT=$(jq '.wallpapers | length' \"$THEME_FILE\");" +
                        "  NEW_IDX=$((COUNT - 1));" +
                        "  state set wallpaper-idx:$THEME \"$NEW_IDX\";" +
                        "fi",
                        "switchToNew"])
                    root.requestClose()
                }
            }
        }
    }

    Process {
        id: fileScanner
        command: ["bash", "-c",
            "command -v swaybg >/dev/null 2>&1 || exit 0;" +
            "command -v jq >/dev/null 2>&1 || exit 0;" +
            "cd ~ && find Documents Downloads Pictures Videos Music . " +
            "-maxdepth 4 -not -path '*/.*' -name '*.png' -type f " +
            "-printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -200 | cut -f2-"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._wallpaperFiles = []
                var raw = text.trim()
                if (raw === "") return
                var lines = raw.split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('/')
                    var name = parts.pop()
                    root._wallpaperFiles.push({
                        relPath: lines[i],
                        name: name
                    })
                }
                root.refreshKey++
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            fileScanner.running = false
            fileScanner.running = true
        }
    }

    Process {
        id: deleteProc
        command: ["true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperLoader.running = false
                wallpaperLoader.running = true
            }
        }
    }

    function remove(entry) {
        if (!entry || !entry.userAdded) return
        deleteProc.command = ["bash", "-c",
            "THEME=$(state get current-theme 2>/dev/null || true);" +
            "if [ -z \"$THEME\" ]; then exit 0; fi;" +
            "if [ -f \"\" + settings.themeDir("$THEME") + \"\" ]; then" +
            "  THEME_FILE=\"\" + settings.themeDir("$THEME") + \"\";" +
            "else exit 0; fi;" +
            "CURRENT_IDX=$(state get wallpaper-idx:$THEME 2>/dev/null || echo 0);" +
            "CURRENT_PATH=$(jq -r \".wallpapers[$CURRENT_IDX] // \\\"\\\"\" \"$THEME_FILE\");" +
            "jq --arg path \"$1\" 'del(.wallpapers[] | select(. == $path))' \"$THEME_FILE\" > \"${THEME_FILE}.tmp\" && " +
            "mv \"${THEME_FILE}.tmp\" \"$THEME_FILE\";" +
            "rm -f \"$1\";" +
            "NEW_COUNT=$(jq '.wallpapers | length' \"$THEME_FILE\");" +
            "if [ \"$NEW_COUNT\" -eq 0 ]; then exit 0; fi;" +
            "NEW_IDX=$(jq -r --arg p \"$CURRENT_PATH\" '.wallpapers | map(. == $p) | index(true)' \"$THEME_FILE\");" +
            "if [ \"$NEW_IDX\" != \"null\" ] && [ -n \"$NEW_IDX\" ]; then" +
            "  state set wallpaper-idx:$THEME \"$NEW_IDX\";" +
            "else" +
            "  switch-wallpaper 0;" +
            "fi",
            "removeWallpaper", entry.fullPath]
        deleteProc.running = false
        deleteProc.running = true
    }

    function removeAll() {
        deleteProc.command = ["bash", "-c",
            "THEME=$(state get current-theme 2>/dev/null || true);" +
            "if [ -z \"$THEME\" ]; then exit 0; fi;" +
            "if [ -f \"\" + settings.themeDir("$THEME") + \"\" ]; then" +
            "  THEME_FILE=\"\" + settings.themeDir("$THEME") + \"\";" +
            "else exit 0; fi;" +
            "PREF=\"\" + root.wpDir + \"/\";" +
            "CURRENT_IDX=$(state get wallpaper-idx:$THEME 2>/dev/null || echo 0);" +
            "CURRENT_PATH=$(jq -r \".wallpapers[$CURRENT_IDX] // \\\"\\\"\" \"$THEME_FILE\");" +
            "jq --arg pref \"$PREF\" 'del(.wallpapers[] | select(. | startswith($pref)))' " +
            "  \"$THEME_FILE\" > \"${THEME_FILE}.tmp\" && " +
            "mv \"${THEME_FILE}.tmp\" \"$THEME_FILE\";" +
            "rm -rf \"\" + root.wpDir + \"/\";" +
            "NEW_COUNT=$(jq '.wallpapers | length' \"$THEME_FILE\");" +
            "if [ \"$NEW_COUNT\" -eq 0 ]; then exit 0; fi;" +
            "if [[ \"$CURRENT_PATH\" == \"$PREF\"* ]]; then" +
            "  switch-wallpaper 0;" +
            "else" +
            "  NEW_IDX=$(jq -r --arg p \"$CURRENT_PATH\" '.wallpapers | map(. == $p) | index(true)' \"$THEME_FILE\");" +
            "  if [ \"$NEW_IDX\" != \"null\" ] && [ -n \"$NEW_IDX\" ]; then" +
            "    state set wallpaper-idx:$THEME \"$NEW_IDX\";" +
            "  fi;" +
            "fi",
            "removeAll"]
        deleteProc.running = false
        deleteProc.running = true
    }

    function refreshWallpapers() {
        wallpaperLoader.running = false
        Qt.callLater(function() { wallpaperLoader.running = true })
    }

    function addWallpaper(filePath) {
        addProc.command = ["bash", "-c",
            "THEME=$(state get current-theme 2>/dev/null || true);" +
            "if [ -z \"$THEME\" ]; then exit 0; fi;" +
            "mkdir -p \"\" + root.wpDir + \"\";" +
            "cp \"$1\" \"\" + root.wpDir + \"/\";" +
            "NEW_PATH=\"\" + root.wpDir + \"/$(basename \"$1\")\";" +
            "if [ -f \"\" + settings.themeDir("$THEME") + \"\" ]; then" +
            "  THEME_FILE=\"\" + settings.themeDir("$THEME") + \"\";" +
            "else exit 0; fi;" +
            "jq --arg new \"$NEW_PATH\" '.wallpapers += [$new]' \"$THEME_FILE\" > \"${THEME_FILE}.tmp\" && " +
            "mv \"${THEME_FILE}.tmp\" \"$THEME_FILE\"",
            "addWallpaper", filePath]
        addProc.running = false
        addProc.running = true
    }

    function activate(entry) {
        if (!entry) return
        if (entry.isAdd) {
            root._browsingMode = true
            root.refreshKey++
            return
        }
        if (entry.isFileSearch) {
            addWallpaper(entry.relPath)
            root._browsingMode = false
            root._pendingAddClose = true
            return
        }
        if (entry.index !== undefined) {
            Quickshell.execDetached(["bash", "-c",
                    "THEME=$(state get current-theme 2>/dev/null || true);" +
                "if [ -z \"$THEME\" ]; then exit 0; fi;" +
                "pkill swaybg 2>/dev/null || true;" +
                "nohup swaybg -i \"$1\" -m fill >/dev/null 2>&1 & disown;" +
                "THEME_FILE=\"\" + settings.themeDir("$THEME") + \"\";" +
                "if [ ! -f \"$THEME_FILE\" ]; then exit 0; fi;" +
                "IDX=$(jq -r --arg p \"$1\" '.wallpapers | map(. == $p) | index(true)' \"$THEME_FILE\");" +
                "if [ \"$IDX\" != \"null\" ] && [ -n \"$IDX\" ]; then" +
                "  state set wallpaper-idx:$THEME \"$IDX\";" +
                "fi",
                "setWallpaper", entry.fullPath])
            for (var i = 0; i < root._wallpapers.length; i++)
                root._wallpapers[i].current = root._wallpapers[i].index === entry.index
            var tmp = root._wallpapers.slice()
            root._wallpapers = tmp
            Quickshell.execDetached(["notify-send",
                "--app-name=Wallpaper Indicator", "--expire-time=2000",
                "Wallpaper", (entry.index + 1) + "/" + entry.total])
            root.requestClose()
        }
    }

    function query(text) {
        if (root._browsingMode) {
            if (root._wallpaperFiles.length === 0) return []

            if (!text || !text.trim()) {
                var count = Math.min(50, root._wallpaperFiles.length)
                var recent = []
                for (var i = 0; i < count; i++)
                    recent.push({ isFileSearch: true, name: root._wallpaperFiles[i].name, relPath: root._wallpaperFiles[i].relPath })
                return recent
            }

            var results = Fuzzy.go(text, root._wallpaperFiles, {
                key: "relPath",
                limit: 50,
                threshold: -10000
            })
            if (results.length > 0) {
                return results.map(function(r) {
                    return { isFileSearch: true, name: r.obj.name, relPath: r.obj.relPath }
                })
            }

            var lower = text.toLowerCase()
            var fallback = []
            for (var i = 0; i < root._wallpaperFiles.length; i++) {
                if (root._wallpaperFiles[i].name.toLowerCase().indexOf(lower) !== -1)
                    fallback.push({ isFileSearch: true, name: root._wallpaperFiles[i].name, relPath: root._wallpaperFiles[i].relPath })
            }
            return fallback
        }

        if (root._wallpapers.length === 0) return []

        if (!text || !text.trim()) {
            var results = [{ index: -1, name: "Add wallpaper...", isAdd: true }]
            return results.concat(_wallpapers.slice())
        }

        var lower = text.toLowerCase()
        return _wallpapers.filter(function(w) {
            return w.name.toLowerCase().indexOf(lower) !== -1
        })
    }

    function textFor(entry) {
        if (!entry) return ""
        if (entry.isFileSearch) return entry.relPath
        if (entry.isAdd) return ""
        return entry.name
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
                visible: modelData && modelData.isFileSearch !== true
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(10 * uiScale)

                Rectangle {
                    width: Math.round(60 * uiScale)
                    height: Math.round(36 * uiScale)
                    radius: Math.round(4 * uiScale)
                    clip: true
                    color: modelData && modelData.isAdd === true ? colors.surface0 || "#333" : "transparent"

                    Rectangle {
                        anchors.fill: parent
                        color: colors.surface0 || "#333"
                        visible: modelData && modelData.isAdd !== true

                        Text {
                            anchors.centerIn: parent
                            text: modelData ? modelData.name.charAt(0).toUpperCase() : ""
                            color: colors.subtext0 || "#888"
                            font.pointSize: 14
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: colors.text
                        font.pointSize: 18
                        font.weight: Font.Bold
                        visible: modelData && modelData.isAdd === true
                    }

                    Image {
                        anchors.fill: parent
                        source: modelData && modelData.isAdd !== true ? modelData.fullPath : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: modelData && modelData.isAdd !== true
                    }
                }

                Text {
                    text: modelData ? ("$ " + modelData.name) : ""
                    color: colors.text
                    font.pointSize: 10
                    font.family: "monospace"
                }

                Text {
                    text: modelData && modelData.current ? "(current)" : ""
                    color: colors.green || colors.text
                    font.pointSize: 8
                    visible: text !== ""
                }

            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.right: parent.right
                anchors.rightMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                visible: modelData && modelData.isFileSearch === true
                text: modelData ? ("$ " + modelData.relPath) : ""
                color: colors.text
                font.pointSize: 9
                font.family: "monospace"
                elide: Text.ElideLeft
            }
        }
    }
}
