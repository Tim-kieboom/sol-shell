import QtQuick
import QtQuick.Layouts
import "../../singletons"

// A shield-like icon while a VPN is up (see VpnService). It is not there when none is. Click it for
// which ones.
Item {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    // there is nothing to show without a VPN; `present` is how BarRenderer finds out
    readonly property bool present: VpnService.anyActive
    visible: present

    implicitWidth: icon.implicitWidth
    implicitHeight: 26

    // the service looks at the interfaces only while an item like this exists
    Component.onCompleted: VpnService.viewerCount += 1
    Component.onDestruction: VpnService.viewerCount -= 1

    Text {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.vpn
        color: mouse.containsMouse || popup.open ? theme.accentHover : theme.success
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup

        alignRight: true
        popupWidth: 240

        ColumnLayout {
            spacing: 6

            Text {
                text: "VPN connected"
                color: theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }

            Repeater {
                model: VpnService.active

                RowLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: modelData.name
                        color: theme.primaryText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodyMedium
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: modelData.kind
                        color: theme.mutedText
                        font.family: Fonts.bodyFontFamily
                        font.pixelSize: Fonts.bodySmall
                    }
                }
            }
        }
    }
}
