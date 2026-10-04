import QtQuick
import "../../../singletons"

// A small preview of one wallpaper. Click to make it the wallpaper.
// path = "" is the special tile for the default wallpaper that ships with the shell.
Rectangle {
    id: root

    required property string path
    readonly property bool isDefault: path === ""
    readonly property bool selected: Settings.wallpaperFile === path

    implicitWidth: 100
    implicitHeight: 60
    radius: 8
    color: Theme.nonAccent
    border.width: selected ? 2 : 1
    border.color: selected ? Theme.accent : Theme.surfaceBorder

    Image {
        anchors.fill: parent
        anchors.margins: 3
        source: root.isDefault ? Settings.defaultWallpaper : "file://" + root.path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // A wallpaper can be 4K, but this preview is ~100px wide. Telling Qt to
        // decode it small saves a lot of memory and time, which matters with a
        // folder full of images.
        sourceSize: Qt.size(200, 120)
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
        onClicked: Settings.wallpaperFile = root.path
    }
}
