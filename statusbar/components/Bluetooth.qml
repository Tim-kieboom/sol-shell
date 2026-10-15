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

        // built when the popup opens, destroyed when it closes
        BluetoothPanel {}
    }
}
