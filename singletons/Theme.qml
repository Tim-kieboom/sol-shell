pragma Singleton

import Quickshell
import QtQuick
import "./themes"

Singleton {
    readonly property QtObject theme: Solliom {}

    readonly property color success: theme.successColor
    readonly property color danger: theme.dangerColor
    readonly property color accent: theme.accentColor
    readonly property color accentHover: theme.accentHoverColor
    readonly property color nonAccent: theme.itemHoverColor
    readonly property color accentText: theme.accentTextColor
    readonly property color primaryText: theme.textColor
    readonly property color secondaryText: theme.secondaryTextColor
    readonly property color shellBackground: theme.foregroundColor
    readonly property color surfaceBorder: theme.searchBorderColor
    readonly property color mutedText: theme.placeholderTextColor

    function withOpacity(color: color, opacity: real): color {
        var c = color;
        return Qt.rgba(c.r, c.g, c.b, opacity);
    }
}
