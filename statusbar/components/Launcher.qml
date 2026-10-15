import QtQuick
import "../../singletons"

// A button that opens the application launcher (wofi, see LauncherService), and closes it again.
Item {
    id: root

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: Icons.launcher
        // a little brighter while the mouse is over it
        color: mouse.containsMouse ? Theme.accentHover : Theme.accent
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: LauncherService.toggle()
    }
}
