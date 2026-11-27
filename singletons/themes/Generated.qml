import QtQuick
import "../"

// Color palette: made from the wallpaper. It has the same property names as every other palette,
// but its colors are computed from one color, the dominant one of the picture
// (WallpaperColorService.seed): the accent takes the seed's hue, and the dark background, the
// surfaces and the text are tinted with the same hue, so the whole bar belongs to the picture.
// It is always a dark palette: the lock screen and the text contrast rely on that.
QtObject {
    id: root

    // the monitor you are working on, unless an owner sets another (a monitor's own theme)
    property color seed: WallpaperColorService.seed

    // A picture with no color (black and white, gray) gives a gray seed: then the whole theme
    // stays gray, instead of picking some hue out of nothing.
    readonly property bool neutral: seed.hslSaturation < 0.1
    readonly property real hue: seed.hslHue < 0 ? 0 : seed.hslHue
    // how colorful the accent is, kept in a range where it is neither gray nor neon
    readonly property real saturation: neutral ? 0.05 : Math.max(0.35, Math.min(0.75, seed.hslSaturation))

    // a color of the seed's hue: `s` the saturation, `l` the lightness
    function tint(s: real, l: real): color {
        return Qt.hsla(root.hue, neutral ? s * 0.2 : s, l, 1);
    }

    readonly property color foregroundColor: tint(0.25, 0.07)
    readonly property color highlightColor: tint(0.25, 0.14)
    readonly property color windowColor: "transparent"
    readonly property color maskColor: tint(0.3, 0.75)
    readonly property color textColor: tint(0.3, 0.88)
    readonly property color secondaryTextColor: tint(0.2, 0.8)
    readonly property color itemHoverColor: tint(0.2, 0.2)
    readonly property color searchBackgroundColor: tint(0.25, 0.11)
    readonly property color searchBorderColor: tint(0.15, 0.27)
    readonly property color placeholderTextColor: tint(0.12, 0.5)
    readonly property color wallpaperFallbackColor: foregroundColor
    readonly property color accentColor: tint(saturation, 0.68)
    readonly property color accentHoverColor: tint(saturation, 0.76)
    readonly property color accentTextColor: foregroundColor
    // green and red whatever the picture is, so "fine" and "wrong" always read the same
    readonly property color successColor: Qt.hsla(0.3, 0.45, 0.68, 1)
    readonly property color dangerColor: Qt.hsla(0.97, 0.6, 0.65, 1)
}
