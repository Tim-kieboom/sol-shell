import QtQuick
import "../singletons"

// An on/off switch. Like IconButton it only reports clicks (the signal) and
// shows whatever `checked` says; the owner decides what a click does.
Rectangle {
    id: root

    property bool checked: false
    signal toggled

    implicitWidth: 36
    implicitHeight: 20
    radius: height / 2
    color: checked ? Theme.accent : Theme.surface

    // Behavior = "whenever this property changes, animate it instead of jumping"
    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    // the knob
    Rectangle {
        width: parent.height - 6
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        // 3px from the left edge when off, 3px from the right edge when on
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? Theme.accentText : Theme.secondaryText

        Behavior on x {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
