import QtQuick

// Color palette: Rosé Pine (main). Every palette defines the same property
// names, which is what lets Theme.qml swap one for another.
// Rosé Pine has no green, so successColor is "foam" (teal). The two border/hover
// greys (#403d52, #524f67) are its "highlight med" and "highlight high" steps.
QtObject {
    readonly property color foregroundColor: "#191724"
    readonly property color highlightColor: "#1f1d2e"
    readonly property color windowColor: "transparent"
    readonly property color maskColor: "#e0def4"
    readonly property color textColor: "#e0def4"
    readonly property color secondaryTextColor: "#908caa"
    readonly property color itemHoverColor: "#403d52"
    readonly property color searchBackgroundColor: "#1f1d2e"
    readonly property color searchBorderColor: "#524f67"
    readonly property color placeholderTextColor: "#6e6a86"
    readonly property color wallpaperFallbackColor: "#191724"
    readonly property color accentColor: "#c4a7e7"
    readonly property color accentHoverColor: "#ebbcba"
    readonly property color accentTextColor: "#191724"
    readonly property color successColor: "#9ccfd8"
    readonly property color dangerColor: "#eb6f92"
}
