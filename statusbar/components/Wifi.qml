import QtQuick
import "../../singletons"

// The wifi icon in the bar. Clicking it opens a popup with a switch and the list of
// nearby wifi networks (with a password prompt for new ones). While a cable is connected an
// ethernet icon sits next to it.
Item {
    id: root

    implicitWidth: icons.implicitWidth
    implicitHeight: 26

    // `enabled` here only dims the icon (off = grey). Clicks are handled by
    // the MouseArea below, so the popup still opens when wifi is off.
    Row {
        id: icons
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            visible: NetworkService.wiredConnected
            text: Icons.ethernet
            color: Theme.accent
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        IconButton {
            id: icon
            text: NetworkService.enabled ? Icons.wifi : Icons.wifiOff
            enabled: NetworkService.enabled
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

        // built when the popup opens, destroyed when it closes (and it counts as a viewer
        // of NetworkService for as long as it lives)
        WifiPanel {}
    }
}
