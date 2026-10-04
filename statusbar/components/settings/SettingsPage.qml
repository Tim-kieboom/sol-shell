import Quickshell
import QtQuick
import "../../../singletons"

// The settings page of the power menu: pick a theme and a wallpaper.
Column {
    id: root

    // The popup listens to this and goes back to the menu
    signal back

    spacing: 12

    // look in the wallpaper folder again every time the page opens
    onVisibleChanged: if (visible) WallpaperService.refresh()

    // ---------- header: back button + title ----------
    Row {
        spacing: 8

        Rectangle {
            width: 28
            height: 28
            radius: 14
            color: backMouse.containsMouse ? Theme.surface : "transparent"

            Text {
                anchors.centerIn: parent
                text: Icons.previousMonth
                color: Theme.primaryText
                font.family: Fonts.materialIconFontFamily
                font.pixelSize: Fonts.bodyLarge
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.back()
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Settings"
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.titleSmall
            font.weight: Font.Medium
        }
    }

    // ---------- theme ----------
    SectionHeader {
        icon: Icons.colorScheme
        title: "Theme"
    }

    // A Flow lays items out left to right and wraps to a new line when the next one
    // would not fit, so any number of themes works (three chips fit per line).
    Flow {
        width: root.width
        spacing: 8

        Repeater {
            // one chip per palette, straight from the list in Theme.qml
            model: Theme.themes

            ThemeChip {
                required property var modelData
                entry: modelData
            }
        }
    }

    // ---------- wallpaper ----------
    SectionHeader {
        icon: Icons.wallpaper
        title: "Wallpaper"
    }

    // Many pictures will not fit, so the grid scrolls: as tall as its content,
    // up to 190px, then it scrolls.
    //
    // A GridView only creates the cells you can see (and reuses them while you
    // scroll), so a folder with hundreds of pictures costs the same as one with
    // twelve. A Repeater inside a Flickable would build a thumbnail for every
    // single image, visible or not.
    GridView {
        width: root.width
        height: Math.min(contentHeight, 190)
        // one cell = a 100px thumbnail plus 8px of space; three fit in a row
        cellWidth: 108
        cellHeight: 68
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // ScriptModel compares the new list with the old one and only changes
        // the cells that differ. Without it, every rescan of the folder (which
        // happens each time this page opens) would rebuild every thumbnail.
        // "" first = the default tile, then the pictures found in the folder.
        model: ScriptModel {
            values: [""].concat(WallpaperService.wallpapers)
        }

        delegate: WallpaperThumb {
            required property string modelData
            path: modelData
        }
    }

    Text {
        visible: WallpaperService.wallpapers.length === 0
        text: "No other images found in " + Settings.wallpaperDir
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }
}
