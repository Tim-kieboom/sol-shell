import Quickshell
import Quickshell.Wayland
import QtQuick
import "../singletons"

// A window that covers one whole monitor and lives on the lowest Wayland layer
// ("background"), underneath normal windows. It only draws the wallpaper image.
PanelWindow {
    id: root

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

    // shown briefly while the image loads
    color: picture.background

    WallpaperPicture {
        id: picture
        anchors.fill: parent
    }
}
