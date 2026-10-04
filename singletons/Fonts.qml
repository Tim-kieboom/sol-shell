pragma Singleton

import Quickshell

// Font families and the text size scale. Sizes are multiplied by
// Settings.uiScale, so the whole shell can be scaled from one place.
//
// Note: "Symbols Nerd Font" holds only symbols, no ordinary letters, so plain
// text drawn with bodyFontFamily actually comes from the system's fallback font.
Singleton {
    readonly property string bodyFontFamily: "Symbols Nerd Font"
    readonly property string materialIconFontFamily: "Material Design Icons"

    readonly property real labelSmall: 11 * Settings.uiScale
    readonly property real labelMedium: 12 * Settings.uiScale
    readonly property real labelLarge: 13 * Settings.uiScale
    readonly property real bodySmall: 12 * Settings.uiScale
    readonly property real bodyMedium: 14 * Settings.uiScale
    readonly property real bodyLarge: 16 * Settings.uiScale
    readonly property real titleSmall: 14 * Settings.uiScale
    readonly property real titleMedium: 16 * Settings.uiScale
    readonly property real titleLarge: 20 * Settings.uiScale
    readonly property real headlineSmall: 24 * Settings.uiScale
}
