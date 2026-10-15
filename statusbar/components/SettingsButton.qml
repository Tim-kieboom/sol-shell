import QtQuick
import "../../singletons"

// The gear in the bar. Click it to open the settings window. Every bar style has to include
// it (the settings can also be opened with `sol-shell ipc call settings open`).
Item {
    id: root

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: Icons.settings
        color: SettingsService.open || mouse.containsMouse ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: SettingsService.toggle()
    }
}
