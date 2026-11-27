import Quickshell
import Quickshell.Wayland
import QtQuick
import "../singletons"

// Looks at the wallpaper and tells WallpaperColorService its dominant color. The "From wallpaper"
// theme is built from that color. It is only created while that theme is chosen (see shell.qml),
// so the picture is not decoded for nothing.
//
// QML can read pixels only from a Canvas, and a Canvas needs a window to live in, so this is a
// window of one transparent pixel that lets every click through.
PanelWindow {
    id: root

    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "sol-wallpaper-colors"
    mask: Region {}

    // the picture is sampled at this size: plenty to find a dominant color, and quick
    readonly property int size: 48

    // the user's picture, or the shipped one when there is none or it cannot be read (the same
    // rule as WallpaperPicture, so the theme matches what is on screen)
    property bool useDefault: false
    readonly property url userSource: Settings.wallpaperFile === "" ? Settings.defaultWallpaper : Settings.fileUrl(Settings.wallpaperFile)
    onUserSourceChanged: useDefault = false

    readonly property url source: root.useDefault ? Settings.defaultWallpaper : root.userSource

    // Only here to find out whether the picture can be read (a missing or broken file switches to
    // the shipped one, as in WallpaperPicture). The pixels themselves come through the canvas.
    Image {
        visible: false
        source: root.source
        sourceSize: Qt.size(1, 1)
        asynchronous: true

        onStatusChanged: {
            if (status === Image.Error && !root.useDefault)
                root.useDefault = true;
            else if (status === Image.Ready)
                root.look();
        }
    }

    // Reads the colors of the picture now on show. A picture the canvas has already loaded (one
    // you went back to) is not loaded again and gives no signal, so it is painted straight away.
    function look(): void {
        if (canvas.isImageLoaded(root.source))
            canvas.requestPaint();
        else
            canvas.loadImage(root.source);
    }

    onSourceChanged: Qt.callLater(look)

    Canvas {
        id: canvas
        width: root.size
        height: root.size
        visible: false
        renderTarget: Canvas.Image

        onImageLoaded: requestPaint()

        onPaint: {
            if (!isImageLoaded(root.source))
                return;
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, root.size, root.size);
            // drawn small: this is also the downscaling
            ctx.drawImage(root.source, 0, 0, root.size, root.size);
            const color = root.dominant(ctx.getImageData(0, 0, root.size, root.size).data);
            WallpaperColorService.seed = color;
        }
    }

    // The dominant color of RGBA pixel data: pixels are put in 12 slices of the color wheel,
    // each counting more the more colorful and bright it is (gray and near-black pixels carry
    // no hue, so they count for nothing), and the heaviest slice gives the hue and saturation.
    // A picture with no color at all gives a nearly gray seed.
    function dominant(data: var): var {
        const slices = 12;
        const weight = new Array(slices).fill(0);
        const hueSum = new Array(slices).fill(0);
        const satSum = new Array(slices).fill(0);
        let lightness = 0;
        const pixels = data.length / 4;

        for (let i = 0; i < data.length; i += 4) {
            const r = data[i] / 255, g = data[i + 1] / 255, b = data[i + 2] / 255;
            const max = Math.max(r, g, b), min = Math.min(r, g, b);
            const delta = max - min;
            lightness += (max + min) / 2;
            if (delta < 0.08 || max < 0.15)
                continue;
            let hue;
            if (max === r)
                hue = ((g - b) / delta + 6) % 6;
            else if (max === g)
                hue = (b - r) / delta + 2;
            else
                hue = (r - g) / delta + 4;
            hue /= 6;
            const saturation = delta / max;
            const slice = Math.min(slices - 1, Math.floor(hue * slices));
            const w = saturation * max;
            weight[slice] += w;
            hueSum[slice] += hue * w;
            satSum[slice] += saturation * w;
        }

        let best = 0;
        for (let s = 1; s < slices; s++)
            if (weight[s] > weight[best])
                best = s;

        if (weight[best] <= 0)
            return Qt.hsla(0, 0.05, 0.6, 1);
        return Qt.hsla(hueSum[best] / weight[best], satSum[best] / weight[best], 0.6, 1);
    }
}
