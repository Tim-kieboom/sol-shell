import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../singletons"

// Two icons in the bar (wifi, bluetooth). Clicking either opens one popup with
// a switch and a list for each: nearby wifi networks (with a password prompt
// for new ones) and paired bluetooth devices.
//
// Why an outer Item: a Row sizes itself from its children, so a child that
// sizes itself from the Row (like a MouseArea with anchors.fill) would chase
// its own tail. The Item is sized from the Row, and the MouseArea fills the Item.
Item {
    id: root

    property bool popupOpen: false
    // when the popup last closed (ms since 1970), see the MouseArea below
    property double closedAt: 0

    // Tell NetworkService how many popups are open (it scans for networks and
    // keeps a password prompt only while at least one is). This fires once per
    // open and once per close, so the +1 and -1 always pair up.
    onPopupOpenChanged: {
        NetworkService.viewerCount += popupOpen ? 1 : -1;
        if (!popupOpen)
            closedAt = Date.now();
    }

    // If this bar disappears while its popup is open (a monitor is unplugged),
    // the close above never fires, so give back our +1 here.
    Component.onDestruction: {
        if (popupOpen)
            NetworkService.viewerCount -= 1;
    }

    implicitWidth: icons.implicitWidth
    implicitHeight: 26

    Row {
        id: icons
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        // `enabled` here only dims the icon (off = grey). Clicks are handled by
        // the MouseArea below, so the popup still opens when wifi is off.
        MediaButton {
            text: NetworkService.enabled ? Icons.wifi : Icons.wifiOff
            enabled: NetworkService.enabled
        }

        MediaButton {
            text: Icons.bluetooth
            enabled: BluetoothService.enabled
        }
    }

    // Declared after the icons, so it sits on top and gets the clicks
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.popupOpen) {
                root.popupOpen = false;
            } else if (Date.now() - root.closedAt > 400) {
                // With grabFocus, a click outside the popup (this icon counts as
                // outside) already closes it. Without this check, that same click
                // would then reopen it. Ignore an open request that arrives right
                // after a close.
                root.popupOpen = true;
            }
        }
    }

    PopupWindow {
        // the popup is positioned relative to this item
        anchor.item: root
        // attach to the item's bottom-right corner, then grow down and to the
        // left, so the popup stays on screen at the right end of the bar
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 6

        visible: root.popupOpen
        // Grab the keyboard (needed to type a password) and let the compositor
        // close the popup when you click anywhere else. Must be set while hidden.
        grabFocus: true
        // The compositor can close the popup by itself (click outside); mirror
        // that into popupOpen so our own state doesn't go out of date.
        onVisibleChanged: root.popupOpen = visible

        implicitWidth: 280
        implicitHeight: content.implicitHeight + 24
        // the window itself is see-through; the Rectangle below draws the panel
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.shellBackground
            border.color: Theme.surfaceBorder
            border.width: 1

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 12
                spacing: 14

                ConnectivityRow {
                    Layout.fillWidth: true
                    icon: NetworkService.enabled ? Icons.wifi : Icons.wifiOff
                    title: "Wi-Fi"
                    subtitle: NetworkService.statusText
                    checked: NetworkService.enabled
                    onToggled: NetworkService.toggle()
                }

                // The network list. There can be a dozen networks, so it lives
                // in a Flickable: a window onto taller content that scrolls
                // with the mouse wheel. Its height is the content's height, up
                // to a maximum of 190px, after which it scrolls.
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(networkList.implicitHeight, 190)
                    visible: NetworkService.enabled
                    contentHeight: networkList.implicitHeight
                    clip: true   // hide rows that are scrolled out of the window
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: networkList
                        width: parent.width
                        spacing: 2

                        Repeater {
                            // ScriptModel compares the new list with the old one and
                            // only adds/removes/moves rows that actually changed. With a
                            // plain array every scan would rebuild all rows, wiping a
                            // half-typed password and the keyboard focus.
                            model: ScriptModel {
                                values: NetworkService.networks
                            }

                            WifiNetworkRow {
                                required property var modelData
                                network: modelData
                                width: networkList.width
                            }
                        }

                        Text {
                            visible: NetworkService.networks.length === 0
                            text: "Searching for networks..."
                            color: Theme.secondaryText
                            font.family: Fonts.bodyFontFamily
                            font.pixelSize: Fonts.labelSmall
                        }
                    }
                }

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
}
