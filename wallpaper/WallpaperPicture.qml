import QtQuick
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

    // How long a new picture takes to fade in over the old one.
    readonly property int fadeMs: 400

    // the address of what is being shown now, and whether that is the shipped painting
    property url shownSource: ""
    property bool shownDefault: false
    // what should be shown: the new picture loads on top (invisible) and fades in when ready
    readonly property url targetSource: useDefault ? Settings.defaultWallpaper : userSource

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

    // the picture that comes next
    Image {
        id: incoming
        anchors.fill: parent
        source: root.targetSource
        fillMode: root.showingDefault ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0

        // Image.Error = file missing or not a valid image. Switch to the default.
        // (Only once: if the default itself fails we stay on it, no endless loop.)
        onStatusChanged: {
            if (status === Image.Error && !root.useDefault)
                root.useDefault = true;
            else if (status === Image.Ready)
                root.reveal();
        }
        onSourceChanged: {
            fade.stop();
            opacity = 0;
        }

        NumberAnimation {
            id: fade
            target: incoming
            property: "opacity"
            from: 0
            to: 1
            duration: root.fadeMs
            easing.type: Easing.InOutQuad
            onFinished: {
                root.shownSource = root.targetSource;
                root.shownDefault = root.showingDefault;
                // the picture underneath takes over; the top one is hidden once it has loaded
                Qt.callLater(root.hideTopIfDone);
            }
        }
    }

    // the new picture is ready: fade it in (the very first one just appears)
    function reveal(): void {
        if (incoming.status !== Image.Ready || targetSource === shownSource)
            return;
        if (shownSource.toString() === "") {
            shownSource = targetSource;
            shownDefault = showingDefault;
            Qt.callLater(hideTopIfDone);
        } else {
            fade.restart();
        }
    }

    // Hides the top picture once the one underneath shows the same thing, so there is no flash.
    function hideTopIfDone(): void {
        if (!fade.running && base.status === Image.Ready && base.source === incoming.source)
            incoming.opacity = 0;
    }
}
