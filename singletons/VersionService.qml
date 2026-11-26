pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The version of the shell, from the VERSION file next to shell.qml (the same file the Nix package
// takes its version from, and `sol-shell --version` prints).
Singleton {
    id: root

    property string version: ""

    readonly property string versionPath: Quickshell.shellPath("VERSION")

    // A packaged shell lives in the Nix store; one run straight from a checkout (`quickshell -p .`)
    // does not. That one is a development copy, and says so, so it can be told apart from the
    // installed shell running next to it.
    readonly property bool dev: !versionPath.startsWith("/nix/store/")

    // what to show people: "0.6.3", or "0.6.3 DEV" for a development copy
    readonly property string display: version + (dev ? " DEV" : "")

    FileView {
        path: root.versionPath
        printErrors: false
        onLoaded: root.version = text().trim()
    }
}
