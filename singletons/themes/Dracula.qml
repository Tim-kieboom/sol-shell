import QtQuick

// Color palette: Dracula. Every palette defines the same property names, which
// is what lets Theme.qml swap one for another.
// secondaryTextColor is the foreground dimmed towards the background (the
// official palette has no secondary text color); searchBackgroundColor reuses
// the selection color.
QtObject {
    readonly property color foregroundColor: "#282a36"
    readonly property color highlightColor: "#44475a"
    readonly property color windowColor: "transparent"
    readonly property color maskColor: "#f8f8f2"
    readonly property color textColor: "#f8f8f2"
    readonly property color secondaryTextColor: "#c4c4c3"
    readonly property color itemHoverColor: "#44475a"
    readonly property color searchBackgroundColor: "#44475a"
    readonly property color searchBorderColor: "#6272a4"
    readonly property color placeholderTextColor: "#6272a4"
    readonly property color wallpaperFallbackColor: "#282a36"
    readonly property color accentColor: "#bd93f9"
    readonly property color accentHoverColor: "#ff79c6"
    readonly property color accentTextColor: "#282a36"
    readonly property color successColor: "#50fa7b"
    readonly property color dangerColor: "#ff5555"
}
