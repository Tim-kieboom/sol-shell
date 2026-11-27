pragma Singleton

import Quickshell
import Quickshell.Hyprland
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
    // Where the next wallpaper change starts spreading: the monitor and the point on it. Set to a
    // click in the picker; everything else (keybind, next, settings) clears it, so the circle
    // starts in the middle.
    property string originScreen: ""
    property real originX: -1
    property real originY: -1

    function setOrigin(screenName: string, x: real, y: real): void {
        originScreen = screenName;
        originX = x;
        originY = y;
    }

    function clearOrigin(): void {
        setOrigin("", -1, -1);
    }

    // whether the full-screen picker (wallpaper/WallpaperPicker.qml) is open
    property bool pickerOpen: false

    // what the picker is changing the wallpaper of: "" (every monitor), a monitor's name or "workspace:<id>"
    property string pickerTarget: ""

    function openPicker(target: string): void {
        refresh();
        pickerTarget = target;
        pickerOpen = true;
    }

    function closePicker(): void {
        pickerOpen = false;
    }

    // What the settings page changes the wallpaper of: "" (every monitor), a monitor's name or "workspace:<id>".
    property string settingsTarget: ""

    // with one monitor there is nothing to tell apart: that is "every monitor"
    function scopeFor(monitor: string): string {
        return Quickshell.screens.length > 1 ? monitor : "";
    }

    // the monitor the keybind commands and the picker act on: the one with the focus
    readonly property string focusedMonitor: scopeFor(Hyprland.focusedMonitor?.name ?? "")

    // the workspace with the focus, as a target
    readonly property string focusedWorkspace: "workspace:" + (Hyprland.focusedWorkspace?.id ?? 0)

    // the default wallpaper ("") and then the pictures found, in the order the picker shows them
    readonly property var all: [""].concat(wallpapers)

    // Changes the wallpaper to the one `step` places further in the list (-1 = the one before),
    // going round at the ends.
    function cycle(step: int, target: string): void {
        const list = all;
        const now = Math.max(0, list.indexOf(Settings.wallpaperOfTarget(target)));
        setOrigin(Hyprland.focusedMonitor?.name ?? "", -1, -1);
        Settings.setWallpaper(target, list[(now + step + list.length) % list.length]);
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

    // sol-shell ipc call wallpaper pick           (open or close the picker, for the monitor with the focus)
    // sol-shell ipc call wallpaper next           (the next picture, on the monitor with the focus)
    // sol-shell ipc call wallpaper previous
    // sol-shell ipc call wallpaper pickWorkspace  (the same three for the workspace with the focus)
    // sol-shell ipc call wallpaper nextWorkspace
    // sol-shell ipc call wallpaper previousWorkspace
    IpcHandler {
        target: "wallpaper"

        function pick(): void {
            if (root.pickerOpen)
                root.closePicker();
            else
                root.openPicker(root.focusedMonitor);
        }

        function pickWorkspace(): void {
            if (root.pickerOpen)
                root.closePicker();
            else
                root.openPicker(root.focusedWorkspace);
        }

        function next(): void {
            root.cycle(1, root.focusedMonitor);
        }

        function previous(): void {
            root.cycle(-1, root.focusedMonitor);
        }

        function nextWorkspace(): void {
            root.cycle(1, root.focusedWorkspace);
        }

        function previousWorkspace(): void {
            root.cycle(-1, root.focusedWorkspace);
        }
    }
}
