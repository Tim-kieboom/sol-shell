import QtQuick

// Color palette: Catppuccin Latte, the light flavour. Every palette defines the
// same property names, which is what lets Theme.qml swap one for another.
// Unlike the dark palettes, text is darker than the background; accentTextColor
// is white, because the light base color is too faint on the blue accent.
QtObject {
    readonly property color foregroundColor: "#eff1f5"
    readonly property color highlightColor: "#e6e9ef"
    readonly property color windowColor: "transparent"
    readonly property color maskColor: "#4c4f69"
    readonly property color textColor: "#4c4f69"
    readonly property color secondaryTextColor: "#5c5f77"
    readonly property color itemHoverColor: "#ccd0da"
    readonly property color searchBackgroundColor: "#e6e9ef"
    readonly property color searchBorderColor: "#bcc0cc"
    readonly property color placeholderTextColor: "#7c7f93"
    readonly property color wallpaperFallbackColor: "#eff1f5"
    readonly property color accentColor: "#1e66f5"
    readonly property color accentHoverColor: "#7287fd"
    readonly property color accentTextColor: "#ffffff"
    readonly property color successColor: "#40a02b"
    readonly property color dangerColor: "#d20f39"
}
