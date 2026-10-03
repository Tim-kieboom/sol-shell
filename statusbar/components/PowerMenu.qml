import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The NixOS icon at the left of the bar. Click it to open the power menu.
Item {
    id: root

    property bool popupOpen: false
    // when the popup last closed (ms since 1970), see the MouseArea below
    property double closedAt: 0

    onPopupOpenChanged: {
        if (!popupOpen) {
            // closing the menu disarms a half-confirmed action
            PowerService.cancel();
            closedAt = Date.now();
        }
    }

    implicitWidth: 50
    implicitHeight: 30

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        text: Icons.nixos
        // a little brighter while hovered or while the menu is open
        color: root.popupOpen || mouse.containsMouse ? Theme.accentHover : Theme.accent
        font.family: Fonts.bodyFontFamily
        font.pixelSize: 28
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.popupOpen) {
                root.popupOpen = false;
            } else if (Date.now() - root.closedAt > 400) {
                // the grab already closes the popup on a click outside it, and this
                // icon counts as "outside"; without this check the same click would
                // reopen it right away
                root.popupOpen = true;
            }
        }
    }

    PopupWindow {
        anchor.item: root
        // attach to the icon's bottom-LEFT corner and grow down and to the right,
        // the mirror image of the wifi popup (which is at the right end of the bar)
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.top: 6

        visible: root.popupOpen
        // click anywhere else closes it
        grabFocus: true
        // keep our state in sync when the compositor closes it
        onVisibleChanged: root.popupOpen = visible

        implicitWidth: 220
        implicitHeight: content.implicitHeight + 16
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
                anchors.margins: 8
                spacing: 2

                Repeater {
                    // the actions come from PowerService; one row per entry
                    model: PowerService.actions

                    PowerActionRow {
                        required property var modelData
                        action: modelData
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
