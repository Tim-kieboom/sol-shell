import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../../singletons"
import "../../../utils"

// The settings page of the power menu: pick a theme and a wallpaper, and set how
// see-through the backgrounds are.
Column {
    id: root

    // The popup listens to this and goes back to the menu
    signal back

    spacing: 12

    // ---------- transparency: the state behind the slider ----------

    // the lowest opacity the slider offers: below this the bar is hard to read
    readonly property real minOpacity: Settings.minBackgroundOpacity
    // While the slider is dragged, this holds the value under the pointer; -1 means
    // "not dragging". The setting itself is written only when the slider rests
    // (see saveTimer): every write rewrites the settings file and all the theme
    // files of the programs we color, and a drag makes dozens of changes a second.
    property real draftOpacity: -1
    readonly property real shownOpacity: draftOpacity >= 0 ? draftOpacity : Settings.backgroundOpacity

    // `value` is a fraction from 0 to 1 along the slider; it is turned into an opacity
    // in steps of 5%
    function chooseOpacity(value: real): void {
        const opacity = minOpacity + value * (1 - minOpacity);
        draftOpacity = Math.round(opacity * 20) / 20;
        saveTimer.restart();
    }

    function saveOpacity(): void {
        saveTimer.stop();
        if (draftOpacity >= 0)
            Settings.setBackgroundOpacity(draftOpacity);
        draftOpacity = -1;
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: root.saveOpacity()
    }

    // closing the page in the middle of a drag must not lose the last choice
    Component.onDestruction: saveOpacity()

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

    // ---------- transparency ----------
    SectionHeader {
        icon: Icons.opacity
        title: "Transparency"
    }

    RowLayout {
        width: root.width
        spacing: 10

        VolumeSlider {
            Layout.fillWidth: true
            // the slider shows 0..1 along its length, the opacity runs from minOpacity to 1
            value: (root.shownOpacity - root.minOpacity) / (1 - root.minOpacity)
            onMoved: fraction => root.chooseOpacity(fraction)
        }

        Text {
            // a fixed width, so the slider does not change length when "100%" becomes "95%"
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.shownOpacity * 100) + "%"
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }
    }

    Text {
        width: root.width
        wrapMode: Text.WordWrap
        text: "The bar and popups change at once. Wofi, Thunar and Zen read it when they start."
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
    }

    // ---------- light or dark for other programs ----------
    SectionHeader {
        icon: Icons.darkMode
        title: "Light or dark for other apps"
    }

    RowLayout {
        width: root.width
        spacing: 10

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Follow the theme in apps the shell cannot color (Electron, GTK4)"
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelMedium
        }

        ToggleSwitch {
            checked: Settings.syncSystemColorScheme
            onToggled: Settings.syncSystemColorScheme = !Settings.syncSystemColorScheme
        }
    }

    Text {
        width: root.width
        wrapMode: Text.WordWrap
        text: "Off by default. Switched on, the theme's light or dark side is written to your desktop-wide preference (dconf), which changes it for all programs."
        color: Theme.mutedText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelSmall
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
