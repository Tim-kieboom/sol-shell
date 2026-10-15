import QtQuick
import "../../singletons"

// The keyboard layout in use ("US", "NL"). Click it for the next layout, scroll over it to go
// forward or back. With one layout there is nothing to switch to.
Item {
    id: root

    implicitWidth: text.implicitWidth
    implicitHeight: 26

    Text {
        id: text
        anchors.verticalCenter: parent.verticalCenter
        text: KeyboardLayoutService.label
        color: mouse.containsMouse ? Theme.accentHover : Theme.secondaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.bodyMedium
        font.weight: Font.Medium
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        // nothing to switch to with one layout: the pointer says so by staying an arrow
        cursorShape: KeyboardLayoutService.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: KeyboardLayoutService.next()
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                KeyboardLayoutService.previous();
            else
                KeyboardLayoutService.next();
        }
    }
}
