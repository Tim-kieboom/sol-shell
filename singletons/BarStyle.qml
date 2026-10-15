pragma Singleton

import Quickshell
import QtQuick
import "../statusbar/styles"

// The style the bar is drawn in right now (see statusbar/styles/MinimalStyle.qml for what a
// style holds). Everything in the bar that depends on the style reads it from here, so
// switching styles changes the bar without touching the items.
Singleton {
    id: root

    // the style object itself: BarRenderer reads the sections and spacing from it
    readonly property var current: minimal

    // shortcuts for what the items need
    readonly property string position: current.position
    readonly property real barHeight: current.barHeight
    readonly property real popupGap: current.popupGap

    MinimalStyle {
        id: minimal
    }
}
