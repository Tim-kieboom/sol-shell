import QtQuick
import "../singletons"

// A small button of the layout editor: a label in a rounded outline.
Rectangle {
    id: root

    property string text
    // drawn with the accent color
    property bool primary: false
    property bool enabled: true

    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 26
    radius: height / 2
    color: mouse.containsMouse && root.enabled ? Theme.surface : "transparent"
    border.width: primary ? 2 : 1
    border.color: primary ? Theme.accent : Theme.surfaceBorder
    opacity: root.enabled ? 1.0 : 0.5

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Theme.primaryText
        font.family: Fonts.bodyFontFamily
        font.pixelSize: Fonts.labelMedium
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
