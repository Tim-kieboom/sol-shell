import QtQuick
import QtQuick.Window
import "../singletons"

// A small preview of one wallpaper. Click to make it the wallpaper.
// path = "" is the special tile for the default wallpaper that ships with the shell.
Rectangle {
    id: root

    required property string path
    readonly property bool isDefault: path === ""
    // what this tile sets the wallpaper of: "" (every monitor), a monitor's name or "workspace:<id>"
    property string target: ""
    readonly property bool selected: Settings.wallpaperOfTarget(target) === path

    // When true, a click makes the new wallpaper spread from the pointer's place (the picker does
    // this); otherwise it spreads from the middle.
    property bool spreadFromClick: false

    // emitted when the tile is clicked, after the wallpaper is changed
    signal picked()

    implicitWidth: 100
    implicitHeight: 60
    radius: 8
    color: Theme.surface
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : Theme.surfaceBorder

    // matches the shipped painting's edge, so its side bars look like part of the picture
    Rectangle {
        visible: root.isDefault
        anchors.fill: parent
        anchors.margins: 3
        radius: 6
        color: Settings.defaultWallpaperBackground
    }

    Image {
        anchors.fill: parent
        anchors.margins: 3
        source: root.isDefault ? Settings.defaultWallpaper : Settings.fileUrl(root.path)
        fillMode: root.isDefault ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        asynchronous: true
        // A wallpaper can be 4K, but this preview is ~100px wide. Telling Qt to
        // decode it small saves a lot of memory and time, which matters with a
        // folder full of images.
        sourceSize: Qt.size(Math.max(200, root.width * 2), Math.max(120, root.height * 2))
    }

    // "Default" label, so you can tell this tile apart from your own pictures
    Rectangle {
        visible: root.isDefault
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 6
        width: label.implicitWidth + 10
        height: label.implicitHeight + 4
        radius: 4
        color: Theme.withOpacity(Theme.shellBackground, 0.75)

        Text {
            id: label
            anchors.centerIn: parent
            text: "Default"
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Same idea as the theme: change the setting, everything else follows.
        // Wallpaper.qml's image source is a binding on this very property.
        onClicked: mouse => {
            if (root.spreadFromClick) {
                const point = root.mapToItem(null, mouse.x, mouse.y);
                WallpaperService.setOrigin(root.Window.window?.screen?.name ?? "", point.x, point.y);
            } else {
                WallpaperService.clearOrigin();
            }
            Settings.setWallpaper(root.target, root.path);
            root.picked();
        }
    }
}
