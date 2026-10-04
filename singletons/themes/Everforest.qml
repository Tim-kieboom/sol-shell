import QtQuick

// Color palette: Everforest (dark, medium contrast). Every palette defines the
// same property names, which is what lets Theme.qml swap one for another.
QtObject {
    readonly property color foregroundColor: "#2d353b"
    readonly property color highlightColor: "#343f44"
    readonly property color windowColor: "transparent"
    readonly property color maskColor: "#d3c6aa"
    readonly property color textColor: "#d3c6aa"
    readonly property color secondaryTextColor: "#9da9a0"
    readonly property color itemHoverColor: "#475258"
    readonly property color searchBackgroundColor: "#343f44"
    readonly property color searchBorderColor: "#4f585e"
    readonly property color placeholderTextColor: "#859289"
    readonly property color wallpaperFallbackColor: "#2d353b"
    readonly property color accentColor: "#dbbc7f"
    readonly property color accentHoverColor: "#e69875"
    readonly property color accentTextColor: "#2d353b"
    readonly property color successColor: "#a7c080"
    readonly property color dangerColor: "#e67e80"
}
