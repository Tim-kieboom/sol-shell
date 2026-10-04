import QtQuick

// Color palette: Tokyo Night (the "night" style). Every palette defines the same
// property names, which is what lets Theme.qml swap one for another.
QtObject {
    readonly property color foregroundColor: "#1a1b26"
    readonly property color highlightColor: "#292e42"
    readonly property color windowColor: "transparent"
    readonly property color maskColor: "#c0caf5"
    readonly property color textColor: "#c0caf5"
    readonly property color secondaryTextColor: "#a9b1d6"
    readonly property color itemHoverColor: "#3b4261"
    readonly property color searchBackgroundColor: "#16161e"
    readonly property color searchBorderColor: "#414868"
    readonly property color placeholderTextColor: "#737aa2"
    readonly property color wallpaperFallbackColor: "#1a1b26"
    readonly property color accentColor: "#7aa2f7"
    readonly property color accentHoverColor: "#7dcfff"
    readonly property color accentTextColor: "#1a1b26"
    readonly property color successColor: "#9ece6a"
    readonly property color dangerColor: "#f7768e"
}
