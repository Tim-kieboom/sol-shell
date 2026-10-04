import QtQuick
import "../singletons"

// A thin horizontal bar that is filled up to `value` (0.0 to 1.0).
Item {
    id: root

    property real value: 0
    property color barColor: Theme.accent

    implicitWidth: 100
    implicitHeight: 6

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.surface

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.barColor
        }
    }
}
