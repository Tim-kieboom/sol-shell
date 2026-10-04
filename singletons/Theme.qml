pragma Singleton

import Quickshell
import QtQuick
import "./themes"

// The active color theme. The rest of the shell takes its colors from here
// and never from a palette file directly, so switching theme recolors
// everything at once.
Singleton {
    // The available palettes. The picker in the settings page loops over this
    // list, so a new theme only needs a file in themes/ and one entry here.
    // `id` is what gets saved in the settings file.
    readonly property var themes: [
        { id: "solliom", label: "Solliom", palette: solliom },
        { id: "catppuccin", label: "Catppuccin", palette: catppuccin },
        { id: "gruvbox", label: "Gruvbox", palette: gruvbox }
    ]

    // The palettes themselves. All three have the same property names
    // (accentColor, textColor, ...), which is what makes swapping possible.
    property QtObject solliom: Solliom {}
    property QtObject catppuccin: Catppuccin {}
    property QtObject gruvbox: Gruvbox {}

    // The active palette. This is a binding on Settings.themeName, so the moment
    // the setting changes, every color below (and every item using them) updates.
    readonly property QtObject theme: (themes.find(t => t.id === Settings.themeName) ?? themes[0]).palette

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
