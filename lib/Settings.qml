import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Loads settings.json from the quickshell root ───────────────────────
    // settings.json is always present (handwritten in the repo, or shipped by
    // the deploying system). Its only job is to expose configuration; there is
    // no fallback to hardcoded values — defaults live entirely in settings.json.
    readonly property string settingsPath: {
        var d = Quickshell.shellDir
        return d + "/settings.json"
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: apply()
        onAdapterUpdated: apply()

        JsonAdapter {
            id: s
            property string themePath: "~/.config/reEnvisioning"
            property string dataPath: "~/.config/reEnvisioning/reShell"
            property real uiScale: 1
            property var defaults: ({})
            property var modules: ({})
            property var border: ({})
            property var launcherProviders: ({})
        }
    }

    function apply() {
        if (s.uiScale !== undefined) root._uiScale = s.uiScale
        if (s.defaults !== undefined) root._defaults = s.defaults
        if (s.modules !== undefined) root._modules = s.modules
        if (s.border !== undefined) root._border = s.border
        if (s.launcherProviders !== undefined) root._launcherProviders = s.launcherProviders
        if (s.themePath !== undefined) root._themePath = s.themePath
        if (s.dataPath !== undefined) root._dataPath = s.dataPath
    }

    // ── Resolved, cached values ────────────────────────────────────────────
    property string _themePath: "~/.config/reEnvisioning"
    property string _dataPath: "~/.config/reEnvisioning/quickshell"
    property real _uiScale: 1
    property var _defaults: ({})
    property var _modules: ({})
    property var _border: ({})
    property var _launcherProviders: ({})

    readonly property string themePath: resolve(_themePath)
    readonly property string dataPath: resolve(_dataPath)
    readonly property real uiScale: _uiScale
    readonly property var defaults: _defaults
    readonly property var modules: _modules
    readonly property var border: _border
    readonly property var launcherProviders: _launcherProviders

    // ── Helpers ────────────────────────────────────────────────────────────
    function resolve(p: string): string {
        if (p && p.startsWith("~"))
            return Quickshell.env("HOME") + p.substring(1)
        return p
    }

    // <theme.path>/theme.json — the single runtime theme file quickshell reads.
    function themeRuntimeFile(): string {
        return themePath + "/theme.json"
    }

    // <theme.path>/themes/<name>/theme.json — per-theme data.
    function themeDir(name: string): string {
        return themePath + "/themes/" + name + "/theme.json"
    }

    // <data.path>/<rel> — quickshell's own runtime data (history, clips, …).
    function dataFile(rel: string): string {
        return dataPath + "/" + rel
    }

    function moduleEnabled(name: string): bool {
        return _modules[name] === true
    }

    function providerEnabled(key: string): bool {
        return _launcherProviders[key] === true
    }
}
