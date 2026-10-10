import QtQuick
import QtQuick.Layouts
import "../../singletons"
import "./settings"

// The NixOS icon at the left of the bar. Click it to open the power menu.
Item {
    id: root

    // Which page the popup shows: "menu" (power actions) or "settings".
    // One popup, two pages: that avoids a second window and keeps one grab.
    property string page: "menu"

    // not a power action, so it is described here and not in PowerService
    readonly property var settingsEntry: ({
            id: "settings",
            label: "Settings",
            icon: Icons.settings
        })

    implicitWidth: 50
    implicitHeight: 30

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1
        text: Icons.nixos
        // a little brighter while hovered or while the menu is open
        color: popup.open || mouse.containsMouse ? Theme.accentHover : Theme.accent
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.headlineMedium
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

        // the settings page needs more room than the short menu
        popupWidth: root.page === "menu" ? 220 : 340
        padding: 8

        onOpenChanged: {
            if (!open) {
                // closing the menu disarms a half-confirmed action
                PowerService.cancel();
                // and next time it opens on the first page again
                root.page = "menu";
            }
        }

        // The contents. Built when the popup opens, destroyed when it closes.
        Item {
            // size follows whichever page is showing (a hidden one has no say)
            implicitHeight: root.page === "menu" ? menu.implicitHeight : settingsPage.implicitHeight

            // ---------- page 1: the menu ----------
            ColumnLayout {
                id: menu
                visible: root.page === "menu"
                width: parent.width
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
                        needsConfirm: modelData.confirm !== false
                        Layout.fillWidth: true
                        // lock and suspend run on the first click, and the menu gets out of the way
                        onActivated: {
                            PowerService.perform(modelData);
                            popup.close();
                        }
                    }
                }
            }

            // ---------- page 2: settings ----------
            // Its own Loader, so the wallpaper thumbnails are only decoded when
            // you actually open the settings page, not every time the menu opens.
            Loader {
                id: settingsPage
                active: root.page === "settings"
                width: parent.width
                readonly property real implicitHeight: item ? item.implicitHeight : 0

                sourceComponent: SettingsPage {
                    onBack: root.page = "menu"
                }
            }
        }
    }
}
