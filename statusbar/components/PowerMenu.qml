import QtQuick
import QtQuick.Layouts
import "../../singletons"

// The NixOS icon at the left of the bar. Click it to open the power menu.
Item {
    id: root

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

        popupWidth: 220
        padding: 8

        // closing the menu disarms a half-confirmed action
        onOpenChanged: {
            if (!open)
                PowerService.cancel();
        }

        // The contents. Built when the popup opens, destroyed when it closes.
        ColumnLayout {
            spacing: 2

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
    }
}
