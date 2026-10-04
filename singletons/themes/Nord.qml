import QtQuick

// Color palette: Nord. Every palette defines the same property names, which is
// what lets Theme.qml swap one for another.
// placeholderTextColor (#7b88a1) is a lightened nord3: it is not in the official
// palette, but nord3 itself is too dark to read on nord0 (contrast 1.9).
QtObject {
    readonly property color foregroundColor: "#2e3440"
    readonly property color highlightColor: "#3b4252"
    readonly property color windowColor: "transparent"
    readonly property color maskColor: "#eceff4"
    readonly property color textColor: "#eceff4"
    readonly property color secondaryTextColor: "#d8dee9"
    readonly property color itemHoverColor: "#434c5e"
    readonly property color searchBackgroundColor: "#3b4252"
    readonly property color searchBorderColor: "#4c566a"
    readonly property color placeholderTextColor: "#7b88a1"
    readonly property color wallpaperFallbackColor: "#2e3440"
    readonly property color accentColor: "#88c0d0"
    readonly property color accentHoverColor: "#8fbcbb"
    readonly property color accentTextColor: "#2e3440"
    readonly property color successColor: "#a3be8c"
    readonly property color dangerColor: "#bf616a"
}
