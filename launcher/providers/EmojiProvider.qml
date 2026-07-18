import QtQuick
import Quickshell
import "../scripts/fuzzy.js" as Fuzzy

Item {
    id: root
    visible: false

    property string prefix: ": "
    property string name: "Emoji"
    property string placeholderText: "Search emoji..."

    property var _emojis: [
        { char: "😀", name: "grinning face" },
        { char: "😃", name: "grinning face big eyes" },
        { char: "😄", name: "grinning face smiling eyes" },
        { char: "😁", name: "beaming face smiling eyes" },
        { char: "😆", name: "grinning squinting face" },
        { char: "😅", name: "grinning face sweat" },
        { char: "🤣", name: "rolling on floor laughing" },
        { char: "😂", name: "face tears of joy" },
        { char: "🙂", name: "slightly smiling face" },
        { char: "🙃", name: "upside down face" },
        { char: "😉", name: "winking face" },
        { char: "😊", name: "smiling face smiling eyes" },
        { char: "😇", name: "smiling face halo" },
        { char: "🥰", name: "smiling face hearts" },
        { char: "😍", name: "heart eyes" },
        { char: "🤩", name: "star struck" },
        { char: "😘", name: "face blowing kiss" },
        { char: "😗", name: "kissing face" },
        { char: "😚", name: "kissing face closed eyes" },
        { char: "😋", name: "face savoring food" },
        { char: "😛", name: "face tongue" },
        { char: "😜", name: "winking face tongue" },
        { char: "🤪", name: "zany face" },
        { char: "😝", name: "squinting face tongue" },
        { char: "🤑", name: "money mouth face" },
        { char: "🤗", name: "hugging face" },
        { char: "🤭", name: "face hand over mouth" },
        { char: "🤫", name: "shushing face" },
        { char: "🤔", name: "thinking face" },
        { char: "🤐", name: "zipper mouth face" },
        { char: "🤨", name: "face raised eyebrow" },
        { char: "😐", name: "neutral face" },
        { char: "😑", name: "expressionless face" },
        { char: "😶", name: "face without mouth" },
        { char: "😏", name: "smirking face" },
        { char: "😒", name: "unamused face" },
        { char: "🙄", name: "face rolling eyes" },
        { char: "😬", name: "grimacing face" },
        { char: "😮", name: "face with open mouth" },
        { char: "😯", name: "hushed face" },
        { char: "😲", name: "astonished face" },
        { char: "😳", name: "flushed face" },
        { char: "🥺", name: "pleading face" },
        { char: "😢", name: "crying face" },
        { char: "😭", name: "loudly crying face" },
        { char: "😤", name: "face steam from nose" },
        { char: "😠", name: "angry face" },
        { char: "😡", name: "pouting face" },
        { char: "🤬", name: "face with symbols on mouth" },
        { char: "😈", name: "smiling face horns" },
        { char: "👿", name: "angry face horns" },
        { char: "💀", name: "skull" },
        { char: "💩", name: "pile of poo" },
        { char: "🤡", name: "clown face" },
        { char: "👻", name: "ghost" },
        { char: "👽", name: "alien" },
        { char: "🤖", name: "robot" },
        { char: "😺", name: "grinning cat" },
        { char: "😸", name: "grinning cat smiling eyes" },
        { char: "😹", name: "cat tears of joy" },
        { char: "😻", name: "heart eyes cat" },
        { char: "👋", name: "waving hand" },
        { char: "🤚", name: "raised back of hand" },
        { char: "🖐️", name: "hand splayed" },
        { char: "✋", name: "raised hand" },
        { char: "🖖", name: "vulcan salute" },
        { char: "👌", name: "ok hand" },
        { char: "🤌", name: "pinched fingers" },
        { char: "🤏", name: "pinching hand" },
        { char: "✌️", name: "victory hand" },
        { char: "🤞", name: "crossed fingers" },
        { char: "🤟", name: "love you gesture" },
        { char: "🤘", name: "sign of horns" },
        { char: "🤙", name: "call me hand" },
        { char: "👈", name: "backhand index pointing left" },
        { char: "👉", name: "backhand index pointing right" },
        { char: "👆", name: "backhand index pointing up" },
        { char: "👇", name: "backhand index pointing down" },
        { char: "☝️", name: "index pointing up" },
        { char: "👍", name: "thumbs up" },
        { char: "👎", name: "thumbs down" },
        { char: "✊", name: "raised fist" },
        { char: "👊", name: "oncoming fist" },
        { char: "🤛", name: "left facing fist" },
        { char: "🤜", name: "right facing fist" },
        { char: "👏", name: "clapping hands" },
        { char: "🙌", name: "raising hands" },
        { char: "🫶", name: "heart hands" },
        { char: "💪", name: "biceps flexed" },
        { char: "❤️", name: "red heart" },
        { char: "🧡", name: "orange heart" },
        { char: "💛", name: "yellow heart" },
        { char: "💚", name: "green heart" },
        { char: "💙", name: "blue heart" },
        { char: "💜", name: "purple heart" },
        { char: "🖤", name: "black heart" },
        { char: "🤍", name: "white heart" },
        { char: "💔", name: "broken heart" },
        { char: "💕", name: "two hearts" },
        { char: "💞", name: "revolving hearts" },
        { char: "💓", name: "beating heart" },
        { char: "💗", name: "growing heart" },
        { char: "💖", name: "sparkling heart" },
        { char: "⭐", name: "star" },
        { char: "🌟", name: "glowing star" },
        { char: "✨", name: "sparkles" },
        { char: "🔥", name: "fire" },
        { char: "💥", name: "collision" },
        { char: "💫", name: "dizzy" },
        { char: "💦", name: "sweat droplets" },
        { char: "💨", name: "dashing away" },
        { char: "💬", name: "speech balloon" },
        { char: "💭", name: "thought balloon" },
        { char: "🛑", name: "stop sign" },
        { char: "🚫", name: "prohibited" },
        { char: "❌", name: "cross mark" },
        { char: "⭕", name: "hollow red circle" },
        { char: "💢", name: "anger symbol" },
        { char: "⚠️", name: "warning" },
        { char: "💯", name: "hundred points" },
        { char: "✅", name: "check mark button" },
        { char: "❓", name: "question mark" },
        { char: "❗", name: "exclamation mark" },
        { char: "🔴", name: "red circle" },
        { char: "🟠", name: "orange circle" },
        { char: "🟡", name: "yellow circle" },
        { char: "🟢", name: "green circle" },
        { char: "🔵", name: "blue circle" },
        { char: "🟣", name: "purple circle" },
        { char: "⚫", name: "black circle" },
        { char: "⚪", name: "white circle" },
        { char: "🏁", name: "chequered flag" },
        { char: "🚩", name: "triangular flag" },
        { char: "🎌", name: "crossed flags" },
        { char: "🏴", name: "black flag" },
        { char: "🏳️", name: "white flag" },
        { char: "🌍", name: "globe europe africa" },
        { char: "🌎", name: "globe americas" },
        { char: "🌏", name: "globe asia australia" },
        { char: "🗺️", name: "world map" },
        { char: "🧭", name: "compass" },
        { char: "⛰️", name: "mountain" },
        { char: "🏔️", name: "snow capped mountain" },
        { char: "🌋", name: "volcano" },
        { char: "🏕️", name: "camping" },
        { char: "🏖️", name: "beach umbrella" },
        { char: "🏜️", name: "desert" },
        { char: "🌅", name: "sunrise" },
        { char: "🌇", name: "sunset" },
        { char: "🌃", name: "night with stars" },
        { char: "🏙️", name: "cityscape" },
        { char: "🚗", name: "car" },
        { char: "🚕", name: "taxi" },
        { char: "🚙", name: "suv" },
        { char: "🚌", name: "bus" },
        { char: "🏎️", name: "race car" },
        { char: "🚓", name: "police car" },
        { char: "🚑", name: "ambulance" },
        { char: "🚒", name: "fire engine" },
        { char: "🚐", name: "minibus" },
        { char: "🚚", name: "delivery truck" },
        { char: "🚛", name: "articulated lorry" },
        { char: "🚜", name: "tractor" },
        { char: "🏍️", name: "motorcycle" },
        { char: "🛵", name: "scooter" },
        { char: "🚲", name: "bicycle" },
        { char: "✈️", name: "airplane" },
        { char: "🛩️", name: "small airplane" },
        { char: "🚀", name: "rocket" },
        { char: "🛸", name: "flying saucer" },
        { char: "🚁", name: "helicopter" },
        { char: "⛵", name: "sailboat" },
        { char: "🚤", name: "speedboat" },
        { char: "⚓", name: "anchor" },
        { char: "⌚", name: "watch" },
        { char: "📱", name: "mobile phone" },
        { char: "💻", name: "laptop" },
        { char: "⌨️", name: "keyboard" },
        { char: "🖥️", name: "desktop computer" },
        { char: "🖨️", name: "printer" },
        { char: "🖱️", name: "computer mouse" },
        { char: "💾", name: "floppy disk" },
        { char: "💿", name: "cd" },
        { char: "📀", name: "dvd" },
        { char: "🎥", name: "movie camera" },
        { char: "📷", name: "camera" },
        { char: "📸", name: "camera flash" },
        { char: "📹", name: "video camera" },
        { char: "📺", name: "television" },
        { char: "📻", name: "radio" },
        { char: "🎤", name: "microphone" },
        { char: "🎧", name: "headphone" },
        { char: "🎵", name: "musical note" },
        { char: "🎶", name: "musical notes" },
        { char: "🎹", name: "musical keyboard" },
        { char: "🥁", name: "drum" },
        { char: "🎷", name: "saxophone" },
        { char: "🎸", name: "guitar" },
        { char: "🎺", name: "trumpet" },
        { char: "🎻", name: "violin" },
        { char: "🎮", name: "video game" },
        { char: "🎯", name: "bullseye" },
        { char: "🎲", name: "game die" },
        { char: "♟️", name: "chess pawn" },
        { char: "🃏", name: "joker" },
        { char: "🀄", name: "mahjong red dragon" },
        { char: "🎨", name: "artist palette" },
        { char: "🧵", name: "thread" },
        { char: "📚", name: "books" },
        { char: "📖", name: "open book" },
        { char: "📕", name: "closed book" },
        { char: "📗", name: "green book" },
        { char: "📘", name: "blue book" },
        { char: "📙", name: "orange book" },
        { char: "📝", name: "memo" },
        { char: "📁", name: "file folder" },
        { char: "📂", name: "open file folder" },
        { char: "📅", name: "calendar" },
        { char: "📊", name: "bar chart" },
        { char: "📈", name: "chart increasing" },
        { char: "📉", name: "chart decreasing" },
        { char: "📋", name: "clipboard" },
        { char: "📌", name: "pushpin" },
        { char: "📍", name: "round pushpin" },
        { char: "📎", name: "paperclip" },
        { char: "📏", name: "straight ruler" },
        { char: "📐", name: "triangular ruler" },
        { char: "✂️", name: "scissors" },
        { char: "🗑️", name: "wastebasket" },
        { char: "🔒", name: "locked" },
        { char: "🔓", name: "unlocked" },
        { char: "🔑", name: "key" },
        { char: "🔨", name: "hammer" },
        { char: "🪓", name: "axe" },
        { char: "⛏️", name: "pick" },
        { char: "⚒️", name: "hammer and pick" },
        { char: "🛠️", name: "hammer and wrench" },
        { char: "🔧", name: "wrench" },
        { char: "🔩", name: "nut and bolt" },
        { char: "⚙️", name: "gear" },
        { char: "🔗", name: "link" },
        { char: "⛓️", name: "chains" },
        { char: "🧲", name: "magnet" },
        { char: "🧪", name: "test tube" },
        { char: "🧬", name: "dna" },
        { char: "🔬", name: "microscope" },
        { char: "🔭", name: "telescope" },
        { char: "💡", name: "light bulb" },
        { char: "🔦", name: "flashlight" },
        { char: "🕯️", name: "candle" },
        { char: "🔋", name: "battery" },
        { char: "🔌", name: "electric plug" },
        { char: "💰", name: "money bag" },
        { char: "💳", name: "credit card" },
        { char: "✉️", name: "envelope" },
        { char: "📧", name: "email" },
        { char: "📨", name: "incoming envelope" },
        { char: "📩", name: "envelope with arrow" },
        { char: "📦", name: "package" },
        { char: "🗳️", name: "ballot box" },
        { char: "✏️", name: "pencil" },
        { char: "✒️", name: "black nib" },
        { char: "🖊️", name: "pen" },
        { char: "🖋️", name: "fountain pen" },
        { char: "🖌️", name: "paintbrush" },
        { char: "🖍️", name: "crayon" },
        { char: "🔍", name: "magnifying glass tilted right" },
        { char: "🔎", name: "magnifying glass tilted left" },
        { char: "💊", name: "pill" },
        { char: "💉", name: "syringe" },
        { char: "🩹", name: "adhesive bandage" },
        { char: "🩺", name: "stethoscope" },
        { char: "🚪", name: "door" },
        { char: "🛏️", name: "bed" },
        { char: "🛋️", name: "couch and lamp" },
        { char: "🚿", name: "shower" },
        { char: "🛁", name: "bathtub" },
        { char: "🧴", name: "lotion bottle" },
        { char: "🧹", name: "broom" },
        { char: "🧺", name: "basket" },
        { char: "🧻", name: "roll of paper" },
        { char: "🧼", name: "soap" },
        { char: "🧽", name: "sponge" },
        { char: "🛒", name: "shopping cart" },
        { char: "🚬", name: "cigarette" },
        { char: "⚰️", name: "coffin" },
        { char: "🗿", name: "moai" },
        { char: "🚽", name: "toilet" },
        { char: "🛗", name: "elevator" },
        { char: "🪞", name: "mirror" },
        { char: "🪟", name: "window" },
        { char: "🪜", name: "ladder" }
    ]

    function query(text) {
        if (!text || !text.trim())
            return root._emojis.slice(0, 50).map(function(e) { return e })

        var results = Fuzzy.go(text, root._emojis, {
            key: "name",
            limit: 50,
            threshold: -10000
        })
        if (results.length > 0)
            return results.map(function(r) { return r.obj })

        var lower = text.toLowerCase()
        var fallback = []
        for (var i = 0; i < root._emojis.length; i++) {
            if (root._emojis[i].name.toLowerCase().indexOf(lower) !== -1)
                fallback.push(root._emojis[i])
        }
        return fallback.slice(0, 50)
    }

    function textFor(entry) { return entry ? entry.char : "" }

    function activate(entry) {
        if (entry && entry.char)
            Quickshell.execDetached(["bash", "-c",
                "echo -n \"$1\" | wl-copy",
                "copy", entry.char])
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
                    text: modelData ? modelData.char : ""
                    font.pointSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: modelData ? (": " + modelData.name) : ""
                    color: colors.text
                    font.pointSize: 9
                    font.family: "monospace"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
