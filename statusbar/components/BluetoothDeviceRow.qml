import "../../singletons"

// One paired device in the popup. Click anywhere on the row to connect/disconnect.
ListRow {
    id: root

    // The Bluetooth device object, handed in by whoever creates the row
    required property var device

    icon: BluetoothService.iconFor(device)
    // connected devices are tinted, the rest are grey
    iconColor: device.connected ? Theme.accent : Theme.secondaryText
    title: device.name
    subtitle: BluetoothService.deviceStatus(device)

    onClicked: BluetoothService.toggleConnection(device)
}
