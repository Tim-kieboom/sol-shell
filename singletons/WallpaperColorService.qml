pragma Singleton

import QtQuick

// The color the "From wallpaper" theme is built around, found in the wallpaper picture by
// wallpaper/WallpaperColors.qml. Until it has looked, `seed` is the default theme's accent, so the
// theme always has colors.
QtObject {
    property color seed: "#d1c88f"
}
