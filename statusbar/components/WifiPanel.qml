import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The Wi-Fi panel: a switch and the list of nearby networks (with a password prompt for new
// ones). It is what the Wi-Fi atom's popup shows, and one page of the quick settings menu.
//
// It tells NetworkService that someone is looking (it scans for networks and keeps a password
// prompt only while at least one panel exists), once when it is built and once when it is
// thrown away, so the +1 and -1 always pair up, wherever the panel lives.
ColumnLayout {
    id: root

    Component.onCompleted: NetworkService.viewerCount += 1
    Component.onDestruction: NetworkService.viewerCount -= 1

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
}
