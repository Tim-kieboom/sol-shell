import QtQuick
import "../../singletons"

// A thin vertical bar in the accent color that sets a group of items apart (it
// frames the media controls). Meant to sit in a Row.
Text {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    anchors.verticalCenter: parent.verticalCenter
    // nudged up 2px so it looks vertically centered next to the buttons
    anchors.verticalCenterOffset: -2
    text: "|"
    color: theme.accent
    font.pixelSize: Fonts.titleLarge
}
