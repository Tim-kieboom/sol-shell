import QtQuick
import "../singletons"

// The handle to drag a whole pill or the dropdown by (a small column of dots at its left end). Pressing it
// starts a drag of the container, with everything in it; the chips inside are dragged by themselves.
Item {
    id: root

    // "pill" or "menu"
    required property string kind
    // for a pill: the name of one of the items directly in it (that is how the editor finds the pill)
    property string ref: ""
    required property var editor

    implicitWidth: 14
    implicitHeight: 26

    Column {
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: 3

            Row {
                spacing: 3

                Repeater {
                    model: 2

                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: mouse.containsMouse ? Theme.accent : Theme.mutedText
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.OpenHandCursor
        preventStealing: true

        onPressed: m => {
            root.editor.beginContainerDrag(root.kind, root.ref);
            root.editor.dragTo(mapToItem(root.editor, m.x, m.y));
        }
        onPositionChanged: m => {
            if (pressed)
                root.editor.dragTo(mapToItem(root.editor, m.x, m.y));
        }
        onReleased: root.editor.endDrag()
        onCanceled: root.editor.cancelDrag()
    }
}
