import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../singletons"
import "../settings"

// The wallpaper picker: the screen you are looking at dims, and a grid of your wallpapers
// appears in the middle. Click one (or move with the arrow keys and press Enter) and the
// wallpaper fades to it. Escape or a click outside the grid closes it. Opened with
// `sol-shell ipc call wallpaper pick`, which is what a keybind uses.
// qmllint disable uncreatable-type
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sol-wallpaper-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    color: "transparent"
    visible: WallpaperService.pickerOpen

    readonly property int thumbWidth: 240
    readonly property int thumbHeight: 144
    readonly property int cell: 8
    readonly property int columns: Math.max(1, Math.min(4, Math.floor((screen.width - 160) / (thumbWidth + cell))))
    readonly property int count: WallpaperService.all.length

    // a click outside the grid closes the picker
    MouseArea {
        anchors.fill: parent
        onClicked: WallpaperService.closePicker()

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: grid.width + 32
        height: grid.height + 32 + title.height + 8
        radius: 16
        color: Theme.withOpacity(Theme.shellBackground, BarStyle.popupOpacity)
        border.color: Theme.surfaceBorder
        border.width: 1

        // swallow clicks on the card itself
        MouseArea {
            anchors.fill: parent
        }

        Text {
            id: title
            x: 16
            y: 16
            text: "Wallpaper"
            color: Theme.primaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.titleSmall
        }

        GridView {
            id: grid
            x: 16
            y: 16 + title.height + 8
            width: root.columns * cellWidth
            height: Math.min(Math.ceil(root.count / root.columns), Math.max(1, Math.floor((root.screen.height - 240) / cellHeight))) * cellHeight
            cellWidth: root.thumbWidth + root.cell
            cellHeight: root.thumbHeight + root.cell
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            focus: root.visible
            keyNavigationEnabled: true
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0

            model: ScriptModel {
                values: WallpaperService.all
            }

            // start on the wallpaper that is in use
            onVisibleChanged: if (visible) currentIndex = Math.max(0, WallpaperService.all.indexOf(Settings.wallpaperFile))

            Keys.onEscapePressed: WallpaperService.closePicker()
            Keys.onReturnPressed: pickCurrent()
            Keys.onEnterPressed: pickCurrent()

            function pickCurrent(): void {
                const path = WallpaperService.all[currentIndex];
                if (path !== undefined)
                    Settings.wallpaperFile = path;
                WallpaperService.closePicker();
            }

            highlight: Rectangle {
                radius: 10
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
            }

            delegate: Item {
                id: cellItem
                required property string modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight

                WallpaperThumb {
                    anchors.centerIn: parent
                    width: root.thumbWidth
                    height: root.thumbHeight
                    path: cellItem.modelData
                    onPicked: WallpaperService.closePicker()
                }
            }
        }
    }
}
