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
            color: backMouse.containsMouse ? Theme.nonAccent : "transparent"

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

    Row {
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

    // Many pictures will not fit, so the grid sits in a Flickable (a scrolling
    // window): as tall as its content, up to 190px, then it scrolls.
    Flickable {
        width: root.width
        height: Math.min(grid.implicitHeight, 190)
        contentHeight: grid.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            columns: 3
            spacing: 8

            Repeater {
                // "" first = the default tile, then the pictures found in the folder
                model: [""].concat(WallpaperService.wallpapers)

                WallpaperThumb {
                    required property string modelData
                    path: modelData
                }
            }
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
