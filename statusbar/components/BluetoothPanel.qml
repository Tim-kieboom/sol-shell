import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The Bluetooth panel: a switch and the list of paired devices. It is what the Bluetooth
// atom's popup shows, and one page of the quick settings menu.
ColumnLayout {
    spacing: 14

    ConnectivityRow {
        Layout.fillWidth: true
        icon: Icons.bluetooth
        title: "Bluetooth"
        subtitle: BluetoothService.statusText
        checked: BluetoothService.enabled
        onToggled: BluetoothService.toggle()
    }

    // The device list. Only shown while Bluetooth is on; when
    // `visible` is false the layout also gives it no space, so the
    // popup shrinks by itself.
    Column {
        Layout.fillWidth: true
        visible: BluetoothService.enabled
        spacing: 2

        Repeater {
            // a plain JS array works as a model; each item arrives as `modelData`
            model: BluetoothService.pairedDevices

            BluetoothDeviceRow {
                required property var modelData
                device: modelData
                width: parent.width
            }
        }

        Text {
            visible: BluetoothService.pairedDevices.length === 0
            text: "No paired devices"
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.labelSmall
        }
    }
}
