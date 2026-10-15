import QtQuick
import QtQuick.Layouts
import "../../singletons"

// An icon for a NixOS update, shown only while there is something to say: a newer nixpkgs than the
// one the system was built from, or a restart for a kernel that was rebuilt (see UpdateService).
// Click it for the details, and to ask again. It only tells you; it rebuilds nothing.
Item {
    id: root

    readonly property bool present: UpdateService.anyActive
    visible: present

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: Icons.update
        color: mouse.containsMouse || popup.open ? Theme.accentHover : Theme.accent
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
        popupWidth: 300

        ColumnLayout {
            spacing: 10

            ColumnLayout {
                visible: UpdateService.updateAvailable
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "A newer nixpkgs is available"
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodyMedium
                    font.weight: Font.Medium
                }

                Text {
                    text: UpdateService.branch + ": " + UpdateService.shortRevision(UpdateService.runningRevision) + " -> " + UpdateService.shortRevision(UpdateService.remoteRevision)
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodySmall
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Update the flake and rebuild to get it."
                    color: Theme.mutedText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodySmall
                }
            }

            ColumnLayout {
                visible: UpdateService.restartNeeded
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "A restart is needed"
                    color: Theme.primaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodyMedium
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "The kernel that is running is not the one of the newest build."
                    color: Theme.secondaryText
                    font.family: Fonts.bodyFontFamily
                    font.pixelSize: Fonts.bodySmall
                }
            }

            Text {
                visible: UpdateService.failure !== ""
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Could not check for updates: " + UpdateService.failure
                color: Theme.danger
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }

            ListRow {
                Layout.fillWidth: true
                icon: Icons.update
                title: UpdateService.checking ? "Checking..." : "Check now"
                subtitle: UpdateService.checkedAt ? "Last checked " + Qt.formatDateTime(UpdateService.checkedAt, "HH:mm") : ""
                onClicked: UpdateService.check()
            }
        }
    }
}
