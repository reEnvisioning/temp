import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../scripts/fuzzy.js" as Fuzzy
Item {
    id: root
    visible: false

    property string prefix: "! "
    property string name: "Apps"
    property string placeholderText: "Search applications..."

    property var _allApps: []

    Process {
        id: appLoader
        command: ["bash", "-c",
            "for dir in \\\n" +
            "  \"$HOME/.nix-profile/share/applications\" \\\n" +
            "  \"$HOME/.local/share/applications\" \\\n" +
            "  \"/run/current-system/sw/share/applications\"; do\n" +
            "  [ -d \"$dir\" ] || continue\n" +
            "  for f in \"$dir\"/*.desktop; do\n" +
            "    [ -f \"$f\" ] || continue\n" +
            "    id=\"${f##*/}\"; id=\"${id%.desktop}\"\n" +
            "    n=\"$(sed -n 's/^Name[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ -z \"$n\" ] && continue\n" +
            "    i=\"$(sed -n 's/^Icon[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    c=\"$(sed -n 's/^Comment[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    e=\"$(sed -n 's/^Exec[^=]*=//p' \"$f\" 2>/dev/null | head -1 | sed 's/%[a-zA-Z]//g')\"\n" +
            "    [ -z \"$e\" ] && continue\n" +
            "    t=\"$(sed -n 's/^Terminal[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ -z \"$t\" ] && t=false\n" +
            "    nd=\"$(sed -n 's/^NoDisplay[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ \"$nd\" = \"true\" ] && continue\n" +
            "    hd=\"$(sed -n 's/^Hidden[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ \"$hd\" = \"true\" ] && continue\n" +
            "    printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$id\" \"$n\" \"$i\" \"$c\" \"$e\" \"$t\"\n" +
            "  done\n" +
            "done\n" +
            "IFS=:\n" +
            "for xdgDir in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do\n" +
            "  d=\"${xdgDir%/}/applications\"\n" +
            "  [ -d \"$d\" ] || continue\n" +
            "  for f in \"$d\"/*.desktop; do\n" +
            "    [ -f \"$f\" ] || continue\n" +
            "    id=\"${f##*/}\"; id=\"${id%.desktop}\"\n" +
            "    n=\"$(sed -n 's/^Name[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ -z \"$n\" ] && continue\n" +
            "    i=\"$(sed -n 's/^Icon[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    c=\"$(sed -n 's/^Comment[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    e=\"$(sed -n 's/^Exec[^=]*=//p' \"$f\" 2>/dev/null | head -1 | sed 's/%[a-zA-Z]//g')\"\n" +
            "    [ -z \"$e\" ] && continue\n" +
            "    t=\"$(sed -n 's/^Terminal[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ -z \"$t\" ] && t=false\n" +
            "    nd=\"$(sed -n 's/^NoDisplay[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ \"$nd\" = \"true\" ] && continue\n" +
            "    hd=\"$(sed -n 's/^Hidden[^=]*=//p' \"$f\" 2>/dev/null | head -1)\"\n" +
            "    [ \"$hd\" = \"true\" ] && continue\n" +
            "    printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \"$id\" \"$n\" \"$i\" \"$c\" \"$e\" \"$t\"\n" +
            "  done\n" +
            "done"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root._allApps = []
                var raw = text.trim()
                if (raw === "") {
                    console.log("AppProvider: no desktop files found")
                    return
                }
                var lines = raw.split('\n')
                console.log("AppProvider: found", lines.length, "desktop files")
                var failed = 0
                var dupes = 0
                var seen = {}
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split('\t')
                    if (parts.length >= 6) {
                        var eid = parts[0]
                        var ename = parts[1]
                        if (!ename || seen[eid]) {
                            if (!ename) failed++
                            else dupes++
                            continue
                        }
                        seen[eid] = true
                        root._allApps.push({
                            id: eid,
                            name: ename,
                            icon: parts[2],
                            comment: parts[3],
                            exec: parts[4],
                            terminal: parts[5]
                        })
                    } else {
                        failed++
                    }
                }
                root._allApps.sort(function(a, b) { return a.name.localeCompare(b.name) })
                console.log("AppProvider: loaded", root._allApps.length, "apps")
                if (failed > 0) console.log("AppProvider:", failed, "skipped (no Name / no Exec / unparseable)")
                if (dupes > 0) console.log("AppProvider:", dupes, "duplicates skipped")
                if (root._allApps.length > 0) {
                    var samples = []
                    for (var s = 0; s < Math.min(3, root._allApps.length); s++) {
                        samples.push(root._allApps[s].id + "=" + root._allApps[s].name)
                    }
                    console.log("AppProvider: sample:", samples.join(", "))
                }
            }
        }
    }

    function query(text) {
        if (root._allApps.length === 0) return []

        if (!text || !text.trim())
            return _allApps.slice(0, 100)

        var results = Fuzzy.go(text, _allApps, {
            key: "name",
            limit: 100,
            threshold: -10000
        })
        if (results.length > 0)
            return results.map(function(r) { return r.obj })

        var lower = text.toLowerCase()
        return _allApps.filter(function(a) {
            return a.name && a.name.toLowerCase().indexOf(lower) !== -1
        }).slice(0, 15)
    }

    function textFor(entry) { return entry ? entry.name : "" }

    function activate(entry) {
        if (entry && entry.exec) {
            if (entry.terminal === "true")
                Quickshell.execDetached({ command: ["sh", "-c", "kitty -e " + entry.exec] })
            else
                Quickshell.execDetached({ command: ["sh", "-c", entry.exec] })
        }
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
                anchors.right: parent.right
                anchors.leftMargin: Math.round(10 * uiScale)
                anchors.rightMargin: Math.round(10 * uiScale)
                anchors.verticalCenter: parent.verticalCenter
                spacing: Math.round(10 * uiScale)

                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(24 * uiScale)
                    height: Math.round(24 * uiScale)
                    source: modelData ? Quickshell.iconPath(modelData.icon, "image-missing") : ""
                    asynchronous: true
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.round(1 * uiScale)

                    Text {
                        text: modelData ? (modelData.name || "Unknown") : ""
                        color: colors.text
                        font.pointSize: 10
                        font.weight: Font.Normal
                        elide: Text.ElideRight
                        width: parent.parent ? parent.parent.width - Math.round(44 * uiScale) : Math.round(400 * uiScale)
                    }

                    Text {
                        text: modelData ? (modelData.comment || "") : ""
                        color: colors.subtext0
                        font.pointSize: 8
                        elide: Text.ElideRight
                        width: parent.parent ? parent.parent.width - Math.round(44 * uiScale) : Math.round(400 * uiScale)
                        visible: text !== ""
                    }
                }
            }
        }
    }
}
