pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Finds the wallpaper pictures in Settings.wallpaperDir, for the picker in the
// settings page.
Singleton {
    id: root

    // full paths of the images found in Settings.wallpaperDir
    property var wallpapers: []

    // Looks in the folder again. Called when the settings page opens, so a
    // picture you just copied there shows up without restarting anything.
    // whether the full-screen picker (wallpaper/WallpaperPicker.qml) is open
    property bool pickerOpen: false

    function openPicker(): void {
        refresh();
        pickerOpen = true;
    }

    function closePicker(): void {
        pickerOpen = false;
    }

    // the default wallpaper ("") and then the pictures found, in the order the picker shows them
    readonly property var all: [""].concat(wallpapers)

    // Changes the wallpaper to the one `step` places further in the list (-1 = the one before),
    // going round at the ends.
    function cycle(step: int): void {
        const list = all;
        const now = Math.max(0, list.indexOf(Settings.wallpaperFile));
        Settings.wallpaperFile = list[(now + step + list.length) % list.length];
    }

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

    // sol-shell ipc call wallpaper pick     (open or close the picker)
    // sol-shell ipc call wallpaper next     (the next picture)
    IpcHandler {
        target: "wallpaper"

        function pick(): void {
            if (root.pickerOpen)
                root.closePicker();
            else
                root.openPicker();
        }

        function next(): void {
            root.cycle(1);
        }

        function previous(): void {
            root.cycle(-1);
        }
    }
}
