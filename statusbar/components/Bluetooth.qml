import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The bluetooth icon in the bar. Clicking it opens a popup with a switch and the
// list of paired devices.
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: 26

    // `enabled` here only dims the icon (off = grey). Clicks are handled by
    // the MouseArea below, so the popup still opens when bluetooth is off.
    IconButton {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.bluetooth
        enabled: BluetoothService.enabled
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

        // The contents. Built when the popup opens, destroyed when it closes.
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
    }
}
