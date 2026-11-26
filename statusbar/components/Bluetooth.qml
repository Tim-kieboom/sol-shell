import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The bluetooth icon in the bar, with the battery of the connected device that is lowest next to it
// (red from 20%). Clicking it opens a popup with a switch and the list of paired devices.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    // the number is only there while bluetooth is on and a connected device reports a battery
    readonly property bool showBattery: BluetoothService.enabled && BluetoothService.lowestBattery >= 0

    // `enabled` here only dims the icon (off = grey). Clicks are handled by
    // the MouseArea below, so the popup still opens when bluetooth is off.
    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        IconButton {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.bluetooth
            enabled: BluetoothService.enabled
        }

        Text {
            visible: root.showBattery
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(BluetoothService.lowestBattery * 100) + "%"
            color: BluetoothService.lowestBattery <= 0.2 ? Theme.danger : Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodySmall
            font.weight: Font.Medium
        }
    }

    // Declared after the icon, so it sits on top and gets the clicks
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup

        // this icon is near the right end of the bar: grow leftwards
        alignRight: true
        popupWidth: 280

        // built when the popup opens, destroyed when it closes
        BluetoothPanel {}
    }
}
