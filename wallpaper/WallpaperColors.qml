import Quickshell
import QtQuick

// One WallpaperColorSampler for every monitor, so each monitor's theme can be made from its own
// wallpaper. It is only created while the "From wallpaper" theme is chosen (see shell.qml).
Scope {
    Variants {
        model: Quickshell.screens

        WallpaperColorSampler {
            required property var modelData
            screen: modelData
        }
    }
}
