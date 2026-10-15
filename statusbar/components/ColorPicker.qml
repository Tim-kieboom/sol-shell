import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "../../utils"

// The palette button in the bar. Click it for a small popup with a hex field: type a code
// (#c8a96a, c8a96a or #ca6) and the swatch beside it shows the color, or move the red,
// green and blue sliders below it, which change the same field. The eyedropper in the
// field picks a color from anywhere on the screen instead, and the result is filled in
// on the same field. The picker can also be started from a keybind
// (`sol-shell ipc call picker pick`); the popup then opens on the monitor you are using.
Item {
    id: root

    // the monitor this bar is on
    required property string screenName

    // what is typed, the color, the sliders (see ColorPickerState)
    ColorPickerState {
        id: pickerState
    }

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: Icons.palette
        // brighter while hovered or while the popup is open; dim while picking
        color: ColorPickerService.picking ? Theme.secondaryText
            : (popup.open || mouse.containsMouse) ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    // A picked color goes into the field. Every monitor has a bar, but only the one you
    // are on opens its popup.
    Connections {
        target: ColorPickerService

        function onPicked(color: string): void {
            pickerState.input = color;
            const focused = Hyprland.focusedMonitor;
            if (!focused || focused.name === root.screenName)
                popup.open = true;
        }
    }

    BarPopup {
        id: popup

        popupWidth: 260
        padding: 12

        ColorPickerPanel {
            picker: pickerState
            onCloseRequested: popup.close()
        }
    }
}
