import QtQuick
import QtQuick.Layouts
import "../../singletons"

// One paired device in the popup. Click anywhere on the row to connect/disconnect.
Rectangle {
    id: root

    // The Bluetooth device object, handed in by whoever creates the row
    required property var device

    implicitHeight: 38
    radius: 8
    // light highlight while the mouse is over the row
    color: mouse.containsMouse ? Theme.nonAccent : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        Text {
            text: BluetoothService.iconFor(root.device)
            // connected devices are tinted, the rest are grey
            color: root.device.connected ? Theme.accent : Theme.secondaryText
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.titleSmall
        }

        Column {
            Layout.fillWidth: true

            Text {
                text: root.device.name
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 190)
            }

            Text {
                text: BluetoothService.deviceStatus(root.device)
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.labelSmall
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        // without this, containsMouse stays false until a button is pressed
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: BluetoothService.toggleConnection(root.device)
    }
}
