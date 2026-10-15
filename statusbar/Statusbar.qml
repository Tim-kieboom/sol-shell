import Quickshell
import QtQuick
import "../singletons"

// The status bar: one window along the top of a monitor. What is in it, and where, comes
// from the style (BarStyle.current); BarRenderer builds the rows from it.
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: BarStyle.barHeight
    color: Theme.withOpacity(Theme.shellBackground, Settings.backgroundOpacity)

    BarRenderer {
        anchors.fill: parent
        screenName: root.screen.name
        style: BarStyle.current
    }
}
