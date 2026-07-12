import QtQuick

Item {
    id: root

    // Defaults are declared once, in settings.json, and injected here by
    // shell.qml (colors.defaults = settings.defaults). No hardcoded fallback.
    property var defaults: ({})

    property color background: "#000000"
    property color backgroundAccent: "#1A1A1A"
    property color highlighted: "#363636"
    property color text: "#C0C0C0"
    property color borderInactive: "#161616"
    property color borderFocused: "#1C1C1C"
    property color accent: "#0E0E0E"
    property color accent_light: "#121212"
    property color accent_dark: "#000000"
    property color red: "#666666"
    property color green: "#868686"
    property color yellow: "#9A9A9A"
    property color blue: "#6A6A6A"
    property color magenta: "#929292"
    property color cyan: "#8A8A8A"
    property color mauve: "#767676"
    property color lavender: "#7A7A7A"
    property color pink: "#8E8E8E"
    property color rosewater: "#A0A0A0"
    property color flamingo: "#969696"
    property color maroon: "#727272"
    property color peach: "#7E7E7E"
    property color sky: "#828282"
    property color sapphire: "#6E6E6E"
    property color surface2: "#505050"
    property color overlay1: "#2C2C2C"
    property color overlay2: "#1E1E1E"
    property color crust: "#000000"
    property color subtext0: "#A8A8A8"
    property color subtext1: "#B0B0B0"
    property string themeName: ""
    property string mode: "dark"

    function applyDefaults(): void {
        var d = root.defaults
        if (!d) return
        for (var key in d) {
            if (root.hasOwnProperty(key))
                root[key] = d[key]
        }
    }

    function parse(data: var): void {
        root.applyDefaults()
        try {
            var j = (typeof data === "string") ? JSON.parse(data.trim()) : data
            if (!j) return
            for (var key in j) {
                if (key === "name")
                    root.themeName = j.name
                else if (key === "mode")
                    root.mode = j.mode
                else if (root.hasOwnProperty(key))
                    root[key] = j[key]
            }
        } catch (e) {
            console.log("Colors: parse error: " + e)
        }
    }
}
