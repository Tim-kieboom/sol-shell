import QtQuick
import QtQuick.Effects
import "../singletons"

// The wallpaper as an item: the user's picture, or the bundled one when the setting is
// empty or the picture is missing or broken. The wallpaper window and the lock screen
// both show it, so they always agree.
Item {
    id: root

    // The picture's path: the wallpaper setting, unless the owner sets another (the login
    // screen, which runs as another user and has no settings of its own).
    property string path: Settings.wallpaperFile

    // The wallpaper as a URL. "" means "use the default", which is the image that ships with
    // the project.
    readonly property url userSource: path === ""
        ? Settings.defaultWallpaper
        : Settings.fileUrl(path)

    // flips to true if the user's image is missing or broken, so we fall back
    // to the default instead of showing a black screen
    property bool useDefault: false
    // if the setting changes, give the new image a fair chance again
    onUserSourceChanged: useDefault = false

    // true while the shipped painting is on screen
    readonly property bool showingDefault: path === "" || useDefault

    // Shown while the image loads, and around it if it does not cover the whole area. The
    // shipped painting matches its own edge colour, so no seam shows.
    readonly property color background: showingDefault ? Settings.defaultWallpaperBackground : "black"

    Rectangle {
        anchors.fill: parent
        color: root.background
    }

    // How long the new picture takes to grow over the old one (a circle that spreads from a point).
    readonly property int revealMs: 700

    // Where the circle starts, in this item's own pixels. The owner sets these before the picture
    // changes (the wallpaper window uses the pointer's place when a wallpaper was clicked in the
    // picker, and the middle otherwise); -1 means the middle.
    property real originX: -1
    property real originY: -1

    // the circle's centre as it was when the current reveal began
    property real centerX: width / 2
    property real centerY: height / 2
    // 0 = the new picture is not visible, 1 = it covers everything
    property real progress: 0
    // the radius the circle needs to cover the whole item from its centre
    readonly property real fullRadius: Math.hypot(Math.max(centerX, width - centerX), Math.max(centerY, height - centerY))

    // the address of what is being shown now, and whether that is the shipped painting
    property url shownSource: ""
    property bool shownDefault: false
    // what should be shown: the new picture loads invisibly and grows in when ready
    readonly property url targetSource: useDefault ? Settings.defaultWallpaper : userSource

    // the picture that is spreading right now (what `shownSource` becomes when it is done)
    property url growingSource: ""
    property bool growingDefault: false

    // A change while a circle is still growing finishes that one at once: it becomes the picture
    // on show, and the new change starts its own circle from the new point.
    onTargetSourceChanged: {
        if (grow.running) {
            grow.stop();
            shownSource = growingSource;
            shownDefault = growingDefault;
            progress = 0;
        }
    }

    // Your own pictures: scale until they cover the monitor and cut off what sticks out (never
    // stretched or squashed, whatever the monitor shape). The shipped painting is portrait, so
    // it is shown whole instead, with bars at the sides.
    //
    // There is deliberately no sourceSize on these. With PreserveAspectCrop it is not a maximum:
    // Qt scales the picture to COVER that size, so a 1080p picture on a 4K monitor was decoded at
    // 4K (4x the memory). Measured with Qt 6.11. A 4K picture on a 1080p monitor does take 4x more
    // memory than it needs, so keep wallpapers no bigger than your biggest monitor.

    // the picture on show
    Image {
        id: base
        anchors.fill: parent
        source: root.shownSource
        fillMode: root.shownDefault ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        // load in the background so the shell does not freeze while decoding
        asynchronous: true
        onStatusChanged: root.hideTopIfDone()
    }

    // the picture that comes next: not drawn itself, only through the circle below
    Image {
        id: incoming
        anchors.fill: parent
        source: root.targetSource
        fillMode: root.showingDefault ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        layer.enabled: true

        // Image.Error = file missing or not a valid image. Switch to the default.
        // (Only once: if the default itself fails we stay on it, no endless loop.)
        onStatusChanged: {
            if (status === Image.Error && !root.useDefault)
                root.useDefault = true;
            else if (status === Image.Ready)
                root.reveal();
        }
    }

    // the circle: white inside, see-through outside; the new picture shows only inside it
    Item {
        id: circleMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true

        Rectangle {
            readonly property real size: 2 * root.fullRadius * root.progress
            x: root.centerX - size / 2
            y: root.centerY - size / 2
            width: size
            height: size
            radius: size / 2
            color: "white"
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: incoming
        maskEnabled: true
        maskSource: circleMask
        visible: root.progress > 0
    }

    NumberAnimation {
        id: grow
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.revealMs
        easing.type: Easing.OutCubic
        onFinished: {
            root.shownSource = root.growingSource;
            root.shownDefault = root.growingDefault;
            // the picture underneath takes over; the circle is hidden once it has loaded
            Qt.callLater(root.hideTopIfDone);
        }
    }

    // the new picture is ready: spread it over the old one (the very first one just appears)
    function reveal(): void {
        if (incoming.status !== Image.Ready || targetSource === shownSource)
            return;
        if (shownSource.toString() === "") {
            shownSource = targetSource;
            shownDefault = showingDefault;
            Qt.callLater(hideTopIfDone);
            return;
        }
        centerX = originX < 0 ? width / 2 : originX;
        centerY = originY < 0 ? height / 2 : originY;
        growingSource = targetSource;
        growingDefault = showingDefault;
        grow.restart();
    }

    // Hides the circle once the picture underneath shows the same thing, so there is no flash.
    function hideTopIfDone(): void {
        if (!grow.running && base.status === Image.Ready && base.source === incoming.source)
            progress = 0;
    }
}
