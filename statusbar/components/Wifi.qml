import QtQuick
import "../../singletons"

// The wifi icon in the bar. Clicking it opens a popup with a switch and the list of
// nearby wifi networks (with a password prompt for new ones).
Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: 26

    // `enabled` here only dims the icon (off = grey). Clicks are handled by
    // the MouseArea below, so the popup still opens when wifi is off.
    IconButton {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        text: NetworkService.enabled ? Icons.wifi : Icons.wifiOff
        enabled: NetworkService.enabled
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

        // built when the popup opens, destroyed when it closes (and it counts as a viewer
        // of NetworkService for as long as it lives)
        WifiPanel {}
    }
}
