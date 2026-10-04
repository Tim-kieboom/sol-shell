import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "./settings"

// The NixOS icon at the left of the bar. Click it to open the power menu.
Item {
    id: root

    property bool popupOpen: false
    // when the popup last closed (ms since 1970), see the MouseArea below
    property double closedAt: 0

    // Which page the popup shows: "menu" (power actions) or "settings".
    // One popup, two pages: that avoids a second window and keeps one grab.
    property string page: "menu"

    // not a power action, so it is described here and not in PowerService
    readonly property var settingsEntry: ({
            id: "settings",
            label: "Settings",
            icon: Icons.settings
        })

    onPopupOpenChanged: {
        if (!popupOpen) {
            // closing the menu disarms a half-confirmed action
            PowerService.cancel();
            // and next time it opens on the first page again
            page = "menu";
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

        // the settings page needs more room than the short menu
        implicitWidth: root.page === "menu" ? 220 : 340
        // size follows whichever page is showing (a hidden one has no say)
        implicitHeight: (root.page === "menu" ? content.implicitHeight : settingsPage.implicitHeight) + 16
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.shellBackground
            border.color: Theme.surfaceBorder
            border.width: 1

            // ---------- page 1: the menu ----------
            ColumnLayout {
                id: content
                visible: root.page === "menu"
                anchors.fill: parent
                anchors.margins: 8
                spacing: 2

                PowerActionRow {
                    Layout.fillWidth: true
                    action: root.settingsEntry
                    needsConfirm: false
                    onActivated: root.page = "settings"
                }

                // thin line between "Settings" and the power actions
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                    height: 1
                    color: Theme.surfaceBorder
                }

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

            // ---------- page 2: settings ----------
            SettingsPage {
                id: settingsPage
                visible: root.page === "settings"
                anchors.fill: parent
                anchors.margins: 8
                onBack: root.page = "menu"
            }
        }
    }
}
