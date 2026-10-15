import QtQuick
import QtQuick.Layouts
import "../../singletons"

// How long the computer has been on ("7h 46m"). Click it for the time it was switched on.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 26

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.uptime
            color: mouse.containsMouse || popup.open ? Theme.accentHover : Theme.accent
            font.family: Fonts.materialIconFontFamily
            font.pixelSize: Fonts.bodyLarge
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: UptimeService.text
            color: Theme.secondaryText
            font.family: Fonts.bodyFontFamily
            font.pixelSize: Fonts.bodyMedium
            font.weight: Font.Medium
        }
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
            spacing: 2

            Text {
                text: "Switched on"
                color: Theme.secondaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodySmall
            }

            Text {
                text: Qt.formatDateTime(UptimeService.bootTime, "dddd d MMMM, HH:mm")
                color: Theme.primaryText
                font.family: Fonts.bodyFontFamily
                font.pixelSize: Fonts.bodyMedium
                font.weight: Font.Medium
            }
        }
    }
}
