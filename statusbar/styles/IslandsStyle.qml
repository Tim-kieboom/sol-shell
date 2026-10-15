import QtQuick

// The islands bar, after Ashell: no strip across the screen, only rounded islands floating
// on it, each holding a few atoms. The window itself is see-through, and only the islands
// take clicks. See MinimalStyle.qml for what the fields mean; this style adds:
//
//   island    how an island looks: its `height`, corner `radius`, the `padding` between its
//             edge and its first and last atom, the `gap` between two islands, and the
//             `itemSpacing` between the atoms inside one
//
// A list inside a section is one island. The values are a first guess at Ashell's default
// look, to be tuned by eye: bar padding 4, islands 26 high and fully round, 4 apart.
QtObject {
    readonly property string label: "Islands"
    readonly property string surface: "transparent"

    readonly property string position: "top"
    // the islands plus 4 above and below
    readonly property real barHeight: 34
    readonly property real edgeMargin: 4
    readonly property real popupGap: 4
    readonly property real itemSpacing: 6

    readonly property var island: ({
            height: 26,
            radius: 13,
            padding: 10,
            gap: 4,
            itemSpacing: 6
        })

    // Ashell's islands are solid by default; the lowest the slider goes is a bit lower than
    // for the strip, because an island that is too faint hides what is on it
    readonly property var opacity: ({
            default: 1.0,
            min: 0.4
        })

    readonly property var sections: ({
            left: [[{
                        atom: "power",
                        width: 30,
                        height: 26
                    }], ["workspaces"]],
            center: [["media"], ["clock", "weather"]],
            right: [["cpu", "memory"], ["volume", "colorPicker", "wifi", "bluetooth"], ["bell", "settings"]]
        })
}
