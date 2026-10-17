pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The version of the shell, from the VERSION file next to shell.qml (the same file the Nix package
// takes its version from, and `sol-shell --version` prints).
Singleton {
    id: root

    property string version: ""

    FileView {
        path: Quickshell.shellPath("VERSION")
        printErrors: false
        onLoaded: root.version = text().trim()
    }
}
