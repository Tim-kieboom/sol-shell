import QtQuick

// The smooth bar: one soft, rounded bar that floats a little way from the edges of the screen, all the
// items in it in a single piece. Its items are the minimal bar's (BarStyle hands them over, so the two
// share one layout and a new item shows up in both); what is its own is the shape. See MinimalStyle.qml
// for what the fields mean; this style adds, with the surface "floating":
//
//   floatMargin    space between the bar and the edges of the screen (the bar window is this much
//                  smaller than the screen on every side)
//   cornerRadius   how round the bar is (half its height makes the ends fully round)
//   groupGap       the space between the entries of a side, with your own layout (bar-layout.json)
//
// The window is exactly the bar, so the whole of it takes clicks and nothing needs a click mask.
QtObject {
    readonly property string label: "Smooth"
    readonly property string surface: "floating"

    readonly property string position: "top"
    readonly property real barHeight: 38
    readonly property real floatMargin: 8
    readonly property real cornerRadius: 19
    readonly property real edgeMargin: 18
    readonly property real popupGap: 10
    readonly property real itemSpacing: 6
    readonly property real groupGap: 14

    // soft: a little see-through, not too much
    readonly property var opacity: ({
            default: 0.9,
            min: 0.4
        })

    // the minimal bar's layout, set by BarStyle
    property var sections: ({})
    property var compactSections: undefined
}
