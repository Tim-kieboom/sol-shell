import QtQuick
import "../../singletons"

// A coffee cup that keeps the screen awake (see KeepAwakeService): lit while it is on, dim while it
// is off.
Item {
    // this monitor's colors
    readonly property var theme: Theme.forScreen(Window.window?.screen?.name ?? "")
    id: root

    implicitWidth: 26
    implicitHeight: 26

    Text {
        anchors.centerIn: parent
        text: KeepAwakeService.enabled ? Icons.keepAwake : Icons.keepAwakeOff
        color: KeepAwakeService.enabled ? theme.accent : (mouse.containsMouse ? theme.secondaryText : theme.mutedText)
        font.family: Fonts.materialIconFontFamily
        font.pixelSize: Fonts.bodyLarge
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: KeepAwakeService.toggle()
    }
}
