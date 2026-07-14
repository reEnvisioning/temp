import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property Settings settings: Settings {}

    readonly property string tmpDir: settings.dataFile("tmp")
    readonly property string clipDir: settings.dataFile("clips")
    readonly property string historyFile: settings.dataFile("clip-history.json")

    property var entries: []
    property int maxEntries: 50
    property bool _skipNextImage: false

    Component.onCompleted: {
        load()
        Qt.callLater(function() {
            seedProcess.running = false
            seedProcess.running = true
            seedImgProcess.running = false
            seedImgProcess.running = true
        })
    }

    // wl-paste --watch triggers on clipboard changes.
    // Instead of trigger files + inotifywait, the command calls
    // qs msg to notify Quickshell's IpcHandler directly.
    Process {
        id: pasteWatch
        command: ["wl-paste", "--watch", "sh", "-c",
            "TMPD=\"" + root.tmpDir + "\" && " +
            "mkdir -p \"$TMPD\" && " +
            "if wl-paste -t text/plain > \"$TMPD/clip-text\" 2>/dev/null; then " +
            "  qs msg panel pushTextClip; " +
            "elif wl-paste -t image/png > \"$TMPD/clip-raw.png\" 2>/dev/null; then " +
            "  hash=$(sha256sum \"$TMPD/clip-raw.png\" | cut -d' ' -f1) && " +
            "  mkdir -p \"" + root.clipDir + "\" && " +
            "  cp \"$TMPD/clip-raw.png\" \"" + root.clipDir + "/$hash.png\" && " +
            "  qs msg panel pushImageClip \"$hash.png\"; " +
            "fi"]
        running: true
    }

    // Read text clipboard from temp file (called by IpcHandler.pushTextClip)
    function readTextClip() {
        readerProcess.command = ["sh", "-c",
            "wl-paste -t text/plain 2>/dev/null || echo ''"]
        readerProcess.running = false
        readerProcess.running = true
    }

    Process {
        id: readerProcess
        command: ["true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = text.trim()
                if (txt.length > 0)
                    root.addClip(txt)
            }
        }
    }

    Process {
        id: seedProcess
        command: ["wl-paste", "-t", "text/plain"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var txt = text.trim()
                if (txt.length > 0)
                    root.addClip(txt)
            }
        }
    }

    Process {
        id: seedImgProcess
        command: ["sh", "-c",
            "TMPD=\"" + root.tmpDir + "\" && " +
            "mkdir -p \"$TMPD\" && " +
            "wl-paste -t image/png > \"$TMPD/clip-raw.png\" 2>/dev/null && " +
            "hash=$(sha256sum \"$TMPD/clip-raw.png\" | cut -d' ' -f1) && " +
            "mkdir -p \"" + root.clipDir + "\" && " +
            "cp \"$TMPD/clip-raw.png\" \"" + root.clipDir + "/$hash.png\" && " +
            "qs msg panel pushImageClip \"$hash.png\""]
        running: false
    }

    function addClip(txt) {
        for (var i = 0; i < root.entries.length; i++) {
            if (root.entries[i].content === txt) {
                var match = root.entries[i]
                root.entries.splice(i, 1)
                root.entries = [match].concat(root.entries)
                save()
                return
            }
        }

        root.entries = [{
            mimeType: "text/plain",
            content: txt,
            preview: txt.substring(0, 80),
            timestamp: Date.now(),
            pinned: false,
            truncated: txt.length > 80,
            charCount: txt.length,
            storagePath: ""
        }].concat(root.entries)

        while (root.entries.length > root.maxEntries)
            root.entries = root.entries.slice(0, root.maxEntries)

        save()
    }

    function addImageClip(fname) {
        if (root._skipNextImage) {
            root._skipNextImage = false
            return
        }
        for (var i = 0; i < root.entries.length; i++) {
            if (root.entries[i].content === fname) {
                var match = root.entries[i]
                root.entries.splice(i, 1)
                root.entries = [match].concat(root.entries)
                save()
                return
            }
        }

        root.entries = [{
            mimeType: "image/png",
            content: fname,
            preview: fname,
            timestamp: Date.now(),
            pinned: false,
            truncated: false,
            charCount: 0,
            storagePath: "clips/" + fname
        }].concat(root.entries)

        while (root.entries.length > root.maxEntries)
            root.entries = root.entries.slice(0, root.maxEntries)

        save()
    }

    function removeAt(index) {
        var entry = root.entries[index]
        if (entry && entry.storagePath && entry.storagePath.length > 0) {
            Quickshell.execDetached(["sh", "-c",
                "rm -f \"" + settings.dataFile(entry.storagePath) + "\""])
        }
        root.entries = root.entries.filter(function(_, i) { return i !== index })
        save()
    }

    function clearAll() {
        var pinned = root.entries.filter(function(e) { return e.pinned })
        var stalePaths = root.entries
            .filter(function(e) { return !e.pinned && e.storagePath })
            .map(function(e) { return "\"" + settings.dataFile(e.storagePath) + "\"" })
        if (stalePaths.length > 0)
            Quickshell.execDetached(["sh", "-c", "rm -f " + stalePaths.join(" ")])
        root.entries = pinned
        save()
    }

    function togglePin(index) {
        var entry = root.entries[index]
        if (!entry) return
        entry.pinned = !entry.pinned
        var pinned = root.entries.filter(function(e) { return e.pinned })
        var unpinned = root.entries.filter(function(e) { return !e.pinned })
        root.entries = pinned.concat(unpinned)
        save()
    }

    function copyAt(index) {
        if (index < 0 || index >= root.entries.length) return
        var entry = root.entries[index]
        if (entry.mimeType === "image/png" && entry.storagePath) {
            root._skipNextImage = true
            Quickshell.execDetached(["sh", "-c",
                "wl-copy --type image/png < \"" + settings.dataFile(entry.storagePath) + "\""])
        } else {
            Quickshell.execDetached(["wl-copy", entry.content])
        }
        if (index !== 0) {
            root.entries.splice(index, 1)
            root.entries = [entry].concat(root.entries)
            save()
        }
    }

    function save() {
        var json = JSON.stringify(root.entries)
        var delim = "HS" + Math.random().toString(36).substring(2, 10) + "EOF"
        saveProcess.command = ["sh", "-c",
            "mkdir -p \"" + settings.dataFile("") + "\" && " +
            "cat > \"" + root.historyFile + "\" << '" + delim + "'\n" +
            json + "\n" +
            delim]
        saveProcess.running = false
        saveProcess.running = true
    }

    Process {
        id: saveProcess
        command: ["true"]
        running: false
    }

    function load() {
        loadProcess.running = false
        loadProcess.running = true
    }

    Process {
        id: loadProcess
        command: ["sh", "-c", "cat \"" + root.historyFile + "\" 2>/dev/null || echo '[]'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var arr = JSON.parse(text.trim())
                    if (Array.isArray(arr)) {
                        for (var i = 0; i < arr.length; i++) {
                            var e = arr[i]
                            if (!e.mimeType) e.mimeType = "text/plain"
                            if (!e.storagePath) e.storagePath = ""
                            if (!e.charCount) e.charCount = e.content ? e.content.length : 0
                            if (!e.pinned) e.pinned = false
                            if (!e.truncated) e.truncated = e.content && e.content.length > 80
                        }
                        root.entries = arr
                    }
                } catch (e) {
                    console.log("ClipMon: load error: " + e)
                }
            }
        }
    }
}
