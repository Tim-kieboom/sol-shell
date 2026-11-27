pragma Singleton

import Quickshell.Hyprland
import QtQuick

// The colors the "From wallpaper" theme is built around: one seed color per monitor, found in the
// picture that monitor shows by wallpaper/WallpaperColorSampler.qml. Until a monitor's picture has
// been looked at, its seed is the default theme's accent, so the theme always has colors.
QtObject {
    readonly property color fallback: "#d1c88f"

    // monitor name -> seed color
    property var seeds: ({})

    function setSeed(monitor: string, color: color): void {
        seeds = Object.assign({}, seeds, { [monitor]: color });
    }

    function seedFor(monitor: string): color {
        return seeds[monitor] ?? fallback;
    }

    // the seed of the monitor you are working on: what the shell-wide parts (the lock screen,
    // the colors written for other programs) are made from
    readonly property color seed: seedFor(Hyprland.focusedMonitor?.name ?? "")
}
