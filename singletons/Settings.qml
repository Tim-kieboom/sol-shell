pragma Singleton

import Quickshell

Singleton {
    readonly property real uiScale: 1.0

    readonly property string userPath: Quickshell.env("HOME")
    readonly property string wallpaperFile: userPath + "/Pictures/Wallpapers/wallpaper_1.jpg"
}
