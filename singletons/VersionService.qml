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

    // what to show people: "0.6.3"
    readonly property string display: version

    FileView {
        path: root.versionPath
        printErrors: false
        onLoaded: root.version = text().trim()
    }
}
