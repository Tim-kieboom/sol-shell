import QtQuick

// The colors of one theme, under the names the rest of the shell uses (the same ones `Theme` has).
// `Theme` is the shell-wide set; there is one of these for every monitor, so a monitor can have colors
// of its own (the "From wallpaper" theme gives each monitor the colors of its own wallpaper).
// Bar items read them through `theme`, which they get from `Theme.forScreen(...)`.
QtObject {
    // a palette object of the themes folder (Solliom, Nord, Generated, ...)
    required property QtObject palette

    readonly property color success: palette.successColor
    readonly property color danger: palette.dangerColor
    readonly property color accent: palette.accentColor
    readonly property color accentHover: palette.accentHoverColor
    readonly property color surface: palette.itemHoverColor
    readonly property color accentText: palette.accentTextColor
    readonly property color primaryText: palette.textColor
    readonly property color secondaryText: palette.secondaryTextColor
    readonly property color shellBackground: palette.foregroundColor
    readonly property color surfaceBorder: palette.searchBorderColor
    readonly property color mutedText: palette.placeholderTextColor

    // green while low, the accent in the middle, red when high (see Theme.usageColor)
    function usageColor(fraction: real): color {
        if (fraction < 0.5)
            return success;
        return fraction < 0.8 ? accent : danger;
    }

    function withOpacity(color: color, opacity: real): color {
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
}
