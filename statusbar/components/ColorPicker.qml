import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The eyedropper in the bar. Click it, then click any pixel on the screen: a popup under
// the eyedropper shows the color and its hex code (select the code with the mouse to copy
// it). The picker can also be started from a keybind (`sol-shell ipc call picker pick`),
// and the popup then opens on the monitor you are using.
Item {
    id: root

    // the monitor this bar is on
    required property string screenName

    implicitWidth: 26
    implicitHeight: 26

    IconButton {
        anchors.centerIn: parent
        text: Icons.eyedropper
        // greyed out while hyprpicker is waiting for a click
        enabled: !ColorPickerService.picking
        onClicked: ColorPickerService.pick()
    }

    // every monitor has a bar, but only the one you are on shows the result
    Connections {
        target: ColorPickerService

        function onPicked(): void {
            const focused = Hyprland.focusedMonitor;
            if (!focused || focused.name === root.screenName)
                popup.open = true;
        }
    }

    // shows the picked color; a click anywhere else closes it
    BarPopup {
        id: popup

        popupWidth: 190
        padding: 12

        RowLayout {
            spacing: 12

            // the color
            Rectangle {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                radius: 8
                color: ColorPickerService.lastColor
                border.width: 1
                border.color: Theme.surfaceBorder
            }

            ColumnLayout {
                spacing: 2

                // selectable, so it can be copied
                TextEdit {
                    text: ColorPickerService.lastColor
                    readOnly: true
                    selectByMouse: true
                    color: Theme.primaryText
                    selectedTextColor: Theme.accentText
                    selectionColor: Theme.accent
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodyLarge
                    font.weight: Font.Medium
                }

                Text {
                    text: "Picked color"
                    color: Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.labelSmall
                }
            }
        }
    }
}
