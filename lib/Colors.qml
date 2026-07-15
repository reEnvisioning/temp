import QtQuick

Item {
    id: root

    // Defaults are declared once, in settings.json, and injected here by
    // shell.qml (colors.defaults = settings.defaults). No hardcoded fallback.
    property var defaults: ({})

    FontLoader {
        id: jetbrainsMono
        source: Qt.resolvedUrl("../fonts/JetBrainsMono-Regular.ttf")
        onStatusChanged: {
            if (status === FontLoader.Ready)
                root.fontFamily = jetbrainsMono.name
            else if (status === FontLoader.Error)
                console.log("Colors: failed to load font:", source)
        }
    }

    property color background: "#000000"
    property color backgroundAccent: "#1A1A1A"
    property color highlighted: "#363636"
    property color element_background: "#363636"
    property color text: "#C0C0C0"
    property color cursor: "#0E0E0E"
    property color border: "#1C1C1C"
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
    property color surface: "#505050"
    property color bar: "#505050"
    property color divider: "#1C1C1C"
    property color overlay1: "#2C2C2C"
    property color overlay2: "#1E1E1E"
    property color crust: "#000000"
    property color subtext0: "#A8A8A8"
    property color subtext1: "#B0B0B0"

    // Interactive states
    property color interactive: "#585858"
    property color interactive_hover: "#6A6A6A"
    property color interactive_pressed: "#4A4A4A"
    property color interactive_disabled: "#363636"

    // Input/form states
    property color input_border: "#363636"

    // Status indicators
    property color status_active: "#4A5A4A"
    property color status_inactive: "#363636"
    property color status_syncing: "#4A4A5A"
    property color status_processing: "#5A5A4A"

    // Transfer/progress
    property color transfer_send: "#4A7C9A"
    property color transfer_receive: "#4A5A4A"
    property color transfer_complete: "#4A5A4A"
    property color transfer_failed: "#5A4A4A"

    // Audio
    property color audio_waveform: "#8A8A8A"
    property color audio_active: "#868686"

    // Syntax/code
    property color syntax_keyword: "#767676"
    property color syntax_string: "#868686"
    property color syntax_number: "#7E7E7E"
    property color syntax_comment: "#A8A8A8"
    property color syntax_function: "#6A6A6A"
    property color syntax_variable: "#C0C0C0"

    // Charts/data
    property color chart_1: "#666666"
    property color chart_2: "#868686"
    property color chart_3: "#9A9A9A"
    property color chart_4: "#6A6A6A"
    property color chart_5: "#929292"
    property color chart_6: "#8A8A8A"
    property color chart_grid: "#2C2C2C"

    // Depth/elevation
    property color elevation_1: "#1E1E1E"
    property color elevation_2: "#2C2C2C"
    property color elevation_3: "#363636"
    property color overlay: "#000000"

    // Text variants
    property color link: "#6A6A6A"
    property color link_hover: "#8A8A8A"
    property color placeholder: "#A8A8A8"

    property string fontFamily: "JetBrains Mono"
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
