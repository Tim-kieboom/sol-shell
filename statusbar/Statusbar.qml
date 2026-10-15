import Quickshell
import QtQuick
import "../singletons"

// The status bar: one window along the top (or bottom) of a monitor. What is in it, and
// where, comes from the style (BarStyle.current); BarRenderer builds the rows from it.
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    // the screen edge comes from the style; the window reserves its own height there
    anchors {
        top: BarStyle.position !== "bottom"
        bottom: BarStyle.position === "bottom"
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
