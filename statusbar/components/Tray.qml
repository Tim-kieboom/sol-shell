import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../singletons"

// The system tray: the little icons programs put here to be reached while they run in the background
// (a chat program, a VPN, a sync tool). Left click opens the program (or its menu, for the ones that
// only have a menu), right click its menu, middle click its second action. A program that says it has
// nothing to tell (`Passive`) is left out. It is not there at all when no program has an icon.
Item {
    id: root

    // the icons that are shown
    readonly property var shown: SystemTray.items.values.filter(item => item.status !== Status.Passive)

    readonly property bool present: shown.length > 0
    visible: present

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: root.shown

            Item {
                id: entry

                required property var modelData

                width: 18
                height: 18

                Image {
                    anchors.fill: parent
                    source: entry.modelData.icon
                    sourceSize: Qt.size(36, 36)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    // dimmed until pointed at, so a row of them stays quiet
                    opacity: mouse.containsMouse ? 1.0 : 0.85
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                    // the menu opens as a window of its own, at this spot of the bar
                    function showMenu(): void {
                        const spot = entry.mapToItem(null, 0, entry.height);
                        entry.modelData.display(QsWindow.window, spot.x, spot.y);
                    }

                    onClicked: mouse => {
                        const item = entry.modelData;
                        if (mouse.button === Qt.LeftButton) {
                            if (item.onlyMenu)
                                showMenu();
                            else
                                item.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (item.hasMenu)
                                showMenu();
                            else
                                item.secondaryActivate();
                        } else {
                            item.secondaryActivate();
                        }
                    }

                    onWheel: wheel => entry.modelData.scroll(wheel.angleDelta.y, false)
                }
            }
        }
    }
}
