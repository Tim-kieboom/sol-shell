import QtQuick
import "../singletons"

// A horizontal slider for a value from 0 to 1. Click or drag anywhere on it.
//
// It only REPORTS where the user pointed (`moved`); it never changes `value`
// itself. The owner sets `value` from the real state (the actual volume), so the
// slider always shows what is true, even if a change was refused or was made
// somewhere else (a keyboard key, another app).
Item {
    id: root

    property real value: 0          // 0 to 1; anything outside is drawn clamped
    signal moved(real value)        // the value the user pointed at, 0 to 1

    implicitWidth: 200
    implicitHeight: 20

    readonly property real _shown: Math.max(0, Math.min(1, value))
    // the handle stays fully inside the track, so its middle runs from
    // handle/2 to width - handle/2
    readonly property real _handle: 14

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface

        // the filled part runs up to the middle of the handle
        Rectangle {
            width: handle.x + handle.width / 2
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    Rectangle {
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        width: root._handle
        height: root._handle
        radius: width / 2
        x: (root.width - width) * root._shown
        color: Theme.accent
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        // mouse.x in pixels -> 0..1, measured between the handle's two extremes
        function report(x: real): void {
            const half = root._handle / 2;
            root.moved(Math.max(0, Math.min(1, (x - half) / (root.width - root._handle))));
        }

        onPressed: mouse => report(mouse.x)
        // while the button is held down, follow the mouse
        onPositionChanged: mouse => {
            if (pressed)
                report(mouse.x);
        }
    }
}
