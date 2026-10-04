pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // full paths of the images found in Settings.wallpaperDir
    property var wallpapers: []

    // Looks in the folder again. Called when the settings page opens, so a
    // picture you just copied there shows up without restarting anything.
    function refresh(): void {
        if (!finder.running)
            finder.running = true;
    }

    Process {
        id: finder
        // No shell involved: every word is its own argument, so a folder name
        // with spaces needs no quoting and nothing gets expanded behind our back.
        command: [
            "find", Settings.wallpaperDir, "-maxdepth", "1", "-type", "f",
            "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o",
            "-iname", "*.png", "-o", "-iname", "*.webp", ")"
        ]
        // we need the whole list before sorting it, so collect everything first
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(line => line !== "");
                // find returns files in no particular order; sort for a stable grid
                root.wallpapers = lines.sort();
            }
        }
    }

    Component.onCompleted: refresh()
}
