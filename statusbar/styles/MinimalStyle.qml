import QtQuick

// The minimalist bar: one full-width strip along the top, every item in a single row.
//
// A style is only a description; BarRenderer builds the bar from it. What it holds:
//
//   label         the name the settings show
//   surface       "solid" or "transparent": whether the bar window or the islands carry the fill
//   position      "top" or "bottom": the screen edge the bar sits on
//   barHeight     height of the bar window, in pixels
//   edgeMargin    space between the bar's left and right ends and the first and last item
//   popupGap      space between the bar and the popups that hang off it
//   sections      the atoms (the items of the bar) in three groups: `left`, `center`
//                 and `right`. The two stretches between the groups keep `center` in the
//                 middle of the free space. An entry is an atom's name, or an object:
//                   { atom: "volume", gap: 11 }
//                 An entry can also be a list of entries: a group, drawn as one island on a
//                 transparent bar (see IslandsStyle.qml). `height` and `width` set the size
//                 of one atom (otherwise it is as big as it wants to be).
//                 `props` is { name: value } to set on the atom itself (`compact: true` for
//                 the clock and the media controls).
//                 `gap` is the space in pixels between this atom and the one before it
//                 (default: `itemSpacing`). It goes with the atom, so when the atom hides
//                 itself (no song playing) its gap goes with it. `rightEnd` is the extra
//                 space after the last atom of `right`.
//                 Every style has to include the "settings" atom.
//   compactSections  the same as `sections`, used when the compact bar is switched on in the
//                 settings (optional: without it the style has no compact layout)
//   itemSpacing   the default `gap`
//   opacity       { default, min }: how see-through the surfaces are (1 = solid) until the
//                 user chooses, and the lowest the settings may set it to
//
// The numbers below are not arbitrary: they reproduce, pixel for pixel, the bar as it was
// built by hand before there were styles (a Spacer of size n between two items was
// n + the layout's 5 on both sides, so a gap of n + 10).
QtObject {
    // what the settings call it
    readonly property string label: "Minimal"

    // "solid": the bar window itself is the strip (it carries the fill); "transparent": the
    // window has no fill and the islands (groups of atoms) carry it
    readonly property string surface: "solid"

    readonly property string position: "top"
    readonly property real barHeight: 30
    readonly property real edgeMargin: 10
    readonly property real popupGap: 6
    readonly property real itemSpacing: 5

    // see-through-ness of the surfaces: the default, and the lowest the settings may set
    readonly property var opacity: ({
            default: 0.8,
            min: 0.3
        })

    readonly property var sections: ({
            left: ["power", "launcher", "workspaces"],
            center: ["media", {
                    atom: "volume",
                    gap: 11
                }, {
                    atom: "clock",
                    gap: 15
                }, {
                    atom: "weather",
                    gap: 14
                }],
            right: ["cpu", "memory", {
                    atom: "colorPicker",
                    gap: 20
                }, {
                    atom: "wifi",
                    gap: 12
                }, {
                    atom: "bluetooth",
                    gap: 8
                }, {
                    atom: "nightLight",
                    gap: 8
                }, {
                    atom: "keyboard",
                    gap: 12
                }, {
                    atom: "privacy",
                    gap: 12
                }, {
                    atom: "bell",
                    gap: 12
                }, "settings"],
            rightEnd: 15
        })

    // The same bar, compact: the volume ring, color picker, wifi and bluetooth are one icon with
    // a menu, the clock shows only the time and the media controls only the buttons.
    readonly property var compactSections: ({
            left: ["power", "launcher", "workspaces"],
            center: [{
                    atom: "media",
                    props: {
                        compact: true
                    }
                }, {
                    atom: "clock",
                    gap: 15,
                    props: {
                        compact: true
                    }
                }, {
                    atom: "weather",
                    gap: 14
                }],
            right: ["cpu", "memory", {
                    atom: "quickSettings",
                    gap: 20
                }, {
                    atom: "keyboard",
                    gap: 12
                }, {
                    atom: "privacy",
                    gap: 12
                }, {
                    atom: "bell",
                    gap: 12
                }, "settings"],
            rightEnd: 15
        })
}
