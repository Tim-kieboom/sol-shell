import Quickshell
import Quickshell.Wayland
import QtQuick
import "../singletons"

// A window that covers one whole monitor and lives on the lowest Wayland layer
// ("background"), underneath normal windows. It only draws the wallpaper image.
PanelWindow {
    id: root

    // The user's wallpaper as a URL. "" in the settings means "I chose the
    // default", which is the image that ships with the project.
    readonly property url userSource: Settings.wallpaperFile === ""
        ? Settings.defaultWallpaper
        : "file://" + Settings.wallpaperFile

    // flips to true if the user's image is missing or broken, so we fall back
    // to the default instead of showing a black screen
    property bool useDefault: false
    // if the setting changes, give the new image a fair chance again
    onUserSourceChanged: useDefault = false

    // Stretch to all four edges = fill the whole monitor
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Normally a panel reserves screen space (the status bar pushes windows
    // down). A wallpaper must not reserve anything, so we opt out.
    exclusionMode: ExclusionMode.Ignore

    // Put the window on the bottom-most layer, and give it a recognizable name
    // (it shows up in `hyprctl layers`)
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "sol-wallpaper"

    // shown briefly while the image loads, and around it if it fails to load
    color: "black"

    Image {
        anchors.fill: parent
        source: root.useDefault ? Settings.defaultWallpaper : root.userSource
        // scale the image until it covers the monitor, then cut off what sticks
        // out (so it is never stretched or squashed, whatever the monitor shape)
        fillMode: Image.PreserveAspectCrop
        // load in the background so the shell does not freeze while decoding
        asynchronous: true

        // Image.Error = file missing or not a valid image. Switch to the default.
        // (Only once: if the default itself fails we stay on it, no endless loop.)
        onStatusChanged: {
            if (status === Image.Error && !root.useDefault)
                root.useDefault = true;
        }
    }
}
